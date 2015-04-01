$dumplocation = $(Read-Host "Enter Dump Location")
$location = gci $dumplocation
foreach($item in $location){
$split = $item.Name
$split2 = $split.split(".")[0]
Write-Host "Restoring $split2 from $split"
&cmd /c ".\mysql.exe -u admin -pC85BU#r7mk $split2 < $split"
}
