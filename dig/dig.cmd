@ECHO OFF & setLocal EnableDelayedExpansion
:: Copyright Conor McKnight
:: https://github.com/C0nw0nk
:: https://www.facebook.com/C0nw0nk
:: Automatically sets up dig.exe for windows to use dig like linux
:: all you need is the batch script it will download the latest versions from their github pages
:: simple fast efficient easy to move and manage

:: Script Settings



:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

set root_path="%~dp0"

goto :next_download

:start_exe
::do stuff here after downloaded and setup
:: Get IP Address with CURL
for /F %%I in ('
%root_path:"=%curl.exe "https://checkip.amazonaws.com/" 2^>Nul
') do set ip=%%I
FOR /F "tokens=1,2,3,4 delims=." %%i in ("%ip%") do (
set one=%%i
set two=%%j
set three=%%k
set four=%%l
)
set reverseip=%four%.%three%.%two%.%one%
::add your spam check lists here
(
echo zen.spamhaus.org
echo sbl.spamhaus.org 
echo bl.spamcop.net
)>"%~n0-temp.txt"
::you can specify a custom dns to use if you don't want to use your default
::set dig_dns=^@1.1.1.1
set dig_dns=
set dig_output=
for /F "tokens=*" %%a in (%~n0-temp.txt) do (
for /F %%I in ('
%root_path:"=%dig.exe %dig_dns% ^+short %reverseip%.%%a
') do set dig_output=%%I
if "!dig_output!" == "" (break)
)
if "!dig_output!" == "" (set dig_output=null)
:: after if dig debug to see result else (echo %%a : !dig_output!)
del "%~n0-temp.txt" >nul

echo %dig_output%

::end stuff

goto :end_script

goto :next_download
:start_download
set downloadurl=%downloadurl: =%
FOR /f %%i IN ("%downloadurl:"=%") DO set filename="%%~ni"& set fileextension="%%~xi"
set downloadpath="%root_path:"=%%filename%%fileextension%"
(
echo Dim oXMLHTTP
echo Dim oStream
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo If Not fso.FileExists^("%downloadpath:"=%"^) Then
echo Set oXMLHTTP = CreateObject^("MSXML2.ServerXMLHTTP.6.0"^)
echo oXMLHTTP.Open "GET", "%downloadurl:"=%", False
echo oXMLHTTP.SetRequestHeader "User-Agent", "Mozilla/5.0 ^(Windows NT 10.0; Win64; rv:51.0^) Gecko/20100101 Firefox/51.0"
echo oXMLHTTP.SetRequestHeader "Referer", "https://www.google.co.uk/"
echo oXMLHTTP.SetRequestHeader "DNT", "1"
echo oXMLHTTP.Send
echo If oXMLHTTP.Status = 200 Then
echo Set oStream = CreateObject^("ADODB.Stream"^)
echo oStream.Open
echo oStream.Type = 1
echo oStream.Write oXMLHTTP.responseBody
echo oStream.SaveToFile "%downloadpath:"=%"
echo oStream.Close
echo End If
echo End If
echo ZipFile="%downloadpath:"=%"
echo ExtractTo="%root_path:"=%"
echo ext = LCase^(fso.GetExtensionName^(ZipFile^)^)
echo If NOT fso.FolderExists^(ExtractTo^) Then
echo fso.CreateFolder^(ExtractTo^)
echo End If
echo Set app = CreateObject^("Shell.Application"^)
echo Sub ExtractByExtension^(fldr, ext, dst^)
echo For Each f In fldr.Items
echo If f.Type = "File folder" Then
echo ExtractByExtension f.GetFolder, ext, dst
echo End If
echo If instr^(f.Path, "\%file_name_to_extract%"^) ^> 0 Then
echo If fso.FileExists^(dst ^& f.Name ^& "." ^& LCase^(fso.GetExtensionName^(f.Path^)^) ^) Then
echo Else
echo call app.NameSpace^(dst^).CopyHere^(f.Path^, 4^+16^)
echo End If
echo End If
echo Next
echo End Sub
echo If instr^(ZipFile, "zip"^) ^> 0 Then
echo ExtractByExtension app.NameSpace^(ZipFile^), "exe", ExtractTo
echo End If
if [%file_name_to_extract%]==[*] echo set FilesInZip = app.NameSpace^(ZipFile^).items
if [%file_name_to_extract%]==[*] echo app.NameSpace^(ExtractTo^).CopyHere FilesInZip, 4
if [%delete_download%]==[1] echo fso.DeleteFile ZipFile
echo Set fso = Nothing
echo Set objShell = Nothing
)>"%root_path:"=%%~n0.vbs"
cscript //nologo "%root_path:"=%%~n0.vbs"
del "%root_path:"=%%~n0.vbs"
:next_download
goto :skip_latest_download_link
:get_latest_download_link
::Get latest download link of a webpage
(
echo $url = "%grab_latest_url:"=%"
echo $html_tag = "%grab_latest_html_tag:"=%"
echo $matching_string = "%grab_latest_matching_string:"=%"
echo foreach^($i in %grab_low_range%..%grab_high_range%^){
echo $downloadUri = ^(^(Invoke-WebRequest $url -UseBasicParsing -MaximumRedirection 10^).Links ^| Where-Object $html_tag -like $matching_string^)[$i].href
echo if ^( -not ^([string]::IsNullOrEmpty^($downloadUri^)^) ^) {
echo $true_variable=%redirect_true_or_false%;
echo if ^($true_variable^) {
echo if ^($downloadUri -match "^^/"^) {
echo $var = [System.Uri]$url
echo $scheme = $var.Scheme
echo $domain = $var.Host
echo $downloadUri = $scheme ^+ "://" ^+ $domain ^+ $downloadUri
echo }
echo $downloadURL = $downloadUri
echo $request = Invoke-WebRequest -Method Head -Uri $downloadURL
echo $redirectedUri = $request.BaseResponse.ResponseUri.AbsoluteUri
echo $downloadUri = $redirectedUri
echo }
echo Write-Output $downloadUri ^| Out-File "%root_path:"=%%~n0-psoutput.txt"
echo break;
echo }
echo }
)>"%root_path:"=%%~n0-latest-download.ps1"
powershell -ExecutionPolicy Unrestricted -File "%root_path:"=%%~n0-latest-download.ps1" "%*" -Verb runAs
for /f "tokens=*" %%a in ('type "%root_path:"=%%~n0-psoutput.txt"') do set "latest_download_output=%%a"
del "%root_path:"=%%~n0-latest-download.ps1"
del "%root_path:"=%%~n0-psoutput.txt"
:skip_latest_download_link

if not exist "%~dp0\curl.exe" (
if not defined curl_exe (
	set downloadurl=https://github.com/C0nw0nk/Cloudflare-my-ip/raw/main/curl.exe
	set delete_download=0
	set curl_exe=true
	goto :start_download
)
)

::start dig dependancies
set dig_downloadurl=https://downloads.isc.org/isc/bind9/9.16.34/BIND9.16.34.x64.zip
set file_name_to_extract=dig.exe
if not exist "%~dp0\%file_name_to_extract%" (
if not defined dig_exe (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set dig_exe=true
	goto :start_download
)
)
set file_name_to_extract=libisc.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libisc_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libisc_dll=true
	goto :start_download
)
)
set file_name_to_extract=libisccfg.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libisccfg_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libisccfg_dll=true
	goto :start_download
)
)
set file_name_to_extract=libirs.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libirs_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libirs_dll=true
	goto :start_download
)
)
set file_name_to_extract=libdns.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libdns_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libdns_dll=true
	goto :start_download
)
)
set file_name_to_extract=libbind9.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libbind9_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libbind9_dll=true
	goto :start_download
)
)
set file_name_to_extract=libcrypto-1_1-x64.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libcrypto-1_1-x64_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libcrypto-1_1-x64_dll=true
	goto :start_download
)
)
set file_name_to_extract=libssl-1_1-x64.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libssl-1_1-x64_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set libssl-1_1-x64_dll=true
	goto :start_download
)
)
set file_name_to_extract=uv.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined uv_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=0
	set uv_dll=true
	goto :start_download
)
)
set file_name_to_extract=libxml2.dll
if not exist "%~dp0\%file_name_to_extract%" (
if not defined libxml2_dll (
	set downloadurl=%dig_downloadurl%
	set delete_download=1
	set libxml2_dll=true
	goto :start_download
)
)
::end dig dependancies

goto :start_exe

:end_script

exit /b
