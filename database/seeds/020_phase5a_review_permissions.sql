-- Phase 5A review permissions. Idempotent reference-data seed.
USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'LOAD_REVIEW_QUEUE_VIEW','loads','review_queue_view','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_REVIEW_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'LOAD_REVIEW_START','loads','review_start','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_REVIEW_START');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'LOAD_REVIEW_REQUEST_CLARIFICATION','loads','review_request_clarification','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_REVIEW_REQUEST_CLARIFICATION');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'LOAD_CLARIFICATION_RESPOND_OWN','loads','clarification_respond_own','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='LOAD_CLARIFICATION_RESPOND_OWN');

INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code IN('LOAD_REVIEW_QUEUE_VIEW','LOAD_REVIEW_START','LOAD_REVIEW_REQUEST_CLARIFICATION')
WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1
AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');

INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'company',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code='LOAD_CLARIFICATION_RESPOND_OWN'
WHERE r.role_code='SHIPPER' AND r.is_active=1
AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT permission_code FROM permissions WHERE permission_code IN('LOAD_REVIEW_QUEUE_VIEW','LOAD_REVIEW_START','LOAD_REVIEW_REQUEST_CLARIFICATION','LOAD_CLARIFICATION_RESPOND_OWN') ORDER BY permission_code;
