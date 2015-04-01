Function DynDNS {

param([string]$domain = $(Read-Host "Enter Domain"))
$rulename = Read-Host "Which Firewall Rule would you like to whitelist for?"
$theip = ping $domain | where-object {$_ -match 'from'} | foreach-object{$_.Split(":")[0].Replace('Reply from ',$null).Trim()} | Get-Unique

#LOAD THE MSSQL SNAPIN############################################################################# 
$sqlSnapin = Get-PSSnapin | where {$_.Name -eq "SqlServerCmdletSnapin100"}
$currentip = Invoke-Sqlcmd -query "select ip from ips where domain = '$domain'" -database "dyndns" | Select -Exp ip

if($sqlSnapin -eq $null){ Add-PSSnapin SqlServerCmdletSnapin100 }

$exist = Invoke-Sqlcmd -query "select domain from ips where domain = '$domain'" -database "dyndns" | Select -Exp domain
$formerips = netsh advfirewall firewall show rule name="$rulename" | where-object {$_ -match 'RemoteIP:'} | foreach-object{$_.Split(":")[1].Replace('RemoteIP:',$null).Trim()} | Get-Unique
#Check if domain exists in DB
if ($exist -eq $null)
{
Invoke-Sqlcmd -query "Insert into ips values ('$domain', '$theip')" -database "dyndns"
Write-Host "$domain did not exist in database. Adding the domain and $theip to the database"

#Firewall Steps

if ("$theip/32" -match $formerips)
{
$newips = "$formerips,$theip/32"
$exists = Invoke-Sqlcmd -query "select domain from ips where ip = '$theip'" -database "dyndns" | Select -Exp domain
Write-Host "Exiting. $theip already exists in $rulename for $exists"
}
else
{
$newips = "$formerips,$theip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
Write-Host "Added $theip to $rulename. Exiting"
}
}
else
{
#Check if IP is current
$currentip = Invoke-Sqlcmd -query "select ip from ips where domain = '$domain'" -database "dyndns" | Select -Exp ip
if ($currentip -ne $theip)
	{
	Invoke-Sqlcmd -query "update ips set ip='$theip' where domain = '$domain'" -database "dyndns"
	}
#Update Firewall with current IP
if ("$currentip/32," -match $formerips)
{
$formerips = $formerips.Replace("$currentip/32,", "")
$newips = "$formerips,$theip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
Write-Host "Added $theip to $rulename. Exiting"
Write-Host "Line 48"
}
elseif ("$currentip/32" -match $formerips)
{
$formerips = $formerips.Replace("$currentip/32", "")
$newips = "$formerips,$theip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
Write-Host "Added $theip to $rulename. Exiting"
Write-Host "Line 55"
}
else
{
$newips = "$formerips,$theip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
Write-Host "Added $theip to $rulename. Exiting"
Write-Host "Line 61"
}
}
}