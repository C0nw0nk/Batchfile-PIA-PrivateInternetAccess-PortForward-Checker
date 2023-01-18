@echo off & setLocal EnableDelayedExpansion
:: Copyright Conor McKnight
:: https://github.com/C0nw0nk
:: https://www.facebook.com/C0nw0nk
:: Automatically sets up pia for windows
:: all you need is the batch script it will download the latest versions from their github pages
:: simple fast efficient easy to move and manage

:: Script Settings



:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

TITLE Installer

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

powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force;"

set root_path="%~dp0"

goto :next_download
:start_download_powershell
set downloadurl=%downloadurl: =%
FOR /f %%i IN ("%downloadurl:"=%") DO set filename="%%~ni"& set fileextension="%%~xi"
set downloadpath="%root_path:"=%%filename%%fileextension%"
powershell -Command "Invoke-WebRequest -Uri "%downloadurl:"=%" -OutFile "%downloadpath:"=%"
goto :next_download

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
echo $request = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $downloadURL
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

if not exist "%ProgramFiles(x86)%\hMailServer\Bin\hmailserver.exe" (
	if not defined get_latest_hmailserver_exe (
			set grab_latest_url="https://www.hmailserver.com/download_getfile/?performdownload=1&downloadid=271"
			set grab_latest_html_tag="href"
			set grab_latest_matching_string="*download_file*"
			set grab_low_range=0
			set grab_high_range=0
			set redirect_true_or_false=$true
			set get_latest_hmailserver_exe=true
			goto :get_latest_download_link
	)
	if not defined hmailserver_exe (
		set downloadurl=%latest_download_output:~0,-1%e
		::my little trick for redirects and links that dont have a file name i will create one
		set downloadurl=!downloadurl!^?#/hMailServer.exe
		set delete_download=0
		set hmailserver_exe=true
		goto :start_download_powershell
	)
	Dism /online /Enable-Feature /FeatureName:"NetFx3" >nul
	call "%root_path:"=%%filename:"=%%fileextension:"=%" /VERYSILENT /PASSWORD=
	del "%root_path:"=%%filename:"=%%fileextension:"=%"
)

if not exist "%ProgramFiles%\Private Internet Access\piactl.exe" (
	if not defined get_latest_pia_exe (
			set grab_latest_url="https://www.privateinternetaccess.com/download/windows-vpn#download-windows"
			set grab_latest_html_tag="data-object"
			set grab_latest_matching_string="*download_windows_64*"
			set grab_low_range=0
			set grab_high_range=0
			set redirect_true_or_false=$false
			set get_latest_pia_exe=true
			goto :get_latest_download_link
	)
	if not defined pia_exe (
		set downloadurl=%latest_download_output%
		set delete_download=0
		set pia_exe=true
		goto :start_download
	)
	call "%root_path:"=%%filename:"=%%fileextension:"=%" /silent
	del "%root_path:"=%%filename:"=%%fileextension:"=%"
)

echo pausing

pause

exit /b
