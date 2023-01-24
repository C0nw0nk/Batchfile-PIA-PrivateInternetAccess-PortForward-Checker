@echo off & setLocal EnableDelayedExpansion
TITLE github.com/C0nw0nk/Cloudflare-my-ip - Cloudflare API Batch FILE CMD Script

:: Copyright Conor McKnight
:: https://github.com/C0nw0nk/Cloudflare-my-ip
:: https://www.facebook.com/C0nw0nk

:: To run this Automatically open command prompt RUN COMMAND PROMPT AS ADMINISTRATOR and use the following command
:: SCHTASKS /CREATE /SC HOURLY /TN "Cons Cloudflare API Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\path-to\script\curl.cmd"

:: Edit Cloudflare API Key and Set your own domain details

:: CloudFlare API Key | https://developers.cloudflare.com/api/tokens/create
set cf_api_key=APIKEYHERE!
:: Domain name without subdomains
set zone_name=primarydomain.com
:: DNS record to be modified
set dns_record=localhost.primarydomain.com
:: IP Type :
:: ip_type=0 | Localhost
:: ip_type=1 | Public Internet IP (DEFAULT)
:: ip_type=1.1.1.1 | Custom
:: If you are using custom or text records set them like this
:: ip_type=\"v^=DMARC1^;^ p^=quarantine\"
set ip_type=1
::Type of record we are creating
:: A record
:: TXT record
:: CNAME
set record_type=A
:: If you don't want to add or edit but want to delete a record
:: Default value 0
:: 1 is to delete the provided dns_record
set delete_record=0

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

:: Make script configurable via command line with arguements example
:: "C:\path\curl.cmd" "APIKEY" "zone_name" "dns_record" "ip_type" "record_type" "delete_record" 2^>nul
:: "C:\path\curl.cmd" "APIKEY" "zone_name" "dns_record" "1" "A" "0" "C:\path\curl.exe" :: A record before MX record obviously creation order is essential 2^>nul
:: "C:\path\curl.cmd" "APIKEY" "zone_name" "dns_record" "subdomain here" "MX" "0" "C:\path\curl.exe" 2^>nul
:: "C:\path\curl.cmd" "APIKEY" "zone_name" "dns_record" "1" "A" "0" "C:\path\curl.exe" 2^>nul
:: "C:\path\curl.cmd" "APIKEY" "zone_name" "dns_record" "v^=DMARC1^;^ p^=quarantine" "TXT" "0" "C:\path\curl.exe" 2^>nul
if "%~1"=="" goto :script_arguments_not_defined
set cf_api_key=%~1
set zone_name=%~2
set dns_record=%~3
set ip_type=%~4
set record_type=%~5
set delete_record=%~6
:script_arguments_not_defined

color 0A
%*
SET root_path="%~dp0"
SET binary_file="%TEMP%\binary.txt"
if NOT "%~7"=="" ( set custom_curl_path=%~7 ) else ( set custom_curl_path=%root_path:"=%curl.exe )

IF NOT DEFINED ip_type (SET ip_type=1)
IF /I "%ip_type%"=="0" (goto :localhost_ip) else (goto :public_ip)
:localhost_ip
:: Get Private IP Land Line Localhost Address
for /f "tokens=1,2* delims=:" %%A in ('
ipconfig ^| find "IPv4 Address"
') do (
    set "tempip=%%~B"
    set "tempip=!tempip: =!"
    ping !tempip! -n 1 -w 50 >Nul
    if !errorlevel!==0 (
        set localip=!tempip!
        goto foundlocal
    )
)
:foundlocal
set ip=%localip%
goto :ip_end

:public_ip
IF /I NOT "%ip_type%"=="1" (
SET ip=%ip_type%
goto :ip_end
)

:: Get IP Address with CURL
for /F %%I in ('
%custom_curl_path% "https://checkip.amazonaws.com/" 2^>Nul
') do set ip=%%I
rem echo %ip%

:ip_end

:: Get Zone ID number from Cloudflare API
For /f "delims=" %%x in ('
%custom_curl_path% "https://api.cloudflare.com/client/v4/zones?name=%zone_name%&status=active" -H "Authorization: Bearer %cf_api_key:"=%" -H "content-type:application/json" 2^>Nul
') do set "data=!data!%%x"
:: Remove new lines and put entire response on a single line
set data=%data:"=\"%
rem echo %data%

:: Remove unwanted JSON leaving us with the ID number we want
set cf_zone_id=%data:~23,32%
rem echo %cf_zone_id%

:: Prove the Zone ID number of main domain to Get DNS ID number of the subdomain from Cloudflare API
For /f "delims=" %%x in ('
%custom_curl_path% "https://api.cloudflare.com/client/v4/zones/%cf_zone_id%/dns_records?type=%record_type%&name=%dns_record%" -H "Authorization: Bearer %cf_api_key:"=%" -H "content-type:application/json" 2^>Nul
') do set "data2=!data2!%%x"
:: Remove new lines and put entire response on a single line
set data2=%data2:"=\"%
rem echo %data2%

:: Remove unwanted JSON leaving us with the ID number we want
set cf_id=%data2:~23,32%
rem echo %cf_id%

IF /I "%delete_record%"=="1" (
%custom_curl_path% -X DELETE "https://api.cloudflare.com/client/v4/zones/%cf_zone_id%/dns_records/%cf_id%" -H "Authorization: Bearer %cf_api_key:"=%" -H "content-type:application/json" >Nul
goto :ending
)

:: Build our JSON to send to Cloudflare API to Update the DNS record with our current IP address
(
echo {
echo 	"content": "%ip%",
echo 	"data": {},
echo 	"id": "%cf_id%",
echo 	"name": "%dns_record%",
IF /I "%record_type%"=="MX" echo 	"priority": 10,
echo 	"proxiable": true,
echo 	"proxied": false,
echo 	"ttl": 1,
echo 	"type": "%record_type%",
echo 	"zone_id": "%cf_zone_id%",
echo 	"zone_name": "%zone_name%"
echo }
)>%binary_file%

:: Incase record does not exist create it first
(echo(%cf_id%)|find /i "," >nul && (
%custom_curl_path% -X POST "https://api.cloudflare.com/client/v4/zones/%cf_zone_id%/dns_records" -H "Authorization: Bearer %cf_api_key:"=%" -H "content-type:application/json" --data-binary "@%binary_file:"=%" 2^>nul
goto :ending
)

:: Send our JSON to Cloudflare API
For /f "delims=" %%x in ('
%custom_curl_path% -X PUT "https://api.cloudflare.com/client/v4/zones/%cf_zone_id%/dns_records/%cf_id%" -H "Authorization: Bearer %cf_api_key:"=%" -H "content-type:application/json" --data-binary "@%binary_file:"=%" 2^>nul
') do set "data3=!data3!%%x"
:: Remove new lines and put entire response on a single line
set data3=%data3:"=\"%
rem echo %data3%

:ending
:: Delete the binary file
del %binary_file% >nul

EXIT /b
