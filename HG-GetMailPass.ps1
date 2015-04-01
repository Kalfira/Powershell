$initdomain = Read-Host "What domain would you like the email accounts for?"
$domid = querypsa "select id from domains where name like '$initdomain'"
$account_id = querypsa "select account_id from mail where dom_id = '$domid';"
foreach ($account in $account_id){
$login = QueryPSA "select * from accounts where id = $account"
$user = QueryPSA "select mail_name from mail where account_id = $account"
$domain = QueryPSA "select DisplayName from domains where id = (select dom_id from mail where account_id = $account)"
$password = Decrypt-Password $login.Split(",")[2]
$variable = "$user@$domain $password"
Write-Output $variable}