USE mccollins_shipping;
SET time_zone='+00:00';

-- Phase 9 keeps the approved tables and adds only the operational columns
-- required to use the existing tracking, alert and incident foundations.
DELIMITER $$
DROP PROCEDURE IF EXISTS p9col$$
CREATE PROCEDURE p9col(IN t VARCHAR(64), IN c VARCHAR(64), IN d TEXT)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=t AND COLUMN_NAME=c
  ) THEN
    SET @q=CONCAT('ALTER TABLE `',t,'` ADD COLUMN `',c,'` ',d);
    PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END$$
DELIMITER ;

CALL p9col('tracking_sessions','trip_id','BIGINT UNSIGNED NULL AFTER tracking_session_ref');
CALL p9col('tracking_sessions','shipment_id','BIGINT UNSIGNED NULL AFTER trip_id');
CALL p9col('tracking_sessions','started_at','DATETIME(6) NULL AFTER shipment_id');
CALL p9col('tracking_sessions','ended_at','DATETIME(6) NULL AFTER started_at');
CALL p9col('tracking_sessions','source_type','VARCHAR(24) NOT NULL DEFAULT ''manual'' AFTER ended_at');
CALL p9col('tracking_sessions','session_status','VARCHAR(24) NOT NULL DEFAULT ''active'' AFTER source_type');

-- Manual web tracking is part of Phase 9. A hardware tracker is optional.
ALTER TABLE tracking_events MODIFY device_tracker_id BIGINT UNSIGNED NULL;
ALTER TABLE tracking_events MODIFY latitude DECIMAL(10,7) NULL;
ALTER TABLE tracking_events MODIFY longitude DECIMAL(11,7) NULL;
CALL p9col('tracking_events','event_type','VARCHAR(32) NOT NULL DEFAULT ''location_update'' AFTER device_tracker_id');
CALL p9col('tracking_events','milestone_code','VARCHAR(32) NULL AFTER event_type');
CALL p9col('tracking_events','location_text','VARCHAR(255) NULL AFTER longitude');
CALL p9col('tracking_events','progress_percent','DECIMAL(5,2) NULL AFTER location_text');
CALL p9col('tracking_events','speed_kph','DECIMAL(7,2) NULL AFTER progress_percent');
CALL p9col('tracking_events','heading_degrees','SMALLINT UNSIGNED NULL AFTER speed_kph');
CALL p9col('tracking_events','notes','VARCHAR(500) NULL AFTER heading_degrees');
CALL p9col('tracking_events','actor_user_id','BIGINT UNSIGNED NULL AFTER notes');
CALL p9col('tracking_events','source_channel','VARCHAR(24) NOT NULL DEFAULT ''web'' AFTER actor_user_id');

CALL p9col('trip_location_summaries','trip_id','BIGINT UNSIGNED NULL AFTER trip_location_summarie_ref');
CALL p9col('trip_location_summaries','last_tracking_event_id','BIGINT UNSIGNED NULL AFTER trip_id');
CALL p9col('trip_location_summaries','latitude','DECIMAL(10,7) NULL AFTER last_tracking_event_id');
CALL p9col('trip_location_summaries','longitude','DECIMAL(11,7) NULL AFTER latitude');
CALL p9col('trip_location_summaries','location_text','VARCHAR(255) NULL AFTER longitude');
CALL p9col('trip_location_summaries','progress_percent','DECIMAL(5,2) NULL AFTER location_text');
CALL p9col('trip_location_summaries','last_event_at','DATETIME(6) NULL AFTER progress_percent');

CALL p9col('eta_updates','trip_id','BIGINT UNSIGNED NULL AFTER eta_update_ref');
CALL p9col('eta_updates','shipment_id','BIGINT UNSIGNED NULL AFTER trip_id');
CALL p9col('eta_updates','previous_eta_at','DATETIME(6) NULL AFTER shipment_id');
CALL p9col('eta_updates','estimated_arrival_at','DATETIME(6) NULL AFTER previous_eta_at');
CALL p9col('eta_updates','reason','VARCHAR(500) NULL AFTER estimated_arrival_at');
CALL p9col('eta_updates','source_type','VARCHAR(24) NOT NULL DEFAULT ''manual'' AFTER reason');
CALL p9col('eta_updates','actor_user_id','BIGINT UNSIGNED NULL AFTER source_type');

CALL p9col('alerts','trip_id','BIGINT UNSIGNED NULL AFTER alert_ref');
CALL p9col('alerts','shipment_id','BIGINT UNSIGNED NULL AFTER trip_id');
CALL p9col('alerts','incident_id','BIGINT UNSIGNED NULL AFTER shipment_id');
CALL p9col('alerts','alert_type','VARCHAR(32) NOT NULL DEFAULT ''operational'' AFTER incident_id');
CALL p9col('alerts','severity','VARCHAR(16) NOT NULL DEFAULT ''medium'' AFTER alert_type');
CALL p9col('alerts','title','VARCHAR(191) NULL AFTER severity');
CALL p9col('alerts','message','VARCHAR(1000) NULL AFTER title');
CALL p9col('alerts','alert_status','VARCHAR(24) NOT NULL DEFAULT ''open'' AFTER message');
CALL p9col('alerts','triggered_at','DATETIME(6) NULL AFTER alert_status');
CALL p9col('alerts','acknowledged_at','DATETIME(6) NULL AFTER triggered_at');
CALL p9col('alerts','acknowledged_by_user_id','BIGINT UNSIGNED NULL AFTER acknowledged_at');
CALL p9col('alerts','resolved_at','DATETIME(6) NULL AFTER acknowledged_by_user_id');
CALL p9col('alerts','resolved_by_user_id','BIGINT UNSIGNED NULL AFTER resolved_at');

