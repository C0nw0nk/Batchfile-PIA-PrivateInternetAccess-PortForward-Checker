@ECHO OFF & setLocal EnableDelayedExpansion

:: Copyright Conor McKnight
:: https://github.com/C0nw0nk/Batchfile-PIA-PrivateInternetAccess-PortForward-Checker
:: https://www.facebook.com/C0nw0nk

:: To run this Automatically open command prompt RUN COMMAND PROMPT AS ADMINISTRATOR and use the following command
:: SCHTASKS /CREATE /SC HOURLY /TN "Cons PIA Port Forward Checking Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\pia_port_check\pia_port_check.cmd"

:: Script Settings

:: IF you like my work please consider helping me keep making things like this
:: DONATE! The same as buying me a beer or a cup of tea/coffee :D <3
:: PayPal : https://paypal.me/wimbledonfc
:: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZH9PFY62YSD7U&source=url
:: Crypto Currency wallets :
:: BTC BITCOIN : 3A7dMi552o3UBzwzdzqFQ9cTU1tcYazaA1
:: ETH ETHEREUM : 0xeD82e64437D0b706a55c3CeA7d116407E43d7257
:: SHIB SHIBA INU : 0x39443a61368D4208775Fd67913358c031eA86D59

::PIA installation path PrivateInternetAccess VPN
set PIA_path="C:\Program Files\Private Internet Access\piactl.exe"

::Check for port change every 60 seconds if the port changes we will set the port as the new vpn portforward
set port_recheck_time=60

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

color 0A
%*
TITLE C0nw0nk - Automatic - PrivateInternetAccess PortForward

set root_path="%~dp0"
:: usage %root_path:"=%

if not exist %PIA_path% goto :PIA_not_installed

::5 seconds to wait for vpn to establish connection to perform check on port
set connection_time=10

::Make sure that the temporary files used does not exist already.
del "%TEMP%\regions.txt" 2>nul

for /f "tokens=*" %%a in ('
%PIA_path% get regions 2^>nul
') do (
	if /I %%a == auto (
		break
	) else (
		echo %%a>>"%TEMP%\regions.txt"
	)
)

:random_country

::153 lines of text
set /a rand=%random% %% 153
for /f "tokens=1* delims=:" %%i in ('findstr /n .* "%TEMP%\regions.txt"') do (
if "%%i"=="%rand%" set random_country=%%j
)
echo Random Country to connect to : %random_country%
if defined connect_new (
	%PIA_path% ^set region %random_country%
	%PIA_PATH% connect
	timeout /t %connection_time% >nul
)

for /f "tokens=*" %%a in ('
%PIA_path% get requestportforward 2^>nul
') do (
	if /I %%a == false (
		%PIA_path% ^set requestportforward true
		%PIA_path% ^set region %random_country%
		%PIA_PATH% connect
	)
)
set connect_new=

:recheck_portforward

for /f "tokens=*" %%a in ('
%PIA_path% get portforward 2^>nul
') do (
	if /I %%a == Inactive (
		echo current vpn server does not allow port forward connecting to a different one
		set connect_new=true
		goto :random_country
	)
	if /I %%a == Unavailable (
		echo current vpn server does not allow port forward connecting to a different one
		set connect_new=true
		goto :random_country
	)
	if /I %%a == Failed (
		echo current vpn server does not allow port forward connecting to a different one
		set connect_new=true
		goto :random_country
	)
	if /I %%a == Attempting (
		goto :recheck_portforward
	)
	set portforward=%%a
	set connect_new=
)
set peer-port=%portforward%
echo Currently forwarding Port : %portforward%
timeout /t %connection_time% >nul

if defined old_peer_port (goto :checkme) else (goto :next_stage)
:checkme
if /I %old_peer_port% == %peer-port% (
	echo ports matched unchanged
	goto :recheck_portforward_change
) else (
	echo ports miss match
)

goto :next_stage

:recheck_portforward_change

goto :recheck_vpn_ip_address_change
:recheck_vpn_ip_address_change_complete

echo rechecking difference with ports
if defined old_peer_port (
	if /I %old_peer_port% == %peer-port% (
		echo unchanged port going to recheck again in %port_recheck_time% seconds
		timeout /t %port_recheck_time% >nul
		goto :recheck_portforward
	) else (
		echo port changed modifying settings
		goto :next_stage
	)
)
goto :recheck_portforward_change

goto :next_stage
:recheck_vpn_ip_address_change
echo rechecking vpn ip address
for /f %%a in ('%PIA_PATH% get vpnip') do set "vpn_ip=%%a"
if "%old_vpn_ip%" == "%vpn_ip%" (
	echo no change in vpn ip old %old_vpn_ip% new %vpn_ip%
	goto :recheck_vpn_ip_address_change_complete
) else (
	echo vpn ip has changed old ip was %old_vpn_ip% new ip is %vpn_ip%
	goto :next_stage
)

:next_stage
if not defined old_vpn_ip (
	set old_vpn_ip=null
	goto :recheck_vpn_ip_address_change
)
:: Start your code here that you want to run when port or ip does change


set dig_output=
for /f %%a in ('call %root_path:"=%dig\dig.cmd') do set "dig_output=%%a"
if "!dig_output!" == "null" (set connect_new= && break) else (echo dig output !dig_output! get new ip && set connect_new=true && goto :random_country)
echo blacklist checks complete not in blacklists

::stuff here for updates to dns programs openssl etc


:: End your custom code here
:end_custom_code
set old_vpn_ip=%vpn_ip%
set old_peer_port=%peer-port%
goto :recheck_portforward_change

goto :end
:PIA_not_installed
echo Private Internet Access not installed please install it first and try again.
pause
goto :end
:end

exit /b
