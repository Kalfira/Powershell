$raw = querypsa "select login, account_id, db_id from db_users;"
foreach($line in $raw){
$user = $line.Split(",")[0]
$account_id = $line.Split(",")[1]
$db_id = $line.Split(",")[2]
$db = querypsa "select name from data_bases where id = $db_id;"
$pass = querypsa "select password from accounts where id = $account_id"
Write-Host "Database: $db User: $user Password: $pass"
}