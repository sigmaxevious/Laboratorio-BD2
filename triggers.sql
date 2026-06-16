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
CREATE TRIGGER
BEGIN
END$
/*2. Trigger sobre actualización del estado de una reserva
Debe:
• Detectar cuando una reserva cambia su estado a Finalizada.
• Actualizar el estado de la habitación a Disponible.
• Registrar la fecha de finalización de la estadía, si corresponde según el diseño adoptado. */
CREATE TRIGGER
BEGIN
END$
/*
3. Trigger tras inserción de consumo
Debe:
• Recalcular automáticamente el total adeudado por el huésped asociado a la
reserva.
• Actualizar la tabla de totales por huésped. */
