<?php
declare(strict_types=1);
namespace App\Services;
use App\Config\Database;
use App\Support\Reference;
use RuntimeException;
final class CompanyOnboarding {
 public static function current(int $userId):?array{
  $st=Database::connection()->prepare("SELECT c.*,ct.type_code,ct.type_name FROM company_members cm JOIN companies c ON c.company_id=cm.company_id LEFT JOIN company_type_links ctl ON ctl.company_id=c.company_id AND ctl.status='active' AND ctl.is_primary=1 LEFT JOIN company_types ct ON ct.company_type_id=ctl.company_type_id WHERE cm.user_id=? AND cm.status='active' AND c.status='active' ORDER BY cm.company_member_id LIMIT 1");$st->execute([$userId]);$row=$st->fetch();return $row?:null;
 }
 public static function createForShipper(int $userId,array $data):int{
  if(!Auth::hasRole('SHIPPER')||!Auth::can('COMPANY_CREATE_OWN'))throw new RuntimeException('You do not have permission to create a company profile.');
  $legal=trim((string)($data['legal_name']??''));$display=trim((string)($data['display_name']??''));$reg=trim((string)($data['registration_number']??''));$country=strtoupper(trim((string)($data['registration_country']??'')));$line1=trim((string)($data['line_1']??''));$city=trim((string)($data['city']??''));$region=trim((string)($data['region']??''));
  if($legal===''||$display===''||$line1===''||!preg_match('/^[A-Z]{2}$/',$country))throw new RuntimeException('Legal name, display name, address line 1, and a two-letter country code are required.');
  if(strlen($legal)>191||strlen($display)>191||strlen($reg)>96||strlen($line1)>191||strlen($city)>120||strlen($region)>120)throw new RuntimeException('One or more fields exceed the permitted length.');
  $pdo=Database::connection();$pdo->beginTransaction();
  try{
   $st=$pdo->prepare("SELECT COUNT(*) FROM company_members WHERE user_id=? AND status='active' AND (effective_to IS NULL OR effective_to>UTC_TIMESTAMP(6))");$st->execute([$userId]);if((int)$st->fetchColumn()>0)throw new RuntimeException('Your account already has an active company membership.');
   if($reg!==''){$st=$pdo->prepare("SELECT COUNT(*) FROM companies WHERE registration_number=? AND registration_country=? AND status='active'");$st->execute([$reg,$country]);if((int)$st->fetchColumn()>0)throw new RuntimeException('A company with that registration number and country already exists.');}
   $st=$pdo->prepare("SELECT company_type_id FROM company_types WHERE type_code='CUSTOMER' AND status='active' LIMIT 1");$st->execute();$typeId=$st->fetchColumn();if(!$typeId)throw new RuntimeException('The approved Customer / Shipper company type is not configured.');
   $companyRef=Reference::make('CMP');$st=$pdo->prepare("INSERT INTO companies(company_ref,legal_name,display_name,registration_number,registration_country,preferred_locale,verification_status,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,'en','pending','active',?,?)");$st->execute([$companyRef,$legal,$display,$reg!==''?$reg:null,$country,$userId,$userId]);$companyId=(int)$pdo->lastInsertId();
   $pdo->prepare("INSERT INTO company_type_links(company_type_link_ref,company_id,company_type_id,is_primary,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,1,'active',?,?)")->execute([Reference::make('CTL'),$companyId,$typeId,$userId,$userId]);
   $pdo->prepare("INSERT INTO company_members(company_member_ref,company_id,user_id,member_title,effective_from,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,'Company profile creator',UTC_TIMESTAMP(6),'active',?,?)")->execute([Reference::make('CMB'),$companyId,$userId,$userId,$userId]);
   $addressRef=Reference::make('ADR');$pdo->prepare("INSERT INTO addresses(address_ref,line_1,line_2,city,region,postal_code,country_code,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,?,?,?,?,'active',?,?)")->execute([$addressRef,$line1,trim((string)($data['line_2']??''))?:null,$city?:null,$region?:null,trim((string)($data['postal_code']??''))?:null,$country,$userId,$userId]);$addressId=(int)$pdo->lastInsertId();
   $pdo->prepare("INSERT INTO address_links(address_link_ref,address_id,company_id,address_role,status,created_by_user_id,updated_by_user_id) VALUES(?,?,?,'registered', 'active',?,?)")->execute([Reference::make('ADL'),$addressId,$companyId,$userId,$userId]);
   $pdo->prepare("UPDATE user_roles ur JOIN roles r ON r.role_id=ur.role_id SET ur.company_id=?,ur.updated_by_user_id=?,ur.updated_at=UTC_TIMESTAMP(6),ur.row_version=ur.row_version+1 WHERE ur.user_id=? AND ur.status='active' AND ur.company_id IS NULL AND r.role_code='SHIPPER'")->execute([$companyId,$userId,$userId]);
   $pdo->prepare("INSERT INTO verification_cases(verification_case_ref,case_type,company_id,status,created_by_user_id,updated_by_user_id) VALUES(?,'company_onboarding',?,'draft',?,?)")->execute([Reference::make('VER'),$companyId,$userId,$userId]);
   $st=$pdo->prepare("SELECT ur.user_role_id FROM user_roles ur JOIN roles r ON r.role_id=ur.role_id WHERE ur.user_id=? AND r.role_code='SHIPPER' AND ur.status='active' LIMIT 1");$st->execute([$userId]);$userRoleId=$st->fetchColumn()?:null;
   $pdo->prepare("INSERT INTO status_history(status_history_ref,entity_type,entity_id_value,previous_status,new_status,actor_user_id,actor_user_role_id,source_channel,reason,occurred_at,status,created_by_user_id) VALUES(?,'company',?,NULL,'pending',?,?, 'web','Company profile submitted for verification',UTC_TIMESTAMP(6),'active',?)")->execute([Reference::make('STH'),$companyId,$userId,$userRoleId,$userId]);
   $metadata=json_encode(['action_code'=>'COMPANY_PROFILE_CREATED','entity_type'=>'company','entity_id'=>$companyId,'result'=>'success','source'=>'web'],JSON_THROW_ON_ERROR);
   $pdo->prepare("INSERT INTO audit_events(audit_event_ref,metadata_json,status,created_by_user_id) VALUES(?,?,'active',?)")->execute([Reference::make('AUD'),$metadata,$userId]);
   $pdo->commit();Auth::refreshContext();return $companyId;
  }catch(\Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
 }
}
