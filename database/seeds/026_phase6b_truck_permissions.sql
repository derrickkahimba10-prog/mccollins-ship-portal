-- Phase 6B truck registration and Operations verification permissions.
USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'TRUCK_CREATE_OWN','truck','create_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='TRUCK_CREATE_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'TRUCK_VIEW_OWN','truck','view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='TRUCK_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'TRUCK_REVIEW_QUEUE_VIEW','truck','review_queue_view','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='TRUCK_REVIEW_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'TRUCK_REVIEW_APPROVE','truck','review_approve','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='TRUCK_REVIEW_APPROVE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'TRUCK_REVIEW_REJECT','truck','review_reject','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='TRUCK_REVIEW_REJECT');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'owner',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('TRUCK_CREATE_OWN','TRUCK_VIEW_OWN')
WHERE r.role_code='TRUCK_OWNER' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('TRUCK_REVIEW_QUEUE_VIEW','TRUCK_REVIEW_APPROVE','TRUCK_REVIEW_REJECT')
WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT permission_code FROM permissions WHERE permission_code LIKE 'TRUCK_%' ORDER BY permission_code;
