$fileloc = Read-Host "Enter file location:"
$raw = Get-Content $fileloc
foreach( $domain in $raw){

$domstatus = querypsa "select status from domains where name = '$domain'"
if ($domstatus -ne 0){
Write-Host "Status != 0 for $domain"
}
#Write-Host "Status for $domain is $domstatus"

}
