USE mccollins_shipping;SET time_zone='+00:00';START TRANSACTION;
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT x.c,'documents',x.a,x.s,1 FROM (
 SELECT 'DOCUMENT_MANAGE_OPERATIONS' c,'manage_operations' a,'sensitive' s
 UNION ALL SELECT 'DOCUMENT_UPLOAD_DRIVER','upload_driver','normal'
 UNION ALL SELECT 'DOCUMENT_VIEW_OPERATIONS','view_operations','sensitive'
 UNION ALL SELECT 'DOCUMENT_VIEW_DRIVER','view_driver','normal'
 UNION ALL SELECT 'DOCUMENT_VIEW_CARRIER','view_carrier','normal'
 UNION ALL SELECT 'DOCUMENT_VIEW_SHIPPER','view_shipper','normal'
 UNION ALL SELECT 'EPOD_SUBMIT_DRIVER','submit_epod','sensitive'
 UNION ALL SELECT 'EPOD_REVIEW_OPERATIONS','review_epod','sensitive'
 UNION ALL SELECT 'EPOD_VIEW_DRIVER','view_epod_driver','normal'
 UNION ALL SELECT 'EPOD_VIEW_CARRIER','view_epod_carrier','normal'
 UNION ALL SELECT 'EPOD_VIEW_SHIPPER','view_epod_shipper','normal'
)x WHERE NOT EXISTS(SELECT 1 FROM permissions p WHERE p.permission_code=x.c);
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('DOCUMENT_MANAGE_OPERATIONS','DOCUMENT_VIEW_OPERATIONS','EPOD_REVIEW_OPERATIONS')
WHERE r.role_code='MCCOLLIN_OPERATIONS' AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'owner',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON
(r.role_code='DRIVER' AND p.permission_code IN('DOCUMENT_UPLOAD_DRIVER','DOCUMENT_VIEW_DRIVER','EPOD_SUBMIT_DRIVER','EPOD_VIEW_DRIVER'))
OR(r.role_code='TRUCK_OWNER' AND p.permission_code IN('DOCUMENT_VIEW_CARRIER','EPOD_VIEW_CARRIER'))
OR(r.role_code='SHIPPER' AND p.permission_code IN('DOCUMENT_VIEW_SHIPPER','EPOD_VIEW_SHIPPER'))
WHERE NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;