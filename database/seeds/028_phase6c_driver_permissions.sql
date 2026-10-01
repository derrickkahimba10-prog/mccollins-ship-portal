-- Phase 6C Driver creation, verification, and carrier assignment permissions.
USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'CARRIER_DRIVER_CREATE','driver','carrier_create','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_DRIVER_CREATE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'CARRIER_DRIVER_VIEW','driver','carrier_view','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_DRIVER_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'CARRIER_DRIVER_ASSIGN_TRUCK','driver','carrier_assign_truck','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_DRIVER_ASSIGN_TRUCK');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'DRIVER_PROFILE_VIEW_OWN','driver','profile_view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='DRIVER_PROFILE_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'DRIVER_REVIEW_QUEUE_VIEW','driver','review_queue_view','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='DRIVER_REVIEW_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'DRIVER_REVIEW_APPROVE','driver','review_approve','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='DRIVER_REVIEW_APPROVE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'DRIVER_REVIEW_REJECT','driver','review_reject','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='DRIVER_REVIEW_REJECT');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'owner',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('CARRIER_DRIVER_CREATE','CARRIER_DRIVER_VIEW','CARRIER_DRIVER_ASSIGN_TRUCK') WHERE r.role_code='TRUCK_OWNER' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'own',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code='DRIVER_PROFILE_VIEW_OWN' WHERE r.role_code='DRIVER' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('DRIVER_REVIEW_QUEUE_VIEW','DRIVER_REVIEW_APPROVE','DRIVER_REVIEW_REJECT') WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT permission_code FROM permissions WHERE permission_code LIKE '%DRIVER%' ORDER BY permission_code;
