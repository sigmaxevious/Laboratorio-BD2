DROP PROCEDURE IF EXISTS registrarReserva;
DELIMITER $$
CREATE PROCEDURE registrarReserva(
    IN p_huesped VARCHAR(50),
    IN p_habitacion INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    DECLARE v_huesped_existe    INT DEFAULT 0;
    DECLARE v_habitacion_existe INT DEFAULT 0;
    DECLARE v_solapamiento      INT DEFAULT 0;

    SELECT COUNT(*) INTO v_huesped_existe
      FROM HUESPED
     WHERE CI = p_huesped;
    IF v_huesped_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'el huesped no existe';
    END IF;

    SELECT COUNT(*) INTO v_habitacion_existe
      FROM HABITACION
     WHERE ID_HABITACION = p_habitacion;
    IF v_habitacion_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La habitacion no existe';
    END IF;

    IF p_fecha_inicio >= p_fecha_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio debe ser menor que la fecha de fin';
    END IF;

    SELECT COUNT(*) INTO v_solapamiento
      FROM RESERVA
     WHERE ID_HABITACION = p_habitacion
       AND ESTADO IN ('Confirmada', 'Activa')
       AND FECHAINICIO < p_fecha_fin
       AND FECHAFIN    > p_fecha_inicio;
    IF v_solapamiento > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La habitacion ya tiene una reserva en ese periodo';
    END IF;

    -- Insertar reserva
    INSERT INTO RESERVA(FECHAINICIO, FECHAFIN, FECHARESERVA, ESTADO, CI_HUESPED, ID_HABITACION)
    VALUES(p_fecha_inicio, p_fecha_fin, CURDATE(), 'Confirmada', p_huesped, p_habitacion);

    -- Si la reserva empieza hoy, marcar la habitación como reservada
    IF p_fecha_inicio = CURDATE() THEN
        UPDATE HABITACION
           SET ESTADO = 'Reservada'
         WHERE ID_HABITACION = p_habitacion;
    END IF;
END$$
DELIMITER ;

/*. registrarReserva(huesped, habitacion, fecha_inicio, fecha_fin)
Este procedimiento debe:
• Validar que el huésped exista.
• Validar que la habitación exista.
• Validar que la fecha de inicio sea menor que la fecha de fin.
• Verificar que la habitación no tenga otra reserva confirmada o activa en un período
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

    -- Obtener datos de la reserva
    SELECT ESTADO, CI_HUESPED
    INTO v_estado_reserva, v_ci_huesped
    FROM RESERVA
    WHERE ID_RESERVA = p_reserva;

    -- Verificar que la reserva esté Activa o Confirmada
    IF v_estado_reserva NOT IN ('Activa', 'Confirmada') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva no está en estado Activa o Confirmada.';
    END IF;

    -- Verificar que el monto sea mayor que cero
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El monto debe ser mayor que cero.';
    END IF;

    -- Buscar la estadía asociada a esa reserva
    SELECT ID_ESTADIA
    INTO v_id_estadia
    FROM ESTADIA
    WHERE ID_RESERVA = p_reserva
    LIMIT 1;

    -- Si no existe estadía, no se puede registrar el consumo
    IF v_id_estadia IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva no tiene una estadía asociada.';
    END IF;

    --Insertar el consumo
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

    -- Actualizar TOTAL_HUESPED
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
DROP PROCEDURE IF EXISTS calcularTotalPorHuesped;
DELIMITER $$
CREATE PROCEDURE calcularTotalPorHuesped(IN p_huesped VARCHAR(50))
BEGIN
    -- Variables de control / acumuladores
    DECLARE v_huesped_existe   INT DEFAULT 0;
    DECLARE v_done             INT DEFAULT 0;

    DECLARE v_id_reserva       INT;
    DECLARE v_fecha_inicio     DATE;
    DECLARE v_fecha_fin        DATE;
    DECLARE v_precio           DECIMAL(10,2);
    DECLARE v_noches           INT;
    DECLARE v_consumos_reserva DECIMAL(10,2) DEFAULT 0;

    DECLARE v_total_noches     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total_consumos   DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total_pagos      DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total_adeudado   DECIMAL(10,2) DEFAULT 0;

    -- Cursor sobre las reservas vigentes del huésped (con precio de la categoría)
    DECLARE cur_reservas CURSOR FOR
        SELECT R.ID_RESERVA, R.FECHAINICIO, R.FECHAFIN, C.PRECIO
          FROM RESERVA   R
          JOIN HABITACION H ON H.ID_HABITACION = R.ID_HABITACION
          JOIN CATEGORIA  C ON C.ID_CATEGORIA  = H.ID_CATEGORIA
         WHERE R.CI_HUESPED = p_huesped
           AND R.ESTADO IN ('Confirmada','Activa','Finalizada');

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- 1) Validar que el huésped exista
    SELECT COUNT(*) INTO v_huesped_existe
      FROM HUESPED
     WHERE CI = p_huesped;
    IF v_huesped_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'el huesped no existe';
    END IF;

    -- 2) Recorrer reservas: noches × precio + consumos por reserva
    OPEN cur_reservas;
    bucle: LOOP
        FETCH cur_reservas INTO v_id_reserva, v_fecha_inicio, v_fecha_fin, v_precio;
        IF v_done = 1 THEN
            LEAVE bucle;
        END IF;

        SET v_noches       = DATEDIFF(v_fecha_fin, v_fecha_inicio);
        SET v_total_noches = v_total_noches + (v_noches * v_precio);

        -- Consumos asociados a esa reserva (vía ESTADIA)
        SELECT IFNULL(SUM(CA.MONTO), 0)
          INTO v_consumos_reserva
          FROM CONSUMO_ADICIONAL CA
          JOIN ESTADIA E ON E.ID_ESTADIA = CA.ID_ESTADIA
         WHERE E.ID_RESERVA = v_id_reserva;

        SET v_total_consumos = v_total_consumos + v_consumos_reserva;
    END LOOP;
    CLOSE cur_reservas;

    -- 3) Pagos del huésped
    SELECT IFNULL(SUM(MONTO), 0) INTO v_total_pagos
      FROM PAGO
     WHERE CI_HUESPED = p_huesped;

    -- 4) Total adeudado
    SET v_total_adeudado = v_total_noches + v_total_consumos - v_total_pagos;

    -- 5) Insertar o actualizar la fila de totales
    INSERT INTO TOTAL_HUESPED(CI_HUESPED, TOTAL_ADEUDADO)
    VALUES (p_huesped, v_total_adeudado)
    ON DUPLICATE KEY UPDATE TOTAL_ADEUDADO = v_total_adeudado;
END$$
DELIMITER ;

/*calcularTotalPorHuesped(huesped)
Este procedimiento debe utilizar un cursor.
Debe:
• Validar que el huésped exista.
• Recorrer las reservas del huésped.
• Calcular el importe correspondiente a las noches reservadas.
• Sumar los consumos asociados a cada reserva.
• Restar los pagos realizados por el huésped.
• Insertar o actualizar el total adeudado en una tabla de totales por huésped */