Function QueryPSA ($SQL) {
     Push-Location $Env:plesk_bin
     $return = .\dbclient.exe --direct-sql --sql="$SQL" | Where-Object {$_ -ne ""} |  foreach {$_.replace("`t", ",")} |  foreach {$_.substring(0,($_.length - 1))}
     Pop-Location
     if ($return -ne $null) {
         if (@($return).count -ne 1) {
             $return = $return | Select-Object -Last ($return.length - 1)
         }
         else { $return = $null }
     }
     $Return
 }

Function HG-BackupWebConfig {

param($domain = $(Read-Host "Enter Domain Name"))
$wwwpath = QueryPSA("SELECT www_root FROM hosting WHERE dom_id=(SELECT id FROM domains WHERE name='$domain');")
cd $wwwpath
icacls.exe . /save .\backupperms.txt /t /c
cd IIS:\
Backup-WebConfiguration $domain
Set-ItemProperty C:\Windows\System32\inetsrv\backup\$domain\schema\rewrite_schema.xml -name IsReadOnly -value $false

}

Function HG-Reconfigure {

param($domain = $(Read-Host "Enter Domain Name"))

$rpath=$env:plesk_vhosts + "\" + $domain + "\.Security"

$websrvmng = $env:plesk_bin + "\websrvmng.exe"
$hostsec = $env:plesk_bin + "\hostingsecurity.exe"
$reconfig = $env:plesk_bin + "\reconfigurator.exe"
$domainx = $env:plesk_bin + "\domain.exe"

$argue0 = "--remove-vhost --vhost-name={0}" -f $domain
$argue1 = "--reconfigure-vhost --vhost-name={0}" -f $domain
$argue2 = "--update-anon-password --domain-name={0}" -f $domain
$argue3 = "--create-domain-security --vhost-name={0}" -f $domain
$argue4 = "/check-permissions={0}" -f $domain

Start-Process $websrvmng -ArgumentList $argue0 -NoNewWindow -Wait -Verbose

Start-Process $websrvmng -ArgumentList $argue1 -NoNewWindow -Wait -Verbose

Start-Process $websrvmng -ArgumentList $argue2 -NoNewWindow -Wait -Verbose

Remove-Item -path $rpath -Force -Verbose

Start-Process $hostsec -ArgumentList $argue3 -NoNewWindow -Wait -Verbose

Start-Process $reconfig -ArgumentList $argue4 -NoNewWindow -Wait -Verbose
}

Function HG-RestoreWebConfig {

param($domain = $(Read-Host "Enter Domain Name"))
$wwwpath = QueryPSA("SELECT www_root FROM hosting WHERE dom_id=(SELECT id FROM domains WHERE name='$domain');")
cd $wwwpath
icacls.exe . /restore .\backupperms.txt
Try
{
cd IIS:\
Restore-WebConfiguration $domain
}
Catch
{}
}

