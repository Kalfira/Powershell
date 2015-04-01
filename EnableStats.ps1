$sourcepath = "C:\inetpub\vhosts\"
$domain_list = dir $sourcepath | ? {$_.name -match "[^.].*[.].*" -and $_.name -notmatch "^hgtran.*"}

foreach ($domain in $domain_list) {

$sub = $env:plesk_bin + "\subscription.exe"
$argue0 = "--update {0} -webstat awstats" -f $domain

Write-Host "
Enabling AWStats for $domain
 " -foregroundcolor "yellow"
Start-Process $sub -ArgumentList $argue0 -NoNewWindow -Wait
}

Write-Host "
****DONE****
" -foregroundcolor "green"