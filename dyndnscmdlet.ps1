Function testsnap { 
param([string]$domain)

#LOAD THE MSSQL SNAPIN############################################################################# 
$sqlSnapin = Get-PSSnapin | where {$_.Name -eq "SqlServerCmdletSnapin100"}
if($sqlSnapin -eq $null){ Add-PSSnapin SqlServerCmdletSnapin100 }

$theip = Invoke-Sqlcmd -query "select ip from data where domain = '$domain'" -database "example" | findstr [0-9]
Write-Host $theip
}

Function CheckIP {

param([string]$domain = $(Read-Host "Enter Domain"))
$theip = [System.Net.Dns]::GetHostAddresses("$domain") | Select -Exp IPAddressToString
Write-Host "The IP for $domain is $theip ."
}

Function UpdateFirewall {
param($ip = $(Read-Host "Enter IP Address"))
$oldip = Read-Host "Enter Old IP"
$rulename = Read-Host "Enter Rule Name" 
$formerips = netsh advfirewall firewall show rule name="$rulename" | where-object {$_ -match 'RemoteIP:'} | foreach-object{$_.Split(":")[1].Replace('RemoteIP:',$null).Trim()} | Get-Unique
if ($formerips -match "$oldip/32,")
{
$formerips = $formerips.Replace("$oldip/32,", "")
$newips = "$formerips,$ip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
}
elseif ($formerips -match "$oldip/32")
{
$formerips = $formerips.Replace("$oldip/32", "")
$newips = "$formerips,$ip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
}
else
{
$newips = "$formerips,$ip/32"
netsh advfirewall firewall set rule name="$rulename" new remoteip="$newips" action="allow"
}
}

Function InstallDynDNS {
#LOAD THE MSSQL SNAPIN############################################################################# 
$sqlSnapin = Get-PSSnapin | where {$_.Name -eq "SqlServerCmdletSnapin100"}
if($sqlSnapin -eq $null){ Add-PSSnapin SqlServerCmdletSnapin100 }


Invoke-Sqlcmd -query "create database dyndns"
Invoke-Sqlcmd -query "create table mssql ( Domain varchar(255), IP varchar(255), UN varchar(255) )" -database "dyndns"
Invoke-Sqlcmd -query "create table mysql ( Domain varchar(255), IP varchar(255), UN varchar(255) )" -database "dyndns"
}