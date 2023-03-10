@echo off & setLocal EnableDelayedExpansion

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

:: PIA installation path PrivateInternetAccess VPN
set PIA_path="C:\Program Files\Private Internet Access\piactl.exe"

:: PIA settings file path
set PIA_settings_json_path="C:\Program Files\Private Internet Access\data\settings.json"

:: The settings below will be enforced if you enable this
:: 1 enabled
:: 0 or empty is disabled
set PIA_custom_settings=1

::PIA username
set PIA_username=""

::PIA password
set PIA_password=""

:: PIA kill switch
:: auto vpn kill switch only while vpn is turned on if you turn vpn off obviously leaks will occur
:: on maximum preventing leaks from going outside the vpn even when the vpn is turned off
:: off no kill switch active
set PIA_killswitch=on

:: PIA MACE adblocking dns service
:: true enabled
:: false disabled
set PIA_enableMACE=false

:: openvpn
:: wireguard
set PIA_vpn_protocol=wireguard

:: Allow local lan traffic
:: true enabled
:: false disabled
set PIA_allowlan=true

:: PIA background daemon to keep VPN active even without GUI running
set PIA_background_daemon=enable

::Check for port change every 60 seconds if the port changes we will set the port as the new vpn portforward
set port_recheck_time=60

::prevent being auto logged out by session expired on long running vpn times always stay logged in
set session_expires=3600

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

if "%~1"=="" goto :script_arguments_not_defined
set PIA_username=%~1
set PIA_password=%~2
:script_arguments_not_defined

color 0A
%*
TITLE C0nw0nk - Automatic - PrivateInternetAccess PortForward

:start
net session >nul 2>&1
if %errorlevel% == 0 (
goto :admin
) else (
@pushd "%~dp0" & fltmc | find ^".^" && (powershell start '%~f0' ' %*' -verb runas 2>nul && exit /b)
)
goto :start
:admin

:start_loop
if "%~1"=="" (
start /wait /B "" "%~dp0%~nx0" go 2^>Nul
) else (
goto begin
)
goto start_loop
:begin

set root_path="%~dp0"
:: usage %root_path:"=%

::start remove last folder
set "remove_last_folder=%root_path:"=%"
::remove last back slash
set "remove_last_folder=%remove_last_folder:~0,-1%"
::last folder into var
set "last1=%remove_last_folder:\=" & set "lastfolder1=%"
::remove last folder from var
set root_path_no_last_folder="!remove_last_folder:%lastfolder1%=!"
::end remove last folder

set vbs_script=\time1.vbs
del %temp%%vbs_script% 2>nul
echo WScript.Echo(DateDiff("s", "01/01/1970 00:00:00", Now())) > %temp%%vbs_script%

if not exist %PIA_path% goto :PIA_not_installed

if [%PIA_custom_settings%]==[1] ( goto :update_pia_settings ) else ( goto :skip_pia_settings )

:update_pia_settings

(
echo %PIA_username:"=%
echo %PIA_password:"=%
)>"%TEMP%\piafile"
::login to PIA
%PIA_path% login "%TEMP%\piafile" 2^>nul

set PIA_settings_json="%TEMP%\new_settings.json"

for /f "tokens=*" %%a in ('
%PIA_path% get protocol 2^>nul
') do (
	if /I %%a == openvpn (
		%PIA_path% ^set protocol %PIA_vpn_protocol%
	)
)

for /f "tokens=*" %%a in ('
%PIA_path% get allowlan 2^>nul
') do (
	if /I %%a == false (
		%PIA_path% ^set allowlan %PIA_allowlan%
	)
)

%PIA_path% ^background %PIA_background_daemon%

del %PIA_settings_json% >nul
for /F "tokens=1* delims=:" %%A in ('call %PIA_path% -u dump daemon-settings') do (
	if /I %%A == ^{ (
			echo %%A>>%PIA_settings_json%
		) else (
			if /I %%A == ^} (
				echo %%A>>%PIA_settings_json%
			) else (
				if /I %%A == ^ ^ ^ ^ ^"killswitch^" (
					echo %%A: "%PIA_killswitch%",>>%PIA_settings_json%
				) else (
					if /I %%A == ^ ^ ^ ^ ^"enableMACE^" (
						echo %%A: %PIA_enableMACE%,>>%PIA_settings_json%
					) else (
						if /I %%A == ^ ^ ^ ^ ^]^, (
							echo %%A>>%PIA_settings_json%
						) else (
							if /I %%A == ^ ^ ^ ^ ^}^, (
								echo %%A>>%PIA_settings_json%
							) else (
								if /I %%A == ^ ^ ^ ^ ^ ^ ^ ^ ^]^, (
									echo %%A>>%PIA_settings_json%
								) else (
									if /I %%A == ^ ^ ^ ^ ^ ^ ^ ^ ^ ^}^, (
										echo %%A>>%PIA_settings_json%
									) else (
										if /I %%A == ^ ^ ^ ^ ^ ^ ^ ^ ^] (
											echo %%A>>%PIA_settings_json%
										) else (
											if /I %%A == ^ ^ ^ ^ ^ ^ ^ ^ ^ ^} (
												echo %%A>>%PIA_settings_json%
											) else (
												echo %%A:%%B | FIND /I ",:" >Nul && (
													echo %%A>>%PIA_settings_json%
												) || (
													echo %%A:%%B^" | FIND /I """:""" >Nul && (
														echo %%A>>%PIA_settings_json%
													) || (
														echo %%A:%%B>>%PIA_settings_json%
													)
												)
											)
										)
									)
								)
							)
						)
					)
				)
			)
		)
	)
)

copy /Y %PIA_settings_json% %PIA_settings_json_path% >nul

:: Service modification to restart automatically if it crashes and instantly at boot
set servicename_wire=PrivateInternetAccessWireguard
net stop %servicename_wire% /y >nul
:: Wireguard service
SC Failure %servicename_wire% actions=restart/0/restart/0/restart/0// reset=0 >nul
SC config %servicename_wire% start=auto >nul
SC config %servicename_wire% depend=PrivateInternetAccessService >nul

set servicename=PrivateInternetAccessService
:: PIA service
SC Failure %servicename% actions=restart/0/restart/0/restart/0// reset=0 >nul
SC config %servicename% start=auto >nul

::powershell -command "Restart-Service %servicename% -Force"
net stop %servicename% /y >nul
net start %servicename% /y >nul

%PIA_path% disconnect
%PIA_path% set region auto
%PIA_path% connect

:skip_pia_settings

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
echo Random Country to connect to : "%random_country%"
if defined connect_new (
	%PIA_path% ^set region %random_country%
	%PIA_path% connect
	timeout /t %connection_time% >nul
)

for /f "tokens=*" %%a in ('
%PIA_path% get requestportforward 2^>nul
') do (
	if /I %%a == false (
		%PIA_path% ^set requestportforward true
		%PIA_path% ^set region %random_country%
		%PIA_path% connect
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
set "peer-port=%portforward%"
echo Currently forwarding Port : "%portforward%"
timeout /t %connection_time% >nul

if defined old_peer_port (goto :checkme) else (goto :next_stage)

:checkme

:: session logout fix
set vbs_script=\time1.vbs
echo WScript.Echo(DateDiff("s", "01/01/1970 00:00:00", Now())) > %temp%%vbs_script%
for /f "tokens=*" %%a in ('cscript //nologo %temp%%vbs_script%') do set /a current_time=%%a && if not defined origin_time set /a origin_time=!current_time: =! && set /a session_renew_time=!origin_time!+%session_expires%
if !current_time! GTR !session_renew_time! (
	echo session expired running login to refresh session
	set origin_time=
(
echo %PIA_username:"=%
echo %PIA_password:"=%
)>"%TEMP%\piafile"
::login to PIA
%PIA_path% login "%TEMP%\piafile" 2^>nul
)
:: session logout fix

if /I "%old_peer_port%" == "%peer-port%" (
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
	if /I "%old_peer_port%" == "%peer-port%" (
		echo unchanged port going to recheck again in "%port_recheck_time%" seconds
		timeout /t %port_recheck_time%
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
for /f %%a in ('
%PIA_path% get vpnip 2^>nul
') do (
set "vpn_ip=%%a"
)
if "%old_vpn_ip%" == "%vpn_ip%" (
	echo no change in vpn ip old "%old_vpn_ip%" new "%vpn_ip%"

	goto :recheck_vpn_ip_address_change_complete
) else (
	echo vpn ip has changed old ip was "%old_vpn_ip%" new ip is "%vpn_ip%"

	goto :next_stage
)

:next_stage
if not defined old_vpn_ip (
	set old_vpn_ip=null
	goto :recheck_vpn_ip_address_change
)
:: Start your code here that you want to run when port or ip does change

:: code to check if our ip assigned by vpn is in a blacklist
:: if our ip is blacklisted get a new one
if exist "%root_path_no_last_folder:"=%dig\dig.cmd" (
	set dig_output=
	for /f %%a in ('call %root_path_no_last_folder:"=%dig\dig.cmd') do set "dig_output=%%a"
	if "!dig_output!" == "null" (set connect_new= && break) else (echo dig output !dig_output! get new ip && set connect_new=true && goto :random_country)
	echo blacklist checks complete not in blacklists
)

:: code to update ssl if you want to use it
if exist "%root_path_no_last_folder:"=%openssl\openssl.cmd" (
	set dig_output=
	for /f %%a in ('call %root_path_no_last_folder:"=%openssl\openssl.cmd') do set "dig_output=%%a"
)

:: update dns if you want example
:: https://github.com/C0nw0nk/Cloudflare-my-ip
if exist "%root_path_no_last_folder:"=%dns\cloudflare.cmd" (
	"%root_path_no_last_folder:"=%dns\cloudflare.cmd" "APIKEY" "zone_name" "dns_record" "v^=DMARC1^;^ p^=quarantine" "TXT" "0" "%root_path_no_last_folder:"=%dig\curl.exe" 2^>nul
)

::stuff here for updates to dns programs etc


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
