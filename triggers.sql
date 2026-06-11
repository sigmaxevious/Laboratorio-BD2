CREATE TRIGGER
BEGIN
END$
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
