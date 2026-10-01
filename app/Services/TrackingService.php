<?php
declare(strict_types=1);

namespace App\Services;

use App\Config\Database;
use App\Support\Reference;
use PDO;
use RuntimeException;

final class TrackingService
{
    private const EVENT_TYPES = ['location_update','checkpoint_reached','delay_reported','route_update','delivery_update'];
    private const ALERT_TYPES = ['delay','trip','delivery','compliance','exception','route','documentation'];
    private const SEVERITIES = ['low','medium','high','critical'];
    private const EXCEPTION_TYPES = ['truck_breakdown','driver_problem','delay','route_problem','delivery_problem','documentation_problem','other'];

    private static function baseSql(): string
    {
        return "SELECT tr.*,sh.shipment_ref,sh.customer_company_id,sh.current_status shipment_status,
            l.load_ref,l.cargo_summary,oa.city origin_city,da.city destination_city,
            tk.registration_number,u.display_name driver_name,d.user_id driver_user_id,
            tls.location_text last_location,tls.latitude last_latitude,tls.longitude last_longitude,
            tls.progress_percent,tls.last_event_at,
            (SELECT eu.estimated_arrival_at FROM eta_updates eu WHERE eu.trip_id=tr.trip_id AND eu.status='active' ORDER BY eu.created_at DESC LIMIT 1) current_eta_at,
            (SELECT COUNT(*) FROM alerts al WHERE al.trip_id=tr.trip_id AND al.status='active' AND al.alert_status IN('open','acknowledged')) open_alerts,
            (SELECT COUNT(*) FROM incidents i WHERE i.trip_id=tr.trip_id AND i.status='active' AND i.incident_status<>'resolved') open_incidents
          FROM trips tr
          JOIN shipments sh ON sh.shipment_id=tr.shipment_id
          JOIN loads l ON l.load_id=sh.load_id
          JOIN addresses oa ON oa.address_id=tr.origin_address_id
          JOIN addresses da ON da.address_id=tr.destination_address_id
          JOIN trucks tk ON tk.truck_id=tr.truck_id
          JOIN drivers d ON d.driver_id=tr.driver_id
          JOIN users u ON u.user_id=d.user_id
          LEFT JOIN trip_location_summaries tls ON tls.trip_id=tr.trip_id AND tls.status='active'";
    }

    public static function operationsTrips(): array
    {
        if (!Auth::can('TRACKING_VIEW_OPERATIONS')) {
            throw new RuntimeException('Operations tracking permission required.');
        }
        return Database::connection()->query(self::baseSql()." ORDER BY tr.updated_at DESC")->fetchAll();
    }

    public static function findScoped(int $tripId, int $userId): ?array
    {
        $st=Database::connection()->prepare(self::baseSql()." WHERE tr.trip_id=? LIMIT 1");
        $st->execute([$tripId]);
        $trip=$st->fetch();
        if (!$trip || !self::canView($trip,$userId)) {
            return null;
        }
        return $trip;
    }

    private static function canView(array $trip, int $userId): bool
    {
        if (Auth::can('TRACKING_VIEW_OPERATIONS')) {
            return true;
        }
        if (Auth::can('TRACKING_VIEW_DRIVER') && (int)$trip['driver_user_id']===$userId) {
            return true;
        }
        if (Auth::can('TRACKING_VIEW_SHIPPER')) {
            foreach (Auth::context()['companies']??[] as $company) {
                if ((int)$company['company_id']===(int)$trip['customer_company_id']) {
                    return true;
                }
            }
        }
        if (Auth::can('TRACKING_VIEW_CARRIER')) {
            $carrier=CarrierOnboarding::current($userId);
            if ($carrier) {
                if ($carrier['owner_type']==='company' && (int)$trip['carrier_company_id']===(int)$carrier['subject_id']) {
                    return true;
                }
                if ($carrier['owner_type']==='individual' && (int)$trip['carrier_user_id']===$userId) {
                    return true;
                }
            }
        }
        return false;
    }

