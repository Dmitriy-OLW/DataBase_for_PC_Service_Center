-- Создание ролей
CREATE ROLE administrator;
CREATE ROLE analyst;
CREATE ROLE technician;
CREATE ROLE manager;


-- Создание пользователей-администраторов
CREATE USER "Андреев Максим Викторович" WITH PASSWORD '12345';
GRANT administrator TO "Андреев Максим Викторович";

CREATE USER "Николаев Артем Дмитриевич" WITH PASSWORD '12345';
GRANT administrator TO "Николаев Артем Дмитриевич";

-- Создание пользователей-аналитиков
CREATE USER "Соболев Александр Игоревич" WITH PASSWORD '12345';
GRANT analyst TO "Соболев Александр Игоревич";

CREATE USER "Власова Ольга Сергеевна" WITH PASSWORD '12345';
GRANT analyst TO "Власова Ольга Сергеевна";

-- Создание пользователей-менеджеров
CREATE USER "Кузнецова Анна Михайловна" WITH PASSWORD '12345';
GRANT manager TO "Кузнецова Анна Михайловна";

CREATE USER "Павлова Виктория Сергеевна" WITH PASSWORD '12345';
GRANT manager TO "Павлова Виктория Сергеевна";

CREATE USER "Ларина Анна Сергеевна" WITH PASSWORD '12345';
GRANT manager TO "Ларина Анна Сергеевна";

-- Создание пользователей-техников
CREATE USER "Иванов Иван Иванович" WITH PASSWORD '12345';
GRANT technician TO "Иванов Иван Иванович";

CREATE USER "Петров Петр Петрович" WITH PASSWORD '12345';
GRANT technician TO "Петров Петр Петрович";

CREATE USER "Смирнов Дмитрий Сергеевич" WITH PASSWORD '12345';
GRANT technician TO "Смирнов Дмитрий Сергеевич";

CREATE USER "Васильева Елена Андреевна" WITH PASSWORD '12345';
GRANT technician TO "Васильева Елена Андреевна";

CREATE USER "Николаева Ольга Викторовна" WITH PASSWORD '12345';
GRANT technician TO "Николаева Ольга Викторовна";

CREATE USER "Алексеев Артем Игоревич" WITH PASSWORD '12345';
GRANT technician TO "Алексеев Артем Игоревич";



-- Привилегии для администраторов (полный доступ ко всему)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Service_Centers_Schema TO administrator;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Service_Centers_Schema TO administrator;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA Service_Centers_Schema TO administrator;
GRANT USAGE ON SCHEMA Service_Centers_Schema TO administrator;

-- Привилегии для аналитиков (только чтение)
GRANT SELECT ON ALL TABLES IN SCHEMA Service_Centers_Schema TO analyst;
GRANT USAGE ON SCHEMA Service_Centers_Schema TO analyst;

-- Привилегии для техников

GRANT USAGE ON SCHEMA Service_Centers_Schema TO technician;
-- Чтение
GRANT SELECT ON Service_Centers_Schema.Services TO technician;
GRANT SELECT ON Service_Centers_Schema.Orders TO technician;
GRANT SELECT ON Service_Centers_Schema.Parts TO technician;
GRANT SELECT ON Service_Centers_Schema.Clients TO technician;
GRANT SELECT ON Service_Centers_Schema.PartsPurchases TO technician;
GRANT SELECT ON Service_Centers_Schema.OrderContent TO technician;
GRANT SELECT ON Service_Centers_Schema.Employees TO technician;

-- Обновление
GRANT UPDATE ON Service_Centers_Schema.Orders TO technician;
GRANT UPDATE ON Service_Centers_Schema.Parts TO technician;
GRANT UPDATE ON Service_Centers_Schema.PartsPurchases TO technician;
GRANT UPDATE ON Service_Centers_Schema.OrderContent TO technician;

-- Вставка
GRANT INSERT ON Service_Centers_Schema.PartsPurchases TO technician;

-- Привилегии для менеджеров

GRANT USAGE ON SCHEMA Service_Centers_Schema TO manager;
-- Чтение
GRANT SELECT ON Service_Centers_Schema.Clients TO manager;
GRANT SELECT ON Service_Centers_Schema.Orders TO manager;
GRANT SELECT ON Service_Centers_Schema.Bookings TO manager;
GRANT SELECT ON Service_Centers_Schema.OrderContent TO manager;
GRANT SELECT ON Service_Centers_Schema.Receipts TO manager;
GRANT SELECT ON Service_Centers_Schema.Services TO manager;
GRANT SELECT ON Service_Centers_Schema.Parts TO manager;
GRANT SELECT ON Service_Centers_Schema.Employees TO manager;
GRANT SELECT ON Service_Centers_Schema.PartsPurchases TO manager;

