$domain = Read-Host "Enter Domain"
$sourcepath = "D:\SmarterMail\Domains\" + $domain + "\Users"
$userlist = dir $sourcepath | ? {$_.name}

foreach ($user in $userlist) {

$path = 'D:\SmarterMail\Domains\' + $domain + '\Users\' + $user + '\*'
$destination = 'C:\SmarterMail\Domains\' + $domain + '\Users\' + $user + '\Mail'

Write-Host " $path
$destination
Processing" $user -foregroundcolor "yellow"

$test = Copy-Item -path $path -destination $destination -recurse
}