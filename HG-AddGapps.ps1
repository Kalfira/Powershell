<#Function QueryPSA {
	param([string]$Query = (Read-Host "What query do you want to run?"))
	
	#Check  for user entry
	if ($Query.length -lt 10) {
		do {
			Write-Host "`nThe query you specified was blank. Please try again."
			$Query = Read-Host "What query do you want to run?"
		}
		until ( $Query.length -gt 9 )
	}
	
	#Check  for malicious sql
	$CheckFor = @("update", "delete", "drop")
	ForEach ($Item in $CheckFor) {
		if ($Item -eq $Query.substring(0,($Item.length))) {
			switch ($Item) {
				"update" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "where") {
						Write-Host "`n`nYou did not  include a WHERE argument in your UPDATE statement. Re-evaluate your statement and try again. `n`nExample: UPDATE domains SET status = 0 WHERE id = 123"
						return
					}
				}
				
				"delete" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "delete") {
						Write-Host "`n`nYou did not  include a WHERE argument in your DELETE statement. Re-evaluate your statement and try again. `n`nExample: DELETE FROM dns_recs WHERE dns_zone_id = 123"
						return
					}
				}
				
				"drop" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "drop") {
						Write-Host "`n`nAre you out of your mind??? You do not run DROP statements against the PSA!"
						return
					}
				}
			}
		}
	}
	
	#Query the PSA and parse the results
	Push-Location $Env:plesk_bin
	$return = .\dbclient.exe --direct-sql --sql="$Query" | Where-Object {$_ -ne ""} |  foreach {$_.replace("`t", ",")} |  foreach {$_.substring(0,($_.length - 1))}
	Pop-Location
	if ($return -ne $null) { 
		if (@($return).count -ne 1) {
			$return = $return | Select-Object -Last ($return.length - 1) 
		}
		else { $return = $null }
	}
	$Return
}#>

Function HG-AddGapps{
#param([string]$domain)
#if([string]::IsNullOrEmpty($domain)){
#$domain = $(Read-Host "Enter domain name")
#}
$domain = Read-Host "Enter domain name"
$dns_id = querypsa "select dns_zone_id from domains where name = '$domain'"
$dns_old = querypsa "select id from dns_recs where dns_zone_id = '$dns_id' AND type = 'MX';"
$time = querypsa "select time_stamp from dns_recs where dns_zone_id = '$dns_id' LIMIT 1;"
$displayHost = $domain+"."
foreach($rec in $dns_old){
querypsa "delete from dns_recs where id = '$rec';"
}
$lastval = querypsa "select id from dns_recs order by id desc limit 1;"
$lastval = [int]$lastval
$lastval++
querypsa "insert into dns_recs (id, dns_zone_id, type, host, displayHost, val, displayVal, opt, time_stamp) values ('$lastval', '$dns_id', 'MX', '$displayHost', '$displayHost', 'ASPMX.L.GOOGLE.COM', 'ASPMX.L.GOOGLE.COM', 0, '$time');"
$lastval++
querypsa "insert into dns_recs (id, dns_zone_id, type, host, displayHost, val, displayVal, opt, time_stamp) values ('$lastval', '$dns_id', 'MX', '$displayHost', '$displayHost', 'ALT1.ASPMX.L.GOOGLE.COM', 'ALT1.ASPMX.L.GOOGLE.COM', 5, '$time');"
$lastval++
querypsa "insert into dns_recs (id, dns_zone_id, type, host, displayHost, val, displayVal, opt, time_stamp) values ('$lastval', '$dns_id', 'MX', '$displayHost', '$displayHost', 'ALT2.ASPMX.L.GOOGLE.COM', 'ALT2.ASPMX.L.GOOGLE.COM', 5, '$time');"
$lastval++
querypsa "insert into dns_recs (id, dns_zone_id, type, host, displayHost, val, displayVal, opt, time_stamp) values ('$lastval', '$dns_id', 'MX', '$displayHost', '$displayHost', 'ALT3.ASPMX.L.GOOGLE.COM', 'ALT3.ASPMX.L.GOOGLE.COM', 10, '$time');"
$lastval++
querypsa "insert into dns_recs (id, dns_zone_id, type, host, displayHost, val, displayVal, opt, time_stamp) values ('$lastval', '$dns_id', 'MX', '$displayHost', '$displayHost', 'ALT4.ASPMX.L.GOOGLE.COM', 'ALT4.ASPMX.L.GOOGLE.COM', 10, '$time');"
Push-Location $env:plesk_bin
.\DNSMng.exe update $domain
Pop-Location
Write-Host "DONE!"
}

HG-AddGapps
