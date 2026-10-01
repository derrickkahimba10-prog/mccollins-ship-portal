USE mccollins_shipping;
START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'LOAD_CREATE_OWN','loads','create_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_CREATE_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'LOAD_VIEW_OWN','loads','view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'LOAD_UPDATE_DRAFT_OWN','loads','update_draft_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_UPDATE_DRAFT_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'LOAD_SUBMIT_OWN','loads','submit_own','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_SUBMIT_OWN');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'company',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('LOAD_CREATE_OWN','LOAD_VIEW_OWN','LOAD_UPDATE_DRAFT_OWN','LOAD_SUBMIT_OWN')
WHERE r.role_code='SHIPPER' AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT permission_code FROM permissions WHERE permission_code LIKE 'LOAD_%' ORDER BY permission_code;