    private static function canUpdate(array $trip, int $userId): bool
    {
        return Auth::can('TRACKING_UPDATE_OPERATIONS')
            || (Auth::can('TRACKING_UPDATE_DRIVER') && (int)$trip['driver_user_id']===$userId);
    }

    private static function requireTrip(int $tripId, int $userId, bool $update=false): array
    {
        $trip=self::findScoped($tripId,$userId);
        if (!$trip || ($update && !self::canUpdate($trip,$userId))) {
            throw new RuntimeException('You are not authorized for this trip.');
        }
        return $trip;
    }

    public static function events(int $tripId): array
    {
        $st=Database::connection()->prepare(
            "SELECT te.*,u.display_name actor_name
             FROM tracking_events te LEFT JOIN users u ON u.user_id=te.actor_user_id
             WHERE te.trip_id=? AND te.status='active' ORDER BY te.source_at DESC,te.tracking_event_id DESC"
        );
        $st->execute([$tripId]);
        return $st->fetchAll();
    }

    public static function alerts(int $tripId): array
    {
        $st=Database::connection()->prepare(
            "SELECT al.*,u.display_name acknowledged_by_name
             FROM alerts al LEFT JOIN users u ON u.user_id=al.acknowledged_by_user_id
             WHERE al.trip_id=? AND al.status='active' ORDER BY al.triggered_at DESC,al.alert_id DESC"
        );
        $st->execute([$tripId]);
        return $st->fetchAll();
    }

    public static function incidents(int $tripId): array
    {
        $st=Database::connection()->prepare(
            "SELECT i.*,u.display_name reported_by_name
             FROM incidents i LEFT JOIN users u ON u.user_id=i.reported_by_user_id
             WHERE i.trip_id=? AND i.status='active' ORDER BY i.reported_at DESC,i.incident_id DESC"
        );
        $st->execute([$tripId]);
        $rows=$st->fetchAll();
        $actions=Database::connection()->prepare(
            "SELECT ia.*,u.display_name actor_name
             FROM incident_actions ia LEFT JOIN users u ON u.user_id=ia.actor_user_id
             WHERE ia.incident_id=? AND ia.status='active' ORDER BY ia.action_at,ia.incident_action_id"
        );
        foreach ($rows as &$row) {
            $actions->execute([$row['incident_id']]);
            $row['actions']=$actions->fetchAll();
        }
        unset($row);
        return $rows;
    }

