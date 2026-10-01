<?php
declare(strict_types=1);
require_once __DIR__.'/../../bootstrap/app.php';
use App\Security\Csrf;
use App\Services\Auth;
use App\Services\TrackingService;
Auth::requireLogin();
$id=(int)($_GET['id']??0);$uid=(int)Auth::user()['id'];
$trip=TrackingService::findScoped($id,$uid);
if(!$trip){http_response_code(403);exit('Trip not found or access denied.');}
$errors=[];
if($_SERVER['REQUEST_METHOD']==='POST'){
 try{
  if(!Csrf::verify($_POST['_csrf']??null))throw new RuntimeException('Invalid token.');
  $action=(string)($_POST['action']??'');
  if($action==='tracking')TrackingService::recordTracking($id,$_POST,$uid);
  elseif($action==='eta')TrackingService::updateEta($id,(string)($_POST['eta']??''),(string)($_POST['reason']??''),$uid);
  elseif($action==='create_alert')TrackingService::createAlert($id,$_POST,$uid);
  elseif($action==='update_alert')TrackingService::updateAlert($id,(int)($_POST['alert_id']??0),(string)($_POST['to']??''),$uid);
  elseif($action==='create_incident')TrackingService::createIncident($id,$_POST,$uid);
  elseif($action==='update_incident')TrackingService::updateIncident($id,(int)($_POST['incident_id']??0),(string)($_POST['to']??''),(string)($_POST['note']??''),$uid);
  else throw new RuntimeException('Invalid action.');
  header('Location: ?id='.$id.'&updated=1');exit;
 }catch(RuntimeException $e){$errors[]=$e->getMessage();}
 $trip=TrackingService::findScoped($id,$uid);
}
$events=TrackingService::events($id);$alerts=TrackingService::alerts($id);$incidents=TrackingService::incidents($id);
$canUpdate=Auth::can('TRACKING_UPDATE_OPERATIONS')||(Auth::can('TRACKING_UPDATE_DRIVER')&&(int)$trip['driver_user_id']===$uid);
$canCreateIncident=Auth::can('EXCEPTION_MANAGE_OPERATIONS')||(Auth::can('EXCEPTION_CREATE_DRIVER')&&(int)$trip['driver_user_id']===$uid);
$pageTitle='Tracking '.$trip['trip_ref'];
require BASE_PATH.'/app/Views/layout/header.php';
?>
<div class="page-head"><div><h1><?=h($trip['trip_ref'])?> tracking</h1><p><?=h($trip['shipment_ref'].' · '.$trip['load_ref'].' · '.$trip['origin_city'].' → '.$trip['destination_city'])?></p><p><a href="<?=h(\App\Support\Url::to('documents/trip.php?id='.$id))?>">Open transport documents & e-POD</a></p></div><span class="status-pill status-<?=h($trip['current_status'])?>"><?=h(str_replace('_',' ',$trip['current_status']))?></span></div>
<?php foreach($errors as $error):?><div class="error"><?=h($error)?></div><?php endforeach;?>
<div class="form-grid">
 <div class="card"><h3>Current position</h3><p><?=h($trip['last_location']?:'No tracking update yet')?></p><p class="muted"><?=h($trip['last_event_at']?:'')?></p></div>
 <div class="card"><h3>Progress</h3><p><?=h($trip['progress_percent']!==null?$trip['progress_percent'].'%':'Not reported')?></p><p>Trip status: <span class="status-pill status-<?=h($trip['current_status'])?>"><?=h(str_replace('_',' ',$trip['current_status']))?></span></p></div>
 <div class="card"><h3>Estimated arrival</h3><p class="timestamp"><?=h($trip['current_eta_at']?:$trip['planned_arrival_at'])?></p><p class="muted">Planned: <strong><?=h($trip['planned_arrival_at'])?></strong></p></div>
 <div class="card"><h3>Operational attention</h3><p><?=h($trip['open_alerts'])?> open alerts · <?=h($trip['open_incidents'])?> open exceptions</p></div>
</div>
<?php if($canUpdate):?>
<div class="form-grid" style="margin-top:18px">
 <form method="post" class="card"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="tracking"><h2>Record tracking update</h2>
  <div class="field"><label>Event</label><select name="event_type"><option value="location_update">Location update</option><option value="checkpoint_reached">Checkpoint reached</option><option value="delay_reported">Delay reported</option><option value="route_update">Route update</option><option value="delivery_update">Delivery update</option></select></div>
  <div class="field"><label>Location</label><input name="location_text" maxlength="255" placeholder="Town, checkpoint or road"></div>
  <div class="form-grid"><div class="field"><label>Latitude</label><input name="latitude" type="number" inputmode="decimal" min="-90" max="90" step="0.000001" placeholder="-6.792354"></div><div class="field"><label>Longitude</label><input name="longitude" type="number" inputmode="decimal" min="-180" max="180" step="0.000001" placeholder="39.208328"></div></div>
  <div class="field"><label>Progress %</label><input name="progress_percent" type="number" min="0" max="100" step="0.01"></div>
  <div class="field"><label>Event time</label><input name="source_at" type="datetime-local" value="<?=h(date('Y-m-d\TH:i'))?>"></div>
  <div class="field"><label>Notes</label><textarea name="notes" maxlength="500"></textarea></div><button class="button">Save tracking update</button>
 </form>
 <form method="post" class="card"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="eta"><h2>Update ETA</h2>
  <div class="field"><label>Estimated arrival</label><input name="eta" type="datetime-local" required></div>
  <div class="field"><label>Reason</label><textarea name="reason" maxlength="500" placeholder="Reason for the ETA update"></textarea></div><button class="button">Update ETA</button>
 </form>
