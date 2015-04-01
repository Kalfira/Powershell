$domain = $(Read-Host "Enter Domain to reset")
$newpass = $(Read-Host "Enter New password")
$domainid = querypsa "select id from domains where displayname = '$domain';"
querypsa "select id from accounts where id = any (select account_id from mail where dom_id='$domainid');" | foreach {querypsa "update accounts set password='$newpass' where id = $_;"}
Write-Host "PSA Updated, Starting mchk.exe now"
$mchk = $env:plesk_bin + "\mchk.exe"
$argue = "--domain --domain-name={0}" -f $domain
Start-Process $mchk -ArgumentList $argue -NoNewWindow -Wait;