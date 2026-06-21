-- =========================================================
-- PRUEBAS DE PROCEDIMIENTOS Y TRIGGERS
-- Ejecutar DESPUÉS del poblado base ya existente
-- =========================================================

-- ---------------------------------------------------------
-- 1. Ver estado inicial
-- ---------------------------------------------------------
SELECT * FROM HUESPED;
SELECT * FROM HABITACION;
SELECT * FROM RESERVA;
SELECT * FROM ESTADIA;
SELECT * FROM CONSUMO_ADICIONAL;
SELECT * FROM PAGO;
SELECT * FROM TOTAL_HUESPED;
SELECT * FROM AUDITORIA;

-- ---------------------------------------------------------
-- 2. Probar procedimiento registrarReserva
-- Caso exitoso: huésped existente, habitación existente,
-- fechas válidas, sin solapamiento con activa/confirmada
-- ---------------------------------------------------------
CALL registrarReserva('45678901', 4, '2026-07-10', '2026-07-12');

-- Verificar que se insertó la reserva
SELECT * 
FROM RESERVA
WHERE CI_HUESPED = '45678901'
ORDER BY ID_RESERVA DESC;

-- Verificar si el estado de la habitación cambió, si tu SP lo hace
SELECT * 
FROM HABITACION
WHERE ID_HABITACION = 4 OR NUMERO = 202;

-- ---------------------------------------------------------
-- 3. Probar registrarReserva con error por solapamiento
-- Usa habitación con reserva confirmada/activa superpuesta
-- ---------------------------------------------------------
-- Esperado: error
CALL registrarReserva('48765432', 3, '2026-06-22', '2026-06-24');

-- ---------------------------------------------------------
-- 4. Probar registrarReserva con huésped inexistente
-- Esperado: error
-- ---------------------------------------------------------
CALL registrarReserva('99999999', 4, '2026-07-15', '2026-07-18');

-- ---------------------------------------------------------
-- 5. Probar registrarReserva con fechas inválidas
-- Esperado: error
-- ---------------------------------------------------------
CALL registrarReserva('48765432', 4, '2026-07-20', '2026-07-18');

-- ---------------------------------------------------------
-- 6. Crear una estadía para la reserva confirmada (si hace falta)
-- Esto es solo para poder probar registrarConsumo si no existe
-- ---------------------------------------------------------
INSERT INTO ESTADIA (ID_RESERVA, FECHA_INICIO_ESTADIA, FECHA_FIN_ESTADIA)
SELECT ID_RESERVA, '2026-06-20', NULL
FROM RESERVA
WHERE ID_RESERVA = 3
  AND NOT EXISTS (
      SELECT 1 FROM ESTADIA E WHERE E.ID_RESERVA = RESERVA.ID_RESERVA
  );

-- Verificar
SELECT * FROM ESTADIA WHERE ID_RESERVA = 3;

-- ---------------------------------------------------------
-- 7. Probar procedimiento registrarConsumo
-- Reserva 3 está Confirmada en tu poblado
-- Esperado: inserta consumo y actualiza TOTAL_HUESPED
-- ---------------------------------------------------------
CALL registrarConsumo(3, 'Minibar', '2 aguas y 1 snack', 500.00);

SELECT * 
FROM CONSUMO_ADICIONAL
WHERE ID_ESTADIA IN (
    SELECT ID_ESTADIA FROM ESTADIA WHERE ID_RESERVA = 3
);

SELECT * 
FROM TOTAL_HUESPED
WHERE CI_HUESPED = '45678901';

-- ---------------------------------------------------------
-- 8. Probar registrarConsumo con monto inválido
-- Esperado: error
-- ---------------------------------------------------------
CALL registrarConsumo(3, 'Restaurante', 'Cena', -100.00);

-- ---------------------------------------------------------
-- 9. Probar registrarConsumo con reserva inexistente
-- Esperado: error
-- ---------------------------------------------------------
CALL registrarConsumo(999, 'Minibar', 'Prueba', 200.00);

-- ---------------------------------------------------------
-- 10. Probar trigger de actualización de reserva a Finalizada
-- Reserva 2 está Activa y tiene estadía abierta
-- Esperado:
--   - HABITACION pasa a Disponible
--   - ESTADIA.FECHA_FIN_ESTADIA se completa
-- ---------------------------------------------------------
SELECT * FROM HABITACION WHERE ID_HABITACION = 2;
SELECT * FROM ESTADIA WHERE ID_RESERVA = 2;
SELECT * FROM RESERVA WHERE ID_RESERVA = 2;

UPDATE RESERVA
SET ESTADO = 'Finalizada'
WHERE ID_RESERVA = 2;

SELECT * FROM HABITACION WHERE ID_HABITACION = 2;
SELECT * FROM ESTADIA WHERE ID_RESERVA = 2;
SELECT * FROM RESERVA WHERE ID_RESERVA = 2;

-- ---------------------------------------------------------
-- 11. Probar trigger de borrado de habitación con reservas
-- Esperado:
--   - rechaza el DELETE
--   - registra en AUDITORIA
-- ---------------------------------------------------------
DELETE FROM HABITACION
WHERE ID_HABITACION = 1;

SELECT * FROM AUDITORIA
ORDER BY FECHA DESC;

-- ---------------------------------------------------------
-- 12. Consultar totales adeudados finales
-- ---------------------------------------------------------
SELECT * FROM TOTAL_HUESPED ORDER BY CI_HUESPED;