-- Обновление
GRANT UPDATE ON Service_Centers_Schema.Clients TO manager;
GRANT UPDATE ON Service_Centers_Schema.Orders TO manager;
GRANT UPDATE ON Service_Centers_Schema.Bookings TO manager;
GRANT UPDATE ON Service_Centers_Schema.OrderContent TO manager;
GRANT UPDATE ON Service_Centers_Schema.Receipts TO manager;
GRANT UPDATE ON Service_Centers_Schema.Services TO manager;
GRANT UPDATE ON Service_Centers_Schema.Parts TO manager;

-- Вставка
GRANT INSERT ON Service_Centers_Schema.Clients TO manager;
GRANT INSERT ON Service_Centers_Schema.Orders TO manager;
GRANT INSERT ON Service_Centers_Schema.Bookings TO manager;
GRANT INSERT ON Service_Centers_Schema.OrderContent TO manager;
GRANT INSERT ON Service_Centers_Schema.Receipts TO manager;

-- Включение RLS для всех таблиц
ALTER TABLE Service_Centers_Schema.ServiceCenters_and_StorageCenters ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.Employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.Clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.Orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.Receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.Bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.OrderContent ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.Parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE Service_Centers_Schema.PartsPurchases ENABLE ROW LEVEL SECURITY;

-- Политики для администраторов (полный доступ)

-- Политики для таблицы ServiceCenters_and_StorageCenters (полный доступ для администраторов)
CREATE POLICY admin_sc_full_access ON ServiceCenters_and_StorageCenters
    FOR ALL TO administrator
    USING (true) WITH CHECK (true);

-- Политики для таблицы Employees (полный доступ для администраторов)
CREATE POLICY admin_employees_full_access ON Employees
    FOR ALL TO administrator
    USING (true) WITH CHECK (true);

