<?php
declare(strict_types=1);
// Local CLI only. This file is outside public/ and refuses web execution or non-local DB hosts.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit("Not found.\n"); }
require_once __DIR__.'/../bootstrap/app.php';
use App\Config\Database;
use App\Config\Env;
use App\Support\Reference;

$host=strtolower((string)Env::get('DB_HOST','127.0.0.1'));
if(!in_array($host,['127.0.0.1','localhost','::1'],true)){fwrite(STDERR,"Refusing to run: DB_HOST must be local.\n");exit(1);}
function ask(string $label):string{fwrite(STDOUT,$label);$v=fgets(STDIN);return trim($v===false?'':$v);}
$name=ask('Operations Officer full name: ');$email=strtolower(ask('Email: '));$password=ask('Temporary password (12+ characters): ');
if($name===''||!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($password)<12){fwrite(STDERR,"Invalid input. A name, valid email, and 12+ character password are required.\n");exit(1);}
$pdo=Database::connection();$pdo->beginTransaction();
try{
 $st=$pdo->prepare("SELECT COUNT(*) FROM contacts WHERE channel='email' AND normalized_value=?");$st->execute([$email]);if($st->fetchColumn())throw new RuntimeException('That email already exists.');
 $st=$pdo->prepare("SELECT role_id FROM roles WHERE role_code='MCCOLLIN_OPERATIONS' AND is_active=1");$st->execute();$roleId=$st->fetchColumn();if(!$roleId)throw new RuntimeException('MCCOLLIN_OPERATIONS role is not configured.');
 $pdo->prepare("INSERT INTO users(user_ref,auth_subject,display_name,preferred_locale,time_zone,account_status) VALUES(?, ?, ?, 'en','Africa/Nairobi','active')")->execute([Reference::make('USR'),'local:'.$email,$name]);$uid=(int)$pdo->lastInsertId();
 $pdo->prepare('INSERT INTO user_credentials(user_id,password_hash) VALUES(?,?)')->execute([$uid,password_hash($password,PASSWORD_DEFAULT)]);
 $pdo->prepare("INSERT INTO contacts(contact_ref,channel,normalized_value,display_value,status) VALUES(?,'email',?,?,'active')")->execute([Reference::make('CON'),$email,$email]);$cid=(int)$pdo->lastInsertId();
 $pdo->prepare("INSERT INTO contact_links(contact_link_ref,contact_id,user_id,contact_role,status) VALUES(?,?,?,'primary','active')")->execute([Reference::make('CLN'),$cid,$uid]);
 $pdo->prepare("INSERT INTO user_roles(user_id,role_id,company_id,effective_from,status) VALUES(?,?,NULL,UTC_TIMESTAMP(6),'active')")->execute([$uid,(int)$roleId]);
 $meta=json_encode(['action_code'=>'LOCAL_OPERATIONS_OFFICER_CREATED','entity_type'=>'user','entity_id'=>$uid,'source'=>'local_cli'],JSON_THROW_ON_ERROR);
 $pdo->prepare("INSERT INTO audit_events(audit_event_ref,metadata_json,status,created_by_user_id) VALUES(?,?,'active',?)")->execute([Reference::make('AUD'),$meta,$uid]);
 $pdo->commit();fwrite(STDOUT,"Operations Officer created. Delete terminal history if your shell records interactive input.\n");
}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();fwrite(STDERR,'Setup failed: '.$e->getMessage()."\n");exit(1);}
