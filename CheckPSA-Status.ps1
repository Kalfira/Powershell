Function CheckPSA-Status {
    param([string]$Query = (Read-Host "What query do you want to run?"))
    Write-Host "Domains:"
    querypsa "select displayname,status from domains where displayname = '$Query'"
    }