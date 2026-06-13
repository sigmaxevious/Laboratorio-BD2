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

CREATE PROCEDURE registrarConsumo(
    IN p_reserva INT,
    IN p_tipo_consumo VARCHAR(50),
    IN p_descripcion VARCHAR(200),
    IN p_monto DECIMAL(10,2)
)
BEGIN
    -- Variables locales
    DECLARE v_existe_reserva INT DEFAULT 0;
    DECLARE v_estado_reserva VARCHAR(50);
    DECLARE v_ci_huesped VARCHAR(50);
    DECLARE v_id_estadia INT;

    --Verificamos que la reserva exista
    SELECT COUNT(*)
    INTO v_existe_reserva
    FROM RESERVA
    WHERE ID_RESERVA = p_reserva;

    IF v_existe_reserva = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva no existe.';
    END IF;

    -- 2) Obtener datos de la reserva
    SELECT ESTADO, CI_HUESPED
    INTO v_estado_reserva, v_ci_huesped
    FROM RESERVA
    WHERE ID_RESERVA = p_reserva;

    -- 3) Verificar que la reserva esté Activa o Confirmada
    IF v_estado_reserva NOT IN ('Activa', 'Confirmada') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva no está en estado Activa o Confirmada.';
    END IF;

    -- 4) Verificar que el monto sea mayor que cero
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El monto debe ser mayor que cero.';
    END IF;

    -- 5) Buscar la estadía asociada a esa reserva
    SELECT ID_ESTADIA
    INTO v_id_estadia
    FROM ESTADIA
    WHERE ID_RESERVA = p_reserva
    LIMIT 1;

    -- 6) Si no existe estadía, no se puede registrar el consumo
    IF v_id_estadia IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva no tiene una estadía asociada.';
    END IF;

    -- 7) Insertar el consumo
    INSERT INTO CONSUMO_ADICIONAL (
        ID_ESTADIA,
        TIPO,
        DESCRIPCION,
        FECHA,
        MONTO
    )
    VALUES (
        v_id_estadia,
        p_tipo_consumo,
        p_descripcion,
        CURDATE(),
        p_monto
    );

    -- 8) Actualizar TOTAL_HUESPED
    INSERT INTO TOTAL_HUESPED (CI_HUESPED, TOTAL_ADEUDADO)
    VALUES (v_ci_huesped, p_monto)
    ON DUPLICATE KEY UPDATE
        TOTAL_ADEUDADO = TOTAL_ADEUDADO + p_monto;

END$$

DELIMITER ;

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
