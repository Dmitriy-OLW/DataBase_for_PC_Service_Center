SET search_path TO Service_Centers_Schema;

-- Задание 1
-- Запрос для выявления запчастей с низким спросом и высокой стоимостью хранения
SELECT p.Parts_id, p.name, p.count, p.price, 
        COALESCE(part_usage.usage_count, 0) as usage_count,   -- Количество использований детали в заказах
       p.price * p.count as total_inventory_value    -- Общая стоимость запасов на складе
FROM Parts p
-- Используем JOIN для включения всех деталей
LEFT JOIN (
    -- подсчитываем сколько раз каждая деталь использовалась в заказах
    SELECT part_id, COUNT(part_id) as usage_count
    FROM OrderContent
    GROUP BY part_id
) part_usage ON p.Parts_id = part_usage.part_id
-- Фильтруем детали неиспользуемые, использованные менее 3 раз
WHERE part_usage.usage_count IS NULL OR part_usage.usage_count < 3
ORDER BY total_inventory_value DESC;



-- Задание 2
-- Запрос для анализа эффективности сотрудников
SELECT e.Employees_id, e.full_name, e.position, e.experience, e.salary,
    COUNT(DISTINCT o.Orders_id) AS completed_orders,  -- Количество уникальных заказов, выполненных сотрудником
    ROUND(AVG(o.completion_date - o.order_date)::numeric, 2) AS avg_completion_days, -- Среднее время выполнения заказа в днях
    COALESCE(SUM(r.final_price), 0) AS total_revenue     -- Общий доход от выполненных заказов
FROM 
    Employees e
LEFT JOIN Orders o ON o.service_center_id IN (e.primary_service_center_id, e.secondary_service_center_id)
LEFT JOIN Receipts r ON r.order_id = o.Orders_id
WHERE 
    o.completion_date IS NOT NULL    -- только завершенные заказы
    AND e.position = 'technician'
	AND o.completion_date >= CURRENT_DATE - INTERVAL '1 year' -- последний год
GROUP BY 
    e.Employees_id
ORDER BY 
    total_revenue DESC,
    avg_completion_days ASC;
-- Сортировка по общему доходу (по убыванию) и среднему времени выполнения (по возрастанию)


-- Задание 3
-- Запрос для определения сотрудников, заслуживающих премии
SELECT 
    e.Employees_id, 
    e.full_name,
    -- Количество выполненных заказов за последние 3 месяца, с удаление дубликатов
    COUNT(DISTINCT o.Orders_id) as completed_orders,
    -- Среднее время выполнения заказа в днях
    ROUND(AVG(o.completion_date - o.order_date)::numeric, 2) as avg_completion_time,
    -- Количество бронирований, с удаление дубликатов
    COUNT(DISTINCT b.Bookings_id) as bookings_handled,
    -- Общая сумма выручки от заказов
    SUM(o.total_cost) as total_revenue,
    -- Рейтинг сотрудника по выручке 
    RANK() OVER (ORDER BY SUM(o.total_cost) DESC) as revenue_rank
FROM 
    Employees e
-- Соединение с таблицей заказов 
LEFT JOIN Orders o ON e.Employees_id = o.service_center_id
-- Соединение с таблицей бронирований
LEFT JOIN Bookings b ON e.Employees_id = b.employee_id
-- Фильтрация только завершенные заказы за последние 3 месяца
WHERE o.completion_date BETWEEN CURRENT_DATE - INTERVAL '3 months' AND CURRENT_DATE
GROUP BY 
    e.Employees_id
-- Сортировка по рейтингу выручки
ORDER BY 
    revenue_rank;


-- Задание 4
-- Использование существующей функции create_booking_with_check
-- Создаем тестовое бронирование
SELECT Service_Centers_Schema.create_booking_with_check(
    78,
    (SELECT Services_id FROM Service_Centers_Schema.Services LIMIT 1),
    2,
    CURRENT_DATE + 1,
    '10:00:00'
);

-- Пытаемся создать бронирование на то же время (должна быть ошибка)
SELECT Service_Centers_Schema.create_booking_with_check(
    78,
    (SELECT Services_id FROM Service_Centers_Schema.Services LIMIT 1),
    2,
    CURRENT_DATE + 1,
    '10:30:00'
);


