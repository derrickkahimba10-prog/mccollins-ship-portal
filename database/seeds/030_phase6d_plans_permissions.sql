-- Phase 6D approved plan limits and permissions.
USE mccollins_shipping;
SET time_zone = '+00:00';
START TRANSACTION;
INSERT INTO subscription_plan_versions(subscription_plan_version_ref,subscription_plan_id,version_no,plan_code,plan_name,max_trucks,max_drivers,effective_from,metadata_json,status)
SELECT 'PLV-GOLD-1',p.subscription_plan_id,1,'GOLD','Gold',2,2,UTC_TIMESTAMP(6),JSON_OBJECT('approved_limit_policy','2 trucks / 2 drivers'),'active' FROM subscription_plans p WHERE p.subscription_plan_ref='PLAN-GOLD' AND NOT EXISTS(SELECT 1 FROM subscription_plan_versions v WHERE v.plan_code='GOLD' AND v.version_no=1);
INSERT INTO subscription_plan_versions(subscription_plan_version_ref,subscription_plan_id,version_no,plan_code,plan_name,max_trucks,max_drivers,effective_from,metadata_json,status)
SELECT 'PLV-PREMIUM-1',p.subscription_plan_id,1,'PREMIUM','Premium',10,10,UTC_TIMESTAMP(6),JSON_OBJECT('approved_limit_policy','10 trucks / 10 drivers'),'active' FROM subscription_plans p WHERE p.subscription_plan_ref='PLAN-PREMIUM' AND NOT EXISTS(SELECT 1 FROM subscription_plan_versions v WHERE v.plan_code='PREMIUM' AND v.version_no=1);
INSERT INTO subscription_plan_versions(subscription_plan_version_ref,subscription_plan_id,version_no,plan_code,plan_name,max_trucks,max_drivers,effective_from,metadata_json,status)
SELECT 'PLV-PLATINUM-1',p.subscription_plan_id,1,'PLATINUM','Platinum',NULL,NULL,UTC_TIMESTAMP(6),JSON_OBJECT('approved_limit_policy','unlimited'),'active' FROM subscription_plans p WHERE p.subscription_plan_ref='PLAN-PLATINUM' AND NOT EXISTS(SELECT 1 FROM subscription_plan_versions v WHERE v.plan_code='PLATINUM' AND v.version_no=1);
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'SUBSCRIPTION_REQUEST_OWN','subscription','request_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='SUBSCRIPTION_REQUEST_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'SUBSCRIPTION_VIEW_OWN','subscription','view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='SUBSCRIPTION_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'ELIGIBILITY_VIEW_OWN','eligibility','view_own','normal',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='ELIGIBILITY_VIEW_OWN');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'SUBSCRIPTION_REVIEW_QUEUE_VIEW','subscription','review_queue_view','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='SUBSCRIPTION_REVIEW_QUEUE_VIEW');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'SUBSCRIPTION_ACTIVATE','subscription','activate','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='SUBSCRIPTION_ACTIVATE');
INSERT INTO permissions(permission_code,domain_code,action_code,sensitivity,is_active) SELECT 'ELIGIBILITY_VIEW_ALL','eligibility','view_all','sensitive',1 WHERE NOT EXISTS(SELECT 1 FROM permissions WHERE permission_code='ELIGIBILITY_VIEW_ALL');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'owner',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('SUBSCRIPTION_REQUEST_OWN','SUBSCRIPTION_VIEW_OWN','ELIGIBILITY_VIEW_OWN') WHERE r.role_code='TRUCK_OWNER' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
INSERT INTO role_permissions(role_id,permission_id,scope_class,effective_from,status)
SELECT r.role_id,p.permission_id,'global',UTC_TIMESTAMP(6),'active' FROM roles r JOIN permissions p ON p.permission_code IN('SUBSCRIPTION_REVIEW_QUEUE_VIEW','SUBSCRIPTION_ACTIVATE','ELIGIBILITY_VIEW_ALL') WHERE r.role_code='MCCOLLIN_OPERATIONS' AND r.is_active=1 AND NOT EXISTS(SELECT 1 FROM role_permissions rp WHERE rp.role_id=r.role_id AND rp.permission_id=p.permission_id AND rp.status='active');
COMMIT;
SELECT plan_code,plan_name,max_trucks,max_drivers FROM subscription_plan_versions WHERE version_no=1 ORDER BY plan_code;
