USE mccollins_shipping;
SET time_zone='+00:00';
DELIMITER $$
DROP PROCEDURE IF EXISTS p10col$$
CREATE PROCEDURE p10col(IN t VARCHAR(64),IN c VARCHAR(64),IN d TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=t AND COLUMN_NAME=c) THEN
  SET @q=CONCAT('ALTER TABLE `',t,'` ADD COLUMN `',c,'` ',d);PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;
 END IF;
END$$
DELIMITER ;
CALL p10col('documents','title','VARCHAR(191) NULL AFTER document_ref');
CALL p10col('documents','description','VARCHAR(500) NULL AFTER sensitivity');
CALL p10col('documents','current_version_id','BIGINT UNSIGNED NULL AFTER description');
CALL p10col('document_versions','original_file_name','VARCHAR(255) NULL AFTER version_no');
CALL p10col('document_versions','uploaded_at','DATETIME(6) NULL AFTER byte_size');

CALL p10col('document_access_grants','document_id','BIGINT UNSIGNED NULL AFTER document_access_grant_ref');
CALL p10col('document_access_grants','grantee_company_id','BIGINT UNSIGNED NULL AFTER document_id');
CALL p10col('document_access_grants','grantee_user_id','BIGINT UNSIGNED NULL AFTER grantee_company_id');
CALL p10col('document_access_grants','grantee_role_code','VARCHAR(48) NULL AFTER grantee_user_id');
CALL p10col('document_access_grants','access_level','VARCHAR(24) NOT NULL DEFAULT ''view'' AFTER grantee_role_code');
CALL p10col('document_access_grants','effective_from','DATETIME(6) NULL AFTER access_level');
CALL p10col('document_access_grants','effective_to','DATETIME(6) NULL AFTER effective_from');

CALL p10col('epods','epod_status','VARCHAR(24) NOT NULL DEFAULT ''draft'' AFTER active_version_id');
CALL p10col('epods','delivery_result','VARCHAR(24) NULL AFTER delivered_at');
CALL p10col('epods','recipient_name','VARCHAR(191) NULL AFTER delivery_result');
CALL p10col('epods','recipient_contact','VARCHAR(120) NULL AFTER recipient_name');
CALL p10col('epods','submitted_at','DATETIME(6) NULL AFTER recipient_contact');
CALL p10col('epods','submitted_by_user_id','BIGINT UNSIGNED NULL AFTER submitted_at');
CALL p10col('epods','confirmed_at','DATETIME(6) NULL AFTER submitted_by_user_id');
CALL p10col('epods','confirmed_by_user_id','BIGINT UNSIGNED NULL AFTER confirmed_at');

CALL p10col('epod_versions','epod_id','BIGINT UNSIGNED NULL AFTER epod_version_ref');
CALL p10col('epod_versions','version_no','INT UNSIGNED NULL AFTER epod_id');
CALL p10col('epod_versions','delivery_result','VARCHAR(24) NULL AFTER version_no');
CALL p10col('epod_versions','recipient_name','VARCHAR(191) NULL AFTER delivery_result');
CALL p10col('epod_versions','recipient_contact','VARCHAR(120) NULL AFTER recipient_name');
CALL p10col('epod_versions','delivery_notes','TEXT NULL AFTER recipient_contact');
CALL p10col('epod_versions','signature_name','VARCHAR(191) NULL AFTER delivery_notes');
CALL p10col('epod_versions','delivered_at','DATETIME(6) NULL AFTER signature_name');
CALL p10col('epod_versions','submitted_by_user_id','BIGINT UNSIGNED NULL AFTER delivered_at');

CALL p10col('epod_item_results','epod_version_id','BIGINT UNSIGNED NULL AFTER epod_item_result_ref');
CALL p10col('epod_item_results','shipment_item_id','BIGINT UNSIGNED NULL AFTER epod_version_id');
CALL p10col('epod_item_results','result_code','VARCHAR(24) NULL AFTER shipment_item_id');
CALL p10col('epod_item_results','quantity_received','DECIMAL(14,3) NULL AFTER result_code');
CALL p10col('epod_item_results','result_notes','VARCHAR(500) NULL AFTER quantity_received');

CALL p10col('epod_confirmations','epod_id','BIGINT UNSIGNED NULL AFTER epod_confirmation_ref');
CALL p10col('epod_confirmations','epod_version_id','BIGINT UNSIGNED NULL AFTER epod_id');
CALL p10col('epod_confirmations','decision','VARCHAR(24) NULL AFTER epod_version_id');
CALL p10col('epod_confirmations','confirmation_notes','VARCHAR(1000) NULL AFTER decision');
CALL p10col('epod_confirmations','confirmed_at','DATETIME(6) NULL AFTER confirmation_notes');
CALL p10col('epod_confirmations','confirmed_by_user_id','BIGINT UNSIGNED NULL AFTER confirmed_at');
DROP PROCEDURE p10col;

DELIMITER $$
DROP PROCEDURE IF EXISTS p10idx$$
CREATE PROCEDURE p10idx(IN t VARCHAR(64),IN n VARCHAR(64),IN c TEXT,IN u BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=t AND INDEX_NAME=n) THEN
  SET @q=CONCAT('ALTER TABLE `',t,'` ADD ',IF(u,'UNIQUE ',''),'INDEX `',n,'` (',c,')');PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;
 END IF;
END$$
DELIMITER ;
CALL p10idx('shipment_documents','uq_shipment_document_link','`subject_id`,`document_id`',TRUE);
CALL p10idx('trip_documents','uq_trip_document_link','`subject_id`,`document_id`',TRUE);
CALL p10idx('epods','uq_epods_trip','`trip_id`',TRUE);
CALL p10idx('epod_versions','uq_epod_versions_number','`epod_id`,`version_no`',TRUE);
CALL p10idx('epod_documents','uq_epod_document_link','`subject_id`,`document_id`',TRUE);
CALL p10idx('epod_confirmations','ix_epod_confirmations_epod','`epod_id`,`confirmed_at`',FALSE);
CALL p10idx('document_access_grants','ix_doc_grants_document','`document_id`,`status`',FALSE);
DROP PROCEDURE p10idx;

DELIMITER $$
DROP PROCEDURE IF EXISTS p10fk$$
CREATE PROCEDURE p10fk(IN t VARCHAR(64),IN n VARCHAR(64),IN c VARCHAR(64),IN rt VARCHAR(64),IN rc VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=t AND CONSTRAINT_NAME=n) THEN
  SET @q=CONCAT('ALTER TABLE `',t,'` ADD CONSTRAINT `',n,'` FOREIGN KEY (`',c,'`) REFERENCES `',rt,'` (`',rc,'`)');PREPARE s FROM @q;EXECUTE s;DEALLOCATE PREPARE s;
 END IF;
END$$
DELIMITER ;
CALL p10fk('shipment_documents','fk_shipment_documents_document','document_id','documents','document_id');
CALL p10fk('shipment_documents','fk_shipment_documents_shipment','subject_id','shipments','shipment_id');
CALL p10fk('trip_documents','fk_trip_documents_document','document_id','documents','document_id');
CALL p10fk('trip_documents','fk_trip_documents_trip','subject_id','trips','trip_id');
CALL p10fk('epods','fk_epods_trip','trip_id','trips','trip_id');
CALL p10fk('epods','fk_epods_stop','stop_id','stops','stop_id');
CALL p10fk('epods','fk_epods_driver','driver_id','drivers','driver_id');
CALL p10fk('epod_versions','fk_epod_versions_epod','epod_id','epods','epod_id');
CALL p10fk('epod_documents','fk_epod_documents_document','document_id','documents','document_id');
CALL p10fk('epod_documents','fk_epod_documents_epod','subject_id','epods','epod_id');
CALL p10fk('epod_item_results','fk_epod_item_results_version','epod_version_id','epod_versions','epod_version_id');
CALL p10fk('epod_confirmations','fk_epod_confirmations_epod','epod_id','epods','epod_id');
CALL p10fk('epod_confirmations','fk_epod_confirmations_version','epod_version_id','epod_versions','epod_version_id');
CALL p10fk('document_access_grants','fk_document_grants_document','document_id','documents','document_id');
DROP PROCEDURE p10fk;
SELECT 'Phase 10 documents and e-POD alignment completed' result;