#Remove Old Rules
		netsh advfirewall firewall delete rule all
		netsh advfirewall firewall add rule name="Remote Desktop" enable=yes dir=in profile=any protocol=TCP localport="3389" action=allow

		#Allow Inbound Rules
		netsh advfirewall firewall add rule name="DNS TCP" enable=yes dir=in profile=any protocol=TCP localport=53 action=allow
		netsh advfirewall firewall add rule name="DNS UDP" enable=yes dir=in profile=any protocol=UDP localport=53 action=allow
		netsh advfirewall firewall add rule name="FTP" enable=yes dir=in profile=any protocol=TCP localport="20,21" action=allow
		netsh advfirewall firewall add rule name="FTP-PASSIVE" enable=yes dir=in profile=any protocol=TCP localport="49152-65535" action=allow
		netsh advfirewall firewall add rule name="HTTP" enable=yes dir=in profile=any protocol=TCP localport="80,443" action=allow
		netsh advfirewall firewall add rule name="ICMPv4" enable=yes dir=in profile=any protocol=ICMPv4 action=allow
		netsh advfirewall firewall add rule name="ICMPv6" enable=yes dir=in profile=any protocol=ICMPv6 action=allow
		netsh advfirewall firewall add rule name="IMAP" enable=yes dir=in profile=any protocol=TCP localport="143,993" action=allow
		netsh advfirewall firewall add rule name="KMS" enable=yes dir=in profile=any protocol=TCP localport=1688 action=allow program="%SystemRoot%\system32\sppsvc.exe"
		netsh advfirewall firewall add rule name="MSSQL Server" enable=yes dir=in profile=any protocol=TCP localport="1433,1434" action=allow remoteip="216.110.94.0/24"
		netsh advfirewall firewall add rule name="MySQL Server" enable=yes dir=in profile=any protocol=TCP localport=3306 action=allow remoteip="216.110.94.0/24"
		netsh advfirewall firewall add rule name="Plesk Control Panel" enable=yes dir=in profile=any protocol=TCP localport=8443 action=allow
		netsh advfirewall firewall add rule name="Plesk Internal Database Server" enable=yes dir=in profile=any protocol=TCP localport=8306 action=allow remoteip="216.110.94.0/24"
		netsh advfirewall firewall add rule name="Plesk Newsfeeds" enable=yes dir=in profile=any protocol=TCP localport=8880 action=allow
		netsh advfirewall firewall add rule name="POP3" enable=yes dir=in profile=any protocol=TCP localport="110,995" action=allow
		netsh advfirewall firewall add rule name="SmarterMail" enable=yes dir=in profile=any protocol=TCP localport="9998" action=allow
		netsh advfirewall firewall add rule name="SMTP" enable=yes dir=in profile=any protocol=TCP localport="25,26,465" action=allow
		netsh advfirewall firewall add rule name="Whitelist" enable=yes dir=in profile=any action=allow remoteip="12.96.160.0/24,66.98.240.192/26,67.18.139.0/24,67.19.0.0/24,70.84.160.0/24,70.85.125.0/24,70.87.253.252/32,75.125.126.8/32,76.30.227.23/32,98.196.11.42/32,99.53.101.126/32,174.121.231.232/32,209.85.4.0/24,216.12.193.9/32,216.40.193.0/24,216.110.94.0/24,216.234.234.0/24"
		
		#Block Inbound Rules
		netsh advfirewall firewall add rule name="File and Printer Sharing (LLMNR-UDP-In)" enable=yes dir=in profile=any protocol=UDP localport=5355 action=block program="%SystemRoot%\system32\svchost.exe"
		netsh advfirewall firewall add rule name="File and Printer Sharing (Spooler Service - RPC-EPMAP)" enable=yes dir=in profile=any protocol=TCP localport=RPC-EPMap action=block
		netsh advfirewall firewall add rule name="File and Printer Sharing (Spooler Service - RPC)" enable=yes dir=in profile=any protocol=TCP localport=RPC action=block program="%SystemRoot%\system32\spoolsv.exe"
		netsh advfirewall firewall add rule name="File and Printer Sharing (NB-Datagram-In)" enable=yes dir=in profile=any protocol=UDP localport=138 action=block program="System"
		netsh advfirewall firewall add rule name="File and Printer Sharing (NB-Name-In)" enable=yes dir=in profile=any protocol=UDP localport=137 action=block program="System"
		netsh advfirewall firewall add rule name="File and Printer Sharing (SMB-In)" enable=yes dir=in profile=any protocol=TCP localport=445 action=block program="System"
		netsh advfirewall firewall add rule name="File and Printer Sharing (NB-Session-In)" enable=yes dir=in profile=any protocol=TCP localport=139 action=block program="System"
		netsh advfirewall firewall add rule name="BLACKLIST_IN" enable=yes dir=in profile=any protocol=any action=block remoteip="9.9.9.9/32"
		netsh advfirewall firewall add rule name="Remote Administration (RPC-EPMAP)" enable=yes dir=in profile=any protocol=TCP localport=RPC-EPMap action=block program="%SystemRoot%\system32\svchost.exe"
		netsh advfirewall firewall add rule name="Remote Administration (NP-In)" enable=yes dir=in profile=any protocol=TCP localport=445 action=block program="System"
		netsh advfirewall firewall add rule name="Remote Administration (RPC)" enable=yes dir=in profile=any protocol=TCP localport=RPC action=block program="%SystemRoot%\system32\svchost.exe"
		
		#Block Outbound Rules
		netsh advfirewall firewall add rule name="File and Printer Sharing (LLMNR-UDP-Out)" enable=yes dir=out profile=any protocol=UDP remoteport=5355 action=block program="%SystemRoot%\system32\svchost.exe"
		netsh advfirewall firewall add rule name="File and Printer Sharing (NB-Datagram-Out)" enable=yes dir=out profile=any protocol=UDP remoteport=138 action=block program="System"
		netsh advfirewall firewall add rule name="File and Printer Sharing (NB-Name-Out)" enable=yes dir=out profile=any protocol=UDP remoteport=137 action=block program="System"
		netsh advfirewall firewall add rule name="File and Printer Sharing (SMB-Out)" enable=yes dir=out profile=any protocol=TCP remoteport=445 action=block program="System"
		netsh advfirewall firewall add rule name="File and Printer Sharing (NB-Session-Out)" enable=yes dir=out profile=any protocol=TCP remoteport=139 action=block program="System"
		netsh advfirewall firewall add rule name="BLACKLIST_OUT" enable=yes dir=out profile=any protocol=any action=block remoteip="9.9.9.9/32"