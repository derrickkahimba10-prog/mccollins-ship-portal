<?php
declare(strict_types=1);
require_once __DIR__.'/../../bootstrap/app.php';
use App\Services\Auth;
use App\Services\TrackingService;
use App\Support\Url;
Auth::requirePermission('TRACKING_VIEW_OPERATIONS');
$rows=TrackingService::operationsTrips();
$pageTitle='Operations Monitoring';
require BASE_PATH.'/app/Views/layout/header.php';
?>
<div class="page-head"><div><h1>Operations monitoring</h1><p>Current trip position, progress, alerts, delays and exceptions.</p></div><span class="badge">Phase 9</span></div>
<div class="card table-wrap"><table>
<thead><tr><th>Trip / Shipment</th><th>Route</th><th>Last position</th><th>Progress</th><th>ETA</th><th>Alerts</th><th>Exceptions</th><th></th></tr></thead>
<tbody>
<?php foreach($rows as $r): ?><tr>
<td><?=h($r['trip_ref'])?><br><span class="muted"><?=h($r['shipment_ref'])?></span><br><span class="status-pill status-<?=h($r['current_status'])?>"><?=h(str_replace('_',' ',$r['current_status']))?></span></td>
<td><?=h($r['origin_city'].' → '.$r['destination_city'])?></td>
<td><?=h($r['last_location']?:'No update')?><br><time><?=h($r['last_event_at']?:'')?></time></td>
<td><?=h($r['progress_percent']!==null?$r['progress_percent'].'%':'—')?></td>
<td><?=h($r['current_eta_at']?:$r['planned_arrival_at'])?></td>
<td><?=h($r['open_alerts'])?></td><td><?=h($r['open_incidents'])?></td>
<td><a href="<?=h(Url::to('tracking/view.php?id='.$r['trip_id']))?>">Monitor</a></td>
</tr><?php endforeach; ?>
<?php if(!$rows): ?><tr><td colspan="8" class="muted">No trips are available for monitoring.</td></tr><?php endif; ?>
</tbody></table></div>
<?php require BASE_PATH.'/app/Views/layout/footer.php'; ?>