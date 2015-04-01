$length = 10
$characters = 'abcdefghkmnprstuvwxyzABCDEFGHKLMNPRSTUVWXYZ123456789!%&/=?*+#_'
# select random characters
$random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
# output random pwd
$private:ofs=""
$pw = [String]$characters[$random]
while (($pw -notmatch '\W') -and ($pw -notmatch '[A-Z]') -and ($pw -notmatch '[a-z]') -and ($pw -notmatch '\d'))
{
	Write-Host "$pw trying again"
	$random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
	$pw = [String]$characters[$random]
}
$pw