</div>
<?php endif;?>
<?php if($canCreateIncident):?>
<form method="post" class="card" style="margin-top:18px"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="create_incident"><h2>Report an exception</h2>
 <div class="form-grid">
  <div class="field"><label>Type</label><select name="exception_type"><option value="truck_breakdown">Truck breakdown</option><option value="driver_problem">Driver problem</option><option value="delay">Delay</option><option value="route_problem">Route problem</option><option value="delivery_problem">Delivery problem</option><option value="documentation_problem">Documentation problem</option><option value="other">Other</option></select></div>
  <div class="field"><label>Severity</label><select name="severity"><option>low</option><option selected>medium</option><option>high</option><option>critical</option></select></div>
  <div class="field"><label>Summary</label><input name="summary" maxlength="191" required></div><div class="field"><label>Location</label><input name="location_text" maxlength="255"></div>
 </div><div class="field"><label>Description</label><textarea name="description"></textarea></div><button class="button">Report exception</button>
</form>
<?php endif;?>
<?php if(Auth::can('ALERT_MANAGE_OPERATIONS')):?>
<form method="post" class="card" style="margin-top:18px"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="create_alert"><h2>Create operational alert</h2>
 <div class="form-grid"><div class="field"><label>Type</label><select name="alert_type"><option value="delay">Delay</option><option value="trip">Trip</option><option value="delivery">Delivery</option><option value="compliance">Compliance</option><option value="route">Route</option><option value="documentation">Documentation</option></select></div>
 <div class="field"><label>Severity</label><select name="severity"><option>low</option><option selected>medium</option><option>high</option><option>critical</option></select></div><div class="field"><label>Title</label><input name="title" maxlength="191" required></div></div>
 <div class="field"><label>Message</label><textarea name="message" maxlength="1000"></textarea></div><button class="button">Create alert</button>
</form>
<?php endif;?>
<div class="card table-wrap" style="margin-top:18px"><h2>Tracking history</h2><table><thead><tr><th>Time</th><th>Event</th><th>Location</th><th>Progress</th><th>Reported by</th><th>Notes</th></tr></thead><tbody>
<?php foreach($events as $event):?><tr><td><?=h($event['source_at'])?></td><td><?=h(str_replace('_',' ',$event['event_type']))?></td><td><?=h($event['location_text']?:trim(($event['latitude']??'').' '.($event['longitude']??'')))?></td><td><?=h($event['progress_percent']!==null?$event['progress_percent'].'%':'—')?></td><td><?=h($event['actor_name']?:'System')?></td><td><?=h($event['notes'])?></td></tr><?php endforeach;?>
<?php if(!$events):?><tr><td colspan="6" class="muted">No tracking updates.</td></tr><?php endif;?></tbody></table></div>
<div class="card" style="margin-top:18px"><h2>Alerts</h2>
<?php foreach($alerts as $alert):?><div class="card" style="margin-top:10px"><strong><?=h(strtoupper($alert['severity']).' · '.$alert['title'])?></strong><p><?=h($alert['message'])?></p><p><span class="status-pill status-<?=h($alert['alert_status'])?>"><?=h($alert['alert_status'])?></span> <strong><?=h(str_replace('_',' ',$alert['alert_type']))?></strong> · <time><?=h($alert['triggered_at'])?></time></p>
<?php if(Auth::can('ALERT_MANAGE_OPERATIONS')&&$alert['alert_status']!=='resolved'):?><form method="post"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="update_alert"><input type="hidden" name="alert_id" value="<?=h($alert['alert_id'])?>"><?php if($alert['alert_status']==='open'):?><button class="button" name="to" value="acknowledged">Acknowledge</button><?php endif;?><button class="button" name="to" value="resolved">Resolve</button></form><?php endif;?></div><?php endforeach;?>
<?php if(!$alerts):?><p class="muted">No alerts.</p><?php endif;?></div>
<div class="card" style="margin-top:18px"><h2>Exceptions</h2>
<?php foreach($incidents as $incident):?><div class="card" style="margin-top:10px"><strong><?=h(strtoupper($incident['severity']).' · '.$incident['summary'])?></strong><p><?=h($incident['description'])?></p><p><span class="status-pill status-<?=h($incident['incident_status'])?>"><?=h($incident['incident_status'])?></span> <strong><?=h(str_replace('_',' ',$incident['exception_type']))?></strong> · <time><?=h($incident['reported_at'])?></time> · <?=h($incident['reported_by_name']?:'System')?></p>
<?php foreach($incident['actions'] as $a):?><p class="muted"><?=h($a['action_at'].' — '.$a['actor_name'].' — '.$a['previous_status'].' → '.$a['new_status'].' — '.$a['action_note'])?></p><?php endforeach;?>
<?php if(Auth::can('EXCEPTION_MANAGE_OPERATIONS')&&$incident['incident_status']!=='resolved'):?><form method="post"><input type="hidden" name="_csrf" value="<?=h(Csrf::token())?>"><input type="hidden" name="action" value="update_incident"><input type="hidden" name="incident_id" value="<?=h($incident['incident_id'])?>"><div class="field"><label>Action note (required to resolve)</label><input name="note" maxlength="1000"></div><?php if($incident['incident_status']==='open'):?><button class="button" name="to" value="acknowledged">Acknowledge</button><?php endif;?><?php if(in_array($incident['incident_status'],['open','acknowledged'],true)):?><button class="button" name="to" value="investigating">Investigate</button><?php endif;?><button class="button" name="to" value="resolved">Resolve</button></form><?php endif;?></div><?php endforeach;?>
<?php if(!$incidents):?><p class="muted">No exceptions.</p><?php endif;?></div>
<?php require BASE_PATH.'/app/Views/layout/footer.php';?>