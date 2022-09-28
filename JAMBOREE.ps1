<# 
TODO:
* somehow auto accespt all licences or get all licence hashes and create them ?
* Clean/wipe install/cache 
* actualy download latest cmdline tools

PRECHECK/REQUIREMENTS:
* Intel for HAXM
* Hyperv disabled
* Enabled Xesst in BIOS

CLEANUP:
rd q/s "c:\Python310\"
rd q/s "c:\Users\internet\.gradle"
rd q/s "c:\Users\internet\AndroidStudioProjects"
rd q/s "c:\Users\internet\AppData\Local\Android"
rd q/s "c:\Users\internet\AppData\Local\Google"
C:\Users\internet\AppData\Roaming\BurpSuite

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
            Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/python"  -Out "$VARCD\python.zip"
            Expand-Archive -Path  "$VARCD\python.zip" -DestinationPath "$VARCD\python" -Force
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install objection "
            Start-Process -FilePath "$VARCD\python\tools\Scripts\frida-ps" -WorkingDirectory "$VARCD\python\tools"  -ArgumentList " -Uai" -NoNewWindow
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
            Write-Host "[+] $VARCD\python Burpsuite"
            }
}


############# InstallAPKS
function InstallAPKS {
New-Item -Path "$VARCD\APKS" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null

$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/Aefyr/SAI/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\APKS\SAI.apk"

$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/TeamAmaze/AmazeFileManager/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\APKS\AmazeFileManager.apk"

$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/duckduckgo/Android/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\APKS\duckduckgo.apk"

}

############# CheckADB
function CheckADB {
    $varadb = (adb devices)
    Write-Host "[+] $varadb"
    $varadb = $varadb -match 'device\b' -replace 'device','' -replace '\s',''
    Write-Host "[+] Online Device: $varadb"
        if (($varadb.length -lt 1 )) {
            Write-Host "[+] ADB Failed! Check for unathorized devices listed in ADB!"
			adb devices
        }
	return $varadb
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
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell  " -Wait  
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
    Write-Host "[+] AVD Install Complete"
    }
    
############# BUTTON3
$Button3 = New-Object System.Windows.Forms.Button
$Button3.AutoSize = $true
$Button3.Text = "3. Create AVD"
$Button3.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+60))
$Button3.Add_Click({Button3})
$main_form.Controls.Add($Button3)

Function Button3 {
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\avdmanager.bat" -ArgumentList  "create avd -n pixel_2 -k `"system-images;android-30;google_apis_playstore;x86`"  -d `"pixel_2`" --force" -Wait -Verbose
}

############# BUTTON4
$Button4 = New-Object System.Windows.Forms.Button
$Button4.AutoSize = $true
$Button4.Text = "4. Start AVD -writable-system"
$Button4.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+90))
$Button4.Add_Click({Button4})
$main_form.Controls.Add($Button4)

Function Button4 {
    Write-Host "[+] Starting AVD emulator"
    Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system"  -WindowStyle Minimized
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
$Button6.Text = "5. rootAVD/Install Magisk"
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
$Button7.Text = "Kill adb.exe"
$Button7.Location = New-Object System.Drawing.Point(($hShift),($vShift+180))
$Button7.Add_Click({Button7})
$main_form.Controls.Add($Button7)

Function Button7 {
Stop-process -name adb -Force -ErrorAction SilentlyContinue |Out-Null
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
$Button9.Text = "cmd prompt"
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
$Button10.Text = "Start Burpsuite"
$Button10.Location = New-Object System.Drawing.Point(($hShift),($vShift+270))
$Button10.Add_Click({Button10})
$main_form.Controls.Add($Button10)

Function Button10 {
CheckBurp
Start-Process -FilePath "$VARCD\jdk-11.0.1\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk-11.0.1\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$VARCD\burpsuite_community.jar`" " 
}

#CheckPython
#InstallAPKS

############# SHOW FORM
$main_form.ShowDialog()

































<#
Shell Notes:

cd C:\DELETE\GG
powershell
.\JAMBOREE.ps1

set ANDROID_SDK_ROOT=%CD%
set ANDROID_AVD_HOME=%CD%
set ANDROID_HOME=%CD%
set ANDROID_AVD_HOME=%CD%\avd
set ANDROID_SDK_HOME=%CD%
set JAVA_HOME=%CD%\jdk-11.0.1
set PATH=%CD%\platform-tools\;%Path%
cd  rootAVD-master

set ANDROID_SERIAL=emulator-5554


https://portswigger-cdn.net/burp/releases/download?product=community&type=Jar


$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/frida/frida/releases/latest").assets | Where-Object name -like frida-server-*-android-x86.xz ).browser_download_url
Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\frida-server"


:: pip3 install objection
:: objection --gadget com.spotme.eventspace explore
objection --gadget  casual.match3.theme.parks.puzzles explore
:: android sslpinning disable

frida-ps -Uai

adb push .\frida-server /data/local/tmp

adb shell -t "chmod 777 /data/local/tmp/frida-server"

::start "FRIDA-SERVER" adb shell "/data/local/tmp/frida-server"
::adb shell "/data/local/tmp/frida-server  -l 0.0.0.0"
adb shell "su -c /data/local/tmp/frida-server"




 
adb push .\_SUPPORT\certs\9a5ba575.0  /data/local/tmp/
adb push .\_SUPPORT\certs\9a5ba575.0  /sdcard/download
adb push "C:\DELETE\ATS\_SUPPORT\certs\BURP.der" /sdcard/download
adb push "C:\DELETE\ATS\_SUPPORT\certs\BURP.der" /sdcard/download/BURP.cer

adb push AlwaysTrustUserCerts.zip /sdcard/download

adb shell "su -c mv /data/local/tmp/9a5ba575.0 /system/etc/security/cacerts/9a5ba575.0 "
 
adb shell "su -c mv /data/local/tmp/9a5ba575.0 /system/etc/security/cacerts/9a5ba575.0 "
 
 

:: adb shell -t "chown root:root /system/etc/security/cacerts/*"
:: adb shell -t "chmod 644 /system/etc/security/cacerts/*"
:: adb shell -t "chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*"
:: adb shell -t "ls -laht /system/etc/security/cacerts/9a5ba575.0"


: burp suite
Dhttp.proxyHost=10.0.0.100 -Dhttp.proxyPort=8800
certutil -user -addstore "Root"  "%~dp0_SUPPORT\certs\BURP.der"
certutil -user -addstore "Root"  "%~dp0_SUPPORT\certs\ZAP.der"

keytool.exe -keystore C:/Users/Administrator/.keystore -genkey -alias client

& 'C:\Program Files\BurpSuitePro\jre\bin\keytool.exe' -importcert -file "C:\Users\foo\Documents\root_ca_DER.cer" -keystore "C:\Users\foo\Documents\cacerts" -alias "customer"
& "C:\Program Files\BurpSuitePro\jre\bin\java.exe" -jar "C:\Program Files\BurpSuitePro\burpsuite_pro.jar" -Djavax.net.ssl.trustStore="C:\Users\foo\Documents\cacerts" -XX:MaxRAMPercentage=50

--


keytool.exe -keystore keystore -genkey -alias burp

keytool.exe -importcert -file "BURP_root_ca_DER.cer" -keystore keystore -alias burp
& "C:\Program Files\BurpSuitePro\jre\bin\java.exe" -jar "C:\Program Files\BurpSuitePro\burpsuite_pro.jar" -Djavax.net.ssl.trustStore="C:\Users\foo\Documents\cacerts" -XX:MaxRAMPercentage=50


#>
