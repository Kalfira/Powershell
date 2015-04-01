Function HG-ChangeSubscriptionName {

    <#
	.SYNOPSIS
	This cmdlet will rename a subscription's domain (and all associated subdomains) to a new domain.
	
	.EXAMPLE
	HG-ChangeSubscriptionName domain.com newdomain.org
    
	#>

param(
	[string]$olddomain = $(Read-Host "Enter Original Domain"), 
	[string]$newdomain = $(Read-Host "What domain do you wish to change it too?") 
	)

$subscription = $env:plesk_bin + "\subscription.exe"
$domainlist = querypsa "select name from domains where name like '%$olddomain';"
foreach($domain in $domainlist){
$arguement = "--update {0} -new_name {1}" -f $domain,$newdomain
if ($domain.split(".").length -gt 2) {
$splitdomain = $domain.Split(".")[0]+"."+$newdomain
$arguement = "--update {0} -new_name {1}" -f $domain,$splitdomain
}
Start-Process $subscription -ArgumentList $arguement -NoNewWindow -Wait -Verbose
}
}