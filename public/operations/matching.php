<?php
declare(strict_types=1);
require_once __DIR__.'/../../bootstrap/app.php';
use App\Services\Auth;
use App\Services\MatchingService;
use App\Support\Url;
Auth::requirePermission('MATCH_QUEUE_VIEW');
$loads=MatchingService::queue();
$pageTitle='Matching Queue';
require BASE_PATH.'/app/Views/layout/header.php';
?>
<div class="page-head"><div><h1>Matching queue</h1><p>Approved loads ready for Operations candidate screening.</p></div><span class="badge"><?=h(count($loads))?> approved</span></div>
<div class="notice">Phase 7A generates read-only candidates from currently eligible and available Driver–truck pairs. It does not create offers, assignments, dispatches, or shipments.</div>
<div class="card table-wrap"><table><thead><tr><th>Load</th><th>Customer</th><th>Cargo</th><th>Route</th><th>Pickup UTC</th><th>Candidates</th><th>Last generated UTC</th><th></th></tr></thead><tbody>
<?php foreach($loads as $load):?>
<tr><td><?=h($load['load_ref'])?> · v<?=h($load['version_no'])?></td><td><?=h($load['company_name'])?></td><td><?=h($load['item_description'].' · '.$load['quantity'].' '.$load['unit_code'])?></td><td><?=h($load['origin_city'].' → '.$load['destination_city'])?></td><td><?=h($load['requested_pickup_from']?:'Not set')?></td><td><?=h((int)$load['candidate_count'])?></td><td><?=h($load['last_generated_at']?:'Not generated')?></td><td><a href="<?=h(Url::to('operations/matching-view.php?id='.$load['load_id']))?>">Open</a></td></tr>
<?php endforeach;if(!$loads):?><tr><td colspan="8" class="muted">No approved loads are ready for matching.</td></tr><?php endif;?>
</tbody></table></div>
<?php require BASE_PATH.'/app/Views/layout/footer.php';
