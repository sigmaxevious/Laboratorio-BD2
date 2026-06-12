DELIMITER $$
CREATE PROCEDURE registrarReserva(huesped, habitacion, fecha_inicio, fecha_fin)
BEGIN



END$$

/*. registrarReserva(huesped, habitacion, fecha_inicio, fecha_fin)
Este procedimiento debe:
• Validar que el huésped exista.
• Validar que la habitación exista.
• Validar que la fecha de inicio sea menor que la fecha de fin.
Verificar que la habitación no tenga otra reserva confirmada o activa en un período
superpuesto.
• Registrar la reserva con estado Confirmada.
• Actualizar el estado de la habitación si corresponde. */

DELIMITER $$
CREATE PROCEDURE registrarConsumo(reserva, tipo_consumo, descripcion, monto)
BEGIN
IF NOT EXISTS (SELECT 1 FROM reservas WHERE id_reserva = reserva) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva no existe.';
END IF;

IF NOT EXISTS (SELECT 1 FROM reservas WHERE id_reserva = reserva AND estado IN ('Activa', 'Confirmada')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva no está en estado Activa o Confirmada.';
END IF;
IF monto <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero.';
END IF;

INSERT INTO consumos (id_reserva, tipo_consumo, descripcion, monto) VALUES (reserva, tipo_consumo, descripcion, monto);

UPDATE TOTAL_HUESPED
SET total_adeudado = total_adeudado + monto
WHERE ci_huesped = (SELECT ci_huesped FROM hotel.reservas WHERE id_reserva = reserva);




END$$

/* 2. registrarConsumo(reserva, tipo_consumo, descripcion, monto)
Este procedimiento debe:
• Validar que la reserva exista.
• Validar que la reserva se encuentre en estado Activa o Confirmada.
• Validar que el monto sea mayor que cero.
• Registrar el consumo asociado a la reserva.
• Actualizar el total adeudado por el huésped.
*/
DELIMITER $$
CREATE PROCEDURE calcularTotalPorHuesped(huesped)
BEGIN


END$$

/*calcularTotalPorHuesped(huesped)
Este procedimiento debe utilizar un cursor.
Debe:
• Validar que el huésped exista.
• Recorrer las reservas del huésped.
• Calcular el importe correspondiente a las noches reservadas.
• Sumar los consumos asociados a cada reserva.
• Restar los pagos realizados por el huésped.
• Insertar o actualizar el total adeudado en una tabla de totales por huésped */
