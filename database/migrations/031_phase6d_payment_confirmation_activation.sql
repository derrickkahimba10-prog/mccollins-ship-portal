-- Phase 6D adjustment: confirmed offline subscription payment activates immediately.
USE mccollins_shipping;
SET time_zone = '+00:00';

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_payment_add_column$$
CREATE PROCEDURE phase6d_payment_add_column(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_definition TEXT)
BEGIN
 IF NOT EXISTS (
  SELECT 1 FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND COLUMN_NAME = p_column
 ) THEN
  SET @ddl = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_column, '` ', p_definition);
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase6d_payment_add_column('subscriptions','payment_reference','VARCHAR(96) NULL AFTER activation_note');
CALL phase6d_payment_add_column('subscriptions','payment_confirmed_at','DATETIME(6) NULL AFTER payment_reference');
CALL phase6d_payment_add_column('subscriptions','payment_confirmed_by_user_id','BIGINT UNSIGNED NULL AFTER payment_confirmed_at');
DROP PROCEDURE phase6d_payment_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_payment_add_index$$
CREATE PROCEDURE phase6d_payment_add_index(IN p_table VARCHAR(64), IN p_name VARCHAR(64), IN p_columns TEXT, IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS (
  SELECT 1 FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND INDEX_NAME = p_name
 ) THEN
  SET @ddl = CONCAT('ALTER TABLE `', p_table, '` ADD ', IF(p_unique,'UNIQUE ',''), 'INDEX `', p_name, '` (', p_columns, ')');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase6d_payment_add_index('subscriptions','uq_subscriptions_payment_reference','`payment_reference`',TRUE);
DROP PROCEDURE phase6d_payment_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_payment_add_fk$$
CREATE PROCEDURE phase6d_payment_add_fk(IN p_table VARCHAR(64), IN p_name VARCHAR(64), IN p_column VARCHAR(64), IN p_ref_table VARCHAR(64), IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS (
  SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND CONSTRAINT_NAME = p_name
 ) THEN
  SET @ddl = CONCAT('ALTER TABLE `', p_table, '` ADD CONSTRAINT `', p_name, '` FOREIGN KEY (`', p_column, '`) REFERENCES `', p_ref_table, '` (`', p_ref, '`)');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase6d_payment_add_fk('subscriptions','fk_subscriptions_payment_confirmer','payment_confirmed_by_user_id','users','user_id');
DROP PROCEDURE phase6d_payment_add_fk;

SELECT 'Phase 6D payment-confirmation activation alignment completed' AS result;
