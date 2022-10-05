<# 

PRECHECK/REQUIREMENTS:
* Tested on Windows 10
* Intel for HAXM
* Hyperv disabled
* Enabled Xesst in BIOS


-RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt
start RedirectStandardOutput.txt 
start RedirectStandardError.txt
#>

# set current directory
$VARCD = (Get-Location)
Write-Host "[+] Current Working Directory $VARCD"
Set-Location -Path "$VARCD"

# env 
$env:ANDROID_SDK_ROOT="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD"
$env:ANDROID_HOME="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD\avd"
New-Item -Path "$VARCD\avd" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:ANDROID_SDK_HOME="$VARCD"

#java 
$env:JAVA_HOME = "$VARCD\jdk-11.0.1"

# Path rootAVD java python
$env:Path = "$env:Path;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\python\tools\Scripts;$VARCD\python\tools;$VARCD\jdk-11.0.1\bin"

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


############# CHECK JAVA
Function CheckJava {
   if (-not(Test-Path -Path "$VARCD\jdk-11.0.1" )) { 
        try {
            Write-Host "[+] Downloading Java"
            downloadFile "https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_windows-x64_bin.zip" "$VARCD\openjdk.zip"
            Write-Host "[+] Extracting Java"
            Expand-Archive -Path  "$VARCD\openjdk.zip" -DestinationPath "$VARCD" -Force
            $env:JAVA_HOME = "$VARCD\jdk-11.0.1"
            $env:Path = "$VARCD\jdk-11.0.1;$env:Path"
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

            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install objection "
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
   if (-not(Test-Path -Path "$VARCD\burpsuite_community.jar" )) { 
        try {
            Write-Host "[+] Downloading Burpsuite" 
            downloadFile "https://portswigger-cdn.net/burp/releases/download?product=community&type=Jar" "$VARCD\burpsuite_community.jar"
           }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\Burpsuite already exists"
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


$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Host "[+] Installing Base APKS"

(Get-ChildItem -Path "$VARCD\APKS").FullName |ForEach-Object {
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

            Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\frida-server-android-x86.xz"

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
            Set-Content -Path "frida-server-extract.py" -Value $PythonXZ -Encoding UTF8 -PassThru -Force

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

################################# FUNCTIONS END


############# BUTTON1
$Button1 = New-Object System.Windows.Forms.Button
$Button1.AutoSize = $true
$Button1.Text = "ADB Shell"
$Button1.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button1.Add_Click({Button1})
$main_form.Controls.Add($Button1)

Function Button1 {
    $varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell  "   
}

############# BUTTON2
$Button2 = New-Object System.Windows.Forms.Button
$Button2.AutoSize = $true
$Button2.Text = "1. AVD Download/Install"
$Button2.Location = New-Object System.Drawing.Point(($hShift),($vShift+30))
$Button2.Add_Click({Button2})
$main_form.Controls.Add($Button2)

Function Button2 {
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
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\commandlinetools-win.zip already exists"
            }
  
    
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

    }
    
############# BUTTON3
$Button3 = New-Object System.Windows.Forms.Button
$Button3.AutoSize = $true
$Button3.Text = "UNUSED"
$Button3.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+60))
$Button3.Add_Click({Button3})
$main_form.Controls.Add($Button3)

Function Button3 {
  echo "UNUSED"
    }

############# BUTTON4
$Button4 = New-Object System.Windows.Forms.Button
$Button4.AutoSize = $true
$Button4.Text = "5. Start AVD With Proxy Support"
$Button4.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+90))
$Button4.Add_Click({Button4})
$main_form.Controls.Add($Button4)

Function Button4 {
    Write-Host "[+] Starting AVD emulator"
    Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -http-proxy 127.0.0.1:8080"  -WindowStyle Minimized
}

############# BUTTON5
$Button5 = New-Object System.Windows.Forms.Button
$Button5.AutoSize = $true
$Button5.Text = "ADB Poweroff"
$Button5.Location = New-Object System.Drawing.Point(($hShift),($vShift+120))
$Button5.Add_Click({Button5})
$main_form.Controls.Add($Button5)

Function Button5 {
    $varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell -t  `"reboot -p`"" -Wait
}

############# Button6
$Button6 = New-Object System.Windows.Forms.Button
$Button6.AutoSize = $true
$Button6.Text = "6. rootAVD/Install Magisk"
$Button6.Location = New-Object System.Drawing.Point(($hShift),($vShift+150))
$Button6.Add_Click({Button6})
$main_form.Controls.Add($Button6)

Function Button6 {

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
	Start-Process -FilePath "$VARCD\rootAVD-master\rootAVD.bat" -ArgumentList  "$VARCD\system-images\android-30\google_apis_playstore\x86\ramdisk.img" -Wait 
    Write-Host "[+] rootAVD Finished if the emulator did not close/poweroff try again"
}



############# Button7
$Button7 = New-Object System.Windows.Forms.Button
$Button7.AutoSize = $true
$Button7.Text = "8. Start Frida/Objection"
$Button7.Location = New-Object System.Drawing.Point(($hShift),($vShift+180))
$Button7.Add_Click({Button7})
$main_form.Controls.Add($Button7)

Function Button7 {
	StartFrida
}

############# Button8
$Button8 = New-Object System.Windows.Forms.Button
$Button8.AutoSize = $true
$Button8.Text = "2. Install HAXM (Reboot?) "
$Button8.Location = New-Object System.Drawing.Point(($hShift),($vShift+210))
$Button8.Add_Click({Button8})
$main_form.Controls.Add($Button8)

Function Button8 {
	Stop-process -name adb.exe -Force -ErrorAction SilentlyContinue |Out-Null
	Start-Process -FilePath "$VARCD\extras\intel\Hardware_Accelerated_Execution_Manager\silent_install.bat" -WorkingDirectory "$VARCD\extras\intel\Hardware_Accelerated_Execution_Manager" -Wait
}

############# Button9
$Button9 = New-Object System.Windows.Forms.Button
$Button9.AutoSize = $true
$Button9.Text = "CMD.exe Prompt"
$Button9.Location = New-Object System.Drawing.Point(($hShift),($vShift+240))
$Button9.Add_Click({Button9})
$main_form.Controls.Add($Button9)

Function Button9 {
	Stop-process -name adb.exe -Force -ErrorAction SilentlyContinue |Out-Null
	Start-Process -FilePath "cmd" -WorkingDirectory "$VARCD"  
}


############# Button10
$Button10 = New-Object System.Windows.Forms.Button
$Button10.AutoSize = $true
$Button10.Text = "4. Start Burpsuite"
$Button10.Location = New-Object System.Drawing.Point(($hShift),($vShift+270))
$Button10.Add_Click({Button10})
$main_form.Controls.Add($Button10)

Function Button10 {
    CheckBurp
    Start-Process -FilePath "$VARCD\jdk-11.0.1\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk-11.0.1\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$VARCD\burpsuite_community.jar`" --use-defaults  && "   
    (New-Object -ComObject Wscript.Shell).Popup("Press OK once burp proxy is listening" ,0,"Waiting",0+64)
    Invoke-WebRequest -Uri "http://burp/cert" -Proxy 'http://127.0.0.1:8080'  -Out "$VARCD\BURP.der" -Verbose
}

############# BUTTON11
$BUTTON11 = New-Object System.Windows.Forms.Button
$BUTTON11.AutoSize = $true
$BUTTON11.Text = "Start AVD -writable-system -wipe-data NO PROXY (Fix unauthorized adb) "
$BUTTON11.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+300))
$BUTTON11.Add_Click({BUTTON11})
$main_form.Controls.Add($BUTTON11)

Function BUTTON11 {
	Write-Host "[+] Starting AVD emulator"
	(New-Object -ComObject Wscript.Shell).Popup("Are you sure you want to wipe all data !?" ,0,"Waiting",0+64)
	(New-Object -ComObject Wscript.Shell).Popup("Are you sure you want to wipe all data !? Really?" ,0,"Waiting",0+64)
	Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -wipe-data"  -WindowStyle Minimized
	
}


############# BUTTON12
$BUTTON12 = New-Object System.Windows.Forms.Button
$BUTTON12.AutoSize = $true
$BUTTON12.Text = "7. Upload BURP.pem as System Cert"
$BUTTON12.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+330))
$BUTTON12.Add_Click({BUTTON12})
$main_form.Controls.Add($BUTTON12)

Function BUTTON12 {
    Write-Host "[+] Starting CertPush"
    CertPush
}

############# BUTTON13
$BUTTON13 = New-Object System.Windows.Forms.Button
$BUTTON13.AutoSize = $true
$BUTTON13.Text = "Install Base APKs"
$BUTTON13.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+360))
$BUTTON13.Add_Click({BUTTON13})
$main_form.Controls.Add($BUTTON13)

Function BUTTON13 {
    InstallAPKS
}


############# SHOW FORM
$main_form.ShowDialog()
