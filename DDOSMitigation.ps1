Function HG-DDOSMitigation {


param(
	[string]$domlist = $(Read-Host "Domain list location:"), 
	[string]$ip = $(Read-Host "New IP") 
	)

$subscription = $env:plesk_bin + "\subscription.exe"
$list = Get-Content $domlist
foreach($domain in $list){
$arguement = "--update {0} -ip {1}" -f $domain,$ip
Start-Process $subscription -ArgumentList $arguement -NoNewWindow -Wait -Verbose
}
}
HG-DDOSMitigation