-- Phase 7A Operations matching permissions.
USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'MATCH_QUEUE_VIEW','matching','queue_view','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='MATCH_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'MATCH_VIEW','matching','view','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='MATCH_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'MATCH_GENERATE','matching','generate','sensitive',1
WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='MATCH_GENERATE');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code IN('MATCH_QUEUE_VIEW','MATCH_VIEW','MATCH_GENERATE')
WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1
AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT permission_code FROM permissions WHERE permission_code IN('MATCH_QUEUE_VIEW','MATCH_VIEW','MATCH_GENERATE') ORDER BY permission_code;
