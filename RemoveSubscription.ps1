$loc = Read-Host "Domain list location"
$cont = Get-Content $loc
$subscription = $env:plesk_bin + "\subscription.exe"
foreach ($domain in $cont){
$arguement = "--remove {0}" -f $domain
Start-Process $subscription -ArgumentList $arguement -NoNewWindow -Wait -Verbose

}