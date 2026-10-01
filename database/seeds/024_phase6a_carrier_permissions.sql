-- Phase 6A carrier onboarding and Operations review permissions.
USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'CARRIER_PROFILE_CREATE_OWN','carrier','profile_create_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_PROFILE_CREATE_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'CARRIER_PROFILE_VIEW_OWN','carrier','profile_view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_PROFILE_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'CARRIER_REVIEW_QUEUE_VIEW','carrier','review_queue_view','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_REVIEW_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'CARRIER_REVIEW_APPROVE','carrier','review_approve','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_REVIEW_APPROVE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'CARRIER_REVIEW_REJECT','carrier','review_reject','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='CARRIER_REVIEW_REJECT');

-- Active carrier roles receive normal profile permissions. Requested-role onboarding is separately and narrowly enforced in CarrierOnboarding.
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'own',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code IN('CARRIER_PROFILE_CREATE_OWN','CARRIER_PROFILE_VIEW_OWN')
WHERE r.role_code='TRUCK_OWNER' AND r.is_active=1
AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');

INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code IN('CARRIER_REVIEW_QUEUE_VIEW','CARRIER_REVIEW_APPROVE','CARRIER_REVIEW_REJECT')
WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1
AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT permission_code FROM permissions WHERE permission_code LIKE 'CARRIER_%' ORDER BY permission_code;
