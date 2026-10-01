<?php
declare(strict_types=1);
namespace App\Services;

use App\Config\Database;
use App\Support\Reference;
use PDO;
use RuntimeException;

final class MatchingService
{
    private static function requireOperations(string $permission): void
    {
        if (!Auth::hasRole('MCCOLLIN_OPERATIONS') || !Auth::can($permission)) {
            throw new RuntimeException('McCollins Operations matching permission is required.');
        }
    }

    private static function operationsRoleId(): int
    {
        foreach (Auth::context()['roles'] ?? [] as $role) {
            if ($role['role_code'] === 'MCCOLLIN_OPERATIONS') return (int)$role['user_role_id'];
        }
        throw new RuntimeException('An active Operations role is required.');
    }

    public static function queue(): array
    {
        self::requireOperations('MATCH_QUEUE_VIEW');
        $sql = "SELECT l.load_id,l.load_ref,l.cargo_summary,l.requested_pickup_from,l.requested_delivery_to,
                       c.display_name company_name,oa.city origin_city,da.city destination_city,
                       lv.load_version_id,lv.version_no,li.description item_description,li.quantity,li.unit_code,
                       SUM(m.status='active') candidate_count,
                       SUM(m.status='active' AND m.suitability_status='review_required') review_count,
                       SUM(m.status='active' AND m.suitability_status='unsuitable') unsuitable_count,
                       MAX(CASE WHEN m.status='active' THEN m.generated_at END) last_generated_at
                FROM loads l
                JOIN companies c ON c.company_id=l.customer_company_id
                JOIN addresses oa ON oa.address_id=l.origin_address_id
                JOIN addresses da ON da.address_id=l.destination_address_id
                JOIN load_versions lv ON lv.load_id=l.load_id
                  AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id)
                JOIN load_items li ON li.load_version_id=lv.load_version_id AND li.line_no=1
                LEFT JOIN matches m ON m.load_version_id=lv.load_version_id
                WHERE l.status='active' AND l.current_status='approved' AND lv.status='approved'
                GROUP BY l.load_id,l.load_ref,l.cargo_summary,l.requested_pickup_from,l.requested_delivery_to,
                         c.display_name,oa.city,da.city,lv.load_version_id,lv.version_no,
                         li.description,li.quantity,li.unit_code
                ORDER BY l.requested_pickup_from IS NULL,l.requested_pickup_from,l.load_id";
        return Database::connection()->query($sql)->fetchAll();
    }

    public static function findLoad(int $loadId): ?array
    {
        self::requireOperations('MATCH_VIEW');
        $sql = "SELECT l.*,c.display_name company_name,
                       oa.line_1 origin_line_1,oa.city origin_city,oa.region origin_region,oa.country_code origin_country,
                       da.line_1 destination_line_1,da.city destination_city,da.region destination_region,da.country_code destination_country,
                       lv.load_version_id,lv.version_no,lv.status version_status,
                       li.description item_description,li.cargo_category_code,li.quantity,li.unit_code,
                       li.weight_value,li.weight_unit_code,li.volume_value,li.volume_unit_code,
                       li.packaging_details,li.handling_requirements
                FROM loads l
                JOIN companies c ON c.company_id=l.customer_company_id
                JOIN addresses oa ON oa.address_id=l.origin_address_id
                JOIN addresses da ON da.address_id=l.destination_address_id
                JOIN load_versions lv ON lv.load_id=l.load_id
                  AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id)
                JOIN load_items li ON li.load_version_id=lv.load_version_id AND li.line_no=1
                WHERE l.load_id=? AND l.status='active' AND l.current_status='approved' AND lv.status='approved'
                LIMIT 1";
        $statement=Database::connection()->prepare($sql);
        $statement->execute([$loadId]);
        $row=$statement->fetch();
        return $row ?: null;
    }

    public static function candidates(int $loadId): array
    {
        self::requireOperations('MATCH_VIEW');
        $load=self::findLoad($loadId);
        if (!$load) return [];
        $sql = "SELECT m.*,t.registration_number,t.make_name,t.model_name,t.body_type_code,t.capacity_value,t.capacity_unit,
                       du.display_name driver_name,cc.display_name carrier_company_name,cu.display_name carrier_user_name
                FROM matches m
                JOIN trucks t ON t.truck_id=m.truck_id
                JOIN drivers d ON d.driver_id=m.driver_id
                JOIN users du ON du.user_id=d.user_id
                LEFT JOIN eligibility_assessments ea ON ea.eligibility_assessment_id=m.eligibility_assessment_id
                LEFT JOIN companies cc ON cc.company_id=ea.carrier_company_id
                LEFT JOIN users cu ON cu.user_id=ea.carrier_user_id
                WHERE m.load_id=? AND m.load_version_id=? AND m.status='active'
                ORDER BY FIELD(m.suitability_status,'suitable','review_required','unsuitable'),t.registration_number";
        $statement=Database::connection()->prepare($sql);
        $statement->execute([$loadId,$load['load_version_id']]);
        $rows=$statement->fetchAll();
        $factorStatement=Database::connection()->prepare("SELECT factor_code,factor_result,required_value,actual_value,unit_code,reason FROM match_factors WHERE match_id=? AND status='active' ORDER BY match_factor_id");
        foreach ($rows as &$row) {
            $factorStatement->execute([$row['match_id']]);
            $row['factors']=$factorStatement->fetchAll();
        }
        unset($row);
        return $rows;
    }

    public static function generate(int $loadId,int $userId): array
    {
        self::requireOperations('MATCH_GENERATE');
        if ($userId!==(int)Auth::user()['id']) throw new RuntimeException('Invalid Operations actor context.');
        if (!self::findLoad($loadId)) throw new RuntimeException('Only an approved load may enter matching.');
        $refresh=SubscriptionEligibilityService::recomputeAll($userId);
        if (($refresh['failed'] ?? 0) > 0) {
            throw new RuntimeException('Eligibility refresh failed for one or more Carriers. Correct eligibility errors before generating candidates.');
        }

        $pdo=Database::connection();
        $pdo->beginTransaction();
        try {
            $sql = "SELECT l.load_id,l.current_status,lv.load_version_id,lv.status version_status,
                           li.quantity,li.unit_code,li.weight_value,li.weight_unit_code,li.volume_value,li.volume_unit_code
                    FROM loads l
                    JOIN load_versions lv ON lv.load_id=l.load_id
                      AND lv.version_no=(SELECT MAX(v.version_no) FROM load_versions v WHERE v.load_id=l.load_id)
                    JOIN load_items li ON li.load_version_id=lv.load_version_id AND li.line_no=1
                    WHERE l.load_id=? AND l.status='active' FOR UPDATE";
            $statement=$pdo->prepare($sql);
            $statement->execute([$loadId]);
            $load=$statement->fetch();
            if (!$load || $load['current_status']!=='approved' || $load['version_status']!=='approved') {
                throw new RuntimeException('Only the latest approved load version may enter matching.');
            }
            $statement=$pdo->prepare("SELECT COUNT(*) FROM bids_offers WHERE load_id=? AND offer_status IN('sent','countered','accepted') AND status='active'");
            $statement->execute([$loadId]);
            if((int)$statement->fetchColumn()>0)throw new RuntimeException('Matching cannot be regenerated while this load has open or accepted offers.');

            $pdo->prepare("UPDATE matches SET status='superseded',updated_by_user_id=?,updated_at=UTC_TIMESTAMP(6),row_version=row_version+1 WHERE load_version_id=? AND status='active'")
                ->execute([$userId,$load['load_version_id']]);

            $candidateSql = "SELECT ra.truck_id,ra.driver_id,ra.eligibility_assessment_id,
                                    t.registration_number,t.body_type_code,t.capacity_value,t.capacity_unit
                             FROM resource_availability ra
                             JOIN eligibility_assessments ea ON ea.eligibility_assessment_id=ra.eligibility_assessment_id
                               AND ea.assessment_result='eligible' AND ea.status='active'
                             JOIN trucks t ON t.truck_id=ra.truck_id
                               AND t.status='active' AND t.verification_status='verified' AND t.availability_status='available'
                             JOIN drivers d ON d.driver_id=ra.driver_id
                               AND d.status='active' AND d.verification_status='verified' AND d.availability_status='available'
                             JOIN driver_engagements de ON de.truck_id=t.truck_id AND de.driver_id=d.driver_id
                               AND de.status='active' AND de.engagement_status='active'
                             WHERE ra.status='active' AND ra.availability_status='available'
                               AND ea.eligibility_assessment_id=(SELECT MAX(x.eligibility_assessment_id) FROM eligibility_assessments x WHERE x.truck_id=ea.truck_id)
                             ORDER BY t.truck_id FOR UPDATE";
            $resources=$pdo->query($candidateSql)->fetchAll();
            $runRef=Reference::make('MGR');
            $counts=['generated'=>0,'review_required'=>0,'unsuitable'=>0];
            $insertMatch=$pdo->prepare("INSERT INTO matches(match_ref,load_id,load_version_id,truck_id,driver_id,eligibility_assessment_id,generated_run_ref,suitability_status,overall_reason,generated_by_user_id,generated_at,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,?,?,?,?,?,UTC_TIMESTAMP(6),'active',?,?)");
            $insertFactor=$pdo->prepare("INSERT INTO match_factors(match_factor_ref,match_id,factor_code,factor_result,required_value,actual_value,unit_code,reason,evaluated_at,metadata_json,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,?,?,?,UTC_TIMESTAMP(6),?,'active',?,?)");

            foreach ($resources as $resource) {
                $capacity=self::capacityFactor($load,$resource);
                $suitability=$capacity['result']==='fail'?'unsuitable':'review_required';
                $overall=$capacity['result']==='fail'
                    ? 'Eligible resource screened out because capacity is insufficient.'
                    : 'Eligible resource requires Operations review because approved body-type and live-location requirements are not yet captured.';
                $insertMatch->execute([
                    Reference::make('MAT'),$loadId,$load['load_version_id'],$resource['truck_id'],$resource['driver_id'],
                    $resource['eligibility_assessment_id'],$runRef,$suitability,$overall,$userId,$userId,$userId
                ]);
                $matchId=(int)$pdo->lastInsertId();
                $factors=[
                    ['ELIGIBILITY','pass',null,null,null,'Current Phase 6D eligibility assessment passed.'],
                    ['AVAILABILITY','pass',null,null,null,'Truck and Driver are currently available.'],
                    ['CAPACITY',$capacity['result'],$capacity['required'],$capacity['actual'],$capacity['unit'],$capacity['reason']],
                    ['BODY_TYPE','not_evaluated',null,null,null,'The approved load version has no explicit required truck body type.'],
                    ['LIVE_LOCATION','not_evaluated',null,null,null,'Current truck location is not captured in Phase 7A.']
                ];
                foreach ($factors as $factor) {
                    $insertFactor->execute([
                        Reference::make('MAF'),$matchId,$factor[0],$factor[1],$factor[2],$factor[3],$factor[4],$factor[5],
                        json_encode(['generation_run_ref'=>$runRef],JSON_THROW_ON_ERROR),$userId,$userId
                    ]);
                }
                $counts['generated']++;
                $counts[$suitability]++;
            }

            $roleId=self::operationsRoleId();
            self::history($pdo,$loadId,'approved','candidates_generated',$userId,$roleId,'Phase 7A candidate generation '.$runRef.' produced '.$counts['generated'].' eligible resource candidate(s).');
            self::audit($pdo,'MATCH_CANDIDATES_GENERATED',$loadId,$userId,[
                'load_version_id'=>(int)$load['load_version_id'],'generation_run_ref'=>$runRef,
                'candidate_count'=>$counts['generated'],'review_required'=>$counts['review_required'],'unsuitable'=>$counts['unsuitable']
            ]);
            $pdo->commit();
            $counts['run_ref']=$runRef;
            return $counts;
        } catch (\Throwable $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $exception;
        }
    }

    private static function capacityFactor(array $load,array $truck): array
    {
        $required=self::normalizeLoadCapacity($load);
        $actual=self::normalizeCapacity((float)$truck['capacity_value'],(string)$truck['capacity_unit']);
        if (!$required) return ['result'=>'not_evaluated','required'=>null,'actual'=>$actual['value']??null,'unit'=>$actual['unit']??null,'reason'=>'The approved load has no weight, volume, or quantity unit comparable to truck capacity.'];
        if (!$actual || $actual['unit']!==$required['unit']) return ['result'=>'not_evaluated','required'=>$required['value'],'actual'=>$actual['value']??null,'unit'=>$required['unit'],'reason'=>'Load requirement and truck capacity use different measurement dimensions.'];
        $pass=$actual['value'] >= $required['value'];
        return ['result'=>$pass?'pass':'fail','required'=>$required['value'],'actual'=>$actual['value'],'unit'=>$required['unit'],'reason'=>$pass?'Truck capacity meets the normalized load requirement.':'Truck capacity is below the normalized load requirement.'];
    }

    private static function normalizeLoadCapacity(array $load): ?array
    {
        if ($load['weight_value']!==null && (float)$load['weight_value']>0) {
            $normalized=self::normalizeCapacity((float)$load['weight_value'],(string)$load['weight_unit_code']);
            if ($normalized) return $normalized;
        }
        if ($load['volume_value']!==null && (float)$load['volume_value']>0) {
            $normalized=self::normalizeCapacity((float)$load['volume_value'],(string)$load['volume_unit_code']);
            if ($normalized) return $normalized;
        }
        if ($load['quantity']!==null && (float)$load['quantity']>0) {
            return self::normalizeCapacity((float)$load['quantity'],(string)$load['unit_code']);
        }
        return null;
    }

    private static function normalizeCapacity(float $value,string $unit): ?array
    {
        $unit=strtoupper(trim($unit));
        if (in_array($unit,['TONNE','TONNES','TON','T','MT'],true)) return ['value'=>round($value,3),'unit'=>'TONNE'];
        if (in_array($unit,['KG','KGS','KILOGRAM','KILOGRAMS'],true)) return ['value'=>round($value/1000,3),'unit'=>'TONNE'];
        if (in_array($unit,['M3','CBM','CUBIC_METRE','CUBIC_METRES'],true)) return ['value'=>round($value,3),'unit'=>'M3'];
        return null;
    }

    private static function history(PDO $pdo,int $loadId,string $old,string $new,int $userId,int $roleId,string $reason): void
    {
        $pdo->prepare("INSERT INTO status_history(status_history_ref,entity_type,entity_id_value,previous_status,new_status,actor_user_id,actor_user_role_id,source_channel,reason,occurred_at,status,created_by_user_id) VALUES(?,'load_matching',?,?,?,?,?,'web',?,UTC_TIMESTAMP(6),'active',?)")
            ->execute([Reference::make('STH'),$loadId,$old,$new,$userId,$roleId,$reason,$userId]);
    }

    private static function audit(PDO $pdo,string $action,int $loadId,int $userId,array $extra): void
    {
        $metadata=json_encode(array_merge(['action_code'=>$action,'entity_type'=>'load_matching','entity_id'=>$loadId,'source'=>'web'],$extra),JSON_THROW_ON_ERROR);
        $pdo->prepare("INSERT INTO audit_events(audit_event_ref,metadata_json,status,created_by_user_id) VALUES(?,?,'active',?)")
            ->execute([Reference::make('AUD'),$metadata,$userId]);
    }
}
