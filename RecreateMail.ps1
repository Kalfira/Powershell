$loc = Read-Host "Enter email file location: "
$file = Get-Content $loc
$binary = $env:plesk_bin + "\mail.exe"

foreach ($line in $file){
$mail = $line.Split(" ")[0]
$pass = $line.Split(" ")[1]
$arguement = "--create {0} -mailbox true -passwd {1}" -f $mail,$pass
Start-Process $binary -ArgumentList $arguement -NoNewWindow -Wait -Verbose
}