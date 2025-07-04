CREATE DATABASE service_centers_db;


CREATE SCHEMA Service_Centers_Schema;
SET search_path TO Service_Centers_Schema;


-- Создание пользовательских типов
CREATE TYPE type AS ENUM ('computer', 'console', 'computer and console', 'storage');
CREATE TYPE for_device AS ENUM('computer', 'console', 'computer and console' , 'other');
CREATE TYPE device AS ENUM('computer', 'console', 'computer and console');
CREATE TYPE status AS ENUM ('Ordinary', 'Regular', 'Premium');
CREATE TYPE pay_status AS ENUM ('paid', 'pending', 'cancelled');


-- Создание таблицы для складов и сервисных центров
CREATE TABLE ServiceCenters_and_StorageCenters (
    SC_id SERIAL PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    postal_code VARCHAR(6),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    employee_count INT,
    type type NOT NULL
);

-- Создание таблицы для сотрудников
CREATE TABLE Employees (
    Employees_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    position VARCHAR(100) NOT NULL,
    contact_info VARCHAR(255),
    experience INT,
    salary DECIMAL(10, 2),
    age INT,
    other_info TEXT,
    primary_service_center_id INT REFERENCES ServiceCenters_and_StorageCenters(SC_id) NOT NULL,
    secondary_service_center_id INT REFERENCES ServiceCenters_and_StorageCenters(SC_id)
);

-- Создание таблицы для услуг
CREATE TABLE Services (
    Services_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    for_device for_device NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Создание таблицы для клиентов
CREATE TABLE Clients (
    Clients_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255),
    status status DEFAULT 'Ordinary',
    bonus_points INT DEFAULT 0
);

-- Создание таблицы для комплектующих
CREATE TABLE Parts (
    Parts_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    count INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    for_device for_device NOT NULL,
    location_id INT REFERENCES ServiceCenters_and_StorageCenters(SC_id) NOT NULL
);

-- Создание таблицы для заказов
CREATE TABLE Orders (
    Orders_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES Clients(Clients_id) NOT NULL,
    service_center_id INT REFERENCES ServiceCenters_and_StorageCenters(SC_id) NOT NULL,
    device device NOT NULL,
    total_cost DECIMAL(10, 2),
    order_date DATE NOT NULL,
    completion_date DATE,
    other_info TEXT
);

-- Создание таблицы для чеков
CREATE TABLE Receipts (
    Receipts_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES Orders(Orders_id) NOT NULL,
    client_id INT REFERENCES Clients(Clients_id) NOT NULL,
    final_total_cost DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0.00,
    final_price DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL,
    pay_status pay_status DEFAULT 'paid'
);

-- Создание таблицы для бронирований
CREATE TABLE Bookings (
    Bookings_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES Clients(Clients_id) NOT NULL,
    service_id INT REFERENCES Services(Services_id) NOT NULL,
    employee_id INT REFERENCES Employees(Employees_id),
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL
);

-- Создание таблицы для содержимого заказов
CREATE TABLE OrderContent (
    OrderContent_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES Orders(Orders_id) NOT NULL,
    services_id INT REFERENCES Services(Services_id),
    part_id INT REFERENCES Parts(Parts_id)
);




-- Создание дополнительной таблицы для заказов запчастей

CREATE TABLE PartsPurchases (
    PartsPurchases_id SERIAL PRIMARY KEY,
    part_id INT REFERENCES Parts(Parts_id) NOT NULL,
    quantity INT DEFAULT 1,
    order_date DATE,
    receipt_date DATE,
    delivery_location_id INT REFERENCES ServiceCenters_and_StorageCenters(SC_id) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL
);

