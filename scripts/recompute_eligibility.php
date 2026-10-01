<?php
declare(strict_types=1);
if(PHP_SAPI!=='cli'){http_response_code(404);exit("Not found.\n");}
require_once __DIR__.'/../bootstrap/app.php';
use App\Config\Env;
use App\Services\SubscriptionEligibilityService;
$host=strtolower((string)Env::get('DB_HOST','127.0.0.1'));
if(!in_array($host,['127.0.0.1','localhost','::1'],true)){fwrite(STDERR,"Refusing to run: DB_HOST must be local.\n");exit(1);}
try{$r=SubscriptionEligibilityService::recomputeAll();fwrite(STDOUT,"Eligibility processed: {$r['processed']}; failed: {$r['failed']}\n");exit($r['failed']?1:0);}catch(Throwable$e){fwrite(STDERR,'Eligibility failed: '.$e->getMessage()."\n");exit(1);}
