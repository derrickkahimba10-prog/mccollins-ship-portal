<?php
declare(strict_types=1);
require_once __DIR__.'/../../bootstrap/app.php';
use App\Services\Auth;
use App\Services\ReviewWorkflow;
use App\Security\Csrf;
use App\Support\Url;
Auth::requirePermission('LOAD_REVIEW_QUEUE_VIEW');
$id=(int)($_GET['id']??0);$errors=[];$load=ReviewWorkflow::find($id);
if(!$load){http_response_code(404);exit('Load not found.');}
if($_SERVER['REQUEST_METHOD']==='POST'){
 if(!Csrf::verify($_POST['_csrf']??null))$errors[]='Invalid form token.';
 else try{
  $action=(string)($_POST['action']??'');$uid=(int)Auth::user()['id'];
  if($action==='start')ReviewWorkflow::start($id,$uid);
  elseif($action==='clarify')ReviewWorkflow::requestClarification($id,$uid,(string)($_POST['clarification_request']??''));
  elseif($action==='approve')ReviewWorkflow::decide($id,$uid,'approved',(string)($_POST['decision_reason']??''));
  elseif($action==='reject')ReviewWorkflow::decide($id,$uid,'rejected',(string)($_POST['decision_reason']??''));
  else throw new RuntimeException('Unknown review action.');
  header('Location: '.Url::to('operations/review.php?id='.$id.'&saved=1'));exit;
 }catch(RuntimeException $e){$errors[]=$e->getMessage();}
}
$pageTitle='Review '.$load['load_ref'];require BASE_PATH.'/app/Views/layout/header.php';
?><div class="page-head"><div><h1><?=h($load['load_ref'])?></h1><p><?=h($load['company_name'])?> · version <?=h($load['version_no'])?></p></div><span class="badge"><?=h(str_replace('_',' ',$load['current_status']))?></span></div>
<?php if(isset($_GET['saved'])):?><div class="success">Review workflow updated.</div><?php endif;foreach($errors as $e):?><div class="error"><?=h($e)?></div><?php endforeach;?>
<div class="grid"><div class="card"><h3>Route</h3><p><?=h($load['origin_line_1'].', '.$load['origin_city'])?></p><p>to <?=h($load['destination_line_1'].', '.$load['destination_city'])?></p></div><div class="card"><h3>Schedule</h3><p>Pickup: <?=h($load['requested_pickup_from']?:'Not set')?> – <?=h($load['requested_pickup_to']?:'Not set')?></p><p>Delivery: <?=h($load['requested_delivery_from']?:'Not set')?> – <?=h($load['requested_delivery_to']?:'Not set')?></p></div><div class="card"><h3>Cargo</h3><p><?=h($load['item_description'])?></p><p><?=h($load['quantity'].' '.$load['unit_code'])?></p></div></div>
<?php if($load['clarification_request']):?><div class="notice"><strong>Clarification requested:</strong><br><?=nl2br(h($load['clarification_request']))?></div><?php endif;?>
<?php if($load['decision_code']):?><div class="<?=h($load['decision_code']==='approved'?'success':'error')?>"><strong>Decision: <?=h(ucfirst($load['decision_code']))?></strong><?php if($load['decision_reason']):?><br><?=nl2br(h($load['decision_reason']))?><?php endif;?></div><?php endif;?>
<div class="card" style="margin-top:18px"><h3>Operations review actions</h3>
<?php if($load['current_status']==='submitted'&&Auth::can('LOAD_REVIEW_START')):?><form method="post"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="start"><button class="button">Start review</button></form>
<?php elseif($load['current_status']==='under_review'):?>
<div class="decision-grid">
<?php if(Auth::can('LOAD_REVIEW_APPROVE')):?><form method="post" class="decision-form"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="approve"><div class="field"><label>Approval note <span class="muted">(optional)</span></label><textarea name="decision_reason" rows="4" maxlength="2000"></textarea></div><button class="button" style="margin-top:12px">Approve load</button></form><?php endif;?>
<?php if(Auth::can('LOAD_REVIEW_REQUEST_CLARIFICATION')):?><form method="post" class="decision-form"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="clarify"><div class="field"><label>Clarification required from Shipper</label><textarea name="clarification_request" rows="4" minlength="10" maxlength="4000" required></textarea></div><button class="button secondary" style="margin-top:12px">Request clarification</button></form><?php endif;?>
<?php if(Auth::can('LOAD_REVIEW_REJECT')):?><form method="post" class="decision-form"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="reject"><div class="field"><label>Rejection reason</label><textarea name="decision_reason" rows="4" minlength="10" maxlength="4000" required></textarea></div><button class="button danger" style="margin-top:12px">Reject load</button></form><?php endif;?>
</div>
<?php else:?><p class="muted">This review is closed or is waiting for the Shipper.</p><?php endif;?></div>
<?php require BASE_PATH.'/app/Views/layout/footer.php';
