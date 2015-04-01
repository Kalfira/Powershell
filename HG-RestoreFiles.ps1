$init = Read-Host "Do you want to restore a path or a domain?"
$value
if($init -match "p")
{
	Write-Host "Enter the path you want:"
	$value = Read-Host
	
}
elseif($init -match "d")
{
	Write-Host "Enter the domain you would like:"
	$domain = Read-Host
	$value = querypsa("select www_root from hosting where dom_id=(select id from domains where name='$domain')")
}
else{
	Write-Host "Try and pick path or domain next time..."
	exit
}
cmd /c wbadmin get versions | findstr "Version identifier:"
Write-Host "Please select a backup date: (recommend copy and paste version identifier)"
$date = Read-Host
cmd /c wbadmin start recovery -version:$date -itemtype:file -items:$value -recursive -recoveryTarget:C:\scripts\temp
Write-Host "Are these the correct file paths to restore from / to? (y/n)"
$choice = Read-Host
if($choice -match "y")
{
	cmd /c wbadmin start recovery -version:$date -itemtype:file -items:$value -recursive -recoveryTarget:C:\scripts\temp -quiet
}
else
{
	Write-Host "No or invalid choice selected. Aborting."
}