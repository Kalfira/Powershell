$test = gc C:\Scripts\Temp\email.txt              

foreach ($email in $test){                       

$emailaddress = ($email.split())[0]                 
$pass = "w6BuyMqM!"                      

$argue = " -u {0} -passwd {1} -mailbox true" -f $emailaddress,$pass 
$subexe = $env:plesk_cli+"\mail.exe"                            

Start-Process $subexe -ArgumentList $argue -NoNewWindow -Wait   
}