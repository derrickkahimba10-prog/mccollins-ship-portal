<?php
declare(strict_types=1);
namespace App\Services;
use App\Config\Database;
use App\Security\Authorization;
use App\Support\Url;
use PDO;
use RuntimeException;
final class Auth {
 public static function attempt(string $email,string $password): bool {
  $pdo=Database::connection(); $email=strtolower(trim($email));
  $sql="SELECT u.user_id,u.display_name,u.account_status,uc.password_hash,uc.failed_attempts,uc.locked_until FROM users u JOIN contact_links cl ON cl.user_id=u.user_id AND cl.status='active' JOIN contacts c ON c.contact_id=cl.contact_id AND c.status='active' JOIN user_credentials uc ON uc.user_id=u.user_id WHERE c.channel='email' AND c.normalized_value=:email LIMIT 1";
  $st=$pdo->prepare($sql);$st->execute(['email'=>$email]);$u=$st->fetch();
  $locked=$u&&$u['locked_until']&&strtotime($u['locked_until'])>time();
  if(!$u||$u['account_status']!=='active'||$locked||!password_verify($password,$u['password_hash'])) { if($u&&!$locked){$pdo->prepare("UPDATE user_credentials SET failed_attempts=failed_attempts+1,locked_until=CASE WHEN failed_attempts+1>=5 THEN DATE_ADD(UTC_TIMESTAMP(6),INTERVAL 15 MINUTE) ELSE locked_until END WHERE user_id=?")->execute([$u['user_id']]);} return false; }
  $pdo->prepare('UPDATE user_credentials SET failed_attempts=0,locked_until=NULL WHERE user_id=?')->execute([$u['user_id']]);
  $pdo->prepare('UPDATE users SET last_login_at=UTC_TIMESTAMP(6) WHERE user_id=?')->execute([$u['user_id']]);
  session_regenerate_id(true);
  $_SESSION['user']=['id'=>(int)$u['user_id'],'name'=>$u['display_name'],'context'=>Authorization::load((int)$u['user_id'])];$_SESSION['login_at']=time();$_SESSION['last_activity']=time();
  return true;
 }
 public static function user(): ?array{return $_SESSION['user']??null;}
 public static function check():bool{if(!isset($_SESSION['user']['id']))return false;$now=time();$last=(int)($_SESSION['last_activity']??$now);$login=(int)($_SESSION['login_at']??$now);if($now-$last>1800||$now-$login>43200){self::logout();return false;}$_SESSION['last_activity']=$now;return true;}
 public static function context():array{return $_SESSION['user']['context']??[];}
 public static function refreshContext():void{if(self::check())$_SESSION['user']['context']=Authorization::load((int)$_SESSION['user']['id']);}
 public static function hasRole(string $role):bool{return in_array($role,self::context()['role_codes']??[],true);}
 public static function can(string $permission):bool{return Authorization::can(self::context(),$permission);}
 public static function requireLogin():void{if(!self::check()){header('Location: '.Url::to('auth/login.php'));exit;}}
 public static function requirePermission(string $permission):void{self::requireLogin();if(!self::can($permission)){http_response_code(403);exit('403 — You do not have permission to view this page.');}}
 public static function logout():void{$_SESSION=[];if(ini_get('session.use_cookies')){$p=session_get_cookie_params();setcookie(session_name(),'',time()-42000,$p['path'],$p['domain'],$p['secure'],$p['httponly']);}session_destroy();}
 public static function dashboardPath():string{$map=['MCCOLLIN_OPERATIONS'=>'dashboards/admin/operations.php','MCCOLLIN_FINANCE'=>'dashboards/admin/finance.php','COMPLIANCE_SUPPORT'=>'dashboards/admin/compliance.php','SYSTEM_ADMIN'=>'dashboards/admin/system.php','SHIPPER'=>'dashboards/customer/dashboard.php','CF_AGENCY'=>'dashboards/customer/cf-dashboard.php','TRUCK_OWNER'=>'dashboards/carrier/dashboard.php','DRIVER'=>'dashboards/driver/dashboard.php','FARMER_AMCOS'=>'dashboards/marketplace/seller-dashboard.php','BUYER'=>'dashboards/marketplace/buyer-dashboard.php','SUPPLIER'=>'dashboards/procurement/supplier-dashboard.php'];foreach($map as $role=>$path)if(self::hasRole($role))return Url::to($path);return Url::to('auth/pending.php');}
 public static function register(array $d):int{$pdo=Database::connection();$email=strtolower(trim((string)($d['email']??'')));$role=(string)($d['role']??'');$allowed=['SHIPPER','CF_AGENCY','TRUCK_OWNER','FARMER_AMCOS','BUYER','SUPPLIER'];if(!filter_var($email,FILTER_VALIDATE_EMAIL)||!in_array($role,$allowed,true)||strlen((string)($d['password']??''))<10)throw new RuntimeException('Invalid registration data. Password must have at least 10 characters.');$pdo->beginTransaction();try{$st=$pdo->prepare("SELECT COUNT(*) FROM contacts WHERE channel='email' AND normalized_value=?");$st->execute([$email]);if($st->fetchColumn())throw new RuntimeException('That email address is already registered.');$ref='USR-'.strtoupper(bin2hex(random_bytes(6)));$st=$pdo->prepare("INSERT INTO users(user_ref,auth_subject,display_name,preferred_locale,time_zone,account_status) VALUES(?, ?, ?, 'en','Africa/Nairobi','active')");$st->execute([$ref,'local:'.$email,trim((string)$d['name'])]);$uid=(int)$pdo->lastInsertId();$pdo->prepare('INSERT INTO user_credentials(user_id,password_hash) VALUES(?,?)')->execute([$uid,password_hash((string)$d['password'],PASSWORD_DEFAULT)]);$pdo->prepare("INSERT INTO contacts(contact_ref,channel,normalized_value,display_value,status) VALUES(?, 'email', ?, ?, 'active')")->execute(['CON-'.strtoupper(bin2hex(random_bytes(6))),$email,$email]);$cid=(int)$pdo->lastInsertId();$pdo->prepare("INSERT INTO contact_links(contact_link_ref,contact_id,user_id,contact_role,status) VALUES(?,?,?,'primary','active')")->execute(['CLN-'.strtoupper(bin2hex(random_bytes(6))),$cid,$uid]);$st=$pdo->prepare('SELECT role_id FROM roles WHERE role_code=? AND is_active=1');$st->execute([$role]);$rid=$st->fetchColumn();if(!$rid)throw new RuntimeException('Selected role is not configured.');$pdo->prepare("INSERT INTO user_roles(user_role_id,user_id,role_id,effective_from,status) VALUES(NULL,?,?,UTC_TIMESTAMP(6),'requested')")->execute([$uid,$rid]);$pdo->commit();return $uid;}catch(\Throwable $e){$pdo->rollBack();throw $e;}}
}
