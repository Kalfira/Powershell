$domains = querypsa "select displayname from domains;"
foreach ( $domain in $domains){
$ip = [System.Net.Dns]::GetHostAddresses("argcommunity.com") | Select -Exp IPAddressToString
Write-Host "$domain $ip"
}