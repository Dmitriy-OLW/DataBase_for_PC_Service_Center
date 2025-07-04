-- Индексы для таблицы Clients
CREATE INDEX idx_clients_status ON Service_Centers_Schema.Clients(status);
CREATE INDEX idx_clients_bonus_points ON Service_Centers_Schema.Clients(bonus_points);

-- Индексы для таблицы Employees
CREATE INDEX idx_employees_service_center ON Service_Centers_Schema.Employees(primary_service_center_id, secondary_service_center_id);
CREATE INDEX idx_employees_position ON Service_Centers_Schema.Employees(position);


-- Индексы для таблицы Orders
CREATE INDEX idx_orders_client ON Service_Centers_Schema.Orders(client_id);
CREATE INDEX idx_orders_service_center ON Service_Centers_Schema.Orders(service_center_id);
CREATE INDEX idx_orders_dates ON Service_Centers_Schema.Orders(order_date, completion_date);
CREATE INDEX idx_orders_device ON Service_Centers_Schema.Orders(device);

-- Индексы для таблицы Receipts
CREATE INDEX idx_receipts_client ON Service_Centers_Schema.Receipts(client_id);
CREATE INDEX idx_receipts_order ON Service_Centers_Schema.Receipts(order_id);

-- Индексы для таблицы Bookings
CREATE INDEX idx_bookings_client ON Service_Centers_Schema.Bookings(client_id);
CREATE INDEX idx_bookings_employee ON Service_Centers_Schema.Bookings(employee_id);
CREATE INDEX idx_bookings_dates ON Service_Centers_Schema.Bookings(booking_date, booking_time);

-- Индексы для таблицы Parts
CREATE INDEX idx_parts_location ON Service_Centers_Schema.Parts(location_id);
CREATE INDEX idx_parts_for_device ON Service_Centers_Schema.Parts(for_device);
CREATE INDEX idx_parts_count ON Service_Centers_Schema.Parts(count) WHERE count > 0;

-- Индексы для таблицы Services
CREATE INDEX idx_services_for_device ON Service_Centers_Schema.Services(for_device);
CREATE INDEX idx_services_price ON Service_Centers_Schema.Services(price);

-- Индексы для таблицы OrderContent
CREATE INDEX idx_ordercontent_order ON Service_Centers_Schema.OrderContent(order_id);
CREATE INDEX idx_ordercontent_service ON Service_Centers_Schema.OrderContent(services_id);
CREATE INDEX idx_ordercontent_part ON Service_Centers_Schema.OrderContent(part_id);

-- Индексы для таблицы PartsPurchases
CREATE INDEX idx_partspurchases_location ON Service_Centers_Schema.PartsPurchases(delivery_location_id);
CREATE INDEX idx_partspurchases_dates ON Service_Centers_Schema.PartsPurchases(order_date, receipt_date);




