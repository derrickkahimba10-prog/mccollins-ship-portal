USE mccollins_shipping;SET time_zone='+00:00';
DELIMITER $$
DROP PROCEDURE IF EXISTS p11col$$
CREATE PROCEDURE p11col(IN t VARCHAR(64),IN c VARCHAR(64),IN d TEXT) BEGIN
IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=t AND COLUMN_NAME=c)THEN SET @q=CONCAT('ALTER TABLE `',t,'` ADD COLUMN `',c,'` ',d);PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;END IF;END$$
DELIMITER ;
CALL p11col('payments','payment_status','VARCHAR(24) NOT NULL DEFAULT ''requested'' AFTER received_amount');
CALL p11col('payments','payment_method','VARCHAR(32) NULL AFTER payment_status');
CALL p11col('payments','transaction_reference','VARCHAR(191) NULL AFTER payment_method');
CALL p11col('payments','due_at','DATETIME(6) NULL AFTER transaction_reference');
CALL p11col('payments','submitted_at','DATETIME(6) NULL AFTER due_at');
CALL p11col('payments','submitted_by_user_id','BIGINT UNSIGNED NULL AFTER submitted_at');
CALL p11col('payments','confirmed_at','DATETIME(6) NULL AFTER submitted_by_user_id');
CALL p11col('payments','confirmed_by_user_id','BIGINT UNSIGNED NULL AFTER confirmed_at');
CALL p11col('payments','payment_notes','VARCHAR(1000) NULL AFTER confirmed_by_user_id');
CALL p11col('payment_events','payment_id','BIGINT UNSIGNED NULL AFTER payment_event_ref');
CALL p11col('payment_events','event_type','VARCHAR(32) NULL AFTER payment_id');
CALL p11col('payment_events','previous_status','VARCHAR(24) NULL AFTER event_type');
CALL p11col('payment_events','new_status','VARCHAR(24) NULL AFTER previous_status');
CALL p11col('payment_events','amount','DECIMAL(19,4) NULL AFTER new_status');
CALL p11col('payment_events','currency','CHAR(3) NULL AFTER amount');
CALL p11col('payment_events','transaction_reference','VARCHAR(191) NULL AFTER currency');
CALL p11col('payment_events','event_notes','VARCHAR(1000) NULL AFTER transaction_reference');
CALL p11col('payment_events','occurred_at','DATETIME(6) NULL AFTER event_notes');
CALL p11col('payment_events','actor_user_id','BIGINT UNSIGNED NULL AFTER occurred_at');
CALL p11col('settlements','payment_id','BIGINT UNSIGNED NULL AFTER settlement_ref');
CALL p11col('settlements','shipment_id','BIGINT UNSIGNED NULL AFTER payment_id');
CALL p11col('settlements','carrier_company_id','BIGINT UNSIGNED NULL AFTER shipment_id');
CALL p11col('settlements','carrier_user_id','BIGINT UNSIGNED NULL AFTER carrier_company_id');
CALL p11col('settlements','currency','CHAR(3) NOT NULL DEFAULT ''TZS'' AFTER carrier_user_id');
CALL p11col('settlements','gross_amount','DECIMAL(19,4) NOT NULL DEFAULT 0 AFTER currency');
CALL p11col('settlements','deduction_amount','DECIMAL(19,4) NOT NULL DEFAULT 0 AFTER gross_amount');
CALL p11col('settlements','net_amount','DECIMAL(19,4) NOT NULL DEFAULT 0 AFTER deduction_amount');
CALL p11col('settlements','settlement_status','VARCHAR(24) NOT NULL DEFAULT ''draft'' AFTER net_amount');
CALL p11col('settlements','due_at','DATETIME(6) NULL AFTER settlement_status');
CALL p11col('settlements','approved_at','DATETIME(6) NULL AFTER due_at');
CALL p11col('settlements','approved_by_user_id','BIGINT UNSIGNED NULL AFTER approved_at');
CALL p11col('settlements','settlement_notes','VARCHAR(1000) NULL AFTER approved_by_user_id');
ALTER TABLE payouts MODIFY beneficiary_company_id BIGINT UNSIGNED NULL;
CALL p11col('payouts','beneficiary_user_id','BIGINT UNSIGNED NULL AFTER beneficiary_company_id');
CALL p11col('payouts','payout_status','VARCHAR(24) NOT NULL DEFAULT ''pending'' AFTER currency');
CALL p11col('payouts','payment_method','VARCHAR(32) NULL AFTER payout_status');
CALL p11col('payouts','transaction_reference','VARCHAR(191) NULL AFTER payment_method');
CALL p11col('payouts','paid_at','DATETIME(6) NULL AFTER transaction_reference');
CALL p11col('payouts','paid_by_user_id','BIGINT UNSIGNED NULL AFTER paid_at');
CALL p11col('payouts','payout_notes','VARCHAR(1000) NULL AFTER paid_by_user_id');
DROP PROCEDURE p11col;
DELIMITER $$
DROP PROCEDURE IF EXISTS p11idx$$
CREATE PROCEDURE p11idx(IN t VARCHAR(64),IN n VARCHAR(64),IN c TEXT,IN u BOOLEAN)BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE()AND TABLE_NAME=t AND INDEX_NAME=n)THEN SET @q=CONCAT('ALTER TABLE `',t,'` ADD ',IF(u,'UNIQUE ',''),'INDEX `',n,'` (',c,')');PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;END IF;END$$
DELIMITER ;
CALL p11idx('payments','uq_payments_shipment','`shipment_id`',TRUE);
CALL p11idx('payments','uq_payments_idempotency','`idempotency_key`',TRUE);
CALL p11idx('payment_events','ix_payment_events_payment','`payment_id`,`occurred_at`',FALSE);
CALL p11idx('settlements','uq_settlements_payment','`payment_id`',TRUE);
CALL p11idx('payouts','uq_payouts_settlement','`settlement_id`',TRUE);
DROP PROCEDURE p11idx;
DELIMITER $$
DROP PROCEDURE IF EXISTS p11fk$$
CREATE PROCEDURE p11fk(IN t VARCHAR(64),IN n VARCHAR(64),IN c VARCHAR(64),IN rt VARCHAR(64),IN rc VARCHAR(64))BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE()AND TABLE_NAME=t AND CONSTRAINT_NAME=n)THEN SET @q=CONCAT('ALTER TABLE `',t,'` ADD CONSTRAINT `',n,'` FOREIGN KEY (`',c,'`) REFERENCES `',rt,'` (`',rc,'`)');PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;END IF;END$$
DELIMITER ;
CALL p11fk('payments','fk_payments_shipment','shipment_id','shipments','shipment_id');
CALL p11fk('payment_events','fk_payment_events_payment','payment_id','payments','payment_id');
CALL p11fk('settlements','fk_settlements_payment','payment_id','payments','payment_id');
CALL p11fk('settlements','fk_settlements_shipment','shipment_id','shipments','shipment_id');
CALL p11fk('payouts','fk_payouts_settlement','settlement_id','settlements','settlement_id');
DROP PROCEDURE p11fk;
SELECT 'Phase 11 payment and settlement alignment completed' result;