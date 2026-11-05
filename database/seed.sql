-- Ship Logistics Management System: sample data
-- Run this file from MySQL Shell (SQL mode) with:
--   \source C:/full/path/to/seed.sql
-- Intended for an EMPTY set of logistics tables. Do not run repeatedly:
-- explicit primary-key IDs are used to keep relationships easy to follow.
-- This file does not insert roles, permissions, or login users.

USE logistics;

START TRANSACTION;

INSERT INTO employees (employee_id, employee_name) VALUES
(1, 'Aarav Sharma'),
(2, 'Meera Khan'),
(3, 'Kabir Singh'),
(4, 'Zoya Ahmed'),
(5, 'Rohan Gupta');

INSERT INTO port (port_id, port_name) VALUES
(1, 'Mumbai Port'),
(2, 'Jawaharlal Nehru Port'),
(3, 'Kochi Port'),
(4, 'Chennai Port');

INSERT INTO route (route_id, route_name) VALUES
(1, 'Western Coastal Route'),
(2, 'Southern Coastal Route');

INSERT INTO route_stop (route_stop_id, sequence_no, route_id, port_id) VALUES
(1, 1, 1, 1),
(2, 2, 1, 2),
(3, 1, 2, 3),
(4, 2, 2, 4);

INSERT INTO ship (ship_id, name, uq_imo, route_id) VALUES
(1, 'Ocean Pioneer', '1234567', 1),
(2, 'Sea Voyager', '2345678', 2),
(3, 'Coastal Star', '3456789', 1);

INSERT INTO ship_assignment
(assignment_id, assigned_from, assigned_to, role, employee_id, ship_id) VALUES
(1, '2026-01-01 08:00:00', NULL, 'Captain', 1, 1),
(2, '2026-01-01 08:00:00', NULL, 'Navigator', 2, 1),
(3, '2026-01-05 08:00:00', NULL, 'Captain', 3, 2),
(4, '2026-01-05 08:00:00', NULL, 'Engineer', 4, 2),
(5, '2026-01-10 08:00:00', NULL, 'Captain', 5, 3);

INSERT INTO shipment
(shipment_id, sender_name, receiver_name, weight, cargo_type, booking_date, current_status, ship_id) VALUES
(1, 'Northstar Exports', 'Bluewave Imports', 1250.50, 'Textiles', '2026-02-01', 'Booked', 1),
(2, 'Greenfield Foods', 'Harbor Markets', 2400.00, 'Food Products', '2026-02-03', 'In Transit', 1),
(3, 'Metro Machinery', 'Southern Engineering', 3750.75, 'Machinery', '2026-02-05', 'In Transit', 2),
(4, 'Coastal Traders', 'City Retail Group', 850.00, 'Household Goods', '2026-02-08', 'Delivered', 3);

INSERT INTO checkpoint
(checkpoint_id, departure_time, arrival_time, status, port_id, shipment_id) VALUES
(1, NULL, NULL, 'Scheduled', 1, 1),
(2, NULL, NULL, 'Scheduled', 2, 1),
(3, NULL, NULL, 'Scheduled', 3, 2),
(4, NULL, NULL, 'Delayed', 4, 3),
(5, NULL, NULL, 'Arrived', 4, 4);

INSERT INTO shipment_updates
(update_id, update_time, update_status, description, shipment_id) VALUES
(1, '2026-02-01 09:00:00', 'Booked', 'Shipment booking was created.', 1),
(2, '2026-02-03 11:30:00', 'In Transit', 'Shipment departed from the origin port.', 2),
(3, '2026-02-05 14:15:00', 'In Transit', 'Shipment is currently in transit.', 3),
(4, '2026-02-07 16:00:00', 'Delayed', 'A checkpoint delay was reported.', 3),
(5, '2026-02-10 10:45:00', 'Delivered', 'Shipment was delivered successfully.', 4);

COMMIT;

-- Verify inserted row counts.
SELECT 'employees' AS table_name, COUNT(*) AS total FROM employees
UNION ALL SELECT 'port', COUNT(*) FROM port
UNION ALL SELECT 'route', COUNT(*) FROM route
UNION ALL SELECT 'route_stop', COUNT(*) FROM route_stop
UNION ALL SELECT 'ship', COUNT(*) FROM ship
UNION ALL SELECT 'ship_assignment', COUNT(*) FROM ship_assignment
UNION ALL SELECT 'shipment', COUNT(*) FROM shipment
UNION ALL SELECT 'checkpoint', COUNT(*) FROM checkpoint
UNION ALL SELECT 'shipment_updates', COUNT(*) FROM shipment_updates;
