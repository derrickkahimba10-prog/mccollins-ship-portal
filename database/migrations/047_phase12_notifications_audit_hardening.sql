USE mccollins_shipping;SET time_zone='+00:00';
DELIMITER $$
DROP PROCEDURE IF EXISTS p12col$$
CREATE PROCEDURE p12col(IN t VARCHAR(64),IN c VARCHAR(64),IN d TEXT)BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()AND TABLE_NAME=t AND COLUMN_NAME=c)THEN SET @q=CONCAT('ALTER TABLE `',t,'` ADD COLUMN `',c,'` ',d);PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;END IF;END$$
DELIMITER ;
CALL p12col('notifications','recipient_user_id','BIGINT UNSIGNED NULL AFTER notification_ref');
CALL p12col('notifications','category','VARCHAR(32) NOT NULL DEFAULT ''system'' AFTER recipient_user_id');
CALL p12col('notifications','priority','VARCHAR(16) NOT NULL DEFAULT ''normal'' AFTER category');
CALL p12col('notifications','title','VARCHAR(191) NULL AFTER priority');
CALL p12col('notifications','message','VARCHAR(1000) NULL AFTER title');
CALL p12col('notifications','entity_type','VARCHAR(48) NULL AFTER message');
CALL p12col('notifications','entity_id_value','BIGINT UNSIGNED NULL AFTER entity_type');
CALL p12col('notifications','action_url','VARCHAR(512) NULL AFTER entity_id_value');
CALL p12col('notifications','emitted_at','DATETIME(6) NULL AFTER action_url');
CALL p12col('notifications','read_at','DATETIME(6) NULL AFTER emitted_at');
CALL p12col('notification_deliveries','notification_id','BIGINT UNSIGNED NULL AFTER notification_deliverie_ref');
CALL p12col('notification_deliveries','recipient_user_id','BIGINT UNSIGNED NULL AFTER notification_id');
CALL p12col('notification_deliveries','channel','VARCHAR(24) NOT NULL DEFAULT ''in_app'' AFTER recipient_user_id');
CALL p12col('notification_deliveries','delivery_status','VARCHAR(24) NOT NULL DEFAULT ''delivered'' AFTER channel');
CALL p12col('notification_deliveries','delivered_at','DATETIME(6) NULL AFTER delivery_status');
CALL p12col('notification_deliveries','read_at','DATETIME(6) NULL AFTER delivered_at');
CALL p12col('audit_events','action_code','VARCHAR(96) NULL AFTER audit_event_ref');
CALL p12col('audit_events','entity_type','VARCHAR(48) NULL AFTER action_code');
CALL p12col('audit_events','entity_id_value','BIGINT UNSIGNED NULL AFTER entity_type');
CALL p12col('audit_events','actor_user_id','BIGINT UNSIGNED NULL AFTER entity_id_value');
CALL p12col('audit_events','source_channel','VARCHAR(24) NULL AFTER actor_user_id');
CALL p12col('audit_events','request_id','VARCHAR(64) NULL AFTER source_channel');
CALL p12col('audit_events','ip_address','VARCHAR(64) NULL AFTER request_id');
CALL p12col('access_logs','user_id','BIGINT UNSIGNED NULL AFTER access_log_ref');
CALL p12col('access_logs','request_method','VARCHAR(12) NULL AFTER user_id');
CALL p12col('access_logs','request_path','VARCHAR(512) NULL AFTER request_method');
CALL p12col('access_logs','ip_address','VARCHAR(64) NULL AFTER request_path');
CALL p12col('access_logs','user_agent','VARCHAR(500) NULL AFTER ip_address');
CALL p12col('access_logs','occurred_at','DATETIME(6) NULL AFTER user_agent');
DROP PROCEDURE p12col;
DELIMITER $$
DROP PROCEDURE IF EXISTS p12idx$$
CREATE PROCEDURE p12idx(IN t VARCHAR(64),IN n VARCHAR(64),IN c TEXT,IN u BOOLEAN)BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE()AND TABLE_NAME=t AND INDEX_NAME=n)THEN SET @q=CONCAT('ALTER TABLE `',t,'` ADD ',IF(u,'UNIQUE ',''),'INDEX `',n,'` (',c,')');PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;END IF;END$$
DELIMITER ;
CALL p12idx('notifications','ix_notifications_user_read','`recipient_user_id`,`read_at`,`emitted_at`',FALSE);
CALL p12idx('notification_deliveries','uq_notification_delivery_user','`notification_id`,`recipient_user_id`,`channel`',TRUE);
CALL p12idx('audit_events','ix_audit_action_created','`action_code`,`created_at`',FALSE);
CALL p12idx('access_logs','ix_access_user_time','`user_id`,`occurred_at`',FALSE);
DROP PROCEDURE p12idx;
DELIMITER $$
DROP PROCEDURE IF EXISTS p12fk$$
CREATE PROCEDURE p12fk(IN t VARCHAR(64),IN n VARCHAR(64),IN c VARCHAR(64),IN rt VARCHAR(64),IN rc VARCHAR(64))BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE()AND TABLE_NAME=t AND CONSTRAINT_NAME=n)THEN SET @q=CONCAT('ALTER TABLE `',t,'` ADD CONSTRAINT `',n,'` FOREIGN KEY (`',c,'`) REFERENCES `',rt,'` (`',rc,'`)');PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;END IF;END$$
DELIMITER ;
CALL p12fk('notifications','fk_notifications_user','recipient_user_id','users','user_id');
CALL p12fk('notification_deliveries','fk_notification_delivery_notification','notification_id','notifications','notification_id');
DROP PROCEDURE p12fk;
UPDATE audit_events SET action_code=JSON_UNQUOTE(JSON_EXTRACT(metadata_json,'$.action_code')),entity_type=JSON_UNQUOTE(JSON_EXTRACT(metadata_json,'$.entity_type')),entity_id_value=CAST(JSON_UNQUOTE(JSON_EXTRACT(metadata_json,'$.entity_id')) AS UNSIGNED),actor_user_id=created_by_user_id,source_channel='web' WHERE metadata_json IS NOT NULL AND action_code IS NULL;
SELECT 'Phase 12 notifications, audit and hardening alignment completed' result;