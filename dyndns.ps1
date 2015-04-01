#LOAD THE MSSQL SNAPIN############################################################################# 
$sqlSnapin = Get-PSSnapin | where {$_.Name -eq "SqlServerCmdletSnapin100"}
if($sqlSnapin -eq $null){ Add-PSSnapin SqlServerCmdletSnapin100 }


Function HG-SetDynDNS {

    <#
	.SYNOPSIS
	This cmdlet will add and update sites to the Dynamic DNS database and push all the relevant changes to the firewall
	
	.PARAMETER DomainName
	Accepts no input and will prompt the user for needed information. However you can pass arguments to expidite the process.
	
	.EXAMPLE
	HG-SetDynDNS domain.com mssql pleskdomain.com
	
	.EXAMPLE
    HG-SetDynDNS example.org mysql domaininbilling.com
    
	#>

param(
	[string]$domain = $(Read-Host "Enter Dynamic IP Target"), 
	[string]$rulename = $(Read-Host "Which Firewall Rule would you like to whitelist for? (MSSQL or MYSQL)"), 
	[string]$pleskdomain = $(Read-Host "Which domain is in Plesk?")
	)
	

# Get the IP, Query PSA for Plesk login, and determine which firewall rule this should go to	
$theip = [System.Net.Dns]::GetHostAddresses("$domain") | Select -Exp IPAddressToString
$pleskun = querypsa "select login from clients where id = (select cl_id from domains where displayname = '$pleskdomain');"

if ($rulename -match 'ms'){
	$table = 'mssql'
	$rulename = 'MSSQL Server'
	}
	else
	{
	$table = 'mysql'
	$rulename = 'MySQL Server'
	}

Write-Host "Username for $pleskdomain is $pleskun"
#Check to make sure domain actually exists
if ($theip -ne $null){
	$currentip = Invoke-Sqlcmd -query "select ip from $table where domain = '$domain'" -database "dyndns" | Select -Exp ip
	$exist = Invoke-Sqlcmd -query "select domain from $table where domain = '$domain'" -database "dyndns" | Select -Exp domain
	$formerips = netsh advfirewall firewall show rule name="$rulename" | where-object {$_ -match 'RemoteIP:'} | foreach-object{$_.Split(":")[1].Replace('RemoteIP:',$null).Trim()} | Get-Unique
	#Check if domain exists in DB
		if ($exist -eq $null){
			Invoke-Sqlcmd -query "Insert into $table values ('$domain', '$theip', '$pleskun')" -database "dyndns"
			Write-Host "$domain did not exist in database. Adding the domain and $theip to the database"

			#Check if IP exists in the firewall currently

			if ($formerips -match "$theip/32"){
				$newips = "$formerips,$theip/32"
				$exists = Invoke-Sqlcmd -query "select domain from $table where ip = '$theip'" -database "dyndns" | Select -Exp domain
				Write-Host "Exiting. $theip already exists in $rulename for $exists"
				}
				else{
					$newips = "$formerips,$theip/32"
					netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
					Write-Host "Added $theip to $rulename. Exiting"
					}
			}
	else{
		#Check if IP is current
		$currentip = Invoke-Sqlcmd -query "select ip from $table where domain = '$domain'" -database "dyndns" | Select -Exp ip
		write-host "Previous IP is $currentip"
		#Update IP in DB if it's not current
		if ($currentip -ne $theip){Invoke-Sqlcmd -query "update $table set ip='$theip' where domain = '$domain'" -database "dyndns"}
		$existselsewhere = Invoke-Sqlcmd -query "select ip from $table where ip = '$currentip'" -database "dyndns" | Select -Exp ip
		write-host "Current IP is $theip"
		#Update Firewall with current IP
		if ($formerips -match "$currentip/32,"){
			if ($null -match $existselsewhere) { $formerips = $formerips.Replace("$currentip/32,", "") }
			$newips = "$formerips,$theip/32"
			netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
			Write-Host "Added $theip to $rulename. Exiting"
			}
			elseif ($formerips -match "$currentip/32"){
				if ($null -match $existselsewhere) { $formerips = $formerips.Replace("$currentip/32,", "") }
				$newips = "$formerips,$theip/32"
				netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
				Write-Host "Added $theip to $rulename. Exiting"
				}
			else{
				$newips = "$formerips,$theip/32"
				netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
				Write-Host "Added $theip to $rulename. Exiting"
				}
		}
}
else{
	#If the domain does not return an IP this is the default fail
	Write-Host "$domain does not resolve to an IP so it could not be added. Please try again later"
	}
}