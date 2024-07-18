DROP DATABASE IF EXISTS salon;
CREATE DATABASE salon;

\c salon;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers(
	customer_id SERIAL PRIMARY KEY,
	phone VARCHAR UNIQUE,
	name VARCHAR
);

DROP TABLE IF EXISTS services;
CREATE TABLE services(
	service_id SERIAL PRIMARY KEY,
	name VARCHAR
);

DROP TABLE IF EXISTS appointments;
CREATE TABLE appointments(
	appointment_id SERIAL PRIMARY KEY,
	customer_id INTEGER REFERENCES customers(customer_id),
	service_id INTEGER REFERENCES services(service_id),
	time VARCHAR
);

--Debo tener al menos 3 servicios para abrir el salon
INSERT INTO services(name) VALUES ('Corte de pelo'), ('Lavado de pelo'), ('Teñir pelo');