-- Задание 5
-- Запрос для расчета ключевых метрик сервиса
SELECT 
    sc.SC_id as service_center_id,
    sc.address as service_center_address,
    -- Общее количество уникальных заказов
    COUNT(DISTINCT o.Orders_id) as total_orders,
    -- Общее количество уникальных бронирований
    COUNT(DISTINCT b.Bookings_id) as total_bookings,
    -- Количество уникальных клиентов
    COUNT(DISTINCT c.Clients_id) as unique_clients,
    -- Суммарная выручка 
    SUM(r.final_price) as total_revenue,
    -- Среднее время выполнения услуги
    ROUND(AVG(o.completion_date - o.order_date)::numeric, 2) as avg_service_time,
    -- Количество премиум-клиентов
    COUNT(DISTINCT CASE WHEN c.status = 'Premium' THEN c.Clients_id END) as premium_clients,
    -- Количество деталей с низким запасом
    (SELECT COUNT(*) FROM Parts p WHERE p.count <= 5 AND p.location_id = sc.SC_id) as low_stock_parts
FROM ServiceCenters_and_StorageCenters sc
LEFT JOIN Orders o ON sc.SC_id = o.service_center_id --Объеденяем таблицы
LEFT JOIN Receipts r ON o.Orders_id = r.order_id
LEFT JOIN Clients c ON o.client_id = c.Clients_id
LEFT JOIN Bookings b ON o.client_id = b.client_id
GROUP BY sc.SC_id, sc.address
ORDER BY sc.SC_id;


-- Задание 6
-- Запрос для анализа исторических данных и выявления сезонных тенденций
SELECT 
    -- месяц из даты заказа для анализа сезонности
    EXTRACT(MONTH FROM o.order_date) as month,
    -- количество заказов в каждом месяце
    COUNT(o.Orders_id) as order_count,
    -- общее количество использованных запчастей
    COUNT(oc.part_id) as parts_used,
    -- Группируем по типам устройств для анализа по категориям
    s.for_device as device_type,
    -- Рассчитываем среднюю стоимость заказа
    ROUND(AVG(o.total_cost)::numeric, 2) as avg_order_value
FROM Orders o
-- JOIN таблицы для получения информации о заказах
JOIN OrderContent oc ON o.Orders_id = oc.order_id
JOIN Services s ON oc.services_id = s.Services_id
GROUP BY month, s.for_device
ORDER BY month, s.for_device;



-- Задание 7
-- Пример транзакции для безопасного создания чека
BEGIN;
-- Блокировка строки заказа для предотвращения параллельных изменений
SELECT * FROM Orders WHERE Orders_id = 79 FOR UPDATE;


-- Создание чека
SELECT create_receipt_for_order(
    p_order_id => 79,
    p_payment_method => 'credit_card',
    p_discount => 0.1
);

COMMIT;

-- Проверяем результат
SELECT * FROM Service_Centers_Schema.Receipts;









BEGIN;
-- Блокируем клиента для предотвращения параллельных изменений
SELECT * FROM Service_Centers_Schema.Clients WHERE Clients_id = 4 FOR UPDATE;

-- Создаем заказ
INSERT INTO Service_Centers_Schema.Orders (client_id, service_center_id, device, order_date)
VALUES (4, 3, 'computer', CURRENT_DATE);

SELECT * FROM Orders;

-- Добавляем услуги в заказ
INSERT INTO Service_Centers_Schema.OrderContent (order_id, services_id, part_id)
VALUES (79, 5, 2);

SELECT Service_Centers_Schema.calculate_order_cost(79);

-- Создаем чек
SELECT create_receipt_for_order(79, 'cash', 0);
COMMIT;


SELECT * FROM OrderContent;
SELECT * FROM Orders;
SELECT * FROM Receipts;




-- Задание 8
-- Анализ сезонности по месяцам
SELECT 
    EXTRACT(MONTH FROM order_date) AS month,  -- месяц из даты заказа
    COUNT(*) AS orders_count,                 -- количество заказов
    SUM(total_cost) AS total_revenue         -- Сумма общей выручки
FROM Orders
GROUP BY EXTRACT(MONTH FROM order_date)     
ORDER BY month;                              

