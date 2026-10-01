<?php
declare(strict_types=1);
namespace App\Services;
use App\Config\Database;
use App\Support\Reference;
use PDO;
use RuntimeException;

final class ReviewWorkflow
{
    private static function roleId(string $roleCode): int
    {
        foreach (Auth::context()['roles'] ?? [] as $role) {
            if ($role['role_code'] === $roleCode) return (int)$role['user_role_id'];
        }
        throw new RuntimeException('The required active role is not present.');
    }

    public static function queue(): array
    {
        if (!Auth::can('LOAD_REVIEW_QUEUE_VIEW') || !Auth::hasRole('MCCOLLIN_OPERATIONS')) throw new RuntimeException('Operations review access is required.');
        $sql="SELECT l.load_id,l.load_ref,l.cargo_summary,l.current_status,l.requested_pickup_from,l.updated_at,
          c.display_name company_name,oa.city origin_city,da.city destination_city,
          lv.version_no,lr.reviewer_user_id
          FROM loads l JOIN companies c ON c.company_id=l.customer_company_id
          JOIN addresses oa ON oa.address_id=l.origin_address_id JOIN addresses da ON da.address_id=l.destination_address_id
          JOIN load_versions lv ON lv.load_id=l.load_id AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id)
          LEFT JOIN load_reviews lr ON lr.load_version_id=lv.load_version_id
          WHERE l.status='active' AND l.current_status IN('submitted','under_review','clarification_required')
          ORDER BY FIELD(l.current_status,'submitted','under_review','clarification_required'),l.updated_at ASC";
        return Database::connection()->query($sql)->fetchAll();
    }

    public static function find(int $loadId): ?array
    {
        if (!Auth::can('LOAD_REVIEW_QUEUE_VIEW') || !Auth::hasRole('MCCOLLIN_OPERATIONS')) return null;
        $sql="SELECT l.*,c.display_name company_name,oa.line_1 origin_line_1,oa.city origin_city,oa.region origin_region,oa.country_code origin_country,
          da.line_1 destination_line_1,da.city destination_city,da.region destination_region,da.country_code destination_country,
          lv.load_version_id,lv.version_no,lv.status version_status,lv.snapshot_json,li.description item_description,li.quantity,li.unit_code,li.weight_value,li.weight_unit_code,
          lr.load_review_id,lr.review_status,lr.reviewer_user_id,lr.clarification_request,lr.started_at,lr.clarification_requested_at,lr.decision_code,lr.decision_reason,lr.decided_at
          FROM loads l JOIN companies c ON c.company_id=l.customer_company_id
          JOIN addresses oa ON oa.address_id=l.origin_address_id JOIN addresses da ON da.address_id=l.destination_address_id
          JOIN load_versions lv ON lv.load_id=l.load_id AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id)
          JOIN load_items li ON li.load_version_id=lv.load_version_id AND li.line_no=1
          LEFT JOIN load_reviews lr ON lr.load_version_id=lv.load_version_id
          WHERE l.load_id=? AND l.status='active' LIMIT 1";
        $st=Database::connection()->prepare($sql);$st->execute([$loadId]);$row=$st->fetch();return $row?:null;
    }

    public static function start(int $loadId,int $userId): void
    {
        if (!Auth::can('LOAD_REVIEW_START') || !Auth::hasRole('MCCOLLIN_OPERATIONS')) throw new RuntimeException('You do not have permission to start review.');
        $pdo=Database::connection();$pdo->beginTransaction();
        try {
            $st=$pdo->prepare("SELECT l.current_status,lv.load_version_id FROM loads l JOIN load_versions lv ON lv.load_id=l.load_id AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id) WHERE l.load_id=? AND l.status='active' FOR UPDATE");
            $st->execute([$loadId]);$load=$st->fetch();
            if(!$load||$load['current_status']!=='submitted') throw new RuntimeException('Only a submitted load may enter review.');
            $roleId=self::roleId('MCCOLLIN_OPERATIONS');
            $st=$pdo->prepare("UPDATE loads SET current_status='under_review',updated_by_user_id=?,row_version=row_version+1 WHERE load_id=? AND current_status='submitted'");$st->execute([$userId,$loadId]);
            if($st->rowCount()!==1) throw new RuntimeException('The load status changed. Refresh the queue.');
            $pdo->prepare("UPDATE load_versions SET status='under_review',updated_by_user_id=?,row_version=row_version+1 WHERE load_version_id=? AND status='submitted'")->execute([$userId,$load['load_version_id']]);
            $pdo->prepare("INSERT INTO load_reviews(load_review_ref,load_id,load_version_id,reviewer_user_id,reviewer_user_role_id,review_status,started_at,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,'under_review',UTC_TIMESTAMP(6),'active',?,?)")
                ->execute([Reference::make('LRV'),$loadId,$load['load_version_id'],$userId,$roleId,$userId,$userId]);
            self::history($pdo,$loadId,'submitted','under_review',$userId,$roleId,'Operations review started');
            self::audit($pdo,'LOAD_REVIEW_STARTED',$loadId,$userId,['load_version_id'=>(int)$load['load_version_id']]);
            $pdo->commit();
        } catch(\Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
    }

    public static function requestClarification(int $loadId,int $userId,string $request): void
    {
        if (!Auth::can('LOAD_REVIEW_REQUEST_CLARIFICATION') || !Auth::hasRole('MCCOLLIN_OPERATIONS')) throw new RuntimeException('You do not have permission to request clarification.');
        $request=trim($request);if(strlen($request)<10||strlen($request)>4000)throw new RuntimeException('Clarification request must be between 10 and 4000 characters.');
        $pdo=Database::connection();$pdo->beginTransaction();
        try {
            $st=$pdo->prepare("SELECT l.current_status,lv.load_version_id,lr.load_review_id,lr.reviewer_user_id FROM loads l JOIN load_versions lv ON lv.load_id=l.load_id AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id) JOIN load_reviews lr ON lr.load_version_id=lv.load_version_id WHERE l.load_id=? AND l.status='active' FOR UPDATE");
            $st->execute([$loadId]);$load=$st->fetch();
            if(!$load||$load['current_status']!=='under_review'||(int)$load['reviewer_user_id']!==$userId)throw new RuntimeException('Only the Operations Officer who started this active review may request clarification.');
            $roleId=self::roleId('MCCOLLIN_OPERATIONS');
            $pdo->prepare("UPDATE loads SET current_status='clarification_required',updated_by_user_id=?,row_version=row_version+1 WHERE load_id=? AND current_status='under_review'")->execute([$userId,$loadId]);
            $pdo->prepare("UPDATE load_versions SET status='clarification_required',updated_by_user_id=?,row_version=row_version+1 WHERE load_version_id=? AND status='under_review'")->execute([$userId,$load['load_version_id']]);
            $pdo->prepare("UPDATE load_reviews SET review_status='clarification_required',clarification_request=?,clarification_requested_at=UTC_TIMESTAMP(6),updated_by_user_id=?,row_version=row_version+1 WHERE load_review_id=? AND review_status='under_review'")->execute([$request,$userId,$load['load_review_id']]);
            self::history($pdo,$loadId,'under_review','clarification_required',$userId,$roleId,$request);
            self::audit($pdo,'LOAD_CLARIFICATION_REQUESTED',$loadId,$userId,['load_version_id'=>(int)$load['load_version_id']]);
            $pdo->commit();
        } catch(\Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
    }

    public static function decide(int $loadId,int $userId,string $decision,string $reason): void
    {
        $allowed=['approved','rejected'];
        if(!in_array($decision,$allowed,true)) throw new RuntimeException('Invalid review decision.');
        $permission=$decision==='approved'?'LOAD_REVIEW_APPROVE':'LOAD_REVIEW_REJECT';
        if(!Auth::can($permission)||!Auth::hasRole('MCCOLLIN_OPERATIONS')) throw new RuntimeException('You do not have permission for this review decision.');
        $reason=trim($reason);
        if($decision==='rejected'&&(strlen($reason)<10||strlen($reason)>4000)) throw new RuntimeException('Rejection reason must be between 10 and 4000 characters.');
        if($decision==='approved'&&strlen($reason)>2000) throw new RuntimeException('Approval note cannot exceed 2000 characters.');
        $pdo=Database::connection();$pdo->beginTransaction();
        try{
            $st=$pdo->prepare("SELECT l.current_status,lv.load_version_id,lr.load_review_id,lr.reviewer_user_id,lr.review_status FROM loads l JOIN load_versions lv ON lv.load_id=l.load_id AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id) JOIN load_reviews lr ON lr.load_version_id=lv.load_version_id WHERE l.load_id=? AND l.status='active' FOR UPDATE");
            $st->execute([$loadId]);$load=$st->fetch();
            if(!$load||$load['current_status']!=='under_review'||$load['review_status']!=='under_review') throw new RuntimeException('Only a load currently under review may receive a decision.');
            if((int)$load['reviewer_user_id']!==$userId) throw new RuntimeException('Only the Operations Officer responsible for this active review may decide it.');
            $roleId=self::roleId('MCCOLLIN_OPERATIONS');
            $st=$pdo->prepare("UPDATE loads SET current_status=?,updated_by_user_id=?,row_version=row_version+1 WHERE load_id=? AND current_status='under_review'");
            $st->execute([$decision,$userId,$loadId]);if($st->rowCount()!==1) throw new RuntimeException('The load status changed. Refresh before deciding.');
            $st=$pdo->prepare("UPDATE load_versions SET status=?,updated_by_user_id=?,row_version=row_version+1 WHERE load_version_id=? AND status='under_review'");
            $st->execute([$decision,$userId,$load['load_version_id']]);if($st->rowCount()!==1) throw new RuntimeException('The active load version changed.');
            $st=$pdo->prepare("UPDATE load_reviews SET review_status=?,decision_code=?,decision_reason=?,decided_by_user_id=?,decided_by_user_role_id=?,decided_at=UTC_TIMESTAMP(6),updated_by_user_id=?,row_version=row_version+1 WHERE load_review_id=? AND review_status='under_review'");
            $st->execute([$decision,$decision,$reason!==''?$reason:null,$userId,$roleId,$userId,$load['load_review_id']]);if($st->rowCount()!==1) throw new RuntimeException('The active review changed.');
            $historyReason=$decision==='approved'?'Load approved by McCollins Operations':'Load rejected by McCollins Operations: '.$reason;
            self::history($pdo,$loadId,'under_review',$decision,$userId,$roleId,$historyReason);
            self::audit($pdo,$decision==='approved'?'LOAD_REVIEW_APPROVED':'LOAD_REVIEW_REJECTED',$loadId,$userId,['load_version_id'=>(int)$load['load_version_id'],'decision_reason'=>$reason!==''?$reason:null]);
            $pdo->commit();
        }catch(\Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
    }

    private static function history(PDO $pdo,int $id,string $old,string $new,int $uid,int $roleId,string $reason):void
    {$pdo->prepare("INSERT INTO status_history(status_history_ref,entity_type,entity_id_value,previous_status,new_status,actor_user_id,actor_user_role_id,source_channel,reason,occurred_at,status,created_by_user_id) VALUES(?,'load',?,?,?,?,?,'web',?,UTC_TIMESTAMP(6),'active',?)")->execute([Reference::make('STH'),$id,$old,$new,$uid,$roleId,$reason,$uid]);}
    private static function audit(PDO $pdo,string $action,int $id,int $uid,array $extra=[]):void
    {$metadata=json_encode(array_merge(['action_code'=>$action,'entity_type'=>'load','entity_id'=>$id,'source'=>'web'],$extra),JSON_THROW_ON_ERROR);$pdo->prepare("INSERT INTO audit_events(audit_event_ref,metadata_json,status,created_by_user_id) VALUES(?,?,'active',?)")->execute([Reference::make('AUD'),$metadata,$uid]);}
}
