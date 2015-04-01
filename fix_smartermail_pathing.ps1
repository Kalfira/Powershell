$DomainList = GCI C:\SmarterMail\Domains | Foreach-Object {$_.Name}
Foreach($Domain in $DomainList){
    $UserList =  GCI C:\SmarterMail\Domains\$Domain\Users\ | Foreach-Object {$_.Name}
    Foreach($User in $UserList){
        $FolderList = GCI C:\SmarterMail\Domains\$Domain\Users\$User | Foreach-Object {$_.Name} | Where-Object {$_ -ne "FileStore"} | Where-Object {$_ -ne "Mail"} | Where-Object {$_ -ne "Index"} | Where-Object {$_ -notlike "*.xml"}
        ForEach($Folder in $FolderList){
            Copy-Item -path C:\SmarterMail\Domains\$Domain\Users\$User\$Folder -destination C:\SmarterMail\Domains\$Domain\Users\$User\Mail\ -recurse -force -verbose
            Remove-Item C:\SmarterMail\Domains\$Domain\Users\$User\$Folder -recurse -force -verbose
        }
        $CFGList = GCI C:\SmarterMail\Domains\$Domain\Users\$User\Mail -recurse | Where-Object {$_.name -like "*.cfg"} | Foreach-Object {$_.FullName}
        Foreach($CFGFile in $CFGList){
            Remove-Item $CFGFile -force -verbose
        }
    }
}