-- Политики для таблицы Clients (чтение всех, запись только для клиентов своих сервисных центров)
CREATE POLICY admin_clients_select ON Clients
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_clients_modify ON Clients
    FOR ALL TO administrator
    USING (
        Clients_id IN (
            SELECT client_id FROM Orders
            WHERE service_center_id IN (
                SELECT primary_service_center_id FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    )
    WITH CHECK (true);

-- Остальные политики (аналогично предыдущему варианту, но с учетом схемы)

-- Политика для таблицы Parts
CREATE POLICY admin_parts_select ON Parts
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_parts_modify ON Parts
    FOR ALL TO administrator
    USING (
        location_id IN (
            SELECT primary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    )
    WITH CHECK (
        true
    );

-- Политика для таблицы Orders
CREATE POLICY admin_orders_select ON Orders
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_orders_modify ON Orders
    FOR ALL TO administrator
    USING (
        service_center_id IN (
            SELECT primary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    )
    WITH CHECK (
        service_center_id IN (
            SELECT primary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    );

-- Политика для таблицы Receipts
CREATE POLICY admin_receipts_select ON Receipts
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_receipts_modify ON Receipts
    FOR ALL TO administrator
    USING (
        EXISTS (
            SELECT 1 FROM Orders 
            WHERE Orders.Orders_id = Receipts.order_id 
            AND Orders.service_center_id IN (
                SELECT primary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM Orders 
            WHERE Orders.Orders_id = Receipts.order_id 
            AND Orders.service_center_id IN (
                SELECT primary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    );

-- Политика для таблицы Bookings
CREATE POLICY admin_bookings_select ON Bookings
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_bookings_modify ON Bookings
    FOR ALL TO administrator
    USING (
        employee_id IS NULL OR
        employee_id IN (
            SELECT Employees_id FROM Employees
            WHERE full_name = current_user
            OR primary_service_center_id IN (
                SELECT primary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    )
    WITH CHECK (
        employee_id IS NULL OR
        employee_id IN (
            SELECT Employees_id FROM Employees
            WHERE full_name = current_user
            OR primary_service_center_id IN (
                SELECT primary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    );

-- Политика для таблицы OrderContent
CREATE POLICY admin_ordercontent_select ON OrderContent
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_ordercontent_modify ON OrderContent
    FOR ALL TO administrator
    USING (
        EXISTS (
            SELECT 1 FROM Orders 
            WHERE Orders.Orders_id = OrderContent.order_id 
            AND Orders.service_center_id IN (
                SELECT primary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM Orders 
            WHERE Orders.Orders_id = OrderContent.order_id 
            AND Orders.service_center_id IN (
                SELECT primary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id 
                FROM Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    );

-- Политика для таблицы PartsPurchases
CREATE POLICY admin_partspurchases_select ON PartsPurchases
    FOR SELECT TO administrator
    USING (true);

CREATE POLICY admin_partspurchases_modify ON PartsPurchases
    FOR ALL TO administrator
    USING (
        delivery_location_id IN (
            SELECT primary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id 
            FROM Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    )
    WITH CHECK (
        true
    );




-- Права на последовательности (если есть другие последовательности кроме указанной)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA Service_Centers_Schema TO administrator;


-- Политики для аналитиков (только чтение)
CREATE POLICY analyst_read_only ON Service_Centers_Schema.ServiceCenters_and_StorageCenters
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.Employees
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.Clients
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.Orders
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.Receipts
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.Bookings
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.OrderContent
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.Parts
    FOR SELECT TO analyst USING (true);
CREATE POLICY analyst_read_only ON Service_Centers_Schema.PartsPurchases
    FOR SELECT TO analyst USING (true);

-- Политики для техников (ограниченный доступ по сервисному центру)
-- Services - only read access
-- Политика доступа техников к таблице Employees (только своя запись)
CREATE POLICY tech_employees_self ON Service_Centers_Schema.Employees
    FOR SELECT TO technician
    USING (full_name = current_user);

CREATE POLICY tech_services_access ON Service_Centers_Schema.Services
    FOR SELECT TO technician USING (true);

-- Orders - read and update only for their service centers
CREATE POLICY tech_orders_select ON Service_Centers_Schema.Orders
    FOR SELECT TO technician 
    USING (service_center_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

CREATE POLICY tech_orders_update ON Service_Centers_Schema.Orders
    FOR UPDATE TO technician
    USING (service_center_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ))
    WITH CHECK (service_center_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

-- Parts - read and update only for their service centers
CREATE POLICY tech_parts_select ON Service_Centers_Schema.Parts
    FOR SELECT TO technician
    USING (location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

CREATE POLICY tech_parts_update ON Service_Centers_Schema.Parts
    FOR UPDATE TO technician
    USING (location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ))
    WITH CHECK (location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

-- Clients - read only clients from their service centers
CREATE POLICY tech_clients_select ON Service_Centers_Schema.Clients
    FOR SELECT TO technician
    USING (Clients_id IN (
        SELECT client_id FROM Service_Centers_Schema.Orders 
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ));

-- PartsPurchases - read, update and insert only for their service centers
CREATE POLICY tech_parts_purchases_select ON Service_Centers_Schema.PartsPurchases
    FOR SELECT TO technician
    USING (delivery_location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

CREATE POLICY tech_parts_purchases_update ON Service_Centers_Schema.PartsPurchases
    FOR UPDATE TO technician
    USING (delivery_location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ))
    WITH CHECK (delivery_location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

CREATE POLICY tech_parts_purchases_insert ON Service_Centers_Schema.PartsPurchases
    FOR INSERT TO technician
    WITH CHECK (delivery_location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

-- OrderContent - read and update only for orders from their service centers
CREATE POLICY tech_order_content_select ON Service_Centers_Schema.OrderContent
    FOR SELECT TO technician
    USING (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders 
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ));

CREATE POLICY tech_order_content_update ON Service_Centers_Schema.OrderContent
    FOR UPDATE TO technician
    USING (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders 
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ))
    WITH CHECK (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders 
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ));

GRANT USAGE, SELECT ON SEQUENCE Service_Centers_Schema.partspurchases_partspurchases_id_seq TO technician;



-- Политики для менеджеров (ограниченный доступ по сервисному центру)
-- Clients - full access to clients from their service centers
-- Создаем отдельные политики для SELECT, UPDATE и DELETE

CREATE POLICY manager_clients_select ON Service_Centers_Schema.Clients
    FOR SELECT TO manager
    USING (
        -- Клиенты, связанные с сервисными центрами менеджера
        Clients_id IN (
            SELECT client_id FROM Service_Centers_Schema.Orders
            WHERE service_center_id IN (
                SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
        OR
        -- Клиенты без заказов
        NOT EXISTS (
            SELECT 1 FROM Service_Centers_Schema.Orders
            WHERE Orders.client_id = Clients.Clients_id
        )
    );

CREATE POLICY manager_clients_update ON Service_Centers_Schema.Clients
    FOR UPDATE TO manager
    USING (
        Clients_id IN (
            SELECT client_id FROM Service_Centers_Schema.Orders
            WHERE service_center_id IN (
                SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
                WHERE full_name = current_user
                UNION
                SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
                WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
            )
        )
    )
    WITH CHECK (true);  -- Разрешаем обновление, если запись изначально доступна


-- Политика для INSERT (без ограничений)
CREATE POLICY manager_clients_insert ON Service_Centers_Schema.Clients
    FOR INSERT TO manager
    WITH CHECK (true);

-- Orders - full access to orders from their service centers
CREATE POLICY manager_orders_all ON Service_Centers_Schema.Orders
    FOR ALL TO manager
    USING (service_center_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ))
    WITH CHECK (service_center_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

-- Bookings - full access to bookings from their service centers
CREATE POLICY manager_bookings_all ON Service_Centers_Schema.Bookings
    FOR ALL TO manager
    USING (employee_id IN (
        SELECT Employees_id FROM Service_Centers_Schema.Employees
        WHERE full_name = current_user
        OR primary_service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
        OR secondary_service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ))
    WITH CHECK (employee_id IN (
        SELECT Employees_id FROM Service_Centers_Schema.Employees
        WHERE full_name = current_user
        OR primary_service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
        OR secondary_service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ));

-- OrderContent - full access to order content from their service centers
CREATE POLICY manager_order_content_all ON Service_Centers_Schema.OrderContent
    FOR ALL TO manager
    USING (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ))
    WITH CHECK (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ));

-- Receipts - full access to receipts from their service centers
CREATE POLICY manager_receipts_all ON Service_Centers_Schema.Receipts
    FOR ALL TO manager
    USING (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ))
    WITH CHECK (order_id IN (
        SELECT Orders_id FROM Service_Centers_Schema.Orders
        WHERE service_center_id IN (
            SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user
            UNION
            SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
            WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
        )
    ));

-- Services - read and update access
CREATE POLICY manager_services_select ON Service_Centers_Schema.Services
    FOR SELECT TO manager USING (true);

CREATE POLICY manager_services_update ON Service_Centers_Schema.Services
    FOR UPDATE TO manager USING (true) WITH CHECK (true);

-- Parts - read and update access for their service centers
CREATE POLICY manager_parts_select ON Service_Centers_Schema.Parts
    FOR SELECT TO manager
    USING (location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

CREATE POLICY manager_parts_update ON Service_Centers_Schema.Parts
    FOR UPDATE TO manager
    USING (location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ))
    WITH CHECK (location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

-- Employees - read only access to employees from their service centers


CREATE FUNCTION get_manager_service_centers()
RETURNS TABLE (sc_id INT) AS $$
BEGIN
    RETURN QUERY
    SELECT primary_service_center_id 
    FROM Service_Centers_Schema.Employees 
    WHERE full_name = current_user
    
    UNION
    
    SELECT secondary_service_center_id 
    FROM Service_Centers_Schema.Employees 
    WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE POLICY manager_employees_select ON Service_Centers_Schema.Employees
    FOR SELECT TO manager
    USING (
        full_name = current_user
        OR primary_service_center_id IN (SELECT sc_id FROM get_manager_service_centers())
        OR secondary_service_center_id IN (SELECT sc_id FROM get_manager_service_centers())
    );

-- PartsPurchases - read access for their service centers
CREATE POLICY manager_parts_purchases_select ON Service_Centers_Schema.PartsPurchases
    FOR SELECT TO manager
    USING (delivery_location_id IN (
        SELECT primary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user
        UNION
        SELECT secondary_service_center_id FROM Service_Centers_Schema.Employees 
        WHERE full_name = current_user AND secondary_service_center_id IS NOT NULL
    ));

-- Предоставление прав на все необходимые последовательности
GRANT USAGE, SELECT ON SEQUENCE Service_Centers_Schema.clients_clients_id_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE Service_Centers_Schema.orders_orders_id_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE Service_Centers_Schema.receipts_receipts_id_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE Service_Centers_Schema.bookings_bookings_id_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE Service_Centers_Schema.ordercontent_ordercontent_id_seq TO manager;