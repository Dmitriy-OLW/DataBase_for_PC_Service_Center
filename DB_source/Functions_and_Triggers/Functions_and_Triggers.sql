-- Функция для обновления статуса клиента при добавлении нового чека
CREATE OR REPLACE FUNCTION update_client_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Service_Centers_Schema.Clients
    SET status = CASE
        WHEN (SELECT COALESCE(SUM(final_price), 0) FROM Service_Centers_Schema.Receipts WHERE client_id = NEW.client_id) >= 10000 THEN 'Premium'::status
        WHEN (SELECT COALESCE(SUM(final_price), 0) FROM Service_Centers_Schema.Receipts WHERE client_id = NEW.client_id) >= 5000 THEN 'Regular'::status
        ELSE 'Ordinary'::status
    END
    WHERE Clients_id = NEW.client_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для обновления статуса клиента при добавлении нового чека
CREATE TRIGGER trg_update_client_status
AFTER INSERT OR UPDATE ON Service_Centers_Schema.Receipts
FOR EACH ROW
EXECUTE FUNCTION update_client_status();

-- Функция для сгорания бонусов раз в год
CREATE OR REPLACE FUNCTION burn_client_bonuses()
RETURNS VOID AS $$
BEGIN
    UPDATE Service_Centers_Schema.Clients
    SET bonus_points = 0
    WHERE bonus_points > 0
    AND EXTRACT(YEAR FROM CURRENT_DATE) > EXTRACT(YEAR FROM (
        SELECT MAX(payment_date) FROM Service_Centers_Schema.Receipts 
        WHERE client_id = Clients_id
    ));
END;
$$ LANGUAGE plpgsql;

