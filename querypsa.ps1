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