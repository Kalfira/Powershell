import-module gatorshell
import-module gatorcommands

$PleskPass=getpass-plesk
$mysqlPass=getpass-mysql
$SMpass=getpass-smartermail
$SMuser = "admin" #on shared this is HGSMAdmin


Function ExecuteBinary () {
param([string] $processname, [string] $arguments)
 
$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
$processStartInfo.FileName = $processname 
$processstartworkingdirectory =($processname.substring(0,(($processname.lastindexof("\") + 1)))) 
$processStartInfo.WorkingDirectory = $processstartworkingdirectory
if($arguments) { $processStartInfo.Arguments = $arguments } 
$processStartInfo.UseShellExecute = $false 
$processStartInfo.RedirectStandardOutput = $true
 
$process = [System.Diagnostics.Process]::Start($processStartInfo)
$process.WaitForExit()
$process.StandardOutput.ReadToEnd()
}

Function QueryPSA ($QueryString) {
    $psamysqlbinary = $Env:plesk_dir + "mysql\bin\mysql.exe"
#    write-host $psamysqlbinary $QueryString
    $psareturn = ExecuteBinary "$psamysqlbinary" "-s -N -u admin -p$PleskPass -P 8306 psa -e `"$QueryString`"" -NoNewWindow -Wait
    $psareturn
}

$domain_list = (QueryPSA "select name from domains;").split()
write-host "getting users"
foreach($domain in $domain_list){
	$API = New-WebServiceProxy -uri http://localhost:9998/Services/svcUserAdmin.asmx
    $domain=$domain.trim()
	if ($domain -ne ""){
		$results = $API.GetUsers($SMuser,$SMpass,$domain)
		$user_list = $results.users
		foreach($user in $user_list){
			$u_name = $user | %{$_.username}
			$pass = $user | %{$_.password}
			$output = $u_name+","+$pass
			$output | out-file "C:\scripts\mailusers.csv" -append
		}
	}
}

notepad.exe "C:\scripts\mailusers.csv"
