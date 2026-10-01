<?php
declare(strict_types=1);
require_once __DIR__.'/../../bootstrap/app.php';

use App\Services\Auth;
use App\Services\DocumentEpodService;

Auth::requireLogin();
$document=DocumentEpodService::document((int)($_GET['id']??0),(int)Auth::user()['id']);
if(!$document){
    http_response_code(404);
    exit('Document not found.');
}
$base=realpath(BASE_PATH.'/storage/uploads/documents');
$path=realpath(BASE_PATH.'/'.$document['storage_object_key']);
if(!$base||!$path||!str_starts_with($path,$base.DIRECTORY_SEPARATOR)||!is_file($path)){
    http_response_code(404);
    exit('Stored file not found.');
}
$fileName=str_replace(['"',"\r","\n"],'',basename($document['original_file_name']));
header('Content-Type: '.$document['mime_type']);
header('Content-Length: '.filesize($path));
header('Content-Disposition: attachment; filename="'.$fileName.'"');
header('X-Content-Type-Options: nosniff');
readfile($path);
exit;