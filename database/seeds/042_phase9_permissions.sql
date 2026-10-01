USE mccollins_shipping;
SET time_zone='+00:00';
START TRANSACTION;

INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT x.c,'tracking',x.a,x.s,1
FROM (
  SELECT 'TRACKING_VIEW_OPERATIONS' c,'view_operations' a,'sensitive' s
  UNION ALL SELECT 'TRACKING_UPDATE_OPERATIONS','update_operations','sensitive'
  UNION ALL SELECT 'TRACKING_VIEW_DRIVER','view_driver','normal'
  UNION ALL SELECT 'TRACKING_UPDATE_DRIVER','update_driver','normal'
  UNION ALL SELECT 'TRACKING_VIEW_CARRIER','view_carrier','normal'
  UNION ALL SELECT 'TRACKING_VIEW_SHIPPER','view_shipper','normal'
  UNION ALL SELECT 'ALERT_MANAGE_OPERATIONS','manage_alerts','sensitive'
  UNION ALL SELECT 'EXCEPTION_MANAGE_OPERATIONS','manage_exceptions','sensitive'
  UNION ALL SELECT 'EXCEPTION_CREATE_DRIVER','create_exception','normal'
) x
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.permission_code=x.c);

INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p
  ON p.permission_code IN(
    'TRACKING_VIEW_OPERATIONS','TRACKING_UPDATE_OPERATIONS',
    'ALERT_MANAGE_OPERATIONS','EXCEPTION_MANAGE_OPERATIONS'
  )
WHERE r.role_code='MCCOLLIN_OPERATIONS'
AND NOT EXISTS (
  SELECT 1 FROM role_permissions rp
  WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active'
);

INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'owner',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON
  (r.role_code='DRIVER' AND p.permission_code IN('TRACKING_VIEW_DRIVER','TRACKING_UPDATE_DRIVER','EXCEPTION_CREATE_DRIVER'))
  OR (r.role_code='TRUCK_OWNER' AND p.permission_code='TRACKING_VIEW_CARRIER')
  OR (r.role_code='SHIPPER' AND p.permission_code='TRACKING_VIEW_SHIPPER')
WHERE NOT EXISTS (
  SELECT 1 FROM role_permissions rp
  WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active'
);

COMMIT;