@ECHO OFF & setLocal EnableDelayedExpansion
:: Copyright Conor McKnight
:: https://github.com/C0nw0nk
:: https://www.facebook.com/C0nw0nk
:: Automatically sets up openssl.exe for windows to use openssl like linux
:: all you need is the batch script it will download the latest versions from their github pages
:: simple fast efficient easy to move and manage

:: Script Settings

set OPENSSL_CONF=openssl.cnf

::set encryption_bit=1024
set encryption_bit=2048

set key_name=domain.com

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

set root_path="%~dp0"

goto :next_download

:start_exe
::do stuff here after downloaded and setup

::debug version of openssl
::%root_path:"=%openssl.exe version

::private key for server
for /f "tokens=*" %%a in ('
%root_path:"=%openssl.exe genrsa -out %root_path:"=%\%key_name%.key %encryption_bit% 2^>Nul
') do set output_key=%%a

::public key for dns
for /f "tokens=*" %%a in ('
%root_path:"=%openssl.exe rsa -in %root_path:"=%\%key_name%.key -pubout 2^>Nul
') do set "outputrsa=!outputrsa!%%a"
set outputrsa=%outputrsa:~26,-25%

echo !outputrsa!

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
if %file_name_to_extract% == * echo set FilesInZip = app.NameSpace^(ZipFile^).items
if %file_name_to_extract% == * echo app.NameSpace^(ExtractTo^).CopyHere FilesInZip, 4
if %delete_download% == 1 echo fso.DeleteFile ZipFile
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

:: https://deac-ams.dl.sourceforge.net/project/openssl-for-windows/OpenSSL-1.1.1h_win32%28static%29%5BNo-GOST%5D.zip
if not exist "%root_path:"=%openssl.exe" (
	if not defined get_latest_openssl_exe (
			set grab_latest_url="https://sourceforge.net/settings/mirror_choices?projectname=openssl-for-windows&filename=OpenSSL-1.1.1h_win32%%28static%%29%%5BNo-GOST%%5D.zip&selected=deac-fra"
			set grab_latest_html_tag="href"
			set grab_latest_matching_string="*downloads.sourceforge.net/project/openssl-for-windows/OpenSSL-1.1.1h_win32*"
			set grab_low_range=0
			set grab_high_range=0
			set redirect_true_or_false=$true
			set get_latest_openssl_exe=true
			goto :get_latest_download_link
	)
	if not defined openssl_zip (
		set downloadurl=%latest_download_output%
		set file_name_to_extract=OpenSSL-1.1.1h\
		set delete_download=1
		set openssl_zip=true
		goto :start_download
	)
)

goto :start_exe

:end_script

exit /b
