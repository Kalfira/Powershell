import-module gatorshell
import-module gatorcommands
 
$PleskPass=getpass-plesk
$mysqlPass=getpass-mysql
$SMpass=getpass-smartermail
$SMuser = "admin" #on shared this is HGSMAdmin
$API = New-WebServiceProxy -uri http://localhost:9998/Services/svcUserAdmin.asmx
$API2 = New-WebServiceProxy http://localhost:9998/services/svcDomainAdmin.asmx
$domain_list
 
$answer = $(Read-Host "Do you want to get the logins for all domains, or a specific domain? (a for all, domain name for single domain)")
if($answer -eq "a"){
 
$domain_list = $API2.GetAllDomains($SMuser,$SMpass)
write-host "getting users"
foreach($domain in $domain_list.domainnames){
        $results = $API.GetUsers($SMuser,$SMpass,$domain)
        $user_list = $results.users
        foreach($user in $user_list){
                $u_name = $user | %{$_.username}
                $pass = $user | %{$_.password}
                $output = $u_name+","+$pass
#               & $env:plesk_bin\mail.exe  -c $u_name -passwd $pass -mailbox true
#               & $env:plesk_bin\mail.exe  -u $u_name -passwd $pass -mailbox true
                $output | out-file "C:\scripts\mailusers.csv" -append
        }
}
}
else{
$domain = $answer
 $results = $API.GetUsers($SMuser,$SMpass,$domain)
        $user_list = $results.users
        foreach($user in $user_list){
                $u_name = $user | %{$_.username}
                $pass = $user | %{$_.password}
                $output = $u_name+","+$pass
#               & $env:plesk_bin\mail.exe  -c $u_name -passwd $pass -mailbox true
#               & $env:plesk_bin\mail.exe  -u $u_name -passwd $pass -mailbox true
                $output
		$output | out-file "C:\scripts\mailusers.csv" -append
        }
}
 
notepad.exe "C:\scripts\mailusers.csv"