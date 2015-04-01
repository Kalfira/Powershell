Function HG-GetDBLogin {

param(
	[string]$dbuser = $(Read-Host "DB user pattern (eg. username_% )")
	)
$account_ids = QueryPSA "select account_id , login, db_id from db_users where login LIKE '$dbuser';"
Write-Host "Database     Login     Password:"
foreach ($id in $account_ids){
$uid = $id.Split(",")[0]
$password = QueryPSA "select password from accounts where id = '$uid';"
$decrypt = Decrypt-Password $password
$login = $id.Split(",")[1]
$db = $id.Split(",")[2]
$database = QueryPSA "select name from data_bases where id = $db;"
Write-Host $database $login $decrypt
}
}