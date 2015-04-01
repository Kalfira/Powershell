function Get-RandomPassword {
	$length = 13
	$characters = 'abcdefghkmnprstuvwxyzABCDEFGHKLMNPRSTUVWXYZ123456789!%&/=?*+#_'
	# select random characters
	$random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
	# output random pwd
	$private:ofs=""
	$pw = [String]$characters[$random]
	while (($pw -notmatch '\W') -and ($pw -notmatch '[A-Z]') -and ($pw -notmatch '[a-z]') -and ($pw -notmatch '\d'))
	{
		$random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
		$pw = [String]$characters[$random]
	}
	$pw
}

Function QueryPSA {
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
}

$domains = querypsa "select name from domains"
$processed = @()
$dbinary = $env:plesk_cli + "\domain.exe"
$cbinary = $env:plesk_cli + "\customer.exe"
$sbinary = $env:plesk_cli + "\ftpsubaccount.exe"
$subaccounts = querypsa "SELECT domains.name, sys_users.login FROM ftp_users, sys_users, domains, clients where ftp_users.sys_user_id = sys_users.id and ftp_users.dom_id = domains.id and clients.id = domains.cl_id;"
foreach($domain in $domains)
{
	$clid = querypsa "select cl_id from domains where name = '$domain';"
	$client = querypsa "select login from clients where id = '$clid';"
	$pass = Get-RandomPassword

	if ($processed -notcontains $client)
	{
		Write-Host "Updating client information for $client"
		$argue = "-u {0} -passwd {1}" -f $client, $pass
		Start-Process $cbinary -ArgumentList $argue -NoNewWindow -Wait;
		if($client.Length -gt 15)
		{
			$short = $client.substring(0,15)
			Write-Host "Updating primary FTP login for $short on $domain"
			$argue = "-u {0} -login {1} -passwd {2}" -f $domain, $short, $pass
			Start-Process $dbinary -ArgumentList $argue -NoNewWindow -Wait;
			"Login for $domain is $client / $pass" | Out-File C:\scripts\results.txt -Append
			"Login for $domain is too long for FTP. Truncated user is $short / $pass" | Out-File C:\scripts\results.txt -Append
		}
		else
		{
			Write-Host "Updating primary FTP login for $client on $domain"
			$argue = "-u {0} -login {1} -passwd {2}" -f $domain, $client, $pass
			Start-Process $dbinary -ArgumentList $argue -NoNewWindow -Wait;
			"Login for $domain is $client / $pass" | Out-File C:\scripts\results.txt -Append

		}
		$processed += $client
		if ($subaccounts -match $domain)
		{
			$subs = $subaccounts -match $domain
			foreach($item in $subs)
			{
				$pass = Get-RandomPassword
				$subuser = $item.Split(",")[1]
				Write-Host "Updating secondary FTP login for $subuser on $domain"
				$argue = "-u {0} -passwd {1} -domain {2}" -f $subuser, $pass, $domain
				Start-Process $sbinary -ArgumentList $argue -NoNewWindow -Wait;
				"Subaccount for $domain is $subuser / $pass" | Out-File C:\scripts\results.txt -Append
			}
		}
	}
	else
	{
		Write-Host "Skipping $client for $domain because it has already been processed"
	}

}