CALL p9col('incidents','trip_id','BIGINT UNSIGNED NULL AFTER incident_ref');
CALL p9col('incidents','shipment_id','BIGINT UNSIGNED NULL AFTER trip_id');
CALL p9col('incidents','exception_type','VARCHAR(32) NOT NULL DEFAULT ''other'' AFTER shipment_id');
CALL p9col('incidents','severity','VARCHAR(16) NOT NULL DEFAULT ''medium'' AFTER exception_type');
CALL p9col('incidents','summary','VARCHAR(191) NULL AFTER severity');
CALL p9col('incidents','description','TEXT NULL AFTER summary');
CALL p9col('incidents','location_text','VARCHAR(255) NULL AFTER description');
CALL p9col('incidents','incident_status','VARCHAR(24) NOT NULL DEFAULT ''open'' AFTER location_text');
CALL p9col('incidents','reported_at','DATETIME(6) NULL AFTER incident_status');
CALL p9col('incidents','reported_by_user_id','BIGINT UNSIGNED NULL AFTER reported_at');
CALL p9col('incidents','resolved_at','DATETIME(6) NULL AFTER reported_by_user_id');
CALL p9col('incidents','resolved_by_user_id','BIGINT UNSIGNED NULL AFTER resolved_at');
CALL p9col('incidents','resolution_note','VARCHAR(1000) NULL AFTER resolved_by_user_id');

CALL p9col('incident_actions','incident_id','BIGINT UNSIGNED NULL AFTER incident_action_ref');
CALL p9col('incident_actions','action_type','VARCHAR(32) NOT NULL DEFAULT ''note'' AFTER incident_id');
CALL p9col('incident_actions','previous_status','VARCHAR(24) NULL AFTER action_type');
CALL p9col('incident_actions','new_status','VARCHAR(24) NULL AFTER previous_status');
CALL p9col('incident_actions','action_note','VARCHAR(1000) NULL AFTER new_status');
CALL p9col('incident_actions','action_at','DATETIME(6) NULL AFTER action_note');
CALL p9col('incident_actions','actor_user_id','BIGINT UNSIGNED NULL AFTER action_at');

DROP PROCEDURE p9col;

DELIMITER $$
DROP PROCEDURE IF EXISTS p9idx$$
CREATE PROCEDURE p9idx(IN t VARCHAR(64), IN n VARCHAR(64), IN c TEXT, IN u BOOLEAN)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=t AND INDEX_NAME=n
  ) THEN
    SET @q=CONCAT('ALTER TABLE `',t,'` ADD ',IF(u,'UNIQUE ',''),'INDEX `',n,'` (',c,')');
    PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END$$
DELIMITER ;

CALL p9idx('tracking_sessions','uq_tracking_sessions_trip','`trip_id`',TRUE);
CALL p9idx('tracking_events','ix_tracking_events_trip_time','`trip_id`,`source_at`',FALSE);
CALL p9idx('tracking_events','uq_tracking_events_idempotency','`idempotency_key`',TRUE);
CALL p9idx('trip_location_summaries','uq_trip_location_summary_trip','`trip_id`',TRUE);
CALL p9idx('eta_updates','ix_eta_updates_trip_time','`trip_id`,`created_at`',FALSE);
CALL p9idx('alerts','ix_alerts_trip_status','`trip_id`,`alert_status`,`triggered_at`',FALSE);
CALL p9idx('incidents','ix_incidents_trip_status','`trip_id`,`incident_status`,`reported_at`',FALSE);
CALL p9idx('incident_actions','ix_incident_actions_incident_time','`incident_id`,`action_at`',FALSE);
DROP PROCEDURE p9idx;

DELIMITER $$
DROP PROCEDURE IF EXISTS p9fk$$
CREATE PROCEDURE p9fk(IN t VARCHAR(64), IN n VARCHAR(64), IN c VARCHAR(64), IN rt VARCHAR(64), IN rc VARCHAR(64))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=t AND CONSTRAINT_NAME=n
  ) THEN
    SET @q=CONCAT('ALTER TABLE `',t,'` ADD CONSTRAINT `',n,'` FOREIGN KEY (`',c,'`) REFERENCES `',rt,'` (`',rc,'`)');
    PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END$$
DELIMITER ;

CALL p9fk('tracking_sessions','fk_tracking_sessions_trip','trip_id','trips','trip_id');
CALL p9fk('tracking_sessions','fk_tracking_sessions_shipment','shipment_id','shipments','shipment_id');
CALL p9fk('tracking_events','fk_tracking_events_session','tracking_session_id','tracking_sessions','tracking_session_id');
CALL p9fk('trip_location_summaries','fk_location_summary_trip','trip_id','trips','trip_id');
CALL p9fk('eta_updates','fk_eta_updates_trip','trip_id','trips','trip_id');
CALL p9fk('alerts','fk_alerts_trip','trip_id','trips','trip_id');
CALL p9fk('alerts','fk_alerts_incident','incident_id','incidents','incident_id');
CALL p9fk('incidents','fk_incidents_trip','trip_id','trips','trip_id');
CALL p9fk('incident_actions','fk_incident_actions_incident','incident_id','incidents','incident_id');
DROP PROCEDURE p9fk;

SELECT 'Phase 9 tracking, alerts and exceptions alignment completed' result;