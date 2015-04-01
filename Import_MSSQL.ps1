$dumplocation = $(Read-Host "Enter Dump Location")
$location = gci $dumplocation
foreach($item in $location){
$split = $item.Name
$split2 = $split.split(".")[0]
Write-Host "Restoring $split2 from $split"
$query = "RESTORE DATABASE $split2 FROM DISK = N`'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\$split`' WITH FILE = 1, NOUNLOAD, STATS = 10, REPLACE"
Invoke-Sqlcmd -query $query
}