-- Анализ сезонности по неделям
SELECT 
    EXTRACT(WEEK FROM order_date) AS week_number,  -- номер недели из даты заказа
    COUNT(*) AS orders_count,                       -- количество заказов
    SUM(total_cost) AS total_revenue 
FROM Orders
GROUP BY EXTRACT(WEEK FROM order_date)            
ORDER BY week_number;                              


-- Анализ популярности услуг по сезонам
-- Выводит статистику заказов услуг по месяцам
SELECT 
    EXTRACT(MONTH FROM o.order_date) AS month,  -- Извлекаем месяц из даты заказа
    s.name AS service_name,                     -- Название услуги
    COUNT(*) AS service_count                   -- Количество заказов с каждой услуги
FROM Service_Centers_Schema.Orders o
JOIN Service_Centers_Schema.OrderContent oc ON o.Orders_id = oc.order_id  
JOIN Service_Centers_Schema.Services s ON oc.services_id = s.Services_id  
GROUP BY EXTRACT(MONTH FROM o.order_date), s.name 
ORDER BY month, service_count DESC;               

-- Анализ спроса на запчасти по месяцам
-- Выводит статистику заказов запчастей по месяцам
SELECT 
    EXTRACT(MONTH FROM o.order_date) AS month,  -- Извлекаем месяц из даты заказа
    p.name AS part_name,                        -- Название запчасти
    COUNT(*) AS part_count                      -- Количество заказов с каждой запчасти
FROM Service_Centers_Schema.Orders o
JOIN Service_Centers_Schema.OrderContent oc ON o.Orders_id = oc.order_id 
JOIN Service_Centers_Schema.Parts p ON oc.part_id = p.Parts_id          
GROUP BY EXTRACT(MONTH FROM o.order_date), p.name 
ORDER BY month, part_count DESC;                  

















-- Задание 9

-- Подготовка данных для кластеризации клиентов
SELECT 
    c.Clients_id,         
    c.status,              
    COUNT(o.Orders_id) AS orders_count,           -- Общее количество заказов клиента
    SUM(r.final_price) AS total_spent,            -- Сумма всех покупок клиента
    ROUND(AVG(r.final_price)::numeric, 2) AS avg_order_value,        -- Средний чек клиента
    MAX(o.order_date) - MIN(o.order_date) AS client_tenure_days,  -- разница между первой и последней покупкой
    COUNT(DISTINCT o.device) AS device_types_used -- Количество различных устройств, с которых делались заказы
FROM Clients c
LEFT JOIN Orders o ON c.Clients_id = o.client_id      -- JOIN клиентов с их заказами
LEFT JOIN Receipts r ON o.Orders_id = r.order_id     -- JOIN заказы с чеками
GROUP BY c.Clients_id, c.status;                     


-- Задание 10

-- Анализ спроса на запчасти за последний месяц
SELECT 
    p.Parts_id,                 
    p.name,                      
    p.count AS current_stock,     
    COUNT(oc.part_id) AS demand_last_month,  -- Количество заказов этой запчасти за последний месяц
    COALESCE(ROUND(AVG(pp.quantity)::numeric, 0), 0)  AS avg_purchase_quantity  -- Среднее количество при закупке
FROM Parts p
LEFT JOIN OrderContent oc ON p.Parts_id = oc.part_id
-- JOIN для данных о закупках 
LEFT JOIN PartsPurchases pp ON p.Parts_id = pp.part_id
GROUP BY p.Parts_id; 


-- Задание 11
-- Анализ загруженности слотов - заполненность временных слотов по датам и времени
SELECT 
    booking_date,
    booking_time,
    COUNT(*) AS bookings_count,  -- Количество бронирований в каждом слоте
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Employees WHERE position = 'technician')::numeric, 2) AS utilization_percentage  -- процент заполненности слотов
FROM Bookings
GROUP BY booking_date, booking_time
ORDER BY utilization_percentage DESC; 

-- Анализ пиковых часов - анализирует нагрузку по часам дня
SELECT 
    EXTRACT(HOUR FROM booking_time) AS hour,  -- часы из времени бронирования
    COUNT(*) AS total_bookings,  -- количество бронирований в час
    ROUND(AVG(COUNT(*)) OVER ()::numeric, 2) AS avg_bookings,  -- Среднее количество бронирований по всем часам
    ROUND(COUNT(*) / AVG(COUNT(*)) OVER ()::numeric, 2) AS percentage_of_avg  --  соотношение к среднему значению
