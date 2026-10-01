<?php
declare(strict_types=1);
require_once __DIR__.'/../../../bootstrap/app.php';
use App\Services\Auth;use App\Services\FinanceService;use App\Support\Url;
Auth::requirePermission('DASHBOARD_VIEW_FINANCE');
$rows=Auth::can('PAYMENT_VIEW_FINANCE')?FinanceService::all():[];
$requested=count(array_filter($rows,fn($row)=>in_array($row['payment_status'],['requested','submitted'],true)));
$confirmed=count(array_filter($rows,fn($row)=>$row['payment_status']==='confirmed'));
$unpaid=count(array_filter($rows,fn($row)=>$row['settlement_id']&&$row['settlement_status']!=='paid'));
$pageTitle='Finance Dashboard';require BASE_PATH.'/app/Views/layout/header.php';?>
<div class="page-head"><div><h1>Finance Dashboard</h1><p>Customer payments, carrier settlements and payouts.</p></div><span class="badge">Phase 11</span></div>
<div class="grid dashboard-metrics"><div class="card metric"><span>Awaiting payment action</span><strong><?=h($requested)?></strong><span>Requested or submitted</span></div><div class="card metric"><span>Confirmed payments</span><strong><?=h($confirmed)?></strong><span>Ready for settlement</span></div><div class="card metric"><span>Open settlements</span><strong><?=h($unpaid)?></strong><span>Draft or approved</span></div></div>
<div class="card" style="margin-top:18px"><h2>Finance workspace</h2><p>Manage customer payments, settlement approval and payout records.</p><?php if(Auth::can('PAYMENT_VIEW_FINANCE')):?><a class="button" href="<?=h(Url::to('finance/index.php'))?>">Open Payments & Settlements</a><?php endif;?></div>
<?php require BASE_PATH.'/app/Views/layout/footer.php';?>
