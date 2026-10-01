-- Approved Phase 4 alignment with the frozen load-intake schema.
-- One-time migration for the imported MariaDB 10.4 baseline.
USE mccollins_shipping;
ALTER TABLE loads
 ADD COLUMN origin_contact_id BIGINT UNSIGNED NULL AFTER destination_address_id,
 ADD COLUMN destination_contact_id BIGINT UNSIGNED NULL AFTER origin_contact_id,
 ADD COLUMN requested_delivery_from DATETIME(6) NULL AFTER requested_pickup_to,
 ADD COLUMN requested_delivery_to DATETIME(6) NULL AFTER requested_delivery_from,
 ADD COLUMN insurance_required BOOLEAN NOT NULL DEFAULT FALSE AFTER requested_delivery_to,
 ADD COLUMN special_instructions TEXT NULL AFTER insurance_required,
 ADD COLUMN source_service_type VARCHAR(32) NULL AFTER special_instructions,
 ADD INDEX ix_loads_customer_status_created (customer_company_id,current_status,created_at),
 ADD INDEX ix_loads_pickup (current_status,requested_pickup_from),
 ADD CONSTRAINT fk_loads_origin_address FOREIGN KEY(origin_address_id) REFERENCES addresses(address_id),
 ADD CONSTRAINT fk_loads_destination_address FOREIGN KEY(destination_address_id) REFERENCES addresses(address_id),
 ADD CONSTRAINT fk_loads_origin_contact FOREIGN KEY(origin_contact_id) REFERENCES contacts(contact_id),
 ADD CONSTRAINT fk_loads_destination_contact FOREIGN KEY(destination_contact_id) REFERENCES contacts(contact_id);
ALTER TABLE load_versions
 ADD COLUMN load_id BIGINT UNSIGNED NOT NULL AFTER load_version_id,
 ADD COLUMN version_no INT UNSIGNED NOT NULL AFTER load_version_ref,
 ADD COLUMN authored_by_user_id BIGINT UNSIGNED NOT NULL AFTER version_no,
 ADD COLUMN source_channel VARCHAR(24) NOT NULL DEFAULT 'web' AFTER authored_by_user_id,
 ADD COLUMN snapshot_json JSON NULL AFTER metadata_json,
 ADD COLUMN submission_reason VARCHAR(500) NULL AFTER snapshot_json,
 ADD COLUMN submitted_at DATETIME(6) NULL AFTER submission_reason,
 ADD CONSTRAINT uq_load_versions_load_version UNIQUE(load_id,version_no),
 ADD INDEX ix_load_versions_load_status (load_id,status),
 ADD CONSTRAINT fk_load_versions_load FOREIGN KEY(load_id) REFERENCES loads(load_id),
 ADD CONSTRAINT fk_load_versions_author FOREIGN KEY(authored_by_user_id) REFERENCES users(user_id);
ALTER TABLE load_items
 ADD COLUMN cargo_category_code VARCHAR(48) NULL AFTER description,
 ADD COLUMN weight_unit_code VARCHAR(16) NULL AFTER weight_value,
 ADD COLUMN volume_unit_code VARCHAR(16) NULL AFTER volume_value,
 ADD COLUMN packaging_details VARCHAR(500) NULL AFTER volume_unit_code,
 ADD COLUMN handling_requirements VARCHAR(500) NULL AFTER packaging_details,
 ADD COLUMN declared_value DECIMAL(19,4) NULL AFTER handling_requirements,
 ADD COLUMN currency_code CHAR(3) NULL AFTER declared_value,
 ADD CONSTRAINT uq_load_items_version_line UNIQUE(load_version_id,line_no),
 ADD INDEX ix_load_items_load (load_id),
 ADD CONSTRAINT fk_load_items_load FOREIGN KEY(load_id) REFERENCES loads(load_id),
 ADD CONSTRAINT fk_load_items_version FOREIGN KEY(load_version_id) REFERENCES load_versions(load_version_id);
SELECT 'Phase 4 load schema alignment completed' AS result;
