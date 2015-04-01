Function HG-SearchMail {

param(
	[string]$date = $(Read-Host "Enter Date (MM/DD/YYYY)"), 
	[string]$email = $(Read-Host "Which email are you looking for?"),
	[string]$shared = $(Read-Host "Is this on a shared server? (y/n)")
	)

$month = $date.Split("/")[0]
$day = $date.Split("/")[1]
$year = $date.Split("/")[2]

$file = "C:\Smartermail\Logs\$year.$month.$day-delivery.log"
if ($shared -eq "y"){$file = "C:\Scripts\Logs\SmarterMail\$year.$month.$day-delivery.log"}
[array]$emaillist = "Emails sent from $email on $date"

$log = select-string -Path $file -Pattern $email
$ids = $log | foreach-object{$_.tostring().Split("[")[1].Split(" ")[0].Replace("]",$null).Trim()} | get-unique

foreach ($id in $ids){
$for = "Delivery for"
$array = (select-string -inputobject $log '\w+@\w+\.\w+' -AllMatches ).Matches
foreach ($item in $array){

if ($item.Value -match $email){}
elseif ($emaillist -match $item.Value){}
else {$emaillist += $item.Value}
}
}
$emaillist
}