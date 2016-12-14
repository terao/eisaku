<?php
     
// Usage:
// 1. create API Key permit Billing infomation
// 2. create 'sacloudapi_config.php' file
// 3. run following command
//   $ ./sacloud_get_all_billdateails.php
//   finished, then Check following file.
//   $ less "bill-".$member_code."-".$account_code.".csv"

////////////////////////////////////////////////////////////////////////////
// API Key Setting
// // set API Tocken
// $token = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxxx";
// // set API Secret
// $secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
require('sacloudapi_config.php');


// set API URL
$url_auth_status = curl_init("https://secure.sakura.ad.jp/cloud/zone/tk1a/api/cloud/1.1/auth-status");

//curl_setopt($url_auth_status, CURLOPT_POST, TRUE);
//curl_setopt($curl, CURLOPT_POSTFIELDS, $POST_DATA ); 
curl_setopt($url_auth_status, CURLOPT_HTTPGET, TRUE);
curl_setopt($url_auth_status, CURLOPT_HTTPAUTH, CURLAUTH_BASIC ) ; 
curl_setopt($url_auth_status, CURLOPT_USERPWD, "$token:$secret");
curl_setopt($url_auth_status, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
//curl_setopt($url_auth_status, CURLOPT_SSL_VERIFYPEER, false);
//curl_setopt($url_auth_status, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($url_auth_status, CURLOPT_RETURNTRANSFER, true);
curl_setopt($url_auth_status, CURLOPT_USERAGENT, "get_bill_all.php");

// API Request
$response = curl_exec($url_auth_status);
// Request result
$header = curl_getinfo($url_auth_status);
// APIのHTTPコードをチェック
$code = $header["http_code"];
if ($code >= 400) { // もしエラーなら
  header("HTTP", true, $code);
  echo "API Error: $code";   // APIのエラー表示
  exit(1);
}
$response = mb_convert_encoding($response, 'UTF8', 'ASCII,JIS,UTF-8,EUC-JP,SJIS-WIN');

$auth_status = json_decode($response,true);

$account_id = $auth_status["Account"]["ID"];
$account_code = $auth_status["Account"]["Code"];
$member_code = $auth_status["Member"]["Code"];

curl_close($url_auth_status);


#-------------------------------------


// set API URL
$url_bill_by_contract = curl_init("https://secure.sakura.ad.jp/cloud/zone/tk1a/api/system/1.0/bill/by-contract/$account_id");

//curl_setopt($url_bill_by_contract, CURLOPT_POST, TRUE);
//curl_setopt($url_bill_by_contract, CURLOPT_POSTFIELDS, $POST_DATA ); 
curl_setopt($url_bill_by_contract, CURLOPT_HTTPGET, TRUE);
curl_setopt($url_bill_by_contract, CURLOPT_HTTPAUTH, CURLAUTH_BASIC ) ; 
curl_setopt($url_bill_by_contract, CURLOPT_USERPWD, "$token:$secret");
curl_setopt($url_bill_by_contract, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
//curl_setopt($url_auth_status, CURLOPT_SSL_VERIFYPEER, false);
//curl_setopt($url_auth_status, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($url_bill_by_contract, CURLOPT_RETURNTRANSFER, true);
curl_setopt($url_bill_by_contract, CURLOPT_USERAGENT, "get_bill_all.php");

// API Request
$response = curl_exec($url_bill_by_contract);

$header = curl_getinfo($url_bill_by_contract);
// APIのHTTPコードをチェック
$code = $header["http_code"];
if ($code >= 400) { // もしエラーなら
  header("HTTP", true, $code);
  echo $res;   // APIのエラー表示
  exit(1);
}
$response = mb_convert_encoding($response, 'UTF8', 'ASCII,JIS,UTF-8,EUC-JP,SJIS-WIN');

$bill_by_contract = json_decode($response,true);

curl_close($url_bill_by_contract);



#-------------------------------------

// loop for each billID
foreach ( $bill_by_contract["Bills"] as $key => $value ){
    sleep( 1 );
    
    // set API URL
    $url_billdetail = curl_init("https://secure.sakura.ad.jp/cloud/zone/tk1a/api/system/1.0/billdetail/".$member_code."/".$value["BillID"]."/csv?%7B%22_save_log%22%3A1%7D");
    
    //curl_setopt($url_billdetail, CURLOPT_POST, TRUE);
    //curl_setopt($url_billdetail, CURLOPT_POSTFIELDS, $POST_DATA ); 
    curl_setopt($url_billdetail, CURLOPT_HTTPGET, TRUE);
    curl_setopt($url_billdetail, CURLOPT_HTTPAUTH, CURLAUTH_BASIC ) ; 
    curl_setopt($url_billdetail, CURLOPT_USERPWD, "$token:$secret");
    curl_setopt($url_billdetail, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
    //curl_setopt($url_billdetail, CURLOPT_SSL_VERIFYPEER, false);
    //curl_setopt($url_billdetail, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($url_billdetail, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($url_billdetail, CURLOPT_USERAGENT, "get_bill_all.php");
    
    // API Request
    $response = curl_exec($url_billdetail);
    // Request result
    $header = curl_getinfo($url_billdetail);
    // APIのHTTPコードをチェック
    $code = $header["http_code"];
    if ($code >= 400) { // もしエラーなら
      header("HTTP", true, $code);
      echo $res;   // APIのエラー表示
      exit(1);
    }
    $response = mb_convert_encoding($response, 'UTF8', 'ASCII,JIS,UTF-8,EUC-JP,SJIS-WIN');

    $billdetail = json_decode($response,true);    
    printf( substr( $billdetail["Body"], 3) );
    $billdetail_csv = substr( sprintf($billdetail["Body"]) , 3);

    // Write to csv file    
    file_put_contents("bill-".$member_code."-".$account_code.".csv", $billdetail_csv, FILE_APPEND | LOCK_EX );
    curl_close($url_billdetail);

}
?>