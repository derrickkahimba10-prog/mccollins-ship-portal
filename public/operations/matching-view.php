<?php
declare(strict_types=1);
require_once __DIR__.'/../../bootstrap/app.php';
use App\Services\Auth;
use App\Services\MatchingService;
use App\Security\Csrf;
use App\Support\Url;
Auth::requirePermission('MATCH_VIEW');
$id=(int)($_GET['id']??0);
$errors=[];
$result=null;
$load=MatchingService::findLoad($id);
if(!$load){http_response_code(404);exit('Approved load not found.');}
if($_SERVER['REQUEST_METHOD']==='POST'){
    if(!Csrf::verify($_POST['_csrf']??null))$errors[]='Invalid form token.';
    else try{
        $result=MatchingService::generate($id,(int)Auth::user()['id']);
    }catch(RuntimeException $exception){$errors[]=$exception->getMessage();}
}
$candidates=MatchingService::candidates($id);
$pageTitle='Match '.$load['load_ref'];
require BASE_PATH.'/app/Views/layout/header.php';
?>
<div class="page-head"><div><h1><?=h($load['load_ref'])?></h1><p><?=h($load['company_name'].' · '.$load['origin_city'].' → '.$load['destination_city'])?></p></div><span class="badge">Approved · v<?=h($load['version_no'])?></span></div>
<?php if($result):?><div class="success">Candidate generation <?=h($result['run_ref'])?> completed: <?=h($result['generated'])?> generated, <?=h($result['review_required'])?> require review, <?=h($result['unsuitable'])?> screened out.</div><?php endif;?>
<?php foreach($errors as $error):?><div class="error"><?=h($error)?></div><?php endforeach;?>
<div class="grid">
<div class="card"><h3>Cargo</h3><p><?=h($load['item_description'])?></p><p><?=h($load['quantity'].' '.$load['unit_code'])?></p><p>Weight: <?=h($load['weight_value']!==null?$load['weight_value'].' '.$load['weight_unit_code']:'Not captured')?></p><p>Volume: <?=h($load['volume_value']!==null?$load['volume_value'].' '.$load['volume_unit_code']:'Not captured')?></p></div>
<div class="card"><h3>Schedule</h3><p>Pickup: <?=h($load['requested_pickup_from']?:'Not set')?> – <?=h($load['requested_pickup_to']?:'Not set')?></p><p>Delivery: <?=h($load['requested_delivery_from']?:'Not set')?> – <?=h($load['requested_delivery_to']?:'Not set')?></p></div>
<div class="card"><h3>Requirements</h3><p><?=h($load['handling_requirements']?:'No handling requirements captured')?></p><p><?=h($load['special_instructions']?:'No special instructions captured')?></p></div>
</div>
<div class="card" style="margin-top:18px"><h2>Generate candidates</h2><p>Eligibility is refreshed first. Existing active results are preserved as superseded history and a new immutable generation is recorded.</p><?php if(Auth::can('MATCH_GENERATE')):?><form method="post"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><button class="button">Generate / refresh candidates</button></form><?php endif;?></div>
<?php if($candidates&&Auth::can('OFFER_CREATE')):?><p style="margin-top:18px"><a class="button" href="<?=h(Url::to('operations/offer-create.php?load_id='.$id))?>">Create transport offers</a></p><?php endif;?><div class="notice">A candidate marked <strong>review required</strong> passed current eligibility and availability checks. Capacity is evaluated when units are comparable. Truck-body requirement and live truck location are not captured in the approved load version, so Phase 7A does not claim a final match.</div>
<?php foreach($candidates as $candidate):?>
<div class="card" style="margin-top:18px"><div class="page-head"><div><h2><?=h($candidate['registration_number'].' · '.$candidate['make_name'].' '.$candidate['model_name'])?></h2><p><?=h(($candidate['carrier_company_name']?:$candidate['carrier_user_name']).' · Driver '.$candidate['driver_name'])?></p></div><span class="status-pill"><?=h(str_replace('_',' ',$candidate['suitability_status']))?></span></div>
<p><strong>Truck:</strong> <?=h($candidate['body_type_code'].' · '.$candidate['capacity_value'].' '.$candidate['capacity_unit'])?></p><p><?=h($candidate['overall_reason'])?></p>
<div class="table-wrap"><table><thead><tr><th>Factor</th><th>Result</th><th>Required</th><th>Actual</th><th>Reason</th></tr></thead><tbody>
<?php foreach($candidate['factors'] as $factor):?><tr><td><?=h(str_replace('_',' ',$factor['factor_code']))?></td><td><?=h(str_replace('_',' ',$factor['factor_result']))?></td><td><?=h($factor['required_value']!==null?$factor['required_value'].' '.$factor['unit_code']:'—')?></td><td><?=h($factor['actual_value']!==null?$factor['actual_value'].' '.$factor['unit_code']:'—')?></td><td><?=h($factor['reason'])?></td></tr><?php endforeach;?>
</tbody></table></div><p class="muted">Run <?=h($candidate['generated_run_ref'])?> · generated UTC <?=h($candidate['generated_at'])?></p></div>
<?php endforeach;if(!$candidates):?><div class="card" style="margin-top:18px"><p class="muted">No current candidates. Confirm at least one Carrier has an active in-term subscription and an eligible available Driver–truck pair, then generate again.</p></div><?php endif;?>
<p style="margin-top:18px"><a href="<?=h(Url::to('operations/matching.php'))?>">← Back to matching queue</a></p>
<?php require BASE_PATH.'/app/Views/layout/footer.php';
