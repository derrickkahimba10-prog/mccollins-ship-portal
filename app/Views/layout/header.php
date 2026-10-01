<?php
use App\Services\Auth;use App\Services\NavigationBadgeService;use App\Support\Url;
if(!isset($pageTitle))$pageTitle='Portal';$u=Auth::user();$ctx=Auth::context();$navCompany=$ctx['companies'][0]??null;$roles=$ctx['role_codes']??[];
function h(mixed $v):string{return htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');}
$navCounts=NavigationBadgeService::counts();$navGroups=[];
$add=function(string$group,string$path,string$label,?string$countKey=null,string$preview='')use(&$navGroups,$navCounts):void{$navGroups[$group][]=[$path,$label,$countKey?(int)($navCounts[$countKey]??0):0,$preview];};
$add('Workspace','dashboard.php','Overview',null,'Your role summary, key activity and quick actions.');
if(Auth::can('NOTIFICATION_VIEW_OWN'))$add('Workspace','notifications/index.php','Notifications','notifications','Unread operational and account messages.');
if(Auth::can('COMPANY_VIEW_OWN'))$add('Workspace','company/profile.php','Company',null,'Company profile and verification details.');
if(Auth::can('IDENTITY_PROFILE_VIEW_OWN'))$add('Workspace','profile.php','My profile',null,'Identity and account information.');
if(Auth::can('LOAD_REVIEW_QUEUE_VIEW'))$add('Operations','operations/queue.php','Load queue','loads','Loads awaiting review or clarification.');
if(Auth::can('CARRIER_REVIEW_QUEUE_VIEW'))$add('Operations','operations/carriers.php','Carrier verification','carriers','Carrier profiles awaiting verification.');
if(Auth::can('TRUCK_REVIEW_QUEUE_VIEW'))$add('Operations','operations/trucks.php','Truck verification','trucks','Trucks awaiting compliance review.');
if(Auth::can('DRIVER_REVIEW_QUEUE_VIEW'))$add('Operations','operations/drivers.php','Driver verification','drivers','Drivers awaiting identity or licence review.');
if(Auth::can('SUBSCRIPTION_REVIEW_QUEUE_VIEW'))$add('Operations','subscriptions/catalog.php','Subscription plans','subscriptions','Available plans and Carrier subscription visibility.');
if(Auth::can('ELIGIBILITY_VIEW_ALL'))$add('Operations','operations/eligibility.php','Fleet eligibility',null,'Verified and eligible fleet resources.');
if(Auth::can('MATCH_QUEUE_VIEW'))$add('Operations','operations/matching.php','Matching queue',null,'Approved loads ready for matching.');
if(Auth::can('OFFER_QUEUE_VIEW'))$add('Operations','operations/offers.php','Transport offers','offers','Countered or accepted offers requiring attention.');
if(Auth::can('ASSIGNMENT_QUEUE_VIEW'))$add('Operations','operations/assignments.php','Assignments',null,'Confirmed truck, driver and carrier assignments.');
if(Auth::can('TRIP_VIEW_OPERATIONS'))$add('Operations','operations/shipments.php','Shipments & Trips',null,'Plan, dispatch and monitor operational trips.');
if(Auth::can('TRACKING_VIEW_OPERATIONS'))$add('Operations','operations/tracking.php','Operations monitoring','monitoring','Open tracking alerts and exceptions.');
if(Auth::can('EPOD_REVIEW_OPERATIONS'))$add('Operations','operations/epods.php','Documents & e-POD',null,'Delivery evidence and e-POD review.');
if(Auth::can('PAYMENT_VIEW_FINANCE')){$add('Finance','subscriptions/catalog.php','Subscription plans',null,'Available plans and Carrier subscription visibility.');$add('Finance','finance/index.php','Payments & Settlements','payments','Payments awaiting finance action.');}
if(Auth::can('AUDIT_VIEW_ALL'))$add('Governance','system/audit.php','Audit events',null,'Important workflow and security history.');
if(Auth::can('ACCESS_LOG_VIEW'))$add('Governance','system/access-logs.php','Access logs',null,'Authentication and protected-resource access.');
if(Auth::hasRole('TRUCK_OWNER')){
 $add('Carrier','carrier/profile.php','Carrier profile',null,'Verification and carrier identity.');
 if(Auth::can('TRUCK_VIEW_OWN'))$add('Carrier','carrier/trucks/index.php','My trucks',null,'Registered fleet and compliance state.');
 if(Auth::can('CARRIER_DRIVER_VIEW'))$add('Carrier','carrier/drivers/index.php','My drivers',null,'Driver records and truck engagements.');
 if(Auth::can('SUBSCRIPTION_VIEW_OWN'))$add('Carrier','carrier/subscription.php','Subscription',null,'Plans, limits and subscription status.');
 if(Auth::can('ELIGIBILITY_VIEW_OWN'))$add('Carrier','carrier/eligibility.php','Fleet eligibility',null,'Current fleet eligibility results.');
 if(Auth::can('OFFER_VIEW_OWN'))$add('Carrier','carrier/offers/index.php','My transport offers','offers','Offers waiting for your response.');
 if(Auth::can('ASSIGNMENT_VIEW_OWN'))$add('Carrier','carrier/assignments/index.php','My assignments',null,'Accepted and active assignments.');
 if(Auth::can('TRIP_VIEW_CARRIER'))$add('Carrier','carrier/trips/index.php','Fleet trips',null,'Trips and transport documents.');
 if(Auth::can('SETTLEMENT_VIEW_CARRIER'))$add('Carrier','carrier/settlements/index.php','Settlements',null,'Carrier settlement and payout status.');
}
if(Auth::hasRole('DRIVER')&&Auth::can('TRIP_VIEW_DRIVER'))$add('Driver','driver/trips/index.php','My trips',null,'Assigned trips, readiness and progress updates.');
if(Auth::hasRole('SHIPPER')){
 if(Auth::can('LOAD_VIEW_OWN'))$add('Shipper','loads/index.php','My loads',null,'Draft and submitted freight requests.');
 if(Auth::can('LOAD_CREATE_OWN'))$add('Shipper','loads/create.php','Post a load',null,'Create a new company freight request.');
 if(Auth::can('SHIPMENT_VIEW_SHIPPER'))$add('Shipper','shipments/index.php','Shipments & Documents',null,'Shipment progress, tracking and documents.');
 if(Auth::can('PAYMENT_VIEW_SHIPPER'))$add('Shipper','payments/index.php','Payments','payments','Payments requiring your attention.');
}
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#043c32"><title><?=h($pageTitle)?> · McCollins</title><link rel="stylesheet" href="<?=h(Url::to('assets/css/app.css'))?>"></head><body><div class="app-shell"><aside class="sidebar" aria-label="Primary navigation"><a class="brand" href="<?=h(Url::to('dashboard.php'))?>"><span class="brand-mark">M</span><span>McCollins<br><small>Freight Intelligence</small></span></a><nav class="nav"><?php foreach($navGroups as$group=>$items):?><div class="nav-group"><span class="nav-section" data-i18n="<?=h($group)?>"><?=h($group)?></span><?php foreach($items as[$path,$label,$count,$preview]):?><a href="<?=h(Url::to($path))?>" data-preview="<?=h($preview)?>"><span data-i18n="<?=h($label)?>"><?=h($label)?></span><?php if($count>0):?><strong class="nav-count" aria-label="<?=h($count.' updates')?>"><?=h($count)?></strong><?php endif;?></a><?php endforeach;?></div><?php endforeach;?></nav><div class="sidebar-footer"><div class="user-chip"><strong><?=h($u['name']??'User')?></strong><span><?=h(implode(', ',$roles))?></span><?php if($navCompany):?><span><?=h($navCompany['display_name'])?></span><?php endif;?></div><form method="post" action="<?=h(Url::to('auth/logout.php'))?>"><input type="hidden" name="_csrf" value="<?=h(\App\Security\Csrf::token())?>"><button class="link-button" type="submit" data-i18n="Log out">Log out</button></form></div></aside><main class="main"><header class="topbar"><button class="menu-button" type="button" aria-label="Toggle navigation" aria-expanded="false">Menu</button><div class="topbar-identity"><span class="eyebrow">Authenticated workspace</span><strong><?=h($navCompany['display_name']??'McCollins internal workspace')?></strong></div><div class="topbar-actions"><button type="button" class="button secondary language-toggle" aria-label="Change interface language">Kiswahili</button><div class="topbar-status"><span class="secure-dot"></span> Secure session</div></div></header><section class="content"><?php if(isset($_GET['created'])):?><div class="success" role="status">Created successfully.</div><?php elseif(isset($_GET['updated'])):?><div class="success" role="status">Changes saved successfully.</div><?php endif;?>
