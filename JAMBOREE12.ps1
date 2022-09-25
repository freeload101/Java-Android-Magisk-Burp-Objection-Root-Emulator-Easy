<# 
TODO:
* somehow auto accespt all licences or get all licence hashes and create them ?
* Clean/wipe install/cache 

PRECHECK/REQUIREMENTS:
* Intel for HAXM
* Hyperv disabled
* Enabled VT-x in BIOS


CLEANUP:
rd q/s "c:\Python310\"
rd q/s "c:\Users\internet\.gradle"
rd q/s "c:\Users\internet\AndroidStudioProjects"
rd q/s "c:\Users\internet\AppData\Local\Android"
rd q/s "c:\Users\internet\AppData\Local\Google"


#>



# REMOVE FOR IDE
Set-Location -Path "C:\JAMBOREE"
Stop-process -name java.exe -Force  -ErrorAction SilentlyContinue



# set current directory
$VARCD = (Get-Location)
Write-Host "[+] Current Working Directory $VARCD"

# Setup Form
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.AutoSize = $true
$main_form.Text = "JAMBOREE"

$hShift = 0
$vShift = 0


### MAIN ###


############# CHECK JAVA
Function CheckJava {
   if (-not(Test-Path -Path "$VARCD\jdk-11.0.1" )) { 
        try {
            Write-Host "[+] Downloading Java"
            $downloadUri = "https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_windows-x64_bin.zip"
            Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\openjdk.zip"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\openjdk.zip already exists"
            }
    Write-Host "[+] Extracting Java"
    Expand-Archive -Path  "$VARCD\openjdk.zip" -DestinationPath "$VARCD" -Force
    $env:JAVA_HOME = "$VARCD\jdk-11.0.1"
    $env:Path = "$VARCD\jdk-11.0.1;$env:Path"
   # [System.Environment]::SetEnvironmentVariable("JAVA_HOME", "$VARCD\jdk-11.0.1","Machine")
   # [System.Environment]::GetEnvironmentVariables()
}


############# BUTTON1
$Button1 = New-Object System.Windows.Forms.Button
$Button1.AutoSize = $true
$Button1.Text = "ADB Shell"
$Button1.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button1.Add_Click({Button1})
$main_form.Controls.Add($Button1)

Function Button1 {
 
$varadb = (adb devices)
$varadb = $varadb -match 'device\b' -replace 'device',''
}

############# BUTTON2
$Button2 = New-Object System.Windows.Forms.Button
$Button2.AutoSize = $true
$Button2.Text = "AVD Download/Install"
$Button2.Location = New-Object System.Drawing.Point(($hShift),($vShift+30))
$Button2.Add_Click({Button2})
$main_form.Controls.Add($Button2)

Function Button2 {
    if (-not(Test-Path -Path "$VARCD\cmdline-tools" )) {
        try {
            Write-Host "[+] Downloading Android Command Line Tools"
            $downloadUri = "https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip"
            Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\commandlinetools-win.zip"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\commandlinetools-win.zip already exists"
            }
  
    Write-Host "[+] Extracting AVD"
    Expand-Archive -Path  "$VARCD\commandlinetools-win.zip" -DestinationPath "$VARCD" -Force
    CheckJava
    Write-Host "[+] Creating licenses Files"
    $licenseContentBase64 = "UEsDBBQAAAAAAKNK11IAAAAAAAAAAAAAAAAJAAAAbGljZW5zZXMvUEsDBAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQo2MDEwODViOTRjZDc3ZjBiNTRmZjg2NDA2OTU3MDk5ZWJlNzljNGQ2UEsDBAoAAAAAAKBK11LzQumJKgAAACoAAAAkAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlDQo4NTlmMzE3Njk2ZjY3ZWYzZDdmMzBhNTBhNTU2MGU3ODM0YjQzOTAzUEsDBAoAAAAAAKFK11IKSOJFKgAAACoAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQ0KMjQzMzNmOGE2M2I2ODI1ZWE5YzU1MTRmODNjMjgyOWIwMDRkMWZlZVBLAwQKAAAAAACiStdSec1a4SoAAAAqAAAAJAAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLXByZXZpZXctbGljZW5zZQ0KODQ4MzFiOTQwOTY0NmE5MThlMzA1NzNiYWI0YzljOTEzNDZkOGFiZFBLAwQKAAAAAACiStdSk6vQKCoAAAAqAAAAGwAAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQ0KMzNiNmEyYjY0NjA3ZjExYjc1OWYzMjBlZjlkZmY0YWU1YzQ3ZDk3YVBLAwQKAAAAAACiStdSrE3jESoAAAAqAAAAJAAAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZQ0KZDk3NWY3NTE2OThhNzdiNjYyZjEyNTRkZGJlZWQzOTAxZTk3NmY1YVBLAwQKAAAAAACjStdSkb1vWioAAAAqAAAAJgAAAGxpY2Vuc2VzL21pcHMtYW5kcm9pZC1zeXNpbWFnZS1saWNlbnNlDQplOWFjYWI1YjVmYmI1NjBhNzJjZmFlY2NlODk0Njg5NmZmNmFhYjlkUEsBAj8AFAAAAAAAo0rXUgAAAAAAAAAAAAAAAAkAJAAAAAAAAAAQAAAAAAAAAGxpY2Vuc2VzLwoAIAAAAAAAAQAYACIHOBcRaNcBIgc4FxFo1wHBTVQTEWjXAVBLAQI/AAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhACQAAAAAAAAAIAAAACcAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2UKACAAAAAAAAEAGACUEFUTEWjXAZQQVRMRaNcB6XRUExFo1wFQSwECPwAKAAAAAACgStdS80LpiSoAAAAqAAAAJAAkAAAAAAAAACAAAACQAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlCgAgAAAAAAABABgAsEM0FBFo1wGwQzQUEWjXAXb1MxQRaNcBUEsBAj8ACgAAAAAAoUrXUgpI4kUqAAAAKgAAABwAJAAAAAAAAAAgAAAA/AAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLWxpY2Vuc2UKACAAAAAAAAEAGAAsMGUVEWjXASwwZRURaNcB5whlFRFo1wFQSwECPwAKAAAAAACiStdSec1a4SoAAAAqAAAAJAAkAAAAAAAAACAAAABgAQAAbGljZW5zZXMvYW5kcm9pZC1zZGstcHJldmlldy1saWNlbnNlCgAgAAAAAAABABgA7s3WFRFo1wHuzdYVEWjXAfGm1hURaNcBUEsBAj8ACgAAAAAAokrXUpOr0CgqAAAAKgAAABsAJAAAAAAAAAAgAAAAzAEAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQoAIAAAAAAAAQAYAGRDRxYRaNcBZENHFhFo1wFfHEcWEWjXAVBLAQI/AAoAAAAAAKJK11KsTeMRKgAAACoAAAAkACQAAAAAAAAAIAAAAC8CAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UKACAAAAAAAAEAGADGsq0WEWjXAcayrRYRaNcBxrKtFhFo1wFQSwECPwAKAAAAAACjStdSkb1vWioAAAAqAAAAJgAkAAAAAAAAACAAAACbAgAAbGljZW5zZXMvbWlwcy1hbmRyb2lkLXN5c2ltYWdlLWxpY2Vuc2UKACAAAAAAAAEAGAA4LjgXEWjXATguOBcRaNcBIgc4FxFo1wFQSwUGAAAAAAgACACDAwAACQMAAAAA"
    $licenseContent = [System.Convert]::FromBase64String($licenseContentBase64)
    Set-Content -Path "$VARCD\android-sdk-licenses.zip" -Value $licenseContent -Encoding Byte
    Expand-Archive  "$VARCD\android-sdk-licenses.zip"  -DestinationPath "$VARCD\"  -Force
    Write-Host "[+] Running sdkmanager/Installing"
    
    $env:ANDROID_SDK_ROOT = "$VARCD\jdk-11.0.1"
    $env:ANDROID_AVD_HOME = "$VARCD\jdk-11.0.1;$env:Path"

    Start-Process -FilePath "$VARCD\cmdline-tools\bin\sdkmanager.bat" -ArgumentList  "--sdk_root=`"$VARCD`" platform-tools && pause" -Wait   -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\bin\sdkmanager.bat" -ArgumentList  "--sdk_root=`"$VARCD`" extras;intel;Hardware_Accelerated_Execution_Manager && pause" -Wait   -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\bin\sdkmanager.bat" -ArgumentList  "--sdk_root=`"$VARCD`" platforms;android-30 && pause" -Wait   -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\bin\sdkmanager.bat" -ArgumentList  "--sdk_root=`"$VARCD`" cmdline-tools;latest && pause" -Wait   -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\bin\sdkmanager.bat" -ArgumentList  "--sdk_root=`"$VARCD`" emulator && pause" -Wait   -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\bin\sdkmanager.bat" -ArgumentList  "--sdk_root=`"$VARCD`" system-images;android-30;google_apis_playstore;x86 && pause" -Wait   -Verbose
    Write-Host "[+] Install AVD Complete"

   

}

<#    
        #  -gpu auto
        # -accel auto

#set ANDROID_SDK_ROOT=%BASE%
#$ANDROID_AVD_HOME, $ANDROID_SDK_HOME\avd and $HOME\.android\avd)
 
:INIT

cd c:\JAMBOREE\ 
set JAVA_HOME="c:\JAMBOREE\jdk-11.0.1\"
set PATH="c:\JAMBOREE\jdk-11.0.1\bin";%PATH%
set ANDROID_SDK_ROOT="c:\JAMBOREE\"
set ANDROID_AVD_HOME="c:\JAMBOREE\"

.\cmdline-tools\bin\avdmanager.bat list --sdk_root="c:\JAMBOREE\"

.\cmdline-tools\bin\avdmanager.bat create avd -n pixel_2 -k "system-images;android-30;google_apis_playstore;x86"  -d "pixel_2"

.\emulator\emulator.exe -avd TRY1  --sdk_root=c:\JAMBOREE\ 


#>

############# SHOW FORM
$main_form.ShowDialog()
