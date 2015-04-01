$appPools = dir IIS:/AppPools | findstr 'Stopped'
$s=$appPools -split "\n"
foreach ($i in $s){ 
	$c=$i -split "\("
	$c=$c[0] -split " "
	$domain=$c[0]
	$status=querypsa("select status from domains where name='$domain'")
	if($status -eq 0){
		Start-WebAppPool $domain*
		echo "Starting $domain"
	}elseif($domain.length > 23){
		echo "$domain -\> length too long, check manually"
	}else{
		echo "$domain is suspended"
	}
}

