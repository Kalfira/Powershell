$loc = Read-Host "Enter email list location"
$content = Get-Content $loc
$mail = $env:plesk_bin + "\mail.exe"
foreach ($line in $content){
$email = $line.split(" ")[0]
$pass = $line.split(" ")[1]
$arguement = "--create {0} -passwd {1} -mailbox true" -f $email,$pass
Start-Process $mail -ArgumentList $arguement -NoNewWindow -Wait -Verbose
}