USE HOTEL;

DROP TRIGGER IF EXISTS borrar_habitacion ;
DELIMITER $$
CREATE TRIGGER borrar_habitacion
BEFORE DELETE ON HABITACION
FOR EACH ROW
BEGIN

    -- Variables locales
    DECLARE v_reserva_existe INT DEFAULT 0;

    -- 1) Verificar si la habitación tiene reservas asociadas
    SELECT COUNT(*) INTO v_reserva_existe
    from RESERVA
    WHERE id_habitacion = OLD.id_habitacion;
    -- 2) Registrar el intento de borrado en una tabla de auditoría.
    IF v_reserva_existe > 0 THEN
        INSERT INTO AUDITORIA(id_habitacion, fecha, usuario_bd, motivo)
        VALUES(OLD.id_habitacion, CURDATE(), CURRENT_USER(), 'habitacion con reserva asociada');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'no se puede borrar esta habitacion';
    END IF;
END$$
DELIMITER ;
/* 1. Trigger de borrado de habitaciones
Debe:
• Impedir borrar habitaciones que tengan reservas asociadas.
• Registrar el intento de borrado en una tabla de auditoría.
La tabla de auditoría puede almacenar:
Identificador del intento.
• Número o identificador de la habitación.
• Fecha del intento.
• Usuario de base de datos (opcional).
• Motivo del rechazo. */



/*2. Trigger sobre actualización del estado de una reserva
- Detectar cuando una reserva cambia su estado a Finalizada.
- Actualizar el estado de la habitación a Disponible.
- Registrar la fecha de finalización de la estadía, si corresponde según el diseño adoptado. */

DROP TRIGGER IF EXISTS finalizar_reserva;
DELIMITER $$
CREATE TRIGGER finalizar_reserva
AFTER UPDATE ON RESERVA
FOR EACH ROW
BEGIN
    IF NEW.ESTADO = 'Finalizada' AND OLD.ESTADO <> 'Finalizada' THEN

        -- Habitación queda disponible
        UPDATE HABITACION
           SET ESTADO = 'Disponible'
         WHERE ID_HABITACION = NEW.ID_HABITACION;

        -- Registrar fecha de fin de la estadía (si quedó abierta)
        UPDATE ESTADIA
           SET FECHA_FIN_ESTADIA = CURDATE()
         WHERE ID_RESERVA = NEW.ID_RESERVA
           AND FECHA_FIN_ESTADIA IS NULL;
    END IF;
END$$
DELIMITER ;

/*
3. Trigger tras inserción de consumo
- Recalcular automáticamente el total adeudado por el huésped asociado a la
reserva.
- Actualizar la tabla de totales por huésped. */
DROP TRIGGER IF EXISTS recalcular_total_consumo;
DELIMITER $$
CREATE TRIGGER recalcular_total_consumo
AFTER INSERT ON CONSUMO_ADICIONAL
FOR EACH ROW
BEGIN
    DECLARE v_ci_huesped     VARCHAR(50);
    DECLARE v_total_noches   DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total_consumos DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total_pagos    DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total_adeudado DECIMAL(10,2) DEFAULT 0;

    -- 1) Huésped del consumo (CONSUMO_ADICIONAL -> ESTADIA -> RESERVA)
    SELECT R.CI_HUESPED
      INTO v_ci_huesped
      FROM ESTADIA E
      JOIN RESERVA R ON R.ID_RESERVA = E.ID_RESERVA
     WHERE E.ID_ESTADIA = NEW.ID_ESTADIA;

    -- 2) Noches × precio de la categoría
    SELECT IFNULL(SUM(DATEDIFF(R.FECHAFIN, R.FECHAINICIO) * C.PRECIO), 0)
      INTO v_total_noches
      FROM RESERVA   R
      JOIN HABITACION H ON H.ID_HABITACION = R.ID_HABITACION
      JOIN CATEGORIA  C ON C.ID_CATEGORIA  = H.ID_CATEGORIA
     WHERE R.CI_HUESPED = v_ci_huesped
       AND R.ESTADO IN ('Confirmada','Activa','Finalizada');

    -- 3) Consumo total del huésped
    SELECT IFNULL(SUM(CA.MONTO), 0)
      INTO v_total_consumos
      FROM CONSUMO_ADICIONAL CA
      JOIN ESTADIA E ON E.ID_ESTADIA = CA.ID_ESTADIA
      JOIN RESERVA R ON R.ID_RESERVA = E.ID_RESERVA
     WHERE R.CI_HUESPED = v_ci_huesped;

    -- 4) Pagos del huésped
    SELECT IFNULL(SUM(MONTO), 0) INTO v_total_pagos
      FROM PAGO
     WHERE CI_HUESPED = v_ci_huesped;

    SET v_total_adeudado = v_total_noches + v_total_consumos - v_total_pagos;

    INSERT INTO TOTAL_HUESPED(CI_HUESPED, TOTAL_ADEUDADO)
    VALUES (v_ci_huesped, v_total_adeudado)
    ON DUPLICATE KEY UPDATE TOTAL_ADEUDADO = v_total_adeudado;
END$$
DELIMITER ;
