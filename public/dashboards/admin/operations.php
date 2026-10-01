<?php
declare(strict_types=1);
require_once __DIR__.'/../../../bootstrap/app.php';
use App\Services\Auth;use App\Services\ReviewWorkflow;use App\Services\MatchingService;use App\Support\Url;
Auth::requirePermission('DASHBOARD_VIEW_OPERATIONS');
$loads=Auth::can('LOAD_REVIEW_QUEUE_VIEW')?ReviewWorkflow::queue():[];
$submitted=count(array_filter($loads,fn($load)=>$load['current_status']==='submitted'));
$matching=Auth::can('MATCH_QUEUE_VIEW')?MatchingService::queue():[];
$links=[
 ['LOAD_REVIEW_QUEUE_VIEW','operations/queue.php','Open load queue'],['CARRIER_REVIEW_QUEUE_VIEW','operations/carriers.php','Carrier verification'],
 ['TRUCK_REVIEW_QUEUE_VIEW','operations/trucks.php','Truck verification'],['DRIVER_REVIEW_QUEUE_VIEW','operations/drivers.php','Driver verification'],
 ['SUBSCRIPTION_REVIEW_QUEUE_VIEW','operations/subscriptions.php','Subscription payments'],['ELIGIBILITY_VIEW_ALL','operations/eligibility.php','Fleet eligibility'],
 ['MATCH_QUEUE_VIEW','operations/matching.php','Matching queue'],['OFFER_QUEUE_VIEW','operations/offers.php','Transport offers'],
 ['ASSIGNMENT_QUEUE_VIEW','operations/assignments.php','Assignments'],['TRIP_VIEW_OPERATIONS','operations/shipments.php','Shipments & Trips'],
 ['TRACKING_VIEW_OPERATIONS','operations/tracking.php','Operations monitoring'],['EPOD_REVIEW_OPERATIONS','operations/epods.php','Documents & e-POD']
];
$pageTitle='Operations Dashboard';require BASE_PATH.'/app/Views/layout/header.php';?>
<div class="page-head"><div><h1>Operations Dashboard</h1><p>McCollins Operations Centre.</p></div><span class="badge">Core freight</span></div>
<div class="grid dashboard-metrics"><div class="card metric"><span>Submitted queue</span><strong><?=h($submitted)?></strong><span>Awaiting review start</span></div><div class="card metric"><span>Open workflow</span><strong><?=h(count($loads))?></strong><span>Review and clarification</span></div><div class="card metric"><span>Approved for matching</span><strong><?=h(count($matching))?></strong><span>Candidate queue</span></div></div>
<div class="card" style="margin-top:18px"><h2>Operations workspace</h2><p>Open a workflow using the shortcuts below.</p><div class="shortcut-grid"><?php foreach($links as[$permission,$path,$label])if(Auth::can($permission)):?><a class="button secondary" href="<?=h(Url::to($path))?>"><?=h($label)?></a><?php endif;?></div></div>
<?php require BASE_PATH.'/app/Views/layout/footer.php';?>
