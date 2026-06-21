USE HOTEL;

INSERT INTO CATEGORIA (ID_CATEGORIA, TIPO, PRECIO) VALUES
(1, 'Individual', 1800.00),
(2, 'Doble', 2600.00),
(3, 'Suite', 4500.00),
(4, 'Familiar', 3800.00);

INSERT INTO HUESPED (CI, NOMBRE, APELLIDO, MAIL, TELEFONO) VALUES
('48765432', 'Ana', 'Pérez', 'ana.perez@mail.com', '099111111'),
('51234567', 'Bruno', 'Gómez', 'bruno.gomez@mail.com', '098222222'),
('45678901', 'Carla', 'Rodríguez', 'carla.rodriguez@mail.com', '097333333'),
('53456789', 'Diego', 'Fernández', 'diego.fernandez@mail.com', '096444444');

INSERT INTO HABITACION (NUMERO, ESTADO, ID_CATEGORIA) VALUES
(101, 'Disponible', 1),
(102, 'Ocupada', 2),
(201, 'Disponible', 3),
(202, 'Mantenimiento', 4),
(203, 'Reservada', 2);

INSERT INTO RESERVA (ID_HABITACION, CI_HUESPED, FECHAINICIO, FECHAFIN, FECHARESERVA, ESTADO) VALUES
(1, '48765432', '2026-06-10', '2026-06-12', '2026-06-01', 'Finalizada'),
(2, '51234567', '2026-06-11', '2026-06-15', '2026-06-05', 'Activa'),
(3, '45678901', '2026-06-20', '2026-06-25', '2026-06-07', 'Confirmada'),
(5, '53456789', '2026-06-18', '2026-06-20', '2026-06-08', 'Pendiente'),
(1, '48765432', '2026-07-01', '2026-07-03', '2026-06-09', 'Cancelada');

INSERT INTO ESTADIA (ID_RESERVA, FECHA_INICIO_ESTADIA, FECHA_FIN_ESTADIA) VALUES
(1, '2026-06-10', '2026-06-12'),
(2, '2026-06-11', NULL);

INSERT INTO CONSUMO_ADICIONAL (ID_ESTADIA, TIPO, DESCRIPCION, FECHA, MONTO) VALUES
(1, 'Minibar', '2 refrescos y 1 snack', '2026-06-10', 450.00),
(1, 'Restaurante', 'Cena para 1 persona', '2026-06-11', 1200.00),
(2, 'Lavandería', 'Lavado de ropa', '2026-06-12', 700.00),
(2, 'Room Service', 'Desayuno en habitación', '2026-06-13', 950.00);

INSERT INTO PAGO (FECHA, MONTO, MEDIO_DE_PAGO, CI_HUESPED) VALUES
('2026-06-01', 2000.00, 'Tarjeta', '48765432'),
('2026-06-11', 3000.00, 'Efectivo', '51234567'),
('2026-06-08', 1500.00, 'Transferencia', '45678901');

INSERT INTO TOTAL_HUESPED (CI_HUESPED, TOTAL_ADEUDADO) VALUES
('48765432', 1250.00),
('51234567', 3650.00),
('45678901', 11500.00),
('53456789', 5200.00);

INSERT INTO AUDITORIA (ID_HABITACION, FECHA, USUARIO_BD, MOTIVO) VALUES
(1, '2026-06-11 18:30:00', 'root@localhost', 'Intento de borrado de habitación con reservas asociadas');