-- Функция для перевода клиента к другому мастеру
CREATE OR REPLACE FUNCTION transfer_client_to_another_technician(
    p_client_id INT,
    p_new_technician_id INT,
    p_service_center_id INT
)
RETURNS VOID AS $$
BEGIN

    
    -- Обновляем бронирования клиента
    UPDATE Service_Centers_Schema.Bookings
    SET employee_id = p_new_technician_id
    WHERE client_id = p_client_id
    AND employee_id IN (
        SELECT Employees_id FROM Service_Centers_Schema.Employees
        WHERE primary_service_center_id = p_service_center_id
        OR secondary_service_center_id = p_service_center_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;













CREATE OR REPLACE FUNCTION calculate_order_cost(p_order_id INT)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    v_total_cost DECIMAL(10, 2) := 0;
BEGIN
    -- Calculate sum of services in the order
    SELECT COALESCE(SUM(s.price), 0) INTO v_total_cost
    FROM Service_Centers_Schema.OrderContent oc
    JOIN Service_Centers_Schema.Services s ON oc.services_id = s.Services_id
    WHERE oc.order_id = p_order_id;
    
    -- Add sum of parts in the order
    SELECT v_total_cost + COALESCE(SUM(p.price), 0) INTO v_total_cost
    FROM Service_Centers_Schema.OrderContent oc
    JOIN Service_Centers_Schema.Parts p ON oc.part_id = p.Parts_id
    WHERE oc.order_id = p_order_id;
    
    -- Update the total_cost in Orders table
    UPDATE Service_Centers_Schema.Orders
    SET total_cost = v_total_cost
    WHERE Orders_id = p_order_id;
    
    RETURN v_total_cost;
END;
$$ LANGUAGE plpgsql;

-- Функция для создания чека при завершении заказа

CREATE OR REPLACE FUNCTION create_receipt_for_order(
    p_order_id INT,
    p_payment_method VARCHAR(50),
    p_discount DECIMAL(10, 2) DEFAULT 0
)
RETURNS INT AS $$
DECLARE
    v_client_id INT;
    v_final_total_cost DECIMAL(10, 2);
    v_final_price DECIMAL(10, 2);
    v_bonus_points_used INT;
    v_receipt_id INT;
BEGIN
    -- Получаем ID клиента для заказа
    SELECT client_id INTO v_client_id
    FROM Service_Centers_Schema.Orders
    WHERE Orders_id = p_order_id;
    
    -- Проверяем и сжигаем бонусные баллы, если нужно (только для текущего клиента)
    UPDATE Service_Centers_Schema.Clients
    SET bonus_points = 0
    WHERE Clients_id = v_client_id
    AND bonus_points > 0
    AND EXTRACT(YEAR FROM CURRENT_DATE) > EXTRACT(YEAR FROM (
        SELECT MAX(payment_date) FROM Service_Centers_Schema.Receipts 
        WHERE client_id = v_client_id
    ));
    
    -- Рассчитываем общую стоимость заказа
    v_final_total_cost := calculate_order_cost(p_order_id);
    
    -- Определяем сколько бонусных баллов можно использовать (не более 20% от стоимости)
    v_bonus_points_used := LEAST(
        (SELECT bonus_points FROM Service_Centers_Schema.Clients WHERE Clients_id = v_client_id),
        FLOOR(v_final_total_cost * 0.2)
    );
    
    -- Рассчитываем итоговую цену с учетом скидки и бонусов
    v_final_price := v_final_total_cost * (1 - p_discount) - v_bonus_points_used;
    
    -- Создаем чек
    INSERT INTO Service_Centers_Schema.Receipts (
        order_id, client_id, final_total_cost, discount, 
        final_price, payment_method
    )
    VALUES (
        p_order_id, v_client_id, v_final_total_cost, p_discount,
        v_final_price, p_payment_method
    )
    RETURNING Receipts_id INTO v_receipt_id;
    
    -- Обновляем бонусные баллы клиента (вычитаем использованные и добавляем 5% от покупки)
    UPDATE Service_Centers_Schema.Clients
    SET bonus_points = bonus_points - v_bonus_points_used + FLOOR(v_final_price * 0.05) 
    WHERE Clients_id = v_client_id;
    
    -- Обновляем информацию о заказе (дата завершения и итоговая стоимость)
    UPDATE Service_Centers_Schema.Orders
    SET completion_date = CURRENT_DATE,
        total_cost = v_final_price
    WHERE Orders_id = p_order_id;
    
    RETURN v_receipt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Триггер для проверки доступности запчастей при добавлении в заказ
CREATE OR REPLACE FUNCTION check_part_availability()
RETURNS TRIGGER AS $$
DECLARE
    v_part_count INT;
BEGIN
    IF NEW.part_id IS NOT NULL THEN
        SELECT count INTO v_part_count
        FROM Service_Centers_Schema.Parts
        WHERE Parts_id = NEW.part_id;
        
        IF v_part_count <= 0 THEN
            RAISE EXCEPTION 'Запрашиваемая запчасть отсутствует на складе';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_part_availability
BEFORE INSERT ON Service_Centers_Schema.OrderContent
FOR EACH ROW
EXECUTE FUNCTION check_part_availability();

-- Триггер для уменьшения количества запчастей при добавлении в заказ
CREATE OR REPLACE FUNCTION decrease_part_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.part_id IS NOT NULL THEN
        UPDATE Service_Centers_Schema.Parts
        SET count = count - 1
        WHERE Parts_id = NEW.part_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrease_part_count
AFTER INSERT ON Service_Centers_Schema.OrderContent
FOR EACH ROW
EXECUTE FUNCTION decrease_part_count();

















-- Функция для проверки доступности времени бронирования
CREATE OR REPLACE FUNCTION check_booking_availability(
    p_employee_id INT,
    p_booking_date DATE,
    p_booking_time TIME
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_available BOOLEAN;
BEGIN
    SELECT NOT EXISTS (
        SELECT 1 FROM Service_Centers_Schema.Bookings
        WHERE employee_id = p_employee_id
        AND booking_date = p_booking_date
        AND booking_time BETWEEN (p_booking_time - INTERVAL '1 hour') AND (p_booking_time + INTERVAL '1 hour')
    ) INTO v_is_available;
    
    RETURN v_is_available;
END;
$$ LANGUAGE plpgsql STABLE;

-- Функция для создания бронирования с проверкой доступности
CREATE OR REPLACE FUNCTION create_booking_with_check(
    p_client_id INT,
    p_service_id INT,
    p_employee_id INT,
    p_booking_date DATE,
    p_booking_time TIME
)
RETURNS INT AS $$
DECLARE
    v_booking_id INT;
BEGIN
    -- Проверяем доступность времени
    IF NOT check_booking_availability(p_employee_id, p_booking_date, p_booking_time) THEN
        RAISE EXCEPTION 'Выбранное время уже занято или слишком близко к другому бронированию';
    END IF;
    
    -- Создаем бронирование
    INSERT INTO Service_Centers_Schema.Bookings (
        client_id, service_id, employee_id, booking_date, booking_time
    )
    VALUES (
        p_client_id, p_service_id, p_employee_id, p_booking_date, p_booking_time
    )
    RETURNING Bookings_id INTO v_booking_id;
    
    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;










CREATE OR REPLACE FUNCTION check_booking_availability(
    p_employee_id INT,
    p_booking_date DATE,
    p_booking_time TIME
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_available BOOLEAN;
BEGIN
    SELECT NOT EXISTS (
        SELECT 1 FROM Service_Centers_Schema.Bookings
        WHERE employee_id = p_employee_id
        AND booking_date = p_booking_date
        AND booking_time BETWEEN (p_booking_time - INTERVAL '1 hour') AND (p_booking_time + INTERVAL '1 hour')
    ) INTO v_is_available;
    
    RETURN v_is_available;
END;
$$ LANGUAGE plpgsql STABLE;











CREATE OR REPLACE FUNCTION suggest_booking_alternatives(
    p_client_id INT,
    p_service_id INT,
    p_employee_id INT,
    p_booking_date DATE,
    p_booking_time TIME
)
RETURNS TABLE (
    alternative_center_id INT,
    alternative_center_address VARCHAR(255),
    alternative_date DATE,
    alternative_time TIME,
    alternative_employee_id INT,
    alternative_employee_name VARCHAR(255)
) AS $$
BEGIN
    -- Проверяем, занят ли запрошенный слот
    IF NOT (SELECT check_booking_availability(p_employee_id, p_booking_date, p_booking_time)) THEN
        -- Возвращаем альтернативные временные слоты у того же мастера (если он техник)
        RETURN QUERY
        SELECT 
            e.primary_service_center_id AS alternative_center_id,
            sc.address AS alternative_center_address,
            p_booking_date AS alternative_date,
            t.time_slot::time AS alternative_time,
            p_employee_id AS alternative_employee_id,
            e.full_name AS alternative_employee_name
        FROM Service_Centers_Schema.Employees e
        JOIN Service_Centers_Schema.ServiceCenters_and_StorageCenters sc 
            ON e.primary_service_center_id = sc.SC_id
        CROSS JOIN generate_series(
            (p_booking_date || ' 09:00:00')::timestamp,
            (p_booking_date || ' 18:00:00')::timestamp,
            '1 hour'::interval
        ) AS t(time_slot)
        WHERE e.Employees_id = p_employee_id
        AND e.position = 'technician'
        AND NOT EXISTS (
            SELECT 1 FROM Service_Centers_Schema.Bookings b
            WHERE b.employee_id = p_employee_id
            AND b.booking_date = p_booking_date
            AND b.booking_time = t.time_slot::time
        )
        LIMIT 3;
        
        -- Если не найдено свободных слотов у того же мастера, предлагаем другие филиалы
        IF NOT FOUND THEN
            RETURN QUERY
            SELECT 
                sc.SC_id AS alternative_center_id,
                sc.address AS alternative_center_address,
                p_booking_date AS alternative_date,
                t.time_slot::time AS alternative_time,
                e.Employees_id AS alternative_employee_id,
                e.full_name AS alternative_employee_name
            FROM Service_Centers_Schema.ServiceCenters_and_StorageCenters sc
            JOIN Service_Centers_Schema.Employees e ON sc.SC_id = e.primary_service_center_id
            CROSS JOIN generate_series(
                (p_booking_date || ' 09:00:00')::timestamp,
                (p_booking_date || ' 18:00:00')::timestamp,
                '1 hour'::interval
            ) AS t(time_slot)
            WHERE sc.SC_id != (SELECT primary_service_center_id FROM Service_Centers_Schema.Employees WHERE Employees_id = p_employee_id)
            AND sc.type = (SELECT type FROM Service_Centers_Schema.ServiceCenters_and_StorageCenters 
                          WHERE SC_id = (SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
                                         WHERE Employees_id = p_employee_id))
            AND e.position = 'technician'
            AND NOT EXISTS (
                SELECT 1 FROM Service_Centers_Schema.Bookings b
                WHERE b.employee_id = e.Employees_id
                AND b.booking_date = p_booking_date
                AND b.booking_time = t.time_slot::time
            )
            ORDER BY random()
            LIMIT 3;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;




-- Функция для создания бронирования с проверкой доступности
CREATE OR REPLACE FUNCTION create_booking_with_check(
    p_client_id INT,
    p_service_id INT,
    p_employee_id INT,
    p_booking_date DATE,
    p_booking_time TIME
)
RETURNS TEXT AS $$
DECLARE
    v_booking_id INT;
    v_alternatives TEXT;
BEGIN
    -- Проверяем доступность времени
    IF NOT check_booking_availability(p_employee_id, p_booking_date, p_booking_time) THEN
        -- Собираем информацию о доступных альтернативах
        SELECT string_agg(
            format('Центр: %s (%s), Дата: %s, Время: %s, Мастер: %s (ID: %s)', 
                   alternative_center_address, 
                   alternative_center_id, 
                   alternative_date, 
                   alternative_time, 
                   alternative_employee_name, 
                   alternative_employee_id),
            E';  '
        ) INTO v_alternatives
        FROM suggest_booking_alternatives(
            p_client_id, p_service_id, p_employee_id, p_booking_date, p_booking_time
        );
        
        RETURN format(
            'Выбранное время уже занято или слишком близко к другому бронированию. Доступные альтернативы:%s%s',
            E'   ',
            COALESCE(v_alternatives, 'Нет доступных альтернатив')
        );
    END IF;
    
    -- Создаем бронирование
    INSERT INTO Service_Centers_Schema.Bookings (
        client_id, service_id, employee_id, booking_date, booking_time
    )
    VALUES (
        p_client_id, p_service_id, p_employee_id, p_booking_date, p_booking_time
    )
    RETURNING Bookings_id INTO v_booking_id;
    
    RETURN 'Бронирование успешно создано, ID: ' || v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;






-- 1. функция для получения статистики бронирований по датам
CREATE OR REPLACE FUNCTION get_bookings_statistics_by_date(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    booking_date DATE,
    bookings_count INT,
    unique_clients_count INT,
    most_popular_service VARCHAR(255))
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.booking_date,
        COUNT(b.Bookings_id)::INT AS bookings_count,
        COUNT(DISTINCT b.client_id)::INT AS unique_clients_count,
        (SELECT s.name FROM Service_Centers_Schema.Services s 
         WHERE s.Services_id = (
             SELECT b2.service_id 
             FROM Service_Centers_Schema.Bookings b2
             WHERE b2.booking_date = b.booking_date 
             GROUP BY b2.service_id 
             ORDER BY COUNT(*) DESC 
             LIMIT 1
         )) AS most_popular_service
    FROM Service_Centers_Schema.Bookings b
    WHERE b.booking_date BETWEEN p_start_date AND p_end_date
    GROUP BY b.booking_date
    ORDER BY b.booking_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;




-- 2. функция для получения наиболее востребованных услуг
CREATE OR REPLACE FUNCTION get_popular_services_stats(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    service_id INTEGER,
    service_name VARCHAR(255),
    bookings_count INTEGER,
    unique_clients_count INTEGER,
    completed_orders_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.Services_id::INTEGER,
        s.name::VARCHAR(255),
        COUNT(b.Bookings_id)::INTEGER,
        COUNT(DISTINCT b.client_id)::INTEGER,
        COUNT(o.Orders_id)::INTEGER
    FROM Service_Centers_Schema.Services s
    LEFT JOIN Service_Centers_Schema.Bookings b ON s.Services_id = b.service_id
        AND b.booking_date BETWEEN p_start_date AND p_end_date
    LEFT JOIN Service_Centers_Schema.OrderContent oc ON s.Services_id = oc.services_id
    LEFT JOIN Service_Centers_Schema.Orders o ON oc.order_id = o.Orders_id
        AND o.order_date BETWEEN p_start_date AND p_end_date
    GROUP BY s.Services_id, s.name
    ORDER BY COUNT(b.Bookings_id) DESC, COUNT(o.Orders_id) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Функция для получения статистики по выполненным услугам 


DROP FUNCTION IF EXISTS get_completed_services_stats(date, date);

-- Создаем новую функцию с правильным расчетом времени выполнения
CREATE OR REPLACE FUNCTION get_completed_services_stats(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    service_name VARCHAR(255),
    completed_count INTEGER,
    total_revenue DECIMAL(10,2),
    avg_completion_days DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name::VARCHAR(255) AS service_name,
        COUNT(oc.OrderContent_id)::INTEGER AS completed_count,
        COALESCE(SUM(s.price), 0)::DECIMAL(10,2) AS total_revenue,
        AVG(o.completion_date - o.order_date)::DECIMAL(10,2) AS avg_completion_days
    FROM Service_Centers_Schema.Services s
    JOIN Service_Centers_Schema.OrderContent oc ON s.Services_id = oc.services_id
    JOIN Service_Centers_Schema.Orders o ON oc.order_id = o.Orders_id
    WHERE o.completion_date IS NOT NULL
    AND o.completion_date BETWEEN p_start_date AND p_end_date
    GROUP BY s.Services_id, s.name
    ORDER BY completed_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


