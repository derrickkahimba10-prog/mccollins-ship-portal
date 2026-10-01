-- McCollins Implementation Phase 3
-- Approved idempotent permission reference-data seed. No tables or columns are created or altered.
USE mccollins_shipping;
START TRANSACTION;

INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'IDENTITY_PROFILE_VIEW_OWN','identity','view_own','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='IDENTITY_PROFILE_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'COMPANY_VIEW_OWN','company','view_own','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='COMPANY_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'COMPANY_CREATE_OWN','company','create_own','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='COMPANY_CREATE_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'COMPANY_UPDATE_OWN','company','update_own','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='COMPANY_UPDATE_OWN');

INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_SHIPPER','dashboard','view_shipper','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_SHIPPER');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_CF','dashboard','view_cf','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_CF');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_CARRIER','dashboard','view_carrier','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_CARRIER');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_DRIVER','dashboard','view_driver','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_DRIVER');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_MARKETPLACE_SELLER','dashboard','view_marketplace_seller','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_MARKETPLACE_SELLER');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_MARKETPLACE_BUYER','dashboard','view_marketplace_buyer','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_MARKETPLACE_BUYER');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_PROCUREMENT_SUPPLIER','dashboard','view_procurement_supplier','normal',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_PROCUREMENT_SUPPLIER');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_OPERATIONS','dashboard','view_operations','sensitive',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_OPERATIONS');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_FINANCE','dashboard','view_finance','sensitive',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_FINANCE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_COMPLIANCE','dashboard','view_compliance','sensitive',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_COMPLIANCE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active)
SELECT 'DASHBOARD_VIEW_SYSTEM_ADMIN','dashboard','view_system_admin','sensitive',1
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permission_code='DASHBOARD_VIEW_SYSTEM_ADMIN');

-- Every approved role may view its own profile.
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'own',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code='IDENTITY_PROFILE_VIEW_OWN'
WHERE r.is_active=1 AND NOT EXISTS (
  SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active'
);

-- Phase 3 company onboarding is deliberately limited to Shipper/Cargo Owner.
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'own',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON p.permission_code IN ('COMPANY_VIEW_OWN','COMPANY_CREATE_OWN','COMPANY_UPDATE_OWN')
WHERE r.role_code='SHIPPER' AND NOT EXISTS (
  SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active'
);

-- One dashboard permission per approved role; no business approval powers are granted.
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'own',UTC_TIMESTAMP(6),'active'
FROM roles r JOIN permissions p ON
 (r.role_code='SHIPPER' AND p.permission_code='DASHBOARD_VIEW_SHIPPER') OR
 (r.role_code='CF_AGENCY' AND p.permission_code='DASHBOARD_VIEW_CF') OR
 (r.role_code='TRUCK_OWNER' AND p.permission_code='DASHBOARD_VIEW_CARRIER') OR
 (r.role_code='DRIVER' AND p.permission_code='DASHBOARD_VIEW_DRIVER') OR
 (r.role_code='FARMER_AMCOS' AND p.permission_code='DASHBOARD_VIEW_MARKETPLACE_SELLER') OR
 (r.role_code='BUYER' AND p.permission_code='DASHBOARD_VIEW_MARKETPLACE_BUYER') OR
 (r.role_code='SUPPLIER' AND p.permission_code='DASHBOARD_VIEW_PROCUREMENT_SUPPLIER') OR
 (r.role_code='MCCOLLIN_OPERATIONS' AND p.permission_code='DASHBOARD_VIEW_OPERATIONS') OR
 (r.role_code='MCCOLLIN_FINANCE' AND p.permission_code='DASHBOARD_VIEW_FINANCE') OR
 (r.role_code='COMPLIANCE_SUPPORT' AND p.permission_code='DASHBOARD_VIEW_COMPLIANCE') OR
 (r.role_code='SYSTEM_ADMIN' AND p.permission_code='DASHBOARD_VIEW_SYSTEM_ADMIN')
WHERE NOT EXISTS (
  SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active'
);
COMMIT;

-- Safe verification (does not require information_schema privileges).
SELECT permission_code,domain_code,action_code FROM permissions
WHERE permission_code IN (
 'IDENTITY_PROFILE_VIEW_OWN','COMPANY_VIEW_OWN','COMPANY_CREATE_OWN','COMPANY_UPDATE_OWN',
 'DASHBOARD_VIEW_SHIPPER','DASHBOARD_VIEW_CF','DASHBOARD_VIEW_CARRIER','DASHBOARD_VIEW_DRIVER',
 'DASHBOARD_VIEW_MARKETPLACE_SELLER','DASHBOARD_VIEW_MARKETPLACE_BUYER','DASHBOARD_VIEW_PROCUREMENT_SUPPLIER',
 'DASHBOARD_VIEW_OPERATIONS','DASHBOARD_VIEW_FINANCE','DASHBOARD_VIEW_COMPLIANCE','DASHBOARD_VIEW_SYSTEM_ADMIN'
) ORDER BY permission_code;