    public static function recordTracking(int $tripId, array $data, int $userId): void
    {
        $trip=self::requireTrip($tripId,$userId,true);
        $type=(string)($data['event_type']??'location_update');
        if (!in_array($type,self::EVENT_TYPES,true)) {
            throw new RuntimeException('Invalid tracking event type.');
        }
        $location=trim((string)($data['location_text']??''));
        $lat=trim((string)($data['latitude']??''));
        $lng=trim((string)($data['longitude']??''));
        if ($location==='' && ($lat==='' || $lng==='')) {
            throw new RuntimeException('Enter a location description or both coordinates.');
        }
        if ($lat!=='' && (!is_numeric($lat) || (float)$lat < -90 || (float)$lat > 90)) {
            throw new RuntimeException('Latitude must be between -90 and 90.');
        }
        if ($lng!=='' && (!is_numeric($lng) || (float)$lng < -180 || (float)$lng > 180)) {
            throw new RuntimeException('Longitude must be between -180 and 180.');
        }
        $progress=trim((string)($data['progress_percent']??''));
        if ($progress!=='' && (!is_numeric($progress) || (float)$progress<0 || (float)$progress>100)) {
            throw new RuntimeException('Progress must be between 0 and 100.');
        }
        $sourceAt=self::dateValue((string)($data['source_at']??''),true);
        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            $sessionId=self::ensureSession($pdo,$trip,$userId);
            $ref=Reference::make('TRK');
            $idempotency=$ref.'-'.bin2hex(random_bytes(8));
            $st=$pdo->prepare(
                "INSERT INTO tracking_events(
                    tracking_event_ref,tracking_session_id,trip_id,device_tracker_id,event_type,milestone_code,
                    source_at,received_at,latitude,longitude,location_text,progress_percent,notes,actor_user_id,
                    source_channel,idempotency_key,status,created_by_user_id,updated_by_user_id
                 ) VALUES(?,?,?,NULL,?,?,?,UTC_TIMESTAMP(6),?,?,?,?,?,?,'web',?,'active',?,?)"
            );
            $milestone=$type==='checkpoint_reached'?'checkpoint_reached':null;
            $st->execute([
                $ref,$sessionId,$tripId,$type,$milestone,$sourceAt,
                $lat===''?null:(float)$lat,$lng===''?null:(float)$lng,$location===''?null:$location,
                $progress===''?null:(float)$progress,trim((string)($data['notes']??''))?:null,
                $userId,$idempotency,$userId,$userId
            ]);
            $eventId=(int)$pdo->lastInsertId();
            $pdo->prepare(
                "INSERT INTO trip_location_summaries(
                    trip_location_summarie_ref,trip_id,last_tracking_event_id,latitude,longitude,location_text,
                    progress_percent,last_event_at,status,created_by_user_id,updated_by_user_id
                 ) VALUES(?,?,?,?,?,?,?,?,'active',?,?)
                 ON DUPLICATE KEY UPDATE last_tracking_event_id=VALUES(last_tracking_event_id),
                    latitude=VALUES(latitude),longitude=VALUES(longitude),location_text=VALUES(location_text),
                    progress_percent=COALESCE(VALUES(progress_percent),progress_percent),
                    last_event_at=VALUES(last_event_at),updated_by_user_id=VALUES(updated_by_user_id),
                    row_version=row_version+1"
            )->execute([
                Reference::make('TLS'),$tripId,$eventId,$lat===''?null:(float)$lat,$lng===''?null:(float)$lng,
                $location===''?null:$location,$progress===''?null:(float)$progress,$sourceAt,$userId,$userId
            ]);
            if ($milestone) {
                self::milestone($pdo,(int)$trip['shipment_id'],$tripId,$milestone,$userId,['tracking_event_id'=>$eventId]);
            }
            if ($type==='delay_reported') {
                self::insertAlert($pdo,$tripId,(int)$trip['shipment_id'],null,'delay','high','Delay reported',
                    trim((string)($data['notes']??''))?:'A delay was reported during tracking.',$userId);
            }
            self::audit($pdo,'TRACKING_EVENT_RECORDED',$tripId,$userId,['tracking_event_id'=>$eventId,'event_type'=>$type]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    public static function updateEta(int $tripId, string $eta, string $reason, int $userId): void
    {
        $trip=self::requireTrip($tripId,$userId,true);
        $newEta=self::dateValue($eta,false);
        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            $st=$pdo->prepare("SELECT estimated_arrival_at FROM eta_updates WHERE trip_id=? AND status='active' ORDER BY created_at DESC LIMIT 1");
            $st->execute([$tripId]);
            $old=$st->fetchColumn()?:$trip['planned_arrival_at'];
            $pdo->prepare(
                "INSERT INTO eta_updates(eta_update_ref,trip_id,shipment_id,previous_eta_at,estimated_arrival_at,reason,source_type,actor_user_id,status,created_by_user_id,updated_by_user_id)
                 VALUES(?,?,?,?,?,?,'manual',?,'active',?,?)"
            )->execute([Reference::make('ETA'),$tripId,$trip['shipment_id'],$old,$newEta,trim($reason)?:null,$userId,$userId,$userId]);
            if (strtotime($newEta)>strtotime((string)$trip['planned_arrival_at'])) {
                self::insertAlert($pdo,$tripId,(int)$trip['shipment_id'],null,'delay','high','Estimated arrival delayed',
                    'The latest ETA is later than the planned arrival. '.(trim($reason)?:''),$userId);
            }
            self::audit($pdo,'TRIP_ETA_UPDATED',$tripId,$userId,['previous_eta_at'=>$old,'estimated_arrival_at'=>$newEta]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    public static function createAlert(int $tripId, array $data, int $userId): void
    {
        if (!Auth::can('ALERT_MANAGE_OPERATIONS')) {
            throw new RuntimeException('Operations alert permission required.');
        }
        $trip=self::requireTrip($tripId,$userId);
        $type=(string)($data['alert_type']??'operational');
        $severity=(string)($data['severity']??'medium');
        $title=trim((string)($data['title']??''));
        if (!in_array($type,self::ALERT_TYPES,true) || !in_array($severity,self::SEVERITIES,true) || $title==='') {
            throw new RuntimeException('Alert type, severity and title are required.');
        }
        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            self::insertAlert($pdo,$tripId,(int)$trip['shipment_id'],null,$type,$severity,$title,trim((string)($data['message']??'')),$userId);
            self::audit($pdo,'TRIP_ALERT_CREATED',$tripId,$userId,['alert_type'=>$type,'severity'=>$severity]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    public static function updateAlert(int $tripId, int $alertId, string $to, int $userId): void
    {
        if (!Auth::can('ALERT_MANAGE_OPERATIONS') || !in_array($to,['acknowledged','resolved'],true)) {
            throw new RuntimeException('Operations alert permission required.');
        }
        self::requireTrip($tripId,$userId);
        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            $st=$pdo->prepare("SELECT * FROM alerts WHERE alert_id=? AND trip_id=? AND status='active' FOR UPDATE");
            $st->execute([$alertId,$tripId]);
            $alert=$st->fetch();
            $allowed=['open'=>['acknowledged','resolved'],'acknowledged'=>['resolved']];
            if (!$alert || !in_array($to,$allowed[$alert['alert_status']]??[],true)) {
                throw new RuntimeException('Invalid alert transition.');
            }
            $extra=$to==='acknowledged'
                ? ",acknowledged_at=UTC_TIMESTAMP(6),acknowledged_by_user_id=".(int)$userId
                : ",resolved_at=UTC_TIMESTAMP(6),resolved_by_user_id=".(int)$userId;
            $pdo->exec("UPDATE alerts SET alert_status=".$pdo->quote($to).$extra.",updated_by_user_id=".(int)$userId.",row_version=row_version+1 WHERE alert_id=".(int)$alertId);
            self::history($pdo,'alert',$alertId,$alert['alert_status'],$to,$userId,'Alert status updated');
            self::audit($pdo,'TRIP_ALERT_UPDATED',$tripId,$userId,['alert_id'=>$alertId,'to'=>$to]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    public static function createIncident(int $tripId, array $data, int $userId): void
    {
        $trip=self::requireTrip($tripId,$userId);
        $isOperations=Auth::can('EXCEPTION_MANAGE_OPERATIONS');
        $isDriver=Auth::can('EXCEPTION_CREATE_DRIVER') && (int)$trip['driver_user_id']===$userId;
        if (!$isOperations && !$isDriver) {
            throw new RuntimeException('You cannot report an exception for this trip.');
        }
        $type=(string)($data['exception_type']??'other');
        $severity=(string)($data['severity']??'medium');
        $summary=trim((string)($data['summary']??''));
        if (!in_array($type,self::EXCEPTION_TYPES,true) || !in_array($severity,self::SEVERITIES,true) || $summary==='') {
            throw new RuntimeException('Exception type, severity and summary are required.');
        }
        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                "INSERT INTO incidents(incident_ref,trip_id,shipment_id,exception_type,severity,summary,description,location_text,incident_status,reported_at,reported_by_user_id,status,created_by_user_id,updated_by_user_id)
                 VALUES(?,?,?,?,?,?,?,?, 'open',UTC_TIMESTAMP(6),?,'active',?,?)"
            )->execute([
                Reference::make('INC'),$tripId,$trip['shipment_id'],$type,$severity,$summary,
                trim((string)($data['description']??''))?:null,trim((string)($data['location_text']??''))?:null,
                $userId,$userId,$userId
            ]);
            $incidentId=(int)$pdo->lastInsertId();
            self::incidentAction($pdo,$incidentId,'created',null,'open','Exception reported',$userId);
            self::insertAlert($pdo,$tripId,(int)$trip['shipment_id'],$incidentId,'exception',$severity,
                'Exception: '.$summary,trim((string)($data['description']??'')),$userId);
            self::history($pdo,'incident',$incidentId,null,'open',$userId,'Exception reported');
            self::audit($pdo,'TRIP_EXCEPTION_CREATED',$tripId,$userId,['incident_id'=>$incidentId,'exception_type'=>$type]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    public static function updateIncident(int $tripId, int $incidentId, string $to, string $note, int $userId): void
    {
        if (!Auth::can('EXCEPTION_MANAGE_OPERATIONS')) {
            throw new RuntimeException('Operations exception permission required.');
        }
        self::requireTrip($tripId,$userId);
        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            $st=$pdo->prepare("SELECT * FROM incidents WHERE incident_id=? AND trip_id=? AND status='active' FOR UPDATE");
            $st->execute([$incidentId,$tripId]);
            $incident=$st->fetch();
            $allowed=[
                'open'=>['acknowledged','investigating','resolved'],
                'acknowledged'=>['investigating','resolved'],
                'investigating'=>['resolved']
            ];
            if (!$incident || !in_array($to,$allowed[$incident['incident_status']]??[],true)) {
                throw new RuntimeException('Invalid exception transition.');
            }
            if ($to==='resolved' && trim($note)==='') {
                throw new RuntimeException('A resolution note is required.');
            }
            $extra=$to==='resolved'
                ? ",resolved_at=UTC_TIMESTAMP(6),resolved_by_user_id=".(int)$userId.",resolution_note=".$pdo->quote(trim($note))
                : '';
            $pdo->exec("UPDATE incidents SET incident_status=".$pdo->quote($to).$extra.",updated_by_user_id=".(int)$userId.",row_version=row_version+1 WHERE incident_id=".(int)$incidentId);
            self::incidentAction($pdo,$incidentId,$to==='resolved'?'resolved':'status_change',$incident['incident_status'],$to,trim($note)?:'Status updated',$userId);
            self::history($pdo,'incident',$incidentId,$incident['incident_status'],$to,$userId,trim($note)?:'Exception status updated');
            if ($to==='resolved') {
                $pdo->prepare("UPDATE alerts SET alert_status='resolved',resolved_at=UTC_TIMESTAMP(6),resolved_by_user_id=?,updated_by_user_id=?,row_version=row_version+1 WHERE incident_id=? AND alert_status<>'resolved'")->execute([$userId,$userId,$incidentId]);
            }
            self::audit($pdo,'TRIP_EXCEPTION_UPDATED',$tripId,$userId,['incident_id'=>$incidentId,'to'=>$to]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }
    }

    private static function ensureSession(PDO $pdo, array $trip, int $userId): int
    {
        $st=$pdo->prepare("SELECT tracking_session_id FROM tracking_sessions WHERE trip_id=? LIMIT 1 FOR UPDATE");
        $st->execute([$trip['trip_id']]);
        $id=$st->fetchColumn();
        if ($id) return (int)$id;
        $pdo->prepare(
            "INSERT INTO tracking_sessions(tracking_session_ref,trip_id,shipment_id,started_at,source_type,session_status,status,created_by_user_id,updated_by_user_id)
             VALUES(?,?,?,UTC_TIMESTAMP(6),'manual','active','active',?,?)"
        )->execute([Reference::make('TRS'),$trip['trip_id'],$trip['shipment_id'],$userId,$userId]);
        return (int)$pdo->lastInsertId();
    }

    private static function insertAlert(PDO $pdo, int $tripId, int $shipmentId, ?int $incidentId, string $type, string $severity, string $title, string $message, int $userId): int
    {
        $pdo->prepare(
            "INSERT INTO alerts(alert_ref,trip_id,shipment_id,incident_id,alert_type,severity,title,message,alert_status,triggered_at,status,created_by_user_id,updated_by_user_id)
             VALUES(?,?,?,?,?,?,?,?,'open',UTC_TIMESTAMP(6),'active',?,?)"
        )->execute([Reference::make('ALT'),$tripId,$shipmentId,$incidentId,$type,$severity,$title,$message?:null,$userId,$userId]);
        return (int)$pdo->lastInsertId();
    }

    private static function incidentAction(PDO $pdo, int $incidentId, string $type, ?string $from, string $to, string $note, int $userId): void
    {
        $pdo->prepare(
            "INSERT INTO incident_actions(incident_action_ref,incident_id,action_type,previous_status,new_status,action_note,action_at,actor_user_id,status,created_by_user_id,updated_by_user_id)
             VALUES(?,?,?,?,?,?,UTC_TIMESTAMP(6),?,'active',?,?)"
        )->execute([Reference::make('INA'),$incidentId,$type,$from,$to,$note,$userId,$userId,$userId]);
    }

    private static function milestone(PDO $pdo, int $shipmentId, int $tripId, string $code, int $userId, array $metadata): void
    {
        $pdo->prepare(
            "INSERT INTO shipment_milestones(shipment_milestone_ref,shipment_id,trip_id,milestone_code,occurred_at,actor_user_id,metadata_json,status,created_by_user_id,updated_by_user_id)
             VALUES(?,?,?,?,UTC_TIMESTAMP(6),?,?,'active',?,?)"
        )->execute([Reference::make('MIL'),$shipmentId,$tripId,$code,$userId,json_encode($metadata),$userId,$userId]);
    }

    private static function history(PDO $pdo, string $entity, int $id, ?string $from, string $to, int $userId, string $reason): void
    {
        $roleId=null;
        foreach (Auth::context()['roles']??[] as $role) {
            if (in_array($role['role_code'],['MCCOLLIN_OPERATIONS','DRIVER'],true)) {
                $roleId=(int)$role['user_role_id']; break;
            }
        }
        $pdo->prepare(
            "INSERT INTO status_history(status_history_ref,entity_type,entity_id_value,previous_status,new_status,actor_user_id,actor_user_role_id,source_channel,reason,occurred_at,status,created_by_user_id)
             VALUES(?,?,?,?,?,?,?,'web',?,UTC_TIMESTAMP(6),'active',?)"
        )->execute([Reference::make('STH'),$entity,$id,$from,$to,$userId,$roleId,$reason,$userId]);
    }

    private static function audit(PDO $pdo, string $action, int $tripId, int $userId, array $metadata): void
    {
        $pdo->prepare("INSERT INTO audit_events(audit_event_ref,metadata_json,status,created_by_user_id) VALUES(?,?,'active',?)")
            ->execute([Reference::make('AUD'),json_encode(array_merge(['action_code'=>$action,'trip_id'=>$tripId],$metadata)),$userId]);
    }

    private static function dateValue(string $value, bool $defaultNow): string
    {
        $timestamp=strtotime($value);
        if (!$timestamp && $defaultNow) $timestamp=time();
        if (!$timestamp) throw new RuntimeException('Enter a valid date and time.');
        return gmdate('Y-m-d H:i:s',$timestamp);
    }
}