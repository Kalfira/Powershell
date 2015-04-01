$stats = Read-Host "What setting would you like all domain stats on the server as? (none|webalizer|awstats|smarterstats)"
$domains1 = Read-Host "Where is the target list?"
$domains = Get-Content $domains1
$subscription = $env:plesk_bin + "\subscription.exe"
foreach ($domain in $domains){

$arguement = "--update {0} -webstat {1}" -f $domain,$stats
Start-Process $subscription -ArgumentList $arguement -NoNewWindow -Wait -Verbose
}