FROM Bookings
GROUP BY EXTRACT(HOUR FROM booking_time)
ORDER BY percentage_of_avg DESC;  


-- Задание 12
-- Выявление запчастей для обмена между сервисными центрами

SELECT 
    p.Parts_id,                  
    p.name,                      
    p.count AS current_stock,
    sc1.SC_id AS location_id,     
    sc1.address AS location_address,
    EXTRACT(MONTH FROM o.order_date) AS month,
    COUNT(*) AS part_count
FROM Parts p
JOIN ServiceCenters_and_StorageCenters sc1 ON p.location_id = sc1.SC_id
LEFT JOIN Service_Centers_Schema.OrderContent oc ON oc.part_id = p.Parts_id
LEFT JOIN Service_Centers_Schema.Orders o ON o.Orders_id = oc.order_id
GROUP BY p.Parts_id, p.name, p.count, sc1.SC_id, sc1.address, EXTRACT(MONTH FROM o.order_date)
ORDER BY month, part_count DESC;




-- Функция обмена запчастями
CREATE OR REPLACE FUNCTION initiate_part_transfer(
    p_part_id INT,          -- ID запчасти для передачи
    p_from_location INT,   -- ID склада-отправителя
    p_to_location INT,     -- ID склада-получателя
    p_quantity INT         -- Количество для передачи
)
RETURNS TEXT AS $$
DECLARE
    v_current_stock INT;   -- Переменная для хранения текущего количества на складе
    v_remaining_stock INT; -- Переменная для хранения остатка после передачи
BEGIN
    -- Проверка наличия достаточного количества запчастей на складе-отправителя
    SELECT count INTO v_current_stock
    FROM Parts
    WHERE Parts_id = p_part_id AND location_id = p_from_location;
    
    -- Если запись не найдена или недостаточно - возвращается сообщение об ошибке
    IF v_current_stock IS NULL THEN
        RETURN 'Запчасть не найдена на складе-отправителе';
    ELSIF v_current_stock < p_quantity THEN
        RETURN 'Недостаточно запчастей для передачи';
    END IF;
    
    -- Вычисляем остаток после передачи
    v_remaining_stock := v_current_stock - p_quantity;
    
    -- Если остаток будет 0 - удаляем запись
    IF v_remaining_stock = 0 THEN
        DELETE FROM Parts
        WHERE Parts_id = p_part_id AND location_id = p_from_location;
    ELSE
        -- Иначе уменьшаем количество на складе-отправителя
        UPDATE Parts
        SET count = v_remaining_stock
        WHERE Parts_id = p_part_id AND location_id = p_from_location;
    END IF;
    
    -- Проверка есть ли уже такая запчасть на складе-получателе
    IF EXISTS (SELECT 1 FROM Parts WHERE Parts_id = p_part_id AND location_id = p_to_location) THEN
        -- Если есть - увеличивается количество
        UPDATE Parts
        SET count = count + p_quantity
        WHERE Parts_id = p_part_id AND location_id = p_to_location;
    ELSE
        -- Если нет - создается новая запись с указанным количеством
        INSERT INTO Parts (Parts_id, name, description, count, price, for_device, location_id)
        SELECT Parts_id, name, description, p_quantity, price, for_device, p_to_location
        FROM Parts
        WHERE Parts_id = p_part_id AND location_id = p_from_location;
    END IF;
    
    -- Сообщение об успешной передаче
    RETURN 'Успешно передано ' || p_quantity || ' единиц запчасти ID ' || p_part_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



SELECT * FROM Service_Centers_Schema.Parts;

SELECT initiate_part_transfer(
   1,
    1,
    2,
    5
) AS transfer_result;


SELECT * FROM Service_Centers_Schema.Parts;

-- Задание 13

-- Анализ востребованности и прибыльности запчастей и услуг
SELECT 
    'Service' AS type,  
    s.Services_id AS id,
    s.name,  -- Название услуги
    COUNT(oc.services_id) AS demand,  -- Количество заказов для этой услуги
    SUM(s.price) AS total_revenue  -- Общая выручка от услуги
FROM Services s
LEFT JOIN OrderContent oc ON s.Services_id = oc.services_id  -- JOIN услуги с заказами
GROUP BY s.Services_id  -- Группируем по ID услуги

UNION ALL  -- Объединяем с результатами по запчастям

SELECT 
    'Part' AS type,  
    p.Parts_id AS id,  
    p.name,  -- Название запчасти
    COUNT(oc.part_id) AS demand,  -- Количество заказов для этой запчасти 
    SUM(p.price) AS total_revenue  -- Общая выручка от запчасти
FROM Parts p
LEFT JOIN OrderContent oc ON p.Parts_id = oc.part_id  -- Соединяем запчасти с заказами
GROUP BY p.Parts_id  -- Группируем по ID запчасти
ORDER BY total_revenue DESC;  -- Сортируем по общей выручке (по убыванию)


-- Задание 14

-- Расчет процента занятости временных слотов для записи
SELECT 
    booking_date,  -- Дата бронирования
    booking_time,  -- Время бронирования
    -- процента занятости: количество записей в слоте * 100 / общее количество техников
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Employees WHERE position = 'technician')::numeric, 2) AS occupancy_percentage
FROM Bookings
-- данные за последнюю неделю
WHERE booking_date BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
GROUP BY booking_date, booking_time
ORDER BY occupancy_percentage DESC;




-- Задание 16

SET search_path TO Service_Centers_Schema;


-- Удаляем таблицу, если она уже существует
DROP TABLE IF EXISTS Service_Centers_Schema.client_service_dataset;

-- Создаем новую таблицу с актуальными данными
CREATE TABLE Service_Centers_Schema.client_service_dataset AS
WITH 
client_visits AS (
    SELECT 
        client_id, 
        COUNT(*) AS visit_count
    FROM Service_Centers_Schema.Orders
    GROUP BY client_id
),
booking_info AS (
    SELECT 
        b.client_id,
        COUNT(b.Bookings_id) AS total_bookings,
        STRING_AGG(DISTINCT e.full_name, ', ') AS booked_employees,
        STRING_AGG(DISTINCT s.name, ', ') AS booked_services
    FROM Service_Centers_Schema.Bookings b
    LEFT JOIN Service_Centers_Schema.Employees e ON b.employee_id = e.Employees_id
    LEFT JOIN Service_Centers_Schema.Services s ON b.service_id = s.Services_id
    GROUP BY b.client_id
)

SELECT
    c.Clients_id AS client_id,
    c.full_name AS client_name,
    c.status AS client_status,
    c.bonus_points,
    cv.visit_count,
    o.Orders_id AS order_id,
    o.order_date,
    o.completion_date,
    CASE 
        WHEN o.completion_date IS NOT NULL AND o.order_date IS NOT NULL 
        THEN (o.completion_date - o.order_date)::INT
        ELSE NULL 
    END AS days_to_complete,
    o.device AS device_type,
    o.total_cost AS order_total,
    sc.SC_id AS service_center_id,
    sc.address AS service_center_address,
    sc.type AS service_center_type,
    s.Services_id AS service_id,
    s.name AS service_name,
    s.price AS service_price,
    s.for_device AS service_for_device,
    p.Parts_id AS part_id,
    p.name AS part_name,
    p.price AS part_price,
    bi.total_bookings,
    bi.booked_employees,
    bi.booked_services,
    r.final_total_cost,
    r.discount,
    r.final_price,
    r.payment_method,
    r.pay_status,
    e.Employees_id AS employee_id,
    e.full_name AS employee_name
FROM Service_Centers_Schema.Clients c
LEFT JOIN Service_Centers_Schema.Orders o ON c.Clients_id = o.client_id
LEFT JOIN Service_Centers_Schema.ServiceCenters_and_StorageCenters sc ON o.service_center_id = sc.SC_id
LEFT JOIN Service_Centers_Schema.OrderContent oc ON o.Orders_id = oc.order_id
LEFT JOIN Service_Centers_Schema.Services s ON oc.services_id = s.Services_id
LEFT JOIN Service_Centers_Schema.Parts p ON oc.part_id = p.Parts_id
LEFT JOIN Service_Centers_Schema.Receipts r ON o.Orders_id = r.order_id
LEFT JOIN client_visits cv ON c.Clients_id = cv.client_id
LEFT JOIN booking_info bi ON c.Clients_id = bi.client_id
LEFT JOIN Service_Centers_Schema.Bookings b ON c.Clients_id = b.client_id
LEFT JOIN Service_Centers_Schema.Employees e ON b.employee_id = e.Employees_id;

SELECT * FROM Service_Centers_Schema.client_service_dataset;

-- Удаляем таблицу, если она уже существует
DROP TABLE IF EXISTS Service_Centers_Schema.client_service_dataset;







-- Задание 18




SELECT 
    c.Clients_id,
    c.full_name,
    c.status,
    STRING_AGG(DISTINCT s.name, ', ') AS used_services,
    STRING_AGG(DISTINCT p.name, ', ') AS purchased_parts,
    c.bonus_points,
    
    -- Получаем последнюю услугу клиента
    ('Клиенту была предоставлена следующая услуга - ' || (SELECT s.name FROM Services s 
     JOIN OrderContent oc ON s.Services_id = oc.services_id 
     JOIN Orders o ON oc.order_id = o.Orders_id 
     WHERE o.client_id = c.Clients_id 
     ORDER BY o.order_date DESC LIMIT 1)  || 
    '. Предложите клиенту услугу, дополняющую заказ.') AS last_service,
    
    -- Основная рекомендация (скидка + предложение услуги)
    CASE 
        WHEN c.status = 'Premium' THEN
            CASE 
                WHEN (SELECT MAX(r.final_total_cost) FROM Receipts r WHERE r.client_id = c.Clients_id) > 30000 THEN
                    CASE 
                        WHEN (SELECT MAX(o.order_date) FROM Orders o WHERE o.client_id = c.Clients_id) < CURRENT_DATE - INTERVAL '1 month' THEN
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 25%. Предложить чистку консоли.'
                                        ELSE
                                            'Скидка 20%. Предложить диагностику консоли.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 22%. Предложить чистку ПК.'
                                        ELSE
                                            'Скидка 18%. Предложить диагностику ПК.'
                                    END
                            END
                        ELSE
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 20%. Предложить замену термопасты консоли.'
                                        ELSE
                                            'Скидка 15%. Предложить настройку геймпада.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 18%. Предложить замену термопасты ПК.'
                                        ELSE
                                            'Скидка 12%. Предложить настройку BIOS.'
                                    END
                            END
                    END
                ELSE
                    CASE 
                        WHEN (SELECT MAX(o.order_date) FROM Orders o WHERE o.client_id = c.Clients_id) < CURRENT_DATE - INTERVAL '1 month' THEN
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 18%. Предложить чистку консоли.'
                                        ELSE
                                            'Скидка 15%. Предложить диагностику консоли.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 15%. Предложить чистку ПК.'
                                        ELSE
                                            'Скидка 12%. Предложить диагностику ПК.'
                                    END
                            END
                        ELSE
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 15%. Предложить замену термопасты консоли.'
                                        ELSE
                                            'Скидка 10%. Предложить настройку геймпада.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 12%. Предложить замену термопасты ПК.'
                                        ELSE
                                            'Скидка 8%. Предложить настройку BIOS.'
                                    END
                            END
                    END
            END
        WHEN c.status = 'Regular' THEN
            CASE 
                WHEN (SELECT MAX(r.final_total_cost) FROM Receipts r WHERE r.client_id = c.Clients_id) > 20000 THEN
                    CASE 
                        WHEN (SELECT MAX(o.order_date) FROM Orders o WHERE o.client_id = c.Clients_id) < CURRENT_DATE - INTERVAL '1 month' THEN
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 18%. Предложить чистку консоли.'
                                        ELSE
                                            'Скидка 15%. Предложить диагностику консоли.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 15%. Предложить чистку ПК.'
                                        ELSE
                                            'Скидка 12%. Предложить диагностику ПК.'
                                    END
                            END
                        ELSE
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 15%. Предложить замену термопасты консоли.'
                                        ELSE
                                            'Скидка 10%. Предложить настройку геймпада.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 12%. Предложить замену термопасты ПК.'
                                        ELSE
                                            'Скидка 8%. Предложить настройку BIOS.'
                                    END
                            END
                    END
                ELSE
                    CASE 
                        WHEN (SELECT MAX(o.order_date) FROM Orders o WHERE o.client_id = c.Clients_id) < CURRENT_DATE - INTERVAL '1 month' THEN
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 12%. Предложить чистку консоли.'
                                        ELSE
                                            'Скидка 10%. Предложить диагностику консоли.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 10%. Предложить чистку ПК.'
                                        ELSE
                                            'Скидка 8%. Предложить диагностику ПК.'
                                    END
                            END
                        ELSE
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 10%. Предложить замену термопасты консоли.'
                                        ELSE
                                            'Скидка 5%. Предложить настройку геймпада.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 8%. Предложить замену термопасты ПК.'
                                        ELSE
                                            'Скидка 5%. Предложить настройку BIOS.'
                                    END
                            END
                    END
            END
        ELSE
            CASE 
                WHEN (SELECT MAX(r.final_total_cost) FROM Receipts r WHERE r.client_id = c.Clients_id) > 10000 THEN
                    CASE 
                        WHEN (SELECT MAX(o.order_date) FROM Orders o WHERE o.client_id = c.Clients_id) < CURRENT_DATE - INTERVAL '1 month' THEN
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 10%. Предложить чистку консоли.'
                                        ELSE
                                            'Скидка 8%. Предложить диагностику консоли.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 8%. Предложить чистку ПК.'
                                        ELSE
                                            'Скидка 5%. Предложить диагностику ПК.'
                                    END
                            END
                        ELSE
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 8%. Предложить замену термопасты консоли.'
                                        ELSE
                                            'Скидка 5%. Предложить настройку геймпада.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 5%. Предложить замену термопасты ПК.'
                                        ELSE
                                            'Скидка 3%. Предложить настройку BIOS.'
                                    END
                            END
                    END
                ELSE
                    CASE 
                        WHEN (SELECT MAX(o.order_date) FROM Orders o WHERE o.client_id = c.Clients_id) < CURRENT_DATE - INTERVAL '1 month' THEN
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 5%. Предложить чистку консоли.'
                                        ELSE
                                            'Скидка 3%. Предложить диагностику консоли.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 3%. Предложить чистку ПК.'
                                        ELSE
                                            'Скидка 0%. Предложить диагностику ПК.'
                                    END
                            END
                        ELSE
                            CASE 
                                WHEN (SELECT o.device FROM Orders o WHERE o.client_id = c.Clients_id ORDER BY o.order_date DESC LIMIT 1) = 'console' THEN
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 3%. Предложить замену термопасты консоли.'
                                        ELSE
                                            'Скидка 0%. Предложить настройку геймпада.'
                                    END
                                ELSE
                                    CASE 
                                        WHEN EXISTS (SELECT 1 FROM OrderContent oc JOIN Orders o ON oc.order_id = o.Orders_id WHERE o.client_id = c.Clients_id AND oc.part_id IS NOT NULL ORDER BY o.order_date DESC LIMIT 1) THEN
                                            'Скидка 0%. Предложить замену термопасты ПК.'
                                        ELSE
                                            'Скидка 0%. Предложить настройку BIOS.'
                                    END
                            END
                    END
            END
    END AS recommendation,
    
    -- Дополнительное предложение на основе бонусных баллов
    CASE 
        WHEN c.bonus_points > 0 THEN
            'У вас ' || c.bonus_points || ' бонусных баллов, мы можем предложить вам ' || 
            COALESCE(
                (SELECT name FROM Services WHERE price <= c.bonus_points ORDER BY RANDOM() LIMIT 1),
                'дополнительную услугу при следующем визите'
            )
        ELSE
            'У вас пока нет бонусных баллов'
    END AS bonus_offer
    
FROM 
    Clients c
LEFT JOIN Orders o ON c.Clients_id = o.client_id
LEFT JOIN OrderContent oc ON o.Orders_id = oc.order_id
LEFT JOIN Services s ON oc.services_id = s.Services_id
LEFT JOIN Parts p ON oc.part_id = p.Parts_id
GROUP BY 
    c.Clients_id, c.full_name, c.status, c.bonus_points;

