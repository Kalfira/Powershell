$sourcepath = "E:\SmarterMail\Domains"
$destinationpath = "c:\Smartermail\Domains"
push-location $sourcepath
$DomainList = GCI $sourcepath | Foreach-Object {$_.Name}
pop-location
Foreach($Domain in $DomainList){
    $UserList =  GCI $sourcepath\$Domain\Users\ | Foreach-Object {$_.Name}
    Foreach($User in $UserList){        
             if (test-path $destinationpath\$domain\users\$user){
             
                if (test-path $sourcepath\$domain\users\$user\mail){
                    if (test-path $destinationpath\$domain\users\$user\mail){
                        $FolderList = GCI $sourcepath\$Domain\Users\$User\mail | Where-Object {$_ -ne "FileStore"} | Where-Object {$_ -ne "Mail"} | Where-Object {$_ -ne "Index"} | Where-Object {$_.psiscontainer -eq $true}
                        ForEach($Folder in $FolderList){
                        Copy-Item -Recurse -Force -verbose -path $sourcepath\$Domain\Users\$User\mail\$Folder -destination $destinationpath\$Domain\Users\$User\Mail\ 

                        }
                    }                   
                
                }
                else{
                $FolderList = GCI $sourcepath\$Domain\Users\$User | Where-Object {$_ -ne "FileStore"} | Where-Object {$_ -ne "Mail"} | Where-Object {$_ -ne "Index"} | Where-Object {$_ -notlike "*.xml"}
                    ForEach($Folder in $FolderList){
                    Copy-Item -Recurse -Force -verbose -path $sourcepath\$Domain\Users\$User\$Folder -destination $destinationpath\$Domain\Users\$User\Mail\ 

                    }
                }
             }
             else{
             "$user@$domain does not exist on the new server!"
             }
            
       $CFGList = GCI $destinationpath\$Domain\ -recurse | Where-Object {$_.name -like "m*.cfg" -or $_.name -like "r*.cfg"}  | Foreach-Object {$_.FullName}
        if ($cfglist -ne $null){
        
        Foreach($CFGFile in $CFGList){
            Remove-Item $CFGFile -force 
        }    
        
        
        }
        
        "copy for $user@$domain complete"
        
        }
}   