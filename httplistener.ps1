[string]$Head = @"
<title>Greetings!</title>
<style type="text/css">
table.gridtable {
	font-family: verdana,arial,sans-serif;
	font-size:11px;
	color:#333333;
	border-width: 1px;
	border-color: #666666;
	border-collapse: collapse;
}
table.gridtable th {
	border-width: 1px;
	padding: 8px;
	border-style: solid;
	border-color: #666666;
	background-color: #dedede;
}
table.gridtable td {
	border-width: 1px;
	padding: 8px;
	border-style: solid;
	border-color: #666666;
	background-color: #ffffff;
}
</style>

"@


param($Plesk='Not Installed')
$Plesk = (gc "C:\Program Files (x86)\Parallels\Plesk\version" -ErrorAction SilentlyContinue).Split()[0]
$WindowsVersion =  (Get-WmiObject -class Win32_OperatingSystem).Caption

$myObject = New-Object PSObject -Property @{
    Plesk = $Plesk
    Windows = $WindowsVersion
} | ConvertTo-Html -Head $Head | ForEach {$_.Replace('<table>','<table class="gridtable">')}

[void] [Reflection.Assembly]::LoadWithPartialName('System.Net')

$myListner = New-Object Net.HttpListener
$myListner.Prefixes.Add('http://dedi.zdeg.com:12345/')
$myListner.Start()

[Net.HttpListenerContext]$Context = $myListner.GetContext()
[Net.HttpListenerRequest]$Resquest = $Context.Request

[Net.HttpListenerResponse]$Response = $Context.Response
[string]$myResponse = $myObject

[Byte[]]$myBuffer = [System.Text.Encoding]::UTF8.GetBytes($myResponse)

$Response.ContentLength64 = $myBuffer.Length

[System.IO.Stream]$Output = $Response.OutputStream
$Output.Write($myBuffer, 0, $myBuffer.Length)
$Output.Close()

$myListner.Stop()