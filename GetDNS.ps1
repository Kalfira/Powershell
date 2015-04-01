$domainlist = querypsa "select displayname from domains;"
foreach($domain in $domainlist){
$address = $domain+"."
$record = querypsa "select val from dns_recs where dns_zone_id = (select dns_zone_id from domains where displayname = '$domain') and host= '$address' and type = 'A';"
Add-Content C:\Scripts\dns.txt $domain"  "$record
}