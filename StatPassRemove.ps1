$sourcepath = "C:\inetpub\vhosts\"
$domain_list = dir $sourcepath | ? {$_.name -match "[^.].*[.].*" -and $_.name -notmatch "^hgtran.*"}

foreach ($domain in $domain_list) {

$ProtDir = $env:plesk_cli + "\protdir.exe"
$argue0 = "--remove plesk-stat -domain {0}" -f $domain

Write-Host "
Removing Stats Password Protection for $domain
 " -foregroundcolor "yellow"
Start-Process $ProtDir -ArgumentList $argue0 -NoNewWindow -Wait
}

Write-Host "
****DONE****
" -foregroundcolor "green"