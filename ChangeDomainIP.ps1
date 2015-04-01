import-module gatorshell
import-module gatorcommands

$PleskPass=getpass-plesk
$mysqlPass=getpass-mysql

$websrvmng = $env:plesk_bin + "\websrvmng.exe"
$subscription = $env:plesk_bin + "\subscription.exe"


Function QueryPSA ($SQL) {
	Push-Location $Env:plesk_bin
	$return = .\dbclient.exe --direct-sql --sql="$SQL" | Where-Object {$_ -ne ""} |  foreach {$_.replace("`t", ",")} |  foreach {$_.substring(0,($_.length - 1))}
	Pop-Location
	if ($return -ne $null) { 
		if (@($return).count -ne 1) {
			$return = $return | Select-Object -Last ($return.length - 1) 
		}
		else { $return = $null }
	}
	$Return
}

Function HG-QueryPSA {
	param([string]$Query = (Read-Host "What query do you want to run?"))
	
	#Check    for user entry
	if ($Query.length -lt 10) {
		do {
			Write-Host "`nThe query you specified was blank. Please try again."
			$Query = Read-Host "What query do you want to run?"
		}
		until ( $Query.length -gt 9 )
	}
	
	#Check    for malicious sql
	$CheckFor = @("update", "delete", "drop")
	ForEach ($Item in $CheckFor) {
		if ($Item -eq $Query.substring(0,($Item.length))) {
			switch ($Item) {
				"update" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "where") {
						Write-Host "`n`nYou did not    include a WHERE argument in your UPDATE statement. Re-evaluate your statement and try again. `n`nExample: UPDATE domains SET status = 0 WHERE id = 123"
						return
					}
				}
				
				"delete" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "delete") {
						Write-Host "`n`nYou did not    include a WHERE argument in your DELETE statement. Re-evaluate your statement and try again. `n`nExample: DELETE FROM dns_recs WHERE dns_zone_id = 123"
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
	$return = .\dbclient.exe --direct-sql --sql="$Query" | Where-Object {$_ -ne ""} |    foreach {$_.replace("`t", ",")} |    foreach {$_.substring(0,($_.length - 1))}
	Pop-Location
	if ($return -ne $null) { 
		if (@($return).count -ne 1) {
			$return = $return | ConvertFrom-Csv
		}
		else { $return = $null }
	}
        $Return
}

Function HG-ChangeDomainIP {
  <#
  .SYNOPSIS
  Change the IP address for the Subscription and all subdomains
  .DESCRIPTION
  Change the IP address for the Subscription and all subdomains
  .EXAMPLE
  HG-ChangeDomainIP
  .EXAMPLE
  HG-ChangeDomainIP domain.com 127.0.0.1
  .PARAMETER Domain
  The domain name to update. 
  .PARAMETER IP
  The new IP address for the domain.
  #>
  [CmdletBinding()]
	param([string]$Dom = (Read-Host "What is the subscription's primary domain?"),
	[string]$IP = (Read-Host "What IP do you want it set on?"))
	Process{
        $CheckDomain=QueryPSA("select id from domains where name='$Dom';")
		If ($CheckDomain){
            $WebSpaceId = QueryPSA("SELECT webspace_id FROM domains WHERE name = '$Dom';")
            If ($webspaceid -ne 0){
                $domain2 = QueryPSA("SELECT name FROM domains WHERE id=$webspaceid")
                Write-error "$dom is a subdomain or addon for $domain2"
                return
                }
            
        } else {
			Throw "$($Dom) is not a valid name! It may be an alias or mistyped."
			}

		$ipObj = [System.Net.IPAddress]::parse($IP)
		$isValidIP = [System.Net.IPAddress]::tryparse([string]$IP, [ref]$ipObj)
		if ($isValidIP) {
            $allIPs=QueryPSA("select ip_address from ip_addresses;")
            If ($allIPs -NotContains $IP)
            {Throw "$IP not in Plesk"}

		   } else {
		      Throw "$IP is not valid"
			  }
        # All parameters are valid so New-stuff"
		$list = hg-querypsa ("select id, name from domains where WebSpace_Id=(select id from domains where name='$dom');")
		write-host "Changing the Subscript for $dom"
		write-host "subscription.exe -u $dom -ip $ip"
		start-process $subscription -ArgumentList "-u $dom -ip $ip" -NoNewWindow -wait
		
		
		write-host "Updating the IP for sub domains and addon domains"
		$ipAddressId = querypsa "select ipAddressId from IpAddressesCollections where ipCollectionID=(select ipCollectionID from DomainServices where type='web' and dom_id=(select id from domains where name='$dom'));"
		foreach ($name in $list){
			$dom_id=$name.id
			$dom_name=$name.name
		    write-host "Updating $dom_name"
			$ipCollectionID = querypsa "select ipCollectionID from DomainServices where type='web' and dom_id=$dom_id;"
			querypsa("update IpAddressesCollections set ipAddressId='$ipAddressId' where ipCollectionId='$ipCollectionID';")
			Write-host "Reconfiguring the web site for $dom_name"
			start-process $websrvmng -ArgumentList  "--reconfigure-vhost --vhost-name=$dom_name" -NoNewWindow -wait
			}
          Write-host "Reconfiguring the web site for $dom"
          start-process $websrvmng -ArgumentList  "--reconfigure-vhost --vhost-name=$dom" -NoNewWindow -wait
}
}

$domain_list = read-host 'Where is the list of domains?'
$new_ip = read-host 'What IP address would you like to set them on?'

$domain_list = Get-Content $domain_list

foreach ($domain in $domain_list){
HG-ChangeDomainIP $domain $new_ip
}