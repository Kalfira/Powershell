<#HG Custom CmdLets by Wes Geddes#>

$SSDir = "C:\Program Files (x86)\SmarterTools\SmarterStats\MRS\App_Data\Config"

Function HG-SmarterStatsGetID {
	<#
	.SYNOPSIS
	This cmdlet will return the site id from Smarter Stats for a domain.
	
	.PARAMETER DomainName
	Accepts a string input. Also, it can be piped in as string or property.
	
	.EXAMPLE
	HG-SmarterStatsGetID domain.com
	
	.EXAMPLE
	QueryPSA "select name from domains limit 10" | HG-SmarterStatsGetID
	#>
	[CmdletBinding()]
	param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		  [string]$DomainName = $_)

	BEGIN {}
	
	PROCESS {
		$StatsUsed = QueryPSA "SELECT hosting.webstat FROM hosting, domains WHERE domains.name = '$DomainName' AND hosting.dom_id = domains.id"
		$DomainExist = QueryPSA "SELECT count(id) from domains where name = '$DomainName'"
			
		#Check for user error
		if ($DomainExist -ne 1) {
			Write-Host "`n The domain does not exist on this server. Exiting..."
			return
		}
		if ($StatsUsed -ne "smarterstats") {
			Write-Host "`n The domain is not set to use smarterstats for statistics. Exiting..."
			return
		}
		
		[xml]$Sites = Get-Content "$SSDir\AppConfig.xml"
		$return = ($Sites.SmarterStatsApplicationSettings.Site | Where-Object {$_.SiteName -eq $DomainName}).SiteID
		$Return
	}
	
	END {}
}

Function HG-SmarterStatsIssue {
	<#
	.SYNOPSIS
	This cmdlet will ensure that the default FTP username and password are the correct logins
	for the SmarterStats site. This addresses the special character issue with SmarterStats.
	
	.PARAMETER what
	Accepts a string input. Also, it can be piped in as string or property.
	
	.EXAMPLE
	 HG-SmarterStatsIssue domain.com
	
	.EXAMPLE
	QueryPSA "select name from domains limit 10" | HG-SmarterStatsIssue
	#>
	[CmdletBinding()]
	param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		  [string]$DomainName = $_)
	
	BEGIN {}
	
	PROCESS {
		$StatsUsed = QueryPSA "SELECT hosting.webstat FROM hosting, domains WHERE domains.name = '$DomainName' AND hosting.dom_id = domains.id"
		$DomainExist = QueryPSA "SELECT count(id) from domains where name = '$DomainName'"
			
		#check for user error
		if ($DomainExist -ne 1) {
			Write-Host "`n The domain does not exist on this server. Exiting..."
			return
		}
		if ($StatsUsed -ne "smarterstats") {
			Write-Host "`n The domain is not set to use smarterstats for statistics. Exiting..."
			return
		}
			
		$SSUser = QueryPSA "SELECT val FROM misc WHERE param = 'smartestats_login'"
		$SSPass = QueryPSA "SELECT val FROM misc WHERE param = 'smartestats_password'"

		$DefaultAccount = QueryPSA "SELECT sys_users.login, accounts.password FROM sys_users, accounts, domains, hosting WHERE domains.name = '$DomainName' AND hosting.dom_id = domains.id AND sys_users.id = hosting.sys_user_id AND accounts.id = sys_users.account_id;"

		$API = New-WebServiceProxy -uri http://localhost:9999/Services/UserAdmin.asmx
		$results = $API.ValidateLogin($SSUser, $SSPass, (HG-SmarterStatsGetID $DomainName), ($DefaultAccount.split(",")[0]), ($DefaultAccount.split(",")[1]))

		if ($results.Result -eq $false) {
			Write-Host "`nThe issue was found, setting the password correctly"
			$API.UpdateUser2($SSUser, $SSPass, (HG-SmarterStatsGetID $DomainName), ($DefaultAccount.split(",")[0]), ($DefaultAccount.split(",")[1]), "", "", "true", "")
			$results = $API.ValidateLogin($SSUser, $SSPass, (HG-SmarterStatsGetID $DomainName), ($DefaultAccount.split(",")[0]), ($DefaultAccount.split(",")[1]))
			if ($results.Result -eq $true) {
				Write-Host "This user can now login with: `nUsername: "($DefaultAccount.split(",")[0])" `nPassword: "($DefaultAccount.split(",")[1])
			}
		}
		else { Write-Host "`nThe password was not the issue. Try using: `nUsername: "($DefaultAccount.split(",")[0])" `nPassword: "($DefaultAccount.split(",")[1]) }
	}
	
	END {}
}

Function HG-GetRandomPassword {
	<#
	.SYNOPSIS
	This cmdlet will generate as many random passwords as you specify.
	By default it will generate 1 random password 15 characters long.
	
	.PARAMETER len
	Accepts an integer entry only. This is the length of the password.
	
	.PARAMETER count
	Accepts an integer entry only. This is the number of passwords generated.
	
	.EXAMPLE
	HG-GetRandomPassword 13 1
	#>
	
	[Cmdletbinding()]
    param([Parameter()]
          [int]$length=13,
          [int]$numOfPass=1
         )
    
    BEGIN{}
    PROCESS{
        [string]$charsToUse = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#%^&*_+-={}[]<>"
        [string]$lcase= "abcdefghijklmnopqrstuvwxyz"
        [string]$ucase= $lcase.toupper()
        [string]$nums= "1234567890"
        [regex]$regexExp = "(?=.*[$lCase])(?=.*[$uCase])(?=.*[$nums])(?=.*[\W])"
        
        $rnd = New-Object System.Random
        [int]$count=0
        
        do{
            do{
                $pw = $null
                for($i=0;$i -lt $length;$i++){
                    $pw += $charsToUse[($rnd.Next(0,$charsToUse.Length))]
                }
            }until($pw -match $regexExp)
            $pw
            $count++
        }until($count -eq $numOfPass)
    }
    END{}	
}

Function HG-TransfersCreateFTP {
	<#
	.SYNOPSIS
	This cmdlet will generate a FTP account under the domain hgxferdeptsx.com
	
	.PARAMETER TickeyNumber
	Accepts a string entry only. This is the ticket number you are working on.
	
	.EXAMPLE
	HG-TransfersCreateFTP 321651321
	#>
	param([string]$TicketNumber = (Read-Host "What ticket ID are you working on?"))
	$Tdir = "D:\InetPub\vhosts\hgxfersdept7.com"
	
	#Check for user error
	if (!($TicketNumber)) {
		do {
			[string]$TicketNumber = Read-Host "What ticket ID are you working on?"
		}
		until ($TicketNumber)
	}

	#Check if ActiveTickets.txt exists
	if (Test-Path $Tdir\ActiveTickets.txt) {
		#Check if ticket already exists
		$DataIn = Get-Content $Tdir\ActiveTickets.txt
		if ($DataIn -ne "") {
			ForEach ($Line in $DataIn) {
				if (($Line.split(",")[0]) -eq $TicketNumber) {
					Write-Host "`n`n$TicketNumber has already been setup. Use the following: `n`nFTP Username: $TicketNumber `nFTP Password: $($Line.split(",")[1]) `nDirectory: $Tdir\$TicketNumber"
					return
				}
			}
		}
	}
	
	#Create ticket ftp user
	New-Item $Tdir\$TicketNumber -type directory 
	$RandomPass = HG-GetRandomPassword
	$Now = ((get-date).ToShortDateString()).replace("/", "-")
	Start-Process "$Env:plesk_cli\ftpsubaccount.exe" "--create $TicketNumber -domain hgxfersdept7.com -passwd $RandomPass -home /$TicketNumber -access_read true -access_write true" -Wait -NoNewWindow
	Add-Content "$Tdir\ActiveTickets.txt" "$TicketNumber,$RandomPass,$Now"
	Write-Host "`n`nYour FTP account has been setup for ticket $TicketNumber. `n`nFTP Username: $TicketNumber `nFTP Password: $RandomPass `nDirectory: $Tdir\$TicketNumber"
}

Function HG-TransfersRemoveFTP {
	<#
	.SYNOPSIS
	This cmdlet will remove a FTP account under the domain hgxfersdeptx.com
	
	.PARAMETER TickeyNumber
	Accepts a string entry only. This is the ticket number you are working on.
	
	.EXAMPLE
	HG-TransfersRemoveFTP 321651321
	#>
	param([string]$TicketNumber = (Read-Host "What ticket ID are you wanting to remove?"))
	$Tdir = "D:\InetPub\vhosts\hgxfersdept7.com"
	
	#Check for user error
	if (!($TicketNumber)) {
		do {
			[string]$TicketNumber = Read-Host "What ticket ID are you working on?"
		}
		until ($TicketNumber)
	}
	
	#Remove the ticket directory
	if (Test-Path $Tdir\$TicketNumber) {
		Remove-Item $Tdir\$TicketNumber -Recurse -Force
	}
	else {
		Write-Host "`nThe ticket number does not exists on this server."
		return
	}
	
	#Remove the FTP Account
	Start-Process "$Env:plesk_cli\ftpsubaccount.exe" "--remove $TicketNumber -domain hgxfersdept.exe" -Wait -NoNewWindow
	$temp = Get-Content $Tdir\ActiveTickets.txt 
	$temp | where-object {$_ -notmatch $TicketNumber} | out-file $Tdir\ActiveTickets.txt
	Write-Host "`n`nThe ticket $TicketNumber has been removed along with it's content."
}

Function HG-ConvertPSACert {
	<#
	.SYNOPSIS
	This cmdlet will convert the certificate entry from the psa to the correct format.
	
	.PARAMETER Uinput
	Accepts a string input. Also, it can be piped in as string or property. This is the entry from the psa.
	
	.PARAMETER filename
	Accepts a string input. If you want to export the entry to a file specify the full path here.
	
	.EXAMPLE
	HG-ConvertPSACert "-----BEGIN+CERTIFICATE-----%0AMIIEjjCCA3agAwIBAgIET6sGizANBgkqhkiG9w0BAQUFADCBjjELMAkGA1UEBhMC%0AVVMxCzAJBgNVBAgTAlRYMRAwDgYDVQQHEwdIb3VzdG9uMRswGQYDVQQKExJIb3N0%0AZ2F0b3IuY29tLCBMTEMxHTAbBgNVBAMTFHd3dy5oZy53ZXNnZWRkZXMuY29tMSQw%0AIgYJKoZIhvcNAQkBFhVub3JlcGx5QGhvc3RnYXRvci5jb20wHhcNMTIwNTEwMDAw%0ANjM2WhcNMTMwNTEwMDAwNjM2WjCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlRY%0AMRAwDgYDVQQHEwdIb3VzdG9uMRswGQYDVQQKExJIb3N0Z2F0b3IuY29tLCBMTEMx%0AHTAbBgNVBAMTFHd3dy5oZy53ZXNnZWRkZXMuY29tMSQwIgYJKoZIhvcNAQkBFhVu%0Ab3JlcGx5QGhvc3RnYXRvci5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK%0AAoIBAQDATY2WxM28p6HjQYtVNzWCp37GKeHoJaJ6PEfmrPOl1r7ajYKDGjfOzHPI%0Arxsu1FJEscDleOz4fEh5lxJFUZefErfY8WA8flimGB5NB2hd9JxJKiN35it3WF%2FP%0ArMM%2FnJB4MqigNuuy6r8RHLN463eGFgeX3oq1Hy%2FWfmLeAD%2F95SmsWDJ24W73DJH4%0AmtVWIA6a%2FuylfoABDCqxsGf80BRNPmIP%2BEYVhOT8cYJqfDY37hG95wzarTHVbuLU%0AnbzElMG2rGAOeJStJFbFHM2v8Xz2ngjQRFk1eR7ICRJEwr%2B6Sa7mP7peGwFWihM8%0A2Rx2xqy4sJvyhA2VCt2DMDCgS1HNAgMBAAGjgfEwge4wHQYDVR0OBBYEFJf%2B7MId%0ALNGk%2FYYwpQmMfCCzoAyfMIG%2BBgNVHSMEgbYwgbOAFJf%2B7MIdLNGk%2FYYwpQmMfCCz%0AoAyfoYGUpIGRMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVFgxEDAOBgNVBAcT%0AB0hvdXN0b24xGzAZBgNVBAoTEkhvc3RnYXRvci5jb20sIExMQzEdMBsGA1UEAxMU%0Ad3d3LmhnLndlc2dlZGRlcy5jb20xJDAiBgkqhkiG9w0BCQEWFW5vcmVwbHlAaG9z%0AdGdhdG9yLmNvbYIET6sGizAMBgNVHRMEBTADAQH%2FMA0GCSqGSIb3DQEBBQUAA4IB%0AAQAJMQ81PhRtpxkihjmWBw2HN8fRNJuI6GhPQqVmRmXxITTAqRHx7lN%2BZ2tUInlc%0ArnrL02bYL56iMaaBkGyUn%2BaSIieNE6m2NrFwctLgZLZqjLZCNqClwZ4IzMgeYH0B%0APhgmhxjWSPLYrl902wfk6YYUVM8H8bD9J2WBO1VEoHbAVgVU7AjowbdyEU3OWx9p%0AFrqXX8WsdgKg3Jm9hTJIwKSsL%2FP2srSWlx65wT4tN2aC0xaQdaaY6D84o7An3n2t%0Av7i1psjaG2Y6fsDW46%2BiKnT%2FooRNUGfeXuSVNu4wxcqxTHBZ25PssxMFQGXjYkBY%0Ava47xDmg7nC%2BAA2g3nJg7HJz%0A-----END+CERTIFICATE-----%0A"
	
	.EXAMPLE
	querypsa "select cert from certificates where id = 12" | HG-ConvertPSACert
	
	.EXAMPLE
	querypsa "select cert from certificates where id = 12" | HG-ConvertPSACert -filename "c:\users\wgeddes\desktop\certificate.crt"
	#>	
	[CmdletBinding()]
	param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uinput = $_,
		$filename = $null)
	
	PROCESS {
		$return = $Uinput.Replace("+"," ")
		$return = $return.Replace("%0A","`n")
		$return = $return.Replace("%2B","+")
		$return = $return.Replace("%2F","/")
		$return = $return.Replace("%3D","=")
		
		if ($filename -ne $null) {
			ForEach ($Line in $return) {
				Add-Content $filename $Line
			}
		}
		
		$Return
	}
}

Function SendNotificationEmail {
	param(
		[parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		$To, 
		[parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[string]$EmailSubject, 
		[string]$EmailBody="Default Body",
		$Attachment=$null
	)
	$PSEmailServer = "zimbra.hostgator.com"
	$SecureEmailPass = ConvertTo-SecureString "pSYyuvBnYjsjNcN4YsdAVZK0" -AsPlainText -Force
	$EmailCreds = New-Object System.Management.Automation.PsCredential "windept@hostgator.com",$SecureEmailPass
	if ($Attachment -eq $null) {
		Send-MailMessage -To $To -From "Windows Department <windept@hostgator.com>" -Credential $EmailCreds -Subject $EmailSubject -Body $EmailBody
	}
	else {
		Send-MailMessage -To $To -From "Windows Department <windept@hostgator.com>" -Credential $EmailCreds -Subject $EmailSubject -Body $EmailBody -Attachments $Attachment
	}
}

Function QueryPSA {
	param([string]$Query = (Read-Host "What query do you want to run?"))
	
	#Check  for user entry
	if ($Query.length -lt 10) {
		do {
			Write-Host "`nThe query you specified was blank. Please try again."
			$Query = Read-Host "What query do you want to run?"
		}
		until ( $Query.length -gt 9 )
	}
	
	#Check  for malicious sql
	$CheckFor = @("update", "delete", "drop")
	ForEach ($Item in $CheckFor) {
		if ($Item -eq $Query.substring(0,($Item.length))) {
			switch ($Item) {
				"update" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "where") {
						Write-Host "`n`nYou did not  include a WHERE argument in your UPDATE statement. Re-evaluate your statement and try again. `n`nExample: UPDATE domains SET status = 0 WHERE id = 123"
						return
					}
				}
				
				"delete" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "delete") {
						Write-Host "`n`nYou did not  include a WHERE argument in your DELETE statement. Re-evaluate your statement and try again. `n`nExample: DELETE FROM dns_recs WHERE dns_zone_id = 123"
						return
					}
				}
				
				"drop" {
					if ($Query.substring(10,($Query.length - 10)) -notcontains "drop") {
						Write-Host "`n`nAre you out of your mind??? You do not run DROP statements against the PSA!"
						return
					}
				}
			}
		}
	}
	
	#Query the PSA and parse the results
	Push-Location $Env:plesk_bin
	$return = .\dbclient.exe --direct-sql --sql="$Query" | Where-Object {$_ -ne ""} |  foreach {$_.replace("`t", ",")} |  foreach {$_.substring(0,($_.length - 1))}
	Pop-Location
	if ($return -ne $null) { 
		if (@($return).count -ne 1) {
			$return = $return | Select-Object -Last ($return.length - 1) 
		}
		else { $return = $null }
	}
	$Return
}

##### VANDERMARK HG-HostFile START ######
$HostFilePath = "C:\Windows\System32\drivers\etc\hosts" #Global Variable for the original host file
$HostFileNew  = "C:\Windows\System32\drivers\etc\hosts2" #Global Variable for the replacement host file

function Clean_Up_File{ #This function reads in the original hosts file and creates a new file without blank lines, and finally replaces the old with the new
    $HostFile = gc $HostFilePath
    foreach($line in $HostFile){
        if($line -ne ""){Add-Content $HostFileNew "$line"}
    }
    Remove-Item $HostFilePath
    Rename-Item $HostFileNew $HostFilePath
}
function AddAll{ #Function to add all domains in the PSA to the hosts file
	if(((Get-WmiObject win32_computersystem).domain) -eq "win.hostgator.com"){
        Write-Host "I'm sorry I'm not allowed to do this on a shared server"
        return
    }
    $domain = QueryPSA("select name from domains")
    foreach($line in $domain){
		if(!(SearchEntry $line)){
			$ipAddress = QueryPSA("select val from dns_recs where type='A' and host='$line.' and displayHost='$line.';")
			Add-Content $HostFilePath "$ipAddress $line www.$line`r"
            Write-Host "Successfully added $line to the hosts file."
		}
        else{Write-Host "Domain $line already exists in the hosts file. Not added."}
    }
}
function AddEntry{ #Function to add a specified domain to the hosts file
	if(((QueryPSA "select name from domains where name='$DomainName'") -eq $DomainName) -and (!(SearchEntry $DomainName))){
    	$ipAddress = QueryPSA("select val from dns_recs where type='A' and host='$DomainName.' and displayHost='$DomainName.';")
        Add-Content $HostFilePath "$ipAddress $DomainName www.$DomainName"
        Write-Host "Successfully added $line to the hosts file."
    }
    else{Write-Host "Domain entered is not a valid entry, or already exists in the hosts file. Please try again"}
}
function SearchEntry{ #This function allows a user to check to see if a specified entry already exists in the hosts file. Usage SearchEntry domain.com
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]  
          [string]$DomainName=$_)
    BEGIN{}
    
    PROCESS{ 
		$return = $false
        $HostFile = gc $HostFilePath
        foreach($line in $HostFile){
            if($line.contains("$DomainName")){
                $line
				$return = $true
            }
        }
		$Return
    }    
    END{}
} #Credit goes to Bradley Faulk for suggesting this cmdlet
function HG-HostFile{
    <#
	.SYNOPSIS
	This cmdlet will add and remove sites to the hosts file, and can even search the hosts file for a specified entry
	
	.PARAMETER DomainName
	Accepts a string input. Also, it can be piped in as string or property.
	
	.EXAMPLE
	HG-HostFile domain.com
	
	.EXAMPLE
    HG-HostFile -search domain.com
    
    .EXAMPLE
    HG-HostFile -remove domain.com
    
    .EXAMPLE
    HG_HostFile -level all
	#>
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]  
          [string]$DomainName=$_,
          [string]$level=$_,
          [string]$search=$_,
          [string]$remove=$_)
    BEGIN{}
    
    PROCESS{
		if((gc $HostFilePath | Select -Last 1) -ne ""){
            Add-Content $HostFilePath "`r"
		}#Check the last line to see if its blank. If not, add a new line
        if(($DomainName -ne "") -and ($level -eq "")){AddEntry $DomainName} #If user enters Update-Host domain.com
        elseif($level -eq "all"){AddAll} #If user enters Update-Host -level all
        elseif($remove -ne ""){RemoveEntry $remove}
        elseif($search -ne ""){SearchEntry $search}
        else{
            $action = Read-Host "Please select from one of the following:`n [a]ll [d]omain [q]uit"
            switch($action){
                a{AddAll}
                all{AddAll}
                d{
					$DomainName = Read-Host "Enter the domain name"
					AddEntry $DomainName
				}
                domain{
					$DomainName = Read-Host "Enter the domain name"
					AddEntry $DomainName
				}
                q{
                    Write-Host "Exiting script!" 
                    return
                }
                quit{
                    Write-Host "Exiting script!" 
                    return
                }
                default{
                    Write-Host "No action specified. Exiting script!" 
                    return
                }
            }
        } #If user doesn't specify what to do initially, they will be presented with these options.
        Clean_Up_File
    }
    END{}
}
function RemoveEntry{
	[CmdletBinding()]
	param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		  [string]$DomainName = $_)
	Begin{}
    
	PROCESS{
        if($DomainName -ne (QueryPSA("select name from domains where name='$DomainName'"))){
            Write-Host "Sorry I cannot remove this domain from the hosts file. It does not exist in the PSA."
            return
        }
        else{
            foreach($line in (gc $HostFilePath)){
			    if(!($line.contains("$DomainName"))){
				    Add-Content $HostFileNew $line
			    }
		    }
		    Remove-Item $HostFilePath
		    Rename-Item $HostFileNew $HostFilePath
            Clean_Up_File
            Write-Host "Successfully removed the entry!"
        }
	}
	END{}
}
##### VANDERMARK HG-HostFile END ###### 

Function FarmPush {
	param(
		$Server = @("PSS001", "PSS002", "PSS003", "PSS004", "PSS005", "PSS006", "PSS007", "PSS008", "PSS009", "PSS010", "PSS011", "PSS012", "PSS013", "PSS014", "PSS015", "PSS016", "STAFF"),
		$File="",
		$Command="",
		[int]$Sleep=0
	)
	
	$IPs = @()	
	$Credentials = Get-Credential
	
	ForEach ($Server in $Server) {
		$ToIP = [System.Net.Dns]::GetHostAddresses("$Server.win.hostgator.com") | Select-Object IPAddressToString -ExpandProperty IPAddressToString
		$IPs += $ToIP
	}
	
	ForEach ($IP in $IPs) {
		if ($File -ne "") {
			if (Test-Path $File) {
				$Dummy = Invoke-Command -ComputerName $IP -credential $Credentials -AsJob -FilePath $File
			}
			else {
				Write-Host "The powershell file you specified did not exist. Exiting..."
				return
			}
		}
		elseif ($Command -ne "") {
			$Dummy = Invoke-Command -ComputerName $IP -credential $Credentials -InputObject $Command -AsJob -ScriptBlock {
				Invoke-Expression $input
			}
		}
	}
	
	$num = 1
	DO {
		if ($Sleep -eq 0) {
			Start-Sleep 3
			Write-Host "Waiting for jobs to complete... ($($num * 3) seconds have passed)"
            $num++
		}
		else {
			Write-Host "Waiting for jobs to complete... ($num minute(s))"
			Start-Sleep ($Sleep * 60)
			$num++
		}
	}
	UNTIL (@(Get-Job -state Running).count -eq 0)

	Get-Job | Receive-Job
	Get-Job | Remove-Job
}

##### VANDERSCRIPTS HG-GETPASSWORDS START #####
function GetClientPassword{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
          [string]$client=$_)
    
    BEGIN{}
    PROCESS{
        $acctPrimary = QueryPSA("select login,passwd from clients where login='$client'")
        if($acctPrimary -eq $Null){
            $subAcct = QueryPSA("select login,password from smb_users where login like '$client%'")
            if($subAcct -eq $Null){
                Write-Host "Cannot find client. Please try again"
                Return
            }
            else{
                $password = ($subAcct.split(",")[1]).trim()
                $password = [System.Convert]::FromBase64String($password)
                $password = [System.Text.Encoding]::UTF8.GetString($password)
                Write-Host "`tUsername:"$subAcct.split(",")[0]"password:"$password
            }    
        }
        else{
            Write-Host "`n`tUsername: $($acctPrimary.split(",")[0]) `n`tPassword: $($acctPrimary.split(",")[1])"
        }
    }
    END{}
}
function GetFTPPasswords{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
          [string]$ftp=$_)
    
    BEGIN{}
    PROCESS{
        $line = QueryPSA("select sys_users.login , accounts.password from accounts right join sys_users on accounts.id = sys_users.account_id where sys_users.login='$ftp'")
        if($line -eq $Null){
            Write-Host "Sorry I could not locate the account you were looking for"
        }
        else{Write-Host "`n`tUsername: $($line.split(",")[0]) `n`tPassword: $($line.split(",")[1])"}
    }
    END{}
}
function GetMailPasswords{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
          [string]$mail = $_)
    
    BEGIN{}
    PROCESS{
        $account = QueryPSA("select concat(mail.mail_name,'@',domains.name),accounts.password from mail,domains,accounts where domains.id=mail.dom_id and accounts.id=mail.account_id and concat(mail.mail_name,'@',domains.name)='$mail'")
        if($mail -eq ($account.split(",")[0])){
            Write-Host "`n`tEmail Account: $($account.split(",")[0]) `n`tEmail Password: $($account.split(",")[1])"
        }
        else{Write-Host "`nSorry I could not locate the account(s) requested."}
    }
    END{}
}
function GetDatabasePasswords{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
          [string]$dbname = $_)
    
    BEGIN{}
    PROCESS{
        $db_info = QueryPSA("select data_bases.name,db_users.login,accounts.password,data_bases.type from data_bases,db_users,accounts where data_bases.id=db_users.db_id and accounts.id=db_users.account_id and data_bases.name='$dbname'")
        if($db_info -eq $Null){
            Write-Host "Sorry I could not find the database(s) requested or there was no Username/Password associated with $dbname."
        }
        else{
            foreach($line in $db_info){
                Write-Host "`tDBName: $($line.split(",")[0]) `n`tDBType: $($line.split(",")[3]) `n`tDBUser: $($line.split(",")[1]) `n`tDBPass: $($line.split(",")[2])`n"
            }
        }
    }
    END{}
}
function GetDBUser{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
          [string]$dbuser = $_)
    
    BEGIN{}
    PROCESS{
        Write-Host "`tPassword: $(QueryPSA("select passwd from db_users where login='$dbuser'"))"
    }
    END{}
}
function GetProtectedDirs{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
          [string]$domain=$_)
          
    BEGIN{}
    PROCESS{
        foreach($line in (QueryPSA("select concat(hosting.www_root,'\\',protected_dirs.path),pd_users.login,accounts.password,protected_dirs.path from protected_dirs join pd_users on pd_users.pd_id = protected_dirs.id join accounts on pd_users.account_id = accounts.id join domains on domains.id = protected_dirs.dom_id join hosting on hosting.dom_id=domains.id where domains.name='$domain'"))){
            if($line -eq $Null){
                Write-Host "`n`tSorry I could not find the Protected Directory requested."
            }
            else{Write-Host "`n`tDirectory: $($line.split(",")[0])`n`tLogin: $($line.split(",")[1])`n`tPassword: $($line.split(",")[2])"}
        }
    }
    END{}
}
function HG-GetPasswords{
    <#
	.SYNOPSIS
	This cmdlet will retreive the passwords for the object you specify. E.g. client passwords, ftp passwords, mail passwords, database passwords, protected directory passwords, and even passwords for the entire domain.
	
	.PARAMETER client, ftp, mail, database, protected, domain
	Accepts a string input.
	
	.EXAMPLE
	HG-GetPasswords domain.com
	
	.EXAMPLE
    HG-GetPasswords -ftp ftp_account
    
    .EXAMPLE
    HG-GetPasswords -mail mail_account
	#>
	[CmdletBinding()]
    param(
            [Parameter()]
            [string]$client="",
            [Parameter()]
            [string]$ftp="",
            [Parameter()]
            [string]$mail="",
            [Parameter()]
            [string]$database="",
            [Parameter()]
            [string]$dbuser="",
            [Parameter()]
            [string]$protected,
            [Parameter(Position=0)]
            [string]$domain=""
         )
    BEGIN{}
    PROCESS{
        $count = 0
        if($client -ne ""){
            Write-Host "Getting the client password for $client"
            GetClientPassword $client
        }
        elseif($ftp -ne ""){
            Write-Host "Getting the FTP Password for $ftp"
            GetFTPPasswords $ftp
        }
        elseif($mail -ne ""){
            Write-Host "Getting the password to $mail"
            GetMailPasswords $mail
        }
        elseif($database -ne ""){
            Write-Host "Getting the database username and password for $database"
            GetDatabasePasswords $database
        }
        elseif($dbuser -ne ""){
            Write-Host "Getting the password for Database User $dbuser"
            GetDBUser $dbuser
        }
        elseif($protected -ne ""){
            Write-Host "Getting the protected directories and passwords for $protected"
            GetProtectedDirs $protected
        }
        elseif(($domain -ne "") -and ($domain -eq (QueryPSA("select name from domains where name='$domain'")))){
            $webid = QueryPSA("select webspace_id from domains where name='$domain'")
            if($webid -ne 0){
                Write-Host "I can only find mail passwords for an addon domain"
                Write-Host "============================================================="
                foreach($line in (QueryPSA("select concat_ws('@',mail.mail_name,domains.name) from mail,domains,accounts where domains.id=mail.dom_id and accounts.id=mail.account_id and domains.name='$domain'"))){
                    if($line -ne $Null){
                        GetMailPasswords $line
                    }
                    else{Write-Host "There are no email accounts configured for $domain"}
                }
                $domain = QueryPSA("select name from domains where id=$webid")
                Write-Host "The rest of the passwords belong to $domain"
            }
            Write-Host "`nGetting all passwords associated with $domain"
            Write-Host "============================================================="
            Write-Host "Client password(s) is/are:"
            foreach($line in (QueryPSA("select smb_users.login from smb_users,domains join clients on smb_users.ownerId=clients.id and domains.cl_id=clients.id where domains.name='$domain'"))){
                if($line -ne $Null){
                    GetClientPassword $line
                }
                else{Write-Host "This domain does not have any FTP Accounts associated with this domain"}
            }
            Write-Host "============================================================="
            Write-Host "The FTP account(s)/password(s) are:"
            foreach($line in (QueryPSA("select login from sys_users where home like '%$domain'"))){
                if($line -ne $Null){
                    GetFTPPasswords $line
                }
                else{Write-Host "There are no FTP Accounts associated with this domain."}
            }
            Write-Host "============================================================="
            Write-Host "The email password(s) are:"
            foreach($line in (QueryPSA("select concat_ws('@',mail.mail_name,domains.name) from mail,domains,accounts where domains.id=mail.dom_id and accounts.id=mail.account_id and domains.name='$domain'"))){
                if($line -ne $Null){
                    GetMailPasswords $line
                }
                else{Write-Host "There are no email accounts configured for $domain"}
            }
            Write-Host "============================================================="
            Write-Host "The database name(s)login(s), password(s), and type(s) are:"
            foreach($line in (QueryPSA("select data_bases.name from data_bases,domains where data_bases.dom_id=domains.id and domains.name='$domain'"))){
                if($line -ne $Null){
                    $count++
                    Write-Host "`nDatabase"$count":"
                    GetDatabasePasswords $line
                }
                else{Write-Host "There are no databases associated with $domain"}
            }
            Write-Host "============================================================="
            Write-Host "The protected path(s), login(s), & password(s) are:"
            GetProtectedDirs $domain
        }
        else{Write-Host "I do not have enough information to get any passwords. Please try again."}
    }
    END{}
}
##### VANDERSCRIPTS HG-GETPASSWORDS STOP #####


##### VANDERSCRIPTS HG-ENABLEASPERRORS #######
function ValidateDomain{
    param([string]$domain=$_)
    
    Set-Variable -Scope Global -Value $domain -Name DomainTemp
    
    if(!(QueryPSA("select name from domains where name='$domain'"))){
        $domain = Read-Host "The domain entered is not valid. Please try again: "
        ValidateDomain $domain
    }
    elseif((QueryPSA("select webspace_id from domains where name='$domain'")) -ne 0){
        $domain = QueryPSA("select name from domains where id=(select webspace_id from domains where name='$domain')")
        Write-Host "You entered an addon domain. The actual domain should be $domain"
        Return $domain
    }
    else{
        Return $domain
    }
}

function HG-EnableASPErrors{
    <#
    .SYNOPSIS
    This cmdlet will copy the 500-100.asp error page to the correct directory, and configure IIS to use it.
        
    .PARAMETER domain
    Accepts a string input.
        
    .EXAMPLE
    HG-EnableASPErrors domain.com
    #>
    
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]
          [string]$domain=""
         )
         
    BEGIN{
        $scriptPath = "\\tsclient\Z\scripts\500-100.asp"
        $domain = ValidateDomain $domain
        $domainPath = QueryPSA("select hosting.www_root from hosting,domains where hosting.dom_id=domains.id and domains.name='$domain'")
        $domainPath = $domainPath.TrimEnd("\httpdocs")+"\error_docs"
        $domain = (Get-Variable -Scope Global -Name DomainTemp).Value
    }
    
    PROCESS{
        if(Test-Path "$domainPath\500-100.asp"){
            Write-Host "Renaming current 500.100 ASP Error Page"
            Move-Item "$domainPath\500-100.asp" "$domainPath\500-100_bak.asp" -Force
        }
        Copy-Item $scriptPath $domainPath
        if(!(Test-Path "$domainPath\500-100.asp")){
            Write-Host "File copy failed. Please manually copy the 500-100.asp to $domainPath" -BackgroundColor Red -ForegroundColor White
        }
        else{Write-Host "SUCCESS 500-100.asp exists in $domainPath"}
        if (Test-Path iis:\sites\$Domain) {
            Push-Location $env:windir\system32\inetsrv
                $ReturnMsg = .\appcmd.exe set config "$domain" -section:system.webServer/httpErrors /-"[statusCode='500',subStatusCode='100']"
                if ($ReturnMsg.substring(0,5) -ne 'ERROR') {
                    $ReturnMsg
                }
                .\appcmd.exe set config "$domain" -section:system.webServer/httpErrors /+"[statusCode='500',subStatusCode='100',path='/error_docs/500-100.asp',responseMode='ExecuteURL']" 
            Pop-Location
        }
    }
    
    END{}
}
##### VANDERSCRIPTS HG-ENABLEASPERRORS STOP ##

Function GetActiveAccounts {
    param(
        $Server = @("PSS001", "PSS002", "PSS003", "PSS004", "PSS005", "PSS006", "PSS007", "PSS008", "PSS009", "PSS010", "PSS011", "PSS012", "PSS013", "PSS014", "PSS015", "PSS016")
    )

    $IPs = @()	
	$Credentials = Get-Credential
	
	ForEach ($Server in $Server) {
		$ToIP = [System.Net.Dns]::GetHostAddresses("$Server.win.hostgator.com") | Select-Object IPAddressToString -ExpandProperty IPAddressToString
		$IPs += $ToIP
	}

    ForEach ($IP in $IPs) {
		$Dummy = Invoke-Command -ComputerName $IP -credential $Credentials -AsJob -ScriptBlock {
			Import-Module GatorCommands -DisableNameChecking
            $Clients = QueryPSA "SELECT count(id) FROM clients WHERE status = 0"
            $Subscriptions = QueryPSA "SELECT count(id) FROM domains WHERE webspace_id = 0 AND parentdomainid = 0 AND status = 0"
            $AddOnDomains = QueryPSA "SELECT count(id) FROM domains WHERE webspace_id != 0 AND parentdomainid = 0 AND status = 0"
            $SubDomains = QueryPSA "SELECT count(id) FROM domains WHERE webspace_id != 0 AND parentdomainid != 0 AND status = 0"
            $PersonalPlanID = QueryPSA "SELECT id FROM templates WHERE name = 'Personal' AND type = 'domain' AND owner_id = 1" 
            $EnterprisePlanID = QueryPSA "SELECT id FROM templates WHERE name = 'Enterprise' AND type = 'domain' AND owner_id = 1"
            $PersonalPlans = QueryPSA "SELECT count(domains.id) FROM domains, subscriptions, planssubscriptions WHERE planssubscriptions.plan_id = $PersonalPlanID AND planssubscriptions.subscription_id = subscriptions.id AND domains.id = subscriptions.object_id AND domains.status = 0"
            $EnterprisePlans = QueryPSA "SELECT count(domains.id) FROM domains, subscriptions, planssubscriptions WHERE planssubscriptions.plan_id = $EnterprisePlanID AND planssubscriptions.subscription_id = subscriptions.id AND domains.id = subscriptions.object_id AND domains.status = 0"
            $WinDetails = Get-WmiObject -Class Win32_OperatingSystem
            $processors = Get-WmiObject win32_processor | foreach {$_.LoadPercentage}
            $totalcpu = 0
            ForEach ($CPU in $Processors) {
	            $totalCPU = ($totalCPU + $CPU)
            }
            $CPUTotal = ($totalCPU / $processors.count)
            $FreeRam = [System.Math]::Round((($WinDetails.FreePhysicalMemory)/ 1024), 0)

            Write-Host "$((Get-WmiObject Win32_Computersystem).Name) `n$('-' * 30)"
            Write-Host "Active Clients: $Clients"
            Write-Host "Active Subscriptions: $Subscriptions"
            Write-Host "Active Add-On Domains: $AddOnDomains"
            Write-Host "Active Sub-Domains: $SubDomains `n"
            Write-Host "Active Personal Subscriptions: $PersonalPlans"
            Write-Host "Active Enterprise Subscriptions: $EnterprisePlans `n"
            Write-Host "CPU Usage: $CPUTotal%"
            Write-Host "Available Ram: $FreeRam `n`n`n`n`n"

            $results = @{}
            $results.Add('clients',$Clients)
            $results.Add('subscriptions',$Subscriptions)
            $results.Add('addondomains',$AddOnDomains)
            $results.Add('subdomains',$Subdomains)
            $results.Add('personalplans',$PersonalPlans)
            $results.Add('enterpriseplans',$EnterprisePlans)
            Return $results
		}
    }

    $num = 1
	DO {
		Start-Sleep 3
        Write-Host "Waiting for jobs to complete... ($($num * 3) seconds have passed)"
        $num++
	}
	UNTIL (@(Get-Job -state Running).count -eq 0)

    $LocalResults = @{'clients'=0;'subscriptions'=0;'addondomains'=0;'subdomains'=0;'personalplans'=0;'enterpriseplans'=0}
    ForEach ($JobID in (Get-Job | Select -ExpandProperty id)) {
        $JobResults = Receive-Job $JobID
        Remove-Job $JobID
        ForEach ($Key in $JobResults.Keys) {
            [int]$LocalValue = $LocalResults.Get_Item($Key)
            [int]$RemoteValue = $JobResults.Get_Item($Key)
            [int]$NewValue = ($LocalValue + $RemoteValue)
            $LocalResults.Set_Item($Key,$NewValue)
        }
    }
    
    Write-Host "All Servers Combined `n$('-' * 30)"
    Write-Host "Total Clients: $($LocalResults.Get_Item('clients'))"
    Write-Host "Total Subscriptions: $($LocalResults.Get_Item('subScriptions'))"
    Write-Host "Total AddOnDomains: $($LocalResults.Get_Item('addondomains'))"
    Write-Host "Total Sub-Domains: $($LocalResults.Get_Item('subdomains'))"
    Write-Host "Total Personal Plans: $($LocalResults.Get_Item('personalplans'))"
    Write-Host "Total Enterprise Plans: $($LocalResults.Get_Item('enterpriseplans')) `n`n`n`n`n"
}