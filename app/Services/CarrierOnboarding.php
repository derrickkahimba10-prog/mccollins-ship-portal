<?php
declare(strict_types=1);
namespace App\Services;
use App\Config\Database;
use App\Support\Reference;
use PDO;
use RuntimeException;

final class CarrierOnboarding
{
 public static function requestedRole(int $userId): ?array
 {
  $st=Database::connection()->prepare("SELECT ur.user_role_id,ur.status FROM user_roles ur JOIN roles r ON r.role_id=ur.role_id WHERE ur.user_id=? AND r.role_code='TRUCK_OWNER' AND r.is_active=1 AND ur.status IN('requested','active') ORDER BY FIELD(ur.status,'active','requested') LIMIT 1");
  $st->execute([$userId]);$row=$st->fetch();return $row?:null;
 }
 public static function mayOnboard(int $userId): bool{return self::requestedRole($userId)!==null;}
 public static function current(int $userId): ?array
 {
  $pdo=Database::connection();
  $sql="SELECT 'individual' owner_type,p.truck_owner_profile_id subject_id,p.truck_owner_profile_ref subject_ref,u.display_name legal_name,u.display_name display_name,NULL registration_number,NULL registration_country,p.tin_number,p.business_license_number,p.business_license_expiry,p.insurance_provider,p.insurance_policy_number,p.insurance_expiry,p.verification_status,vc.verification_case_id,vc.status case_status,vc.findings
    FROM truck_owner_profiles p JOIN users u ON u.user_id=p.user_id
    LEFT JOIN verification_cases vc ON vc.user_id=p.user_id AND vc.case_type='carrier_onboarding_individual'
    WHERE p.user_id=? AND p.status='active' ORDER BY vc.verification_case_id DESC LIMIT 1";
  $st=$pdo->prepare($sql);$st->execute([$userId]);$row=$st->fetch();if($row)return$row;
  $sql="SELECT 'company' owner_type,c.company_id subject_id,c.company_ref subject_ref,c.legal_name,c.display_name,c.registration_number,c.registration_country,
    p.tin_number,p.business_license_number,p.business_license_expiry,p.insurance_provider,p.insurance_policy_number,p.insurance_expiry,
    c.verification_status,vc.verification_case_id,vc.status case_status,vc.findings
    FROM company_members cm JOIN companies c ON c.company_id=cm.company_id
    JOIN company_type_links ctl ON ctl.company_id=c.company_id AND ctl.status='active' AND ctl.is_primary=1
    JOIN company_types ct ON ct.company_type_id=ctl.company_type_id AND ct.type_code='TRUCK_OWNER'
    LEFT JOIN truck_owner_profiles p ON p.company_id=c.company_id AND p.status='active'
    LEFT JOIN verification_cases vc ON vc.company_id=c.company_id AND vc.case_type='carrier_onboarding_company'
    WHERE cm.user_id=? AND cm.status='active' AND c.status='active' ORDER BY vc.verification_case_id DESC LIMIT 1";
  $st=$pdo->prepare($sql);$st->execute([$userId]);$row=$st->fetch();return$row?:null;
 }
 private static function clean(array $d): array
 {
  $type=(string)($d['owner_type']??'');if(!in_array($type,['individual','company'],true))throw new RuntimeException('Choose individual or company carrier.');
  $country=strtoupper(trim((string)($d['registration_country']??'')));$line1=trim((string)($d['line_1']??''));
  if($line1===''||!preg_match('/^[A-Z]{2}$/',$country))throw new RuntimeException('Address line 1 and a two-letter country code are required.');
  $out=['owner_type'=>$type,'legal_name'=>trim((string)($d['legal_name']??'')),'display_name'=>trim((string)($d['display_name']??'')),'registration_number'=>trim((string)($d['registration_number']??'')),'country'=>$country,
   'tin'=>trim((string)($d['tin_number']??'')),'license'=>trim((string)($d['business_license_number']??'')),'license_expiry'=>self::date($d['business_license_expiry']??null),
   'insurer'=>trim((string)($d['insurance_provider']??'')),'policy'=>trim((string)($d['insurance_policy_number']??'')),'insurance_expiry'=>self::date($d['insurance_expiry']??null),
   'line1'=>$line1,'line2'=>trim((string)($d['line_2']??'')),'city'=>trim((string)($d['city']??'')),'region'=>trim((string)($d['region']??'')),'postal'=>trim((string)($d['postal_code']??''))];
  if($type==='company'&&($out['legal_name']===''||$out['display_name']===''||$out['registration_number']===''))throw new RuntimeException('Company legal name, display name, and registration number are required.');
  foreach(['tin','license','insurer','policy'] as $key)if($out[$key]==='')throw new RuntimeException('TIN, business licence, insurer, and policy number are required for verification.');
  $limits=['legal_name'=>191,'display_name'=>191,'registration_number'=>96,'tin'=>96,'license'=>96,'insurer'=>191,'policy'=>96,'line1'=>191,'line2'=>191,'city'=>120,'region'=>120,'postal'=>32];
  foreach($limits as$key=>$max)if(strlen($out[$key])>$max)throw new RuntimeException('One or more fields exceed the approved length.');return$out;
 }
 private static function date(mixed $value): ?string{$value=trim((string)$value);if($value==='')return null;$dt=\DateTimeImmutable::createFromFormat('!Y-m-d',$value,new \DateTimeZone('UTC'));if(!$dt||$dt->format('Y-m-d')!==$value)throw new RuntimeException('Enter valid expiry dates.');return$value;}
 public static function create(int $userId,array $data): int
 {
  $role=self::requestedRole($userId);if(!$role)throw new RuntimeException('A requested or active Truck Owner role is required.');if(self::current($userId))throw new RuntimeException('A carrier profile already exists for this account.');$d=self::clean($data);$pdo=Database::connection();$pdo->beginTransaction();
  try{
   $companyId=null;$profileId=null;
   if($d['owner_type']==='company'){
    $st=$pdo->prepare("SELECT COUNT(*) FROM companies WHERE registration_number=? AND registration_country=? AND status='active'");$st->execute([$d['registration_number'],$d['country']]);if((int)$st->fetchColumn()>0)throw new RuntimeException('That company registration already exists.');
    $st=$pdo->prepare("SELECT company_type_id FROM company_types WHERE type_code='TRUCK_OWNER' AND status='active' LIMIT 1");$st->execute();$typeId=$st->fetchColumn();if(!$typeId)throw new RuntimeException('Approved Truck Owner company type is missing.');
    $pdo->prepare("INSERT INTO companies(company_ref,legal_name,display_name,registration_number,registration_country,verification_status,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,'pending','active',?,?)")->execute([Reference::make('CMP'),$d['legal_name'],$d['display_name'],$d['registration_number'],$d['country'],$userId,$userId]);$companyId=(int)$pdo->lastInsertId();
    $pdo->prepare("INSERT INTO company_type_links(company_type_link_ref,company_id,company_type_id,is_primary,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,1,'active',?,?)")->execute([Reference::make('CTL'),$companyId,$typeId,$userId,$userId]);
    $pdo->prepare("INSERT INTO company_members(company_member_ref,company_id,user_id,member_title,effective_from,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,'Carrier profile owner',UTC_TIMESTAMP(6),'active',?,?)")->execute([Reference::make('CMB'),$companyId,$userId,$userId,$userId]);
    $meta=json_encode(['tin_number'=>$d['tin'],'business_license_number'=>$d['license'],'business_license_expiry'=>$d['license_expiry'],'insurance_provider'=>$d['insurer'],'insurance_policy_number'=>$d['policy'],'insurance_expiry'=>$d['insurance_expiry']],JSON_THROW_ON_ERROR);
    $pdo->prepare("INSERT INTO truck_owner_profiles(truck_owner_profile_ref,owner_type,company_id,tin_number,business_license_number,business_license_expiry,insurance_provider,insurance_policy_number,insurance_expiry,verification_status,metadata_json,status,created_by_user_id,updated_by_user_id) VALUES(?,'company',?,?,?,?,?,?,?,'pending',?,'active',?,?)")->execute([Reference::make('TOP'),$companyId,$d['tin'],$d['license'],$d['license_expiry'],$d['insurer'],$d['policy'],$d['insurance_expiry'],$meta,$userId,$userId]);$profileId=(int)$pdo->lastInsertId();
   }else{
    $meta=json_encode(['owner_type'=>'individual'],JSON_THROW_ON_ERROR);
    $pdo->prepare("INSERT INTO truck_owner_profiles(truck_owner_profile_ref,owner_type,user_id,tin_number,business_license_number,business_license_expiry,insurance_provider,insurance_policy_number,insurance_expiry,verification_status,metadata_json,status,created_by_user_id,updated_by_user_id) VALUES(?,'individual',?,?,?,?,?,?,?,'pending',?,'active',?,?)")->execute([Reference::make('TOP'),$userId,$d['tin'],$d['license'],$d['license_expiry'],$d['insurer'],$d['policy'],$d['insurance_expiry'],$meta,$userId,$userId]);$profileId=(int)$pdo->lastInsertId();
   }
   $pdo->prepare("INSERT INTO addresses(address_ref,line_1,line_2,city,region,postal_code,country_code,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,?,?,'active',?,?)")->execute([Reference::make('ADR'),$d['line1'],$d['line2']?:null,$d['city']?:null,$d['region']?:null,$d['postal']?:null,$d['country'],$userId,$userId]);$addressId=(int)$pdo->lastInsertId();
   $pdo->prepare("INSERT INTO address_links(address_link_ref,address_id,company_id,user_id,address_role,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?, 'registered','active',?,?)")->execute([Reference::make('ADL'),$addressId,$companyId,$companyId?null:$userId,$userId,$userId]);
   $caseType=$companyId?'carrier_onboarding_company':'carrier_onboarding_individual';$pdo->prepare("INSERT INTO verification_cases(verification_case_ref,case_type,user_id,company_id,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?, 'pending',?,?)")->execute([Reference::make('VER'),$caseType,$companyId?null:$userId,$companyId,$userId,$userId]);$caseId=(int)$pdo->lastInsertId();
   self::history($pdo,$caseId,null,'pending',$userId,(int)$role['user_role_id'],'Carrier onboarding submitted for Operations verification');self::audit($pdo,'CARRIER_ONBOARDING_SUBMITTED',$caseId,$userId,['owner_type'=>$d['owner_type'],'profile_id'=>$profileId,'company_id'=>$companyId]);
   $pdo->commit();return$caseId;
  }catch(\Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw$e;}
 }
 public static function queue(): array
 {
  self::requireOperations('CARRIER_REVIEW_QUEUE_VIEW');$sql="SELECT vc.verification_case_id,vc.verification_case_ref,vc.case_type,vc.status case_status,vc.created_at,u.display_name user_name,c.display_name company_name,p.verification_status,p.tin_number,p.business_license_number,p.insurance_expiry FROM verification_cases vc LEFT JOIN users u ON u.user_id=vc.user_id LEFT JOIN companies c ON c.company_id=vc.company_id LEFT JOIN truck_owner_profiles p ON (p.user_id=vc.user_id OR p.company_id=vc.company_id) AND p.status='active' WHERE vc.case_type IN('carrier_onboarding_individual','carrier_onboarding_company') AND vc.status='pending' ORDER BY vc.created_at";return Database::connection()->query($sql)->fetchAll();
 }
 public static function review(int $caseId): ?array
 {
  self::requireOperations('CARRIER_REVIEW_QUEUE_VIEW');$sql="SELECT vc.*,u.display_name user_name,u.user_id subject_user_id,c.legal_name,c.display_name company_name,c.registration_number,c.registration_country,p.truck_owner_profile_id,p.tin_number,p.business_license_number,p.business_license_expiry,p.insurance_provider,p.insurance_policy_number,p.insurance_expiry,p.verification_status FROM verification_cases vc LEFT JOIN users u ON u.user_id=vc.user_id LEFT JOIN companies c ON c.company_id=vc.company_id LEFT JOIN truck_owner_profiles p ON (p.user_id=vc.user_id OR p.company_id=vc.company_id) AND p.status='active' WHERE vc.verification_case_id=? AND vc.case_type IN('carrier_onboarding_individual','carrier_onboarding_company') LIMIT 1";$st=Database::connection()->prepare($sql);$st->execute([$caseId]);$row=$st->fetch();return$row?:null;
 }
 public static function decide(int $caseId,int $reviewerId,string $decision,string $reason): void
 {
  if(!in_array($decision,['approved','rejected'],true))throw new RuntimeException('Invalid carrier decision.');self::requireOperations($decision==='approved'?'CARRIER_REVIEW_APPROVE':'CARRIER_REVIEW_REJECT');$reason=trim($reason);if($decision==='rejected'&&(strlen($reason)<10||strlen($reason)>4000))throw new RuntimeException('Rejection reason must be 10 to 4000 characters.');if($decision==='approved'&&strlen($reason)>2000)throw new RuntimeException('Approval note cannot exceed 2000 characters.');
  $pdo=Database::connection();$pdo->beginTransaction();try{
   $st=$pdo->prepare("SELECT * FROM verification_cases WHERE verification_case_id=? AND case_type IN('carrier_onboarding_individual','carrier_onboarding_company') FOR UPDATE");$st->execute([$caseId]);$case=$st->fetch();if(!$case||$case['status']!=='pending')throw new RuntimeException('Only a pending carrier verification may be decided.');$roleId=self::operationsRoleId();
   if($case['company_id']){$st=$pdo->prepare("UPDATE companies SET verification_status=?,updated_by_user_id=?,row_version=row_version+1 WHERE company_id=? AND verification_status='pending'");$st->execute([$decision==='approved'?'verified':'rejected',$reviewerId,$case['company_id']]);if($st->rowCount()!==1)throw new RuntimeException('The carrier company verification state changed.');$st=$pdo->prepare("UPDATE truck_owner_profiles SET verification_status=?,updated_by_user_id=?,row_version=row_version+1 WHERE company_id=? AND status='active' AND verification_status='pending'");$st->execute([$decision==='approved'?'verified':'rejected',$reviewerId,$case['company_id']]);if($st->rowCount()!==1)throw new RuntimeException('The carrier profile verification state changed.');$st=$pdo->prepare("SELECT user_id FROM company_members WHERE company_id=? AND status='active' ORDER BY company_member_id LIMIT 1");$st->execute([$case['company_id']]);$carrierUserId=(int)$st->fetchColumn();if($carrierUserId<1)throw new RuntimeException('The carrier company owner could not be resolved.');}
   else{$st=$pdo->prepare("UPDATE truck_owner_profiles SET verification_status=?,updated_by_user_id=?,row_version=row_version+1 WHERE user_id=? AND status='active' AND verification_status='pending'");$st->execute([$decision==='approved'?'verified':'rejected',$reviewerId,$case['user_id']]);if($st->rowCount()!==1)throw new RuntimeException('The carrier profile verification state changed.');$carrierUserId=(int)$case['user_id'];}
   if($decision==='approved'){$st=$pdo->prepare("UPDATE user_roles ur JOIN roles r ON r.role_id=ur.role_id SET ur.status='active',ur.company_id=?,ur.updated_by_user_id=?,ur.updated_at=UTC_TIMESTAMP(6),ur.row_version=ur.row_version+1 WHERE ur.user_id=? AND r.role_code='TRUCK_OWNER' AND ur.status='requested'");$st->execute([$case['company_id']?:null,$reviewerId,$carrierUserId]);if($st->rowCount()!==1)throw new RuntimeException('The requested Truck Owner role could not be activated.');}
   $st=$pdo->prepare("UPDATE verification_cases SET assigned_reviewer_user_id=?,findings=?,status=?,updated_by_user_id=?,row_version=row_version+1 WHERE verification_case_id=? AND status='pending'");$st->execute([$reviewerId,$reason!==''?$reason:null,$decision,$reviewerId,$caseId]);if($st->rowCount()!==1)throw new RuntimeException('The carrier verification changed.');
   self::history($pdo,$caseId,'pending',$decision,$reviewerId,$roleId,$decision==='approved'?'Carrier verified and role activated':'Carrier verification rejected: '.$reason);self::audit($pdo,$decision==='approved'?'CARRIER_VERIFICATION_APPROVED':'CARRIER_VERIFICATION_REJECTED',$caseId,$reviewerId,['carrier_user_id'=>$carrierUserId,'company_id'=>$case['company_id']]);$pdo->commit();
  }catch(\Throwable$e){if($pdo->inTransaction())$pdo->rollBack();throw$e;}
 }
 private static function requireOperations(string $permission):void{if(!Auth::hasRole('MCCOLLIN_OPERATIONS')||!Auth::can($permission))throw new RuntimeException('Operations carrier-review permission is required.');}
 private static function operationsRoleId():int{foreach(Auth::context()['roles']??[]as$r)if($r['role_code']==='MCCOLLIN_OPERATIONS')return(int)$r['user_role_id'];throw new RuntimeException('Active Operations role is required.');}
 private static function history(PDO$pdo,int$id,?string$old,string$new,int$uid,?int$roleId,string$reason):void{$pdo->prepare("INSERT INTO status_history(status_history_ref,entity_type,entity_id_value,previous_status,new_status,actor_user_id,actor_user_role_id,source_channel,reason,occurred_at,status,created_by_user_id) VALUES(?,'carrier_verification',?,?,?,?,?,'web',?,UTC_TIMESTAMP(6),'active',?)")->execute([Reference::make('STH'),$id,$old,$new,$uid,$roleId,$reason,$uid]);}
 private static function audit(PDO$pdo,string$action,int$id,int$uid,array$extra=[]):void{$metadata=json_encode(array_merge(['action_code'=>$action,'entity_type'=>'carrier_verification','entity_id'=>$id,'source'=>'web'],$extra),JSON_THROW_ON_ERROR);$pdo->prepare("INSERT INTO audit_events(audit_event_ref,metadata_json,status,created_by_user_id) VALUES(?,?,'active',?)")->execute([Reference::make('AUD'),$metadata,$uid]);}
}
