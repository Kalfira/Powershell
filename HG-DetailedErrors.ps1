$domain = read-host "What is the domain name?"
$docroot = querypsa("select www_root from hosting where dom_id=(select id from domains where name='$domain')")
$configs = gci $docroot | ?{$_.name -match "web.config"}
foreach($config in $configs){
    pushd $config.directoryname
    (gc .\web.config).replace('<customErrors mode="On"/>','<customErrors mode="Off"/>')|sc .\webconfig.new;rename-item web.config webconfig.bak;rename-item webconfig.new web.config
    popd
    }