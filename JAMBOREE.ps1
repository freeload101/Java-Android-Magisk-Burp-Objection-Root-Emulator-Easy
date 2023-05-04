<# 
-RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt
start RedirectStandardOutput.txt 
start RedirectStandardError.txt
#>
$splashArt = @"
 "                                  .
      .              .   .'.     \   /
    \   /      .'. .' '.'   '  -=  o  =-
  -=  o  =-  .'   '              / | \
    / | \                          |
      |        JAMBOREE            |
      |                            |
      |                      .=====|
      |=====.                |.---.|
      |.---.|                ||=o=||
      ||=o=||                ||   ||
      ||   ||                |[___]|
      ||___||                |[:::]|
      |[:::]|                '-----'
      '-----'   
 
"@


function Draw-Splash{
    param([string]$Text)

    # Use a random colour for each character
    $Text.ToCharArray() | ForEach-Object{
        switch -Regex ($_){
            # Ignore new line characters
            "`r"{
                break
            }
            # Start a new line
            "`n"{
                Write-Host " ";break
            }
            # Use random colours for displaying this non-space character
            "[^ ]"{
                # Splat the colours to write-host
                $arrColors = @('DarkRed','DarkYellow','Gray','DarkGray','Green','Cyan','Red','Magenta','Yellow','White')
                $writeHostOptions = @{
                    ForegroundColor = ($arrColors) | get-random
                    NoNewLine = $true
                }
                Write-Host $_ @writeHostOptions
                break
            }
            " "{Write-Host " " -NoNewline}

        } 
    }
}




# splash art
Draw-Splash $splashArt

# set current directory
$VARCD = (Get-Location)

Write-Host "`n[+] Current Working Directory $VARCD"
Set-Location -Path "$VARCD"

Write-Host "`n[+] Setting ANDROID ENV Paths $VARCD"

$env:ANDROID_SDK_ROOT="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD"
$env:ANDROID_HOME="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD\avd"
New-Item -Path "$VARCD\avd" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:ANDROID_SDK_HOME="$VARCD"

#java 
Write-Host "`n[+] Setting JAVA ENV Paths $VARCD"
$env:JAVA_HOME = "$VARCD\jdk"


Write-Host "`n[+] Setting rootAVD ENV Paths $VARCD"
<#Use this if you want to keep your %PATH% ...
$env:Path = "$env:Path;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\python\tools\Scripts;$VARCD\python\tools;python\tools\Lib\site-packages;$VARCD\PortableGit\cmd"
#>
Write-Host "`n[+] Resetting Path variables to not use local python" 
$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem;$env:SystemRoot\System32\WindowsPowerShell\v1.0\;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\python\tools\Scripts;$VARCD\python\tools;python\tools\Lib\site-packages;$VARCD\PortableGit\cmd"

# python
$env:PYTHONHOME="$VARCD\python\tools"
 

# Setup Form
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.AutoSize = $true
$main_form.Text = "JAMBOREE"

$hShift = 0
$vShift = 0

### MAIN ###

################################# FUNCTIONS


############# downloadFile
function downloadFile($url, $targetFile)
{
    "Downloading $url"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
        #[System.Console]::CursorLeft = 0
        #[System.Console]::Write("`nDownloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
    "Finished Download"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

############# CHECK JAVA FOR NEO4J
Function CheckJavaNeo4j {
   if (-not(Test-Path -Path "$VARCD\jdk_neo4j" )) { 
        try {
            Write-Host "[+] Downloading Java"
            # does not work for neo4j bloodhound wants java11 ... downloadFile "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip" "$VARCD\openjdk.zip"
            downloadFile "https://cfdownload.adobe.com/pub/adobe/coldfusion/java/java11/java11018/jdk-11.0.18_windows-x64_bin.zip" "$VARCD\jdk_neo4j.zip"
			Write-Host "[+] Extracting Java"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\jdk_neo4j.zip", "$VARCD")
			Get-ChildItem "$VARCD\jdk-*"  | Rename-Item -NewName "jdk_neo4j"
			$env:JAVA_HOME = "$VARCD\jdk_neo4j"
			#$env:Path = "$VARCD\jdk_neo4j;$env:Path"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\jdk_neo4j already exists"
            $env:JAVA_HOME = "$VARCD\jdk_neo4j"
			
			}
}


############# CHECK JAVA
Function CheckJava {
   if (-not(Test-Path -Path "$VARCD\jdk" )) { 
        try {
            Write-Host "[+] Downloading Java"
            downloadFile "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip" "$VARCD\jdk.zip"
            Write-Host "[+] Extracting Java"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\jdk.zip", "$VARCD")
			Get-ChildItem "$VARCD\jdk-*"  | Rename-Item -NewName { $_.Name -replace '-.*','' }
            $env:JAVA_HOME = "$VARCD\jdk"
            #$env:Path = "$VARCD\jdk;$env:Path"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\openjdk.zip already exists"
            }
}


############# CHECK PYTHON
Function CheckPython {
   if (-not(Test-Path -Path "$VARCD\python" )) { 
        try {
            Write-Host "[+] Downloading Python nuget package" 
            downloadFile "https://www.nuget.org/api/v2/package/python" "$VARCD\python.zip"
            New-Item -Path "$VARCD\python" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
            Write-Host "[+] Extracting Python nuget package" 
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\python.zip", "$VARCD\python")

			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install --upgrade pip " -wait

            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install objection " -wait
            # for Frida Android Binary
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install python-xz " -wait
			
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Host "[+] $VARCD\python already exists"
            }
}

############# CHECK BURP
Function CheckBurp {
CheckJava
   if (-not(Test-Path -Path "$VARCD\burpsuite_community.jar" )) { 
        try {
            Write-Host "[+] Downloading Burpsuite Community" 
            downloadFile "https://portswigger-cdn.net/burp/releases/download?product=community&type=Jar" "$VARCD\burpsuite_community.jar"
           }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\Burpsuite already exists"
            }
			
			   if (-not(Test-Path -Path "$VARCD\burpsuite_pro.jar" )) { 
        try {
            Write-Host "[+] Downloading Burpsuite Pro" 
            downloadFile "https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar" "$VARCD\burpsuite_pro.jar"
           }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\Burpsuite Pro already exists"
            }
}

############# InstallAPKS
function InstallAPKS {
Write-Host "[+] Downloading Base APKS"
New-Item -Path "$VARCD\APKS" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null

Write-Host "[+] Downloading SAI Split Package Installer"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/Aefyr/SAI/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\SAI.apk"

Write-Host "[+] Downloading Amaze File Manager"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/TeamAmaze/AmazeFileManager/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\AmazeFileManager.apk"

Write-Host "[+] Downloading Duckduckgo"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/duckduckgo/Android/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\duckduckgo.apk"

Write-Host "[+] Downloading Gameguardian"
downloadFile "https://gameguardian.net/forum/files/file/2-gameguardian/?do=download&r=50314&confirm=1&t=1" "$VARCD\APKS\gameguardian.apk"

Write-Host "[+] Downloading Lucky Patcher"
downloadFile "https://chelpus.com/download/LuckyPatchers.com_Official_Installer_10.6.5.apk" "$VARCD\APKS\LP_Downloader.apk"

Write-Host "[+] Downloading YASNAC"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/RikkaW/YASNAC/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\yasnac.apk"

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Host "[+] Installing Base APKS"

(Get-ChildItem -Path "$VARCD\APKS").FullName |ForEach-Object {
	Write-Host "[+] Installing $_"
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " install $_ "  -NoNewWindow -Wait
	
    }
Write-Host "[+] Complete Installing Base APKS"
}

############# CheckADB
function CheckADB {
    $varadb = (adb devices)
    Write-Host "[+] $varadb"
    $varadb = $varadb -match 'device\b' -replace 'device','' -replace '\s',''
    Write-Host "[+] Online Device: $varadb"
        if (($varadb.length -lt 1 )) {
            Write-Host "[+] ADB Failed! Check for unauthorized devices listed in ADB!"
			adb devices
        }
	return $varadb
}

############# CertPush
function CertPush {
Write-Host "[+] Starting CertPush"

AlwaysTrustUserCerts

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Host "[+] Converting "$VARCD\BURP.der" to "$VARCD\BURP.pem""
Remove-Item -Path "$VARCD\BURP.pem" -Force -ErrorAction SilentlyContinue |Out-Null
Start-Process -FilePath "$env:SYSTEMROOT\System32\certutil.exe" -ArgumentList  " -encode `"$VARCD\BURP.der`"  `"$VARCD\BURP.pem`" "  -NoNewWindow -Wait

Write-Host "[+] Copying PEM to Androind format just in case its not standard burp suite cert Subject Hash 9a5ba575.0"
# Rename a PEM in Android format (openssl -subject_hash_old ) with just certutil and powershell
$CertSubjectHash = (certutil "$VARCD\BURP.der")
$CertSubjectHash = $CertSubjectHash |Select-String  -Pattern 'Subject:.*' -AllMatches  -Context 1, 8
$CertSubjectHash = ($CertSubjectHash.Context.PostContext[7]).SubString(24,2)+($CertSubjectHash.Context.PostContext[7]).SubString(22,2)+($CertSubjectHash.Context.PostContext[7]).SubString(20,2)+($CertSubjectHash.Context.PostContext[7]).SubString(18,2)+"."+0
Copy-Item -Path "$VARCD\BURP.pem" -Destination "$VARCD\$CertSubjectHash" -Force

Write-Host "[+] Pushing $VARCD\$CertSubjectHash to /sdcard "
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push $VARCD\$CertSubjectHash   /sdcard"  -NoNewWindow -Wait

Write-Host "[+] Pushing Copying /scard/$CertSubjectHash /data/misc/user/0/cacerts-added "

Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c mkdir /data/misc/user/0/cacerts-added`" "  -NoNewWindow -Wait

Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c cp /sdcard/$CertSubjectHash /data/misc/user/0/cacerts-added`" " -NoNewWindow -Wait

Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c chown root:root /data/misc/user/0/cacerts-added/$CertSubjectHash"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c chmod 644 /data/misc/user/0/cacerts-added/$CertSubjectHash"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c ls -laht /data/misc/user/0/cacerts-added/$CertSubjectHash"  -NoNewWindow -Wait

Write-Host "[+] Reboot for changes to take effect!"
}

############# AlwaysTrustUserCerts
Function AlwaysTrustUserCerts {
Write-Host "[+] Checking for AlwaysTrustUserCerts.zip"
   if (-not(Test-Path -Path "$VARCD\AlwaysTrustUserCerts.zip" )) { 
        try {
            Write-Host "[+] Downloading Magisk Module AlwaysTrustUserCerts.zip"
            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/NVISOsecurity/MagiskTrustUserCerts/releases/latest").assets | Where-Object name -like *.zip ).browser_download_url
            Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\AlwaysTrustUserCerts.zip"
            Write-Host "[+] Extracting AlwaysTrustUserCerts.zip"
            Expand-Archive -Path  "$VARCD\AlwaysTrustUserCerts.zip" -DestinationPath "$VARCD\trustusercerts" -Force
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\AlwaysTrustUserCerts.zip already exists"
            }

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Host "[+] Pushing $VARCD\AlwaysTrustUserCerts.zip"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push `"$VARCD\trustusercerts`"   /sdcard"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c cp -R /sdcard/trustusercerts /data/adb/modules`" " -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c find /data/adb/modules`" "  -NoNewWindow -Wait

}
Function StartFrida {
CheckPython
   if (-not(Test-Path -Path "$VARCD\frida-server" )) { 
        try {
            Write-Host "[+] Downloading Latest frida-server-*android-x86.xz "
            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/frida/frida/releases/latest").assets | Where-Object name -like frida-server-*-android-x86.xz ).browser_download_url
            downloadFile  $downloadUri "$VARCD\frida-server-android-x86.xz"
            Write-Host "[+] Extracting frida-server-android-x86.xz"
# don't mess with spaces for these lines for python ...
$PythonXZ = @'
import xz
import shutil

with xz.open('frida-server-android-x86.xz') as f:
    with open('frida-server', 'wb') as fout:
        shutil.copyfileobj(f, fout)
'@ 
# don't mess with spaces for these lines for python ...

            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD" -ArgumentList " `"$VARCD\frida-server-extract.py`" "
            $PythonXZ | Out-File -FilePath frida-server-extract.py 
            # change endoding from Windows-1252 to UTF-8
            Set-Content -Path "$VARCD\frida-server-extract.py" -Value $PythonXZ -Encoding UTF8 -PassThru -Force

            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\frida-server already exists"
            }




$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Host "[+] Pushing $VARCD\frida-server"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c killall frida-server;sleep 1`" "  -NoNewWindow -Wait -ErrorAction SilentlyContinue |Out-Null
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push `"$VARCD\frida-server`"   /sdcard"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c cp -R /sdcard/frida-server /data/local/tmp`" " -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c chmod 777 /data/local/tmp/frida-server`" "  -NoNewWindow -Wait
Write-Host "[+] Starting /data/local/tmp/frida-server"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c /data/local/tmp/frida-server &`" "  -NoNewWindow  

Write-Host "[+] Running Frida-ps select package to run Objection on:"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c pm list packages  `" "  -NoNewWindow -RedirectStandardOutput "$VARCDRedirectStandardOutput.txt"
Start-Sleep -Seconds 2
$PackageName = (Get-Content -Path "$VARCDRedirectStandardOutput.txt") -replace 'package:',''    | Out-GridView -Title "Select Package to Run Objection" -OutputMode Single

 

Write-Host "[+] Starting Objection"
Start-Process -FilePath "$VARCD\python\tools\Scripts\objection.exe" -WorkingDirectory "$VARCD\python\tools\Scripts" -ArgumentList " --gadget $PackageName explore " 

start-sleep -Seconds 5
# wscript may not work as good ? 
#$SendWait = New-Object -ComObject wscript.shell;
#$SendWait.SendKeys('android sslpinning disable')

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("android sslpinning disable")
start-sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait("{enter}")
[System.Windows.Forms.SendKeys]::SendWait("{enter}")

}

############# StartADB
function StartADB {
    $varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " logcat *:W  " 
}

############# AVDDownload
Function AVDDownload {
    if (-not(Test-Path -Path "$VARCD\cmdline-tools" )) {
        try {
            Write-Host "[+] Downloading Android Command Line Tools"
            downloadFile "https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip" "$VARCD\commandlinetools-win.zip"
            Write-Host "[+] Extracting AVD"
            Expand-Archive -Path  "$VARCD\commandlinetools-win.zip" -DestinationPath "$VARCD" -Force 
            Write-Host "[+] Setting path to latest that AVD wants ..."
            Rename-Item -Path "$VARCD\cmdline-tools" -NewName "$VARCD\latest"
            New-Item -Path "$VARCD\cmdline-tools" -ItemType Directory 
            Move-Item "$VARCD\latest" "$VARCD\cmdline-tools\"
			
			CheckJava
			CheckPython
			Write-Host "[+] Creating licenses Files"
			$licenseContentBase64 = "UEsDBBQAAAAAAKNK11IAAAAAAAAAAAAAAAAJAAAAbGljZW5zZXMvUEsDBAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQo2MDEwODViOTRjZDc3ZjBiNTRmZjg2NDA2OTU3MDk5ZWJlNzljNGQ2UEsDBAoAAAAAAKBK11LzQumJKgAAACoAAAAkAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlDQo4NTlmMzE3Njk2ZjY3ZWYzZDdmMzBhNTBhNTU2MGU3ODM0YjQzOTAzUEsDBAoAAAAAAKFK11IKSOJFKgAAACoAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQ0KMjQzMzNmOGE2M2I2ODI1ZWE5YzU1MTRmODNjMjgyOWIwMDRkMWZlZVBLAwQKAAAAAACiStdSec1a4SoAAAAqAAAAJAAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLXByZXZpZXctbGljZW5zZQ0KODQ4MzFiOTQwOTY0NmE5MThlMzA1NzNiYWI0YzljOTEzNDZkOGFiZFBLAwQKAAAAAACiStdSk6vQKCoAAAAqAAAAGwAAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQ0KMzNiNmEyYjY0NjA3ZjExYjc1OWYzMjBlZjlkZmY0YWU1YzQ3ZDk3YVBLAwQKAAAAAACiStdSrE3jESoAAAAqAAAAJAAAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZQ0KZDk3NWY3NTE2OThhNzdiNjYyZjEyNTRkZGJlZWQzOTAxZTk3NmY1YVBLAwQKAAAAAACjStdSkb1vWioAAAAqAAAAJgAAAGxpY2Vuc2VzL21pcHMtYW5kcm9pZC1zeXNpbWFnZS1saWNlbnNlDQplOWFjYWI1YjVmYmI1NjBhNzJjZmFlY2NlODk0Njg5NmZmNmFhYjlkUEsBAj8AFAAAAAAAo0rXUgAAAAAAAAAAAAAAAAkAJAAAAAAAAAAQAAAAAAAAAGxpY2Vuc2VzLwoAIAAAAAAAAQAYACIHOBcRaNcBIgc4FxFo1wHBTVQTEWjXAVBLAQI/AAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhACQAAAAAAAAAIAAAACcAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2UKACAAAAAAAAEAGACUEFUTEWjXAZQQVRMRaNcB6XRUExFo1wFQSwECPwAKAAAAAACgStdS80LpiSoAAAAqAAAAJAAkAAAAAAAAACAAAACQAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlCgAgAAAAAAABABgAsEM0FBFo1wGwQzQUEWjXAXb1MxQRaNcBUEsBAj8ACgAAAAAAoUrXUgpI4kUqAAAAKgAAABwAJAAAAAAAAAAgAAAA/AAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLWxpY2Vuc2UKACAAAAAAAAEAGAAsMGUVEWjXASwwZRURaNcB5whlFRFo1wFQSwECPwAKAAAAAACiStdSec1a4SoAAAAqAAAAJAAkAAAAAAAAACAAAABgAQAAbGljZW5zZXMvYW5kcm9pZC1zZGstcHJldmlldy1saWNlbnNlCgAgAAAAAAABABgA7s3WFRFo1wHuzdYVEWjXAfGm1hURaNcBUEsBAj8ACgAAAAAAokrXUpOr0CgqAAAAKgAAABsAJAAAAAAAAAAgAAAAzAEAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQoAIAAAAAAAAQAYAGRDRxYRaNcBZENHFhFo1wFfHEcWEWjXAVBLAQI/AAoAAAAAAKJK11KsTeMRKgAAACoAAAAkACQAAAAAAAAAIAAAAC8CAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UKACAAAAAAAAEAGADGsq0WEWjXAcayrRYRaNcBxrKtFhFo1wFQSwECPwAKAAAAAACjStdSkb1vWioAAAAqAAAAJgAkAAAAAAAAACAAAACbAgAAbGljZW5zZXMvbWlwcy1hbmRyb2lkLXN5c2ltYWdlLWxpY2Vuc2UKACAAAAAAAAEAGAA4LjgXEWjXATguOBcRaNcBIgc4FxFo1wFQSwUGAAAAAAgACACDAwAACQMAAAAA"
			$licenseContent = [System.Convert]::FromBase64String($licenseContentBase64)
			Set-Content -Path "$VARCD\android-sdk-licenses.zip" -Value $licenseContent -Encoding Byte
			Expand-Archive  "$VARCD\android-sdk-licenses.zip"  -DestinationPath "$VARCD\"  -Force
			Write-Host "[+] Running sdkmanager/Installing"
			
			# now we are using latest cmdline-tools ...!?
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "platform-tools" -Verbose -Wait -NoNewWindow 
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "extras;intel;Hardware_Accelerated_Execution_Manager" -Verbose -Wait -NoNewWindow 
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "platforms;android-30" -Verbose -Wait -NoNewWindow 
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "emulator" -Verbose -Wait -NoNewWindow 
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "system-images;android-30;google_apis_playstore;x86" -Verbose -Wait -NoNewWindow 
			Write-Host "[+] AVD Install Complete Creating AVD Device"
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\avdmanager.bat" -ArgumentList  "create avd -n pixel_2 -k `"system-images;android-30;google_apis_playstore;x86`"  -d `"pixel_2`" --force" -Wait -Verbose
			Start-Sleep -Seconds 2
			AVDStart
            }
                catch {
                    throw $_.Exception.Message
            }
			
            }
        else {
            Write-Host "[+] $VARCD\cmdline-tools already exists remove everything but this script to perform full reinstall/setup"
			AVDStart
            }
  
    
   
}


############# HAXMInstall
Function HyperVInstall {
    $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
    # Check if Hyper-V is enabled
    if($hyperv.State -eq "Enabled") {
        Write-Host "[!] Hyper-V is already enabled."
    } else {
        Write-Host "[+] Hyper-V not found, installing ..."        
        Stop-process -name adb.exe -Force -ErrorAction SilentlyContinue |Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    }
}

############# HAXMInstall
Function HAXMInstall {
	Stop-process -name adb.exe -Force -ErrorAction SilentlyContinue |Out-Null
	Start-Process -FilePath "$VARCD\extras\intel\Hardware_Accelerated_Execution_Manager\silent_install.bat" -WorkingDirectory "$VARCD\extras\intel\Hardware_Accelerated_Execution_Manager" -Wait
}

############# AVDStart
Function AVDStart {
	if (-not(Test-Path -Path "$VARCD\emulator" )) {
        try {
			AVDDownload
			Write-Host "[+] $VARCD\emulator already exists remove everything but this script to perform full reinstall/setup"
			Write-Host "[+] Starting AVD emulator"
			Start-Sleep -Seconds 2
			Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -http-proxy 127.0.0.1:8080"
            }
                catch {
                    throw $_.Exception.Message
            }
			
            }
    else {
            Write-Host "[+] $VARCD\emulator already exists remove everything but this script to perform full reinstall/setup"
			Write-Host "[+] Starting AVD emulator"
			Start-Sleep -Seconds 2
			Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -http-proxy 127.0.0.1:8080"
			
            }
}

############# AVDPoweroff
Function AVDPoweroff {
    $varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
	
	$wshell = New-Object -ComObject Wscript.Shell
	$pause = $wshell.Popup("Are you sure you want to shutdown ?!?", 0, "Wait!", 48+1)

	if ($pause -eq '1') {
		Write-Host "[+] Wiping data you will need to rerun Magisk and push cert"
		Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell -t  `"reboot -p`"" -Wait
	}
	Elseif ($pause = '2') {
		Write-Host "[+] Not rebooting..."
		return
	}
}

############# CMDPrompt
Function CMDPrompt {
	CheckJava
	CheckGit
	CheckPython
	Start-Process -FilePath "cmd" -WorkingDirectory "$VARCD"
	
	$varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell  " 
	
}


############# A1111
Function A1111 {
	# THIS IS BROKEN NEEDS OLDER PYTHON OR JUST US BINARY ...
	Write-Host "`n[+] Cloning stable-diffusion-webui"
	Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD\" -ArgumentList " clone `"https://github.com/AUTOMATIC1111/stable-diffusion-webui.git`" " -wait -NoNewWindow 

	CheckPython

	Start-Process -FilePath "$VARCD\stable-diffusion-webui\webui-user.bat" -WorkingDirectory "$VARCD\stable-diffusion-webui"  -ArgumentList " "  -wait -NoNewWindow 
}




############# AutoGPTEnv
Function AutoGPTEnv {
	
	if (-not(Test-Path -Path "$VARCD\Auto-GPT\.env" )) { 
        try {
	Write-Host "[+] Updating AutoGPT .env config for YOLO and Gpt-3 because I'm cheap"
	$OPENAI_API_KEY = Read-Host 'Enter your OPENAI_API_KEY see: http://www.google.com/cse/ '
	$CUSTOM_SEARCH_ENGINE_ID = Read-Host 'Enter your CUSTOM_SEARCH_ENGINE_ID see: http://www.google.com/cse/ '
	$GOOGLE_API_KEY = Read-Host 'Enter your GOOGLE_API_KEY key see https://console.cloud.google.com/apis/credentials click "Create Credentials". Choose "API Key".'


	(Get-Content "$VARCD\Auto-GPT\.env.template") `
	-replace '# EXECUTE_LOCAL_COMMANDS=False', 'EXECUTE_LOCAL_COMMANDS=True' `
	-replace '# RESTRICT_TO_WORKSPACE=True', 'RESTRICT_TO_WORKSPACE=False' `
	-replace 'OPENAI_API_KEY=your-openai-api-key', "OPENAI_API_KEY=$OPENAI_API_KEY"`
	-replace '# CUSTOM_SEARCH_ENGINE_ID=your-custom-search-engine-id', "CUSTOM_SEARCH_ENGINE_ID=$CUSTOM_SEARCH_ENGINE_ID"`
	-replace '# GOOGLE_API_KEY=your-google-api-key', "GOOGLE_API_KEY=$GOOGLE_API_KEY"`
	-replace '# SMART_LLM_MODEL=gpt-4', 'SMART_LLM_MODEL=gpt-3.5-turbo' `
	-replace '# FAST_LLM_MODEL=gpt-3.5-turbo', 'FAST_LLM_MODEL=gpt-3.5-turbo'`
	-replace '# FAST_TOKEN_LIMIT=4000', 'FAST_TOKEN_LIMIT=4000'`
	-replace '# SMART_TOKEN_LIMIT=8000', 'SMART_TOKEN_LIMIT=4000'`	|
	Out-File -Encoding Ascii "$VARCD\Auto-GPT\.env"			
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Host "[+] $VARCD\Auto-GPT\.env already exists"
            }
}

############# RootAVD
Function RootAVD {
    # I had to start the image before I enabled keyboard ....
	Start-Sleep -Seconds 2
	Write-Host "[+] Enbleing keyboard in config.ini"
	(Get-Content "$VARCD\avd\pixel_2.avd\config.ini") `
	-replace 'hw.keyboard = no', 'hw.keyboard = yes' `
	-replace 'hw.keyboard=no', 'hw.keyboard=yes' ` |
	Out-File -Encoding Ascii "$VARCD\avd\pixel_2.avd\config.ini"
if (-not(Test-Path -Path "$VARCD\rootAVD-master" )) {
    try {
            Write-Host "[+] Downloading rootAVD"
            downloadFile "https://github.com/newbit1/rootAVD/archive/refs/heads/master.zip" "$VARCD\rootAVD-master.zip"
            Write-Host "[+] Extracting rootAVD (Turn On AVD 1st" 
            Expand-Archive -Path  "$VARCD\rootAVD-master.zip" -DestinationPath "$VARCD" -Force
        }
            catch {
            throw $_.Exception.Message
            }
        }
        else {
            Write-Host "[+] $VARCD\rootAVD-master already exists"
        }
    
	$varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb

	cd "$VARCD\rootAVD-master"
	Write-Host "[+] Running installing magisk via rootAVD to ramdisk.img"
	Start-Process -FilePath "$VARCD\rootAVD-master\rootAVD.bat" -ArgumentList  "$VARCD\system-images\android-30\google_apis_playstore\x86\ramdisk.img" -WorkingDirectory "$VARCD\rootAVD-master\" 
    Write-Host "[+] rootAVD Finished if the emulator did not close/poweroff try again"
}

############# AVDWipeData
Function AVDWipeData {
	Write-Host "[+] Starting AVD emulator"
	$wshell = New-Object -ComObject Wscript.Shell
	$pause = $wshell.Popup("Are you sure you want to wipe all data ?!?", 0, "Wait!", 48+1)

	if ($pause -eq '1') {
		Write-Host "[+] Wiping data you will need to rerun Magisk and push cert"
		Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -wipe-data" 
	}
	Elseif ($pause = '2') {
		Write-Host "[+] Not wiping data..."
		return
	}
}

############# StartBurp
Function StartBurp {
    CheckBurp
    SecListsCheck
    Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$VARCD\burpsuite_community.jar`" --use-defaults  && "   
	Write-Host "[+] Waiting for Burp Suite to download cert"
	Retry{PullCert "Error PullCert"} # -maxAttempts 10
}

############# StartBurpPro
Function StartBurpPro {
    CheckBurp
    SecListsCheck
	$BurpProLatest = Get-ChildItem -Force -Recurse -File -Path "$VARCD" -Depth 0 -Filter *pro*.jar -ErrorAction SilentlyContinue | Sort-Object LastwriteTime -Descending | select -first 1
	Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$VARCD\$BurpProLatest`" --use-defaults  && "
	# wait for burp to setup env paths for config
	Start-Sleep -Seconds 2
	BurpConfigPush	
	Write-Host "[+] Waiting for Burp Suite to download cert"
	Retry{PullCert "Error PullCert"} # -maxAttempts 10
}

############# BurpConfigPush
Function BurpConfigPush {
# BurpConfigChrome.json
$BurpConfigChrome = @'
{
    "crawler":{
        "crawl_limits":{
            "maximum_crawl_time":0,
            "maximum_request_count":0,
            "maximum_unique_locations":0
        },
        "crawl_optimization":{
            "allow_all_clickables":false,
            "await_navigation_timeout":10,
            "breadth_first_until_depth":5,
            "crawl_strategy":"fastest",
            "crawl_strategy_customized":false,
            "crawl_using_provided_logins_only":false,
            "discovered_destinations_group_size":2147483647,
            "error_destination_multiplier":1,
            "form_destination_optimization_threshold":1,
            "form_submission_optimization_threshold":1,
            "idle_time_for_mutations":0,
            "incy_wincy":true,
            "link_fingerprinting_threshold":1,
            "logging_directory":"",
            "logging_enabled":false,
            "loopback_link_fingerprinting_threshold":1,
            "maximum_form_field_permutations":4,
            "maximum_form_permutations":5,
            "maximum_link_depth":0,
            "maximum_state_changing_sequences":0,
            "maximum_state_changing_sequences_length":3,
            "maximum_state_changing_sequences_per_destination":0,
            "maximum_unmatched_anchor_tolerance":3,
            "maximum_unmatched_form_tolerance":0,
            "maximum_unmatched_frame_tolerance":0,
            "maximum_unmatched_iframe_tolerance":3,
            "maximum_unmatched_image_area_tolerance":0,
            "maximum_unmatched_redirect_tolerance":0,
            "recent_destinations_buffer_size":1,
            "total_unmatched_feature_tolerance":3
        },
        "crawl_project_option_overrides":{
            "connect_timeout":3,
            "normal_timeout":3
        },
        "customization":{
            "allow_out_of_scope_resources":true,
            "application_uses_fragments_for_routing":"unsure",
            "browser_based_navigation_mode":"only_if_hardware_supports",
            "customize_user_agent":true,
            "maximum_items_from_sitemap":1000,
            "maximum_speculative_links":1000,
            "parse_api_definitions":true,
            "request_robots_txt":false,
            "request_sitemap":true,
            "request_speculative":true,
            "submit_forms":true,
            "timeout_for_in_progress_resource_requests":10,
            "user_agent":"Mozilla/5.0 (Linux; Android 4.4.2; Nexus 4 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.114 Mobile Safari/537.36 Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
        },
        "error_handling":{
            "number_of_follow_up_passes":0,
            "pause_task_requests_timed_out_count":0,
            "pause_task_requests_timed_out_percentage":0
        },
        "login_functions":{
            "attempt_to_self_register_a_user":true,
            "trigger_login_failures":true
        }
    }
}
 
'@
$BurpConfigChrome |set-Content "$env:USERPROFILE\AppData\Roaming\BurpSuite\ConfigLibrary\_JAMBOREE_Crawl_Level_01.json"

}



############# PullCert
Function PullCert {
    Invoke-WebRequest -Uri "http://burp/cert" -Proxy 'http://127.0.0.1:8080'  -Out "$VARCD\BURP.der" -Verbose
    Start-Process -FilePath "$env:SYSTEMROOT\System32\certutil.exe" -ArgumentList  " -user -addstore `"Root`"    `"$VARCD\BURP.der`"  "  -NoNewWindow -Wait
}


############# ZAPCheck
Function ZAPCheck {
    CheckJava
    if (-not(Test-Path -Path "$VARCD\ZAP.zip" )) {
        try {
            Write-Host "[+] Downloading ZAP"
            $xmlResponseIWR = Invoke-WebRequest -Method GET -Uri 'https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml' -OutFile ZapVersions.xml
            [xml]$xmlAttr = Get-Content -Path ZapVersions.xml
            Write-Host ([xml]$xmlAttr).ZAP.core.daily.url
            downloadFile ([xml]$xmlAttr).ZAP.core.daily.url "$VARCD\ZAP.zip"
	   
            Write-Host "[+] Extracting ZAP"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\ZAP.zip", "$VARCD")
			Get-ChildItem "$VARCD\ZAP_D*"  | Rename-Item -NewName { $_.Name -replace '_.*','' }

            ###


            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\ZAP.zip already exists"
            }
  
    
   
}

############# StartZAP
Function StartZAP {
	StartBurp
    ZAPCheck
    SecListsCheck
	Write-Host "[+] Starting ZAP"
    # https://www.zaproxy.org/faq/how-do-you-find-out-what-key-to-use-to-set-a-config-value-on-the-command-line/
    $ZAPJarPath = (Get-ChildItem "$VARCD\ZAP\*.jar")
    Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$ZAPJarPath`" -config network.localServers.mainProxy.address=localhost -config network.localServers.mainProxy.port=8081 -config network.connection.httpProxy.host=localhost -config network.connection.httpProxy.port=8080 -config network.connection.httpProxy.enabled=true" 
}



############# Retry
function Retry()
{
    param(
        [Parameter(Mandatory=$true)][Action]$action,
        [Parameter(Mandatory=$false)][int]$maxAttempts = 10
    )

    $attempts=1    
    $ErrorActionPreferenceToRestore = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    do
    {
        try
        {
            $action.Invoke();
            break;
        }
        catch [Exception]
        {
            Write-Host $_.Exception.Message
        }

        # exponential backoff delay
        $attempts++
        if ($attempts -le $maxAttempts) {
            $retryDelaySeconds = [math]::Pow(2, $attempts)
            $retryDelaySeconds = $retryDelaySeconds - 1  # Exponential Backoff Max == (2^n)-1
            Write-Host("Action failed. Waiting " + $retryDelaySeconds + " seconds before attempt " + $attempts + " of " + $maxAttempts + ".")
            Start-Sleep $retryDelaySeconds 
        }
        else {
            $ErrorActionPreference = $ErrorActionPreferenceToRestore
            Write-Error $_.Exception.Message
        }
    } while ($attempts -le $maxAttempts)
    $ErrorActionPreference = $ErrorActionPreferenceToRestore
}


############# SecListsCheck
Function SecListsCheck {
    if (-not(Test-Path -Path "$VARCD\SecLists.zip" )) {
        try {
            Write-Host "[+] Downloading SecLists.zip"
            downloadFile "https://github.com/danielmiessler/SecLists/archive/refs/heads/master.zip" "$VARCD\SecLists.zip"
            Write-Host "[+] Extracting SecLists.zip"

            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\SecLists.zip", "$VARCD")
			#Get-ChildItem "$VARCD\ZAP_D*"  | Rename-Item -NewName { $_.Name -replace '_.*','' }
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\SecLists.zip already exists"
            }
  
    
   
} 

############# SharpHoundRun
Function SharpHoundRun {
	Write-Host "[+] Example Runas Usage: runas /user:"nr.ad.COMPANY.com\USERNAME" /netonly cmd"
    if (-not(Test-Path -Path "$VARCD\SharpHound.exe" )) {
        try {
            Write-Host "[+] Sharphound Missing Downloading"
			downloadFile "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/DebugBuilds/SharpHound.exe" "$VARCD\SharpHound.exe"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
    Write-Host "[+] Starting SharpHound"
	Start-Process -FilePath "$VARCD\SharpHound.exe" -WorkingDirectory "$VARCD\"  -ArgumentList "  -s --CollectionMethods All --prettyprint true " 
}


############# Neo4jRun
Function Neo4jRun {
    CheckJavaNeo4j
	# Neo4j
    if (-not(Test-Path -Path "$VARCD\Neo4j" )) {
        try {
            Write-Host "[+] Downloading Neo4j"
            downloadFile "https://dist.neo4j.org/neo4j-community-4.4.19-windows.zip" "$VARCD\Neo4j.zip"
			Write-Host "[+] Extracting Neo4j"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\Neo4j.zip", "$VARCD")
			Get-ChildItem "$VARCD\neo4j-community*"  | Rename-Item -NewName { $_.Name -replace '-.*','' }
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\Neo4j.zip already exists"
            }
	Write-Host "[+] Starting Neo4j"
	Start-Process -FilePath "$VARCD\jdk_neo4j\bin\java.exe" -WorkingDirectory "$VARCD\neo4j\lib"  -ArgumentList "  -cp `"$VARCD\neo4j/lib/*`" -Dbasedir=`"$VARCD\neo4j`" org.neo4j.server.startup.Neo4jCommand `"console`"  " 
	Write-Host "[+] Wait for Neo4j You must change password at http://localhost:7474"
}

############# BloodhoundRun
Function BloodhoundRun {
    CheckJava
	# pull custom searches
	Stop-process -name BloodHound.exe -Force -ErrorAction SilentlyContinue |Out-Null
	if (-not(Test-Path -Path "$VARCD\BloodHound-win32-x64" )) {
        try {
            Write-Host "[+] Downloading BloodHound"
			#downloadFile "https://github.com/BloodHoundAD/BloodHound/releases/download/4.2.0/BloodHound-win32-x64.zip" "$VARCD\BloodHound-win32-x64.zip"
			$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/BloodHoundAD/BloodHound/releases/latest").assets | Where-Object name -like BloodHound-win32-x64*.zip ).browser_download_url
			downloadFile  $downloadUri "$VARCD\BloodHound-win32-x64.zip"
			Write-Host "[+] Extracting BloodHound"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\BloodHound-win32-x64.zip", "$VARCD")
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\BloodHound-win32-x64 already exists"
            }
	Write-Host "[+] Starting BloodHound"
	Start-Process -FilePath "$VARCD\BloodHound-win32-x64\BloodHound.exe" -WorkingDirectory "$VARCD\"
}




############# CHECK CheckGit
Function CheckGit {
   if (-not(Test-Path -Path "$VARCD\PortableGit" )) { 
        try {
            Write-Host "[+] Downloading Git" 

            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest").assets | Where-Object name -like *PortableGit*64*.exe ).browser_download_url
            downloadFile "$downloadUri" "$VARCD\git7zsfx.exe"
            # https://superuser.com/questions/1104567/how-can-i-find-out-the-command-line-options-for-git-bash-exe
            # file:///C:/Users/Administrator/SDUI/git/mingw64/share/doc/git-doc/git-bash.html#GIT-WRAPPER
            Start-Process -FilePath "$VARCD\git7zsfx.exe" -WorkingDirectory "$VARCD\" -ArgumentList " -o`"$VARCD\PortableGit`" -y " -wait -NoNewWindow

           
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Host "[+] $VARCD\Git already exists"
            }
} 





############# CHECK CheckGit
Function StartAutoGPT {
CheckPython
CheckGit


<#
 Weather2
Role:  tell me the weather for atlanta georgia using google.com website and no docker or APIs
Goals: ['tell me the weather for atlanta georgia using google.com website and no docker or APIs', 'output the results to a file called weather1']

#>

Write-Host "`n[+] Cloning https://github.com/Torantulino/Auto-GPT.git"
Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD\" -ArgumentList " clone `"https://github.com/Significant-Gravitas/Auto-GPT.git`" " -wait -NoNewWindow 
$env:SystemRoot
AutoGPTEnv

Write-Host "`n[+] Current Working Directory $VARCD\Auto-GPT"
Set-Location -Path "$VARCD\Auto-GPT"

Write-Host "`n[+] Running pip install -r requirements.txt"
Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\Auto-GPT"  -ArgumentList " -m pip install -r requirements.txt  " -wait -NoNewWindow 

Write-Host "`n[+] Running  .\run.bat --debug --gpt3only"
Start-Process -FilePath "cmd.exe" -WorkingDirectory "$VARCD\Auto-GPT"  -ArgumentList " /c .\run.bat --debug --gpt3only "  

Write-Host "`n[+] EXIT"
Start-Sleep -Seconds 30
} 
 

######################################################################################################################### FUNCTIONS END



############# BUTTON1
$Button1 = New-Object System.Windows.Forms.Button
$Button1.AutoSize = $true
$Button1.Text = "AVD With Proxy Support" #AVDDownload
$Button1.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button1.Add_Click({Retry({AVDDownload "Error AVDDownload"})})
$main_form.Controls.Add($Button1)
$vShift = $vShift + 30

############# BUTTON22
$pname=(Get-WMIObject win32_Processor | Select-Object name)
if ($pname -like "*AMD*") { 
    Write-host "[+] AMD Processor detected"
    ############# BUTTON22
    ############# AMD PROCESSOR DETECTED
    $Button22 = New-Object System.Windows.Forms.Button 
    $Button22.AutoSize = $true
    $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
    # Check if Hyper-V is enabled
        if($hyperv.State -eq "Enabled") {
            Write-Host "[!] Hyper-V is already enabled."
            # Already installed, disable button    
            $Button22.Text = "2. Hyper-V Already Installed"
            $Button22.Enabled = $false
        } else {

        $Button22.Text = "Hyper-V Install (Reboot?)" # Install Hyper-V
        $Button22.Enabled = $true
        }
    $Button22.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
    $Button22.Add_Click({HyperVInstall})
    $main_form.Controls.Add($Button22)
	$vShift = $vShift + 30
}
else {
    ############# BUTTON2
    ############# INTEL PROCESSOR DETECTED
    $Button2 = New-Object System.Windows.Forms.Button 
    $Button2.AutoSize = $true
    $Button2.Text = "HAXM Install" #HAXMInstall
    $Button2.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
    $Button2.Add_Click({HAXMInstall})
    $main_form.Controls.Add($Button2)
	$vShift = $vShift + 30
}

    
############# BUTTON3
$Button3 = New-Object System.Windows.Forms.Button
$Button3.AutoSize = $true
$Button3.Text = "BurpSuite" #StartBurp
$Button3.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button3.Add_Click({StartBurp})
$main_form.Controls.Add($Button3)
$vShift = $vShift + 30

############# BUTTON5
$Button5 = New-Object System.Windows.Forms.Button
$Button5.AutoSize = $true
$Button5.Text = "RootAVD/Install Magisk" #RootAVD
$Button5.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button5.Add_Click({RootAVD})
$main_form.Controls.Add($Button5)
$vShift = $vShift + 30

############# Button6
$Button6 = New-Object System.Windows.Forms.Button
$Button6.AutoSize = $true
$Button6.Text = "Upload BURP.pem as System Cert" #CertPush
$Button6.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button6.Add_Click({CertPush})
$main_form.Controls.Add($Button6)
$vShift = $vShift + 30

############# Button7
$Button7 = New-Object System.Windows.Forms.Button
$Button7.AutoSize = $true
$Button7.Text = "Frida/Objection" #StartFrida
$Button7.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button7.Add_Click({StartFrida})
$main_form.Controls.Add($Button7)
$vShift = $vShift + 30

############# Button8
$Button8 = New-Object System.Windows.Forms.Button
$Button8.AutoSize = $true
$Button8.Text = "CMD/ADB/Java/Python Prompt" #CMDPrompt
$Button8.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button8.Add_Click({CMDPrompt})
$main_form.Controls.Add($Button8)
$vShift = $vShift + 30

############# Button9
$Button9 = New-Object System.Windows.Forms.Button
$Button9.AutoSize = $true
$Button9.Text = "ADB Logcat" #StartADB
$Button9.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button9.Add_Click({StartADB})
$main_form.Controls.Add($Button9)
$vShift = $vShift + 30

############# Button10
$Button10 = New-Object System.Windows.Forms.Button
$Button10.AutoSize = $true
$Button10.Text = "Shutdown AVD" #AVDPoweroff
$Button10.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button10.Add_Click({AVDPoweroff})
$main_form.Controls.Add($Button10)
$vShift = $vShift + 30

############# BUTTON11
$BUTTON11 = New-Object System.Windows.Forms.Button
$BUTTON11.AutoSize = $true
$BUTTON11.Text = "AVD -wipe-data (Fix unauthorized adb)" #AVDWipeData
$BUTTON11.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$BUTTON11.Add_Click({AVDWipeData})
$main_form.Controls.Add($BUTTON11)
$vShift = $vShift + 30

############# BUTTON12
$BUTTON12 = New-Object System.Windows.Forms.Button
$BUTTON12.AutoSize = $true
$BUTTON12.Text = "Install Base APKs" #InstallAPKS
$BUTTON12.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$BUTTON12.Add_Click({InstallAPKS})
$main_form.Controls.Add($BUTTON12)
$vShift = $vShift + 30

############# BUTTON13
$Button13 = New-Object System.Windows.Forms.Button
$Button13.AutoSize = $true
$Button13.Text = "ZAP Using Burp" #StartZAP
$Button13.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button13.Add_Click({StartZAP})
$main_form.Controls.Add($Button13)
$vShift = $vShift + 30

############# BUTTON13
$Button14 = New-Object System.Windows.Forms.Button
$Button14.AutoSize = $true
$Button14.Text = "BurpSuite Pro" #StartBurpPro
$Button14.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button14.Add_Click({StartBurpPro})
$main_form.Controls.Add($Button14)
$vShift = $vShift + 30

############# BUTTON4
$Button4 = New-Object System.Windows.Forms.Button
$Button4.AutoSize = $true
$Button4.Text = "SharpHound" #SharpHoundRun 
$Button4.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button4.Add_Click({SharpHoundRun})
$main_form.Controls.Add($Button4)
$vShift = $vShift + 30

############# BUTTON30
$Button30 = New-Object System.Windows.Forms.Button
$Button30.AutoSize = $true
$Button30.Text = "Neo4j" #Neo4jRun 
$Button30.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button30.Add_Click({Neo4jRun})
$main_form.Controls.Add($Button30)
$vShift = $vShift + 30

############# BUTTON31
$Button31 = New-Object System.Windows.Forms.Button
$Button31.AutoSize = $true
$Button31.Text = "Bloodhound" #Bloodhound 
$Button31.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button31.Add_Click({BloodhoundRun})
$main_form.Controls.Add($Button31)
$vShift = $vShift + 30

############# BUTTON32
$Button32 = New-Object System.Windows.Forms.Button
$Button32.AutoSize = $true
$Button32.Text = "AutoGPT" #StartAutoGPT 
$Button32.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button32.Add_Click({StartAutoGPT})
$main_form.Controls.Add($Button32)
$vShift = $vShift + 30

<#
############# BUTTON33
$Button33 = New-Object System.Windows.Forms.Button
$Button33.AutoSize = $true
$Button33.Text = "AUTOMATIC1111" #A1111 
$Button33.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button33.Add_Click({A1111})
$main_form.Controls.Add($Button33)
$vShift = $vShift + 30
#>

############# SHOW FORM
$main_form.ShowDialog()
