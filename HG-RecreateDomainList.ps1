$domainlist = Get-ChildItem C:\SmarterMail\Domains | Select-Object Name
$length = $domainlist.Length
foreach( $domain in $domainlist){
$temp = $domain.Name
$domain1 = "`"$temp`""
$domain2 = "`"c:\SmarterMail\Domains\$temp`""
$string= "<Domain name=$domain1 directory=$domain2 />"
$string >> C:\Scripts\domainList.txt
}
Write-Host "Domains list exported to C:\Scripts\domainList.txt"