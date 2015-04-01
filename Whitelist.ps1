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
	

# Get the IP, Query PSA for Plesk login, ID, name, email, and determine which firewall rule this should go to	
$theip = [System.Net.Dns]::GetHostAddresses("$domain") | Select -Exp IPAddressToString
$pleskid = querypsa "select cl_id from domains where displayname = '$pleskdomain';"
$plesk = querypsa "select login,pname,email,cname from clients where id = '$pleskid';"
$pleskun = ($plesk.split(","))[0]
$pleskname = ($plesk.split(","))[1]
$pleskemail = ($plesk.split(","))[2]
$pleskcname= ($plesk.split(","))[3]

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

#Ensure there is a company name and if there isn't set it as NA

if ($pleskcname -eq $null){$pleskcname="NA"}

#Check Whitelist tool to see if that hgclient exists and if not create it.
$hgclientexists = show-hgclient | where-object {$_.id -contains "$pleskid"}
if ($hgclientexists -eq $null){	Add-HGClient $pleskid $pleskname $pleskemail $pleskcname}

#######
#Check to make sure domain actually exists
if ($theip -ne $null){
	$exist = Invoke-Sqlcmd -query "select domain from $table where domain = '$domain'" -database "dyndns" | Select -Exp domain
	#Check if domain exists in DB
		if ($exist -eq $null){
			Invoke-Sqlcmd -query "Insert into $table values ('$domain', '$theip', '$pleskun', '$pleskid')" -database "dyndns"
			Write-Host "$domain did not exist in database. Adding the domain and $theip to the database"

			#Check if IP exists in the firewall currently
			$formerip = get-whitelist | where-object {$_.owner -contains "$pleskname" -and {$_.RemoteIP -contains "$currentip"} -and {$_.ServiceName -contains "$table"}
			if ($formerip -ne $null){
				Write-Host "Exiting. $theip already exists in $rulename for $pleskname"
				}
				else{
				Add-Whitelist $pleskid $table $theip
				Push-Firewall
				Write-Host "Added $theip to $rulename. Exiting"
					}
			}
	else{
		#Check if IP is current
		$currentip = Invoke-Sqlcmd -query "select ip from $table where domain = '$domain'" -database "dyndns" | Select -Exp ip
		write-host "Previous IP is $currentip"
		#Update IP in DB if it's not current
		if ($currentip -ne $theip){Invoke-Sqlcmd -query "update $table set ip='$theip' where domain = '$domain'" -database "dyndns"}
		$existselsewhere = get-whitelist | where-object {$_.owner -contains "$pleskname" -and $_.RemoteIP -contains "$currentip" -and $_.ServiceName -contains "$table"}
		write-host "Current IP is $theip"
		#Update Firewall with current IP
		if ($existselsewhere -ne $null){
			Remove-Whitelist $existselsewhere.RuleID
			Add-Whitelist $pleskid $table $theip
			Push-Firewall
			Write-Host "Added $theip to $rulename. Exiting"
			}
			else{
				Add-Whitelist $pleskid $table $theip
				Push-Firewall
				Write-Host "Added $theip to $rulename. Exiting"
				}
		}
}
else{
	#If the domain does not return an IP this is the default fail
	Write-Host "$domain does not resolve to an IP so it could not be added. Please try again later"
	}
}
	Function InstallDynDNS {
Invoke-Sqlcmd -query "create database dyndns"
Invoke-Sqlcmd -query "create table mssql ( Domain varchar(255), IP varchar(255), UN varchar(255), PleskID varchar(255) )" -database "dyndns"
Invoke-Sqlcmd -query "create table mysql ( Domain varchar(255), IP varchar(255), UN varchar(255), PleskID varchar(255) )" -database "dyndns"
}