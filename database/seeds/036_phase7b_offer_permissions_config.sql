USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO configuration_setting_versions(configuration_setting_version_ref,setting_code,version_no,decimal_value,effective_from,metadata_json,status)
SELECT 'CFG-FX-TZS-USD-1','FX_TZS_PER_USD',1,2600,UTC_TIMESTAMP(6),JSON_OBJECT('approved_for','Phase 7B offer display'),'active'
WHERE NOT EXISTS(SELECT 1 FROM configuration_setting_versions WHERE setting_code='FX_TZS_PER_USD' AND version_no=1);
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'OFFER_QUEUE_VIEW','offer','queue_view','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='OFFER_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'OFFER_CREATE','offer','create','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='OFFER_CREATE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'OFFER_REVISE','offer','revise','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='OFFER_REVISE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'OFFER_VIEW_OWN','offer','view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='OFFER_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'OFFER_RESPOND_OWN','offer','respond_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='OFFER_RESPOND_OWN');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('OFFER_QUEUE_VIEW','OFFER_CREATE','OFFER_REVISE') WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'owner',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('OFFER_VIEW_OWN','OFFER_RESPOND_OWN') WHERE r.role_code='TRUCK_OWNER' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT setting_code,decimal_value FROM configuration_setting_versions WHERE setting_code='FX_TZS_PER_USD' AND status='active';
