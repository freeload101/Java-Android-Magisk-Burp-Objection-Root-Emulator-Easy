param(
    [Parameter(Mandatory=$false)]
    [string]$Headless
)

# function for messages
#$ErrorActionPreference="Continue"
$Global:VerNum = 'JAMBOREE 4.4.5'

$host.ui.RawUI.WindowTitle = $Global:VerNum 

function Write-Message  {
    <#
    .SYNOPSIS
        Prints	 colored messages depending on type
    .PARAMETER TYPE
        Type of error message to be prepended to the message and sets the color
    .PARAMETER MESSAGE
        Message to be output
    #>
    [CmdletBinding()]
    param (
        [string]
        $Type,
        
        [string]
        $Message
        )

if  (($TYPE) -eq  ("INFO")) { $Tag = "INFO"  ; $Color = "Green"}
if  (($TYPE) -eq  ("WARNING")) { $Tag = "WARNING"  ; $Color = "Yellow"}
if  (($TYPE) -eq  ("ERROR")) { $Tag = "ERROR"  ; $Color = "Red"}
Write-Host  (Get-Date -UFormat "%m/%d:%T")$($Tag)$($Message) -ForegroundColor $Color  
#echo "$Message"
}

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

#backup USERPROFILE for BurpSuite Open Dialog Fix
$USERPROFILE_BACKUP="$env:USERPROFILE"

# set current directory
$VARCD = (Get-Location)

Write-Message  -Message  "Current Working Directory $VARCD" -Type "INFO"
Set-Location -Path "$VARCD"
 
# for pycharm and any other 
Write-Message  -Message  "Setting base path for HOMEPATH,USERPROFILE,APPDATA,LOCALAPPDATA,TEMP and TMP to $VARCD" -Type "INFO"
$env:HOMEPATH="$VARCD"
$env:USERPROFILE="$VARCD"

New-Item -Path "$VARCD\AppData\Roaming" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:APPDATA="$VARCD\AppData\Roaming"

New-Item -Path "$VARCD\AppData\Local" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:LOCALAPPDATA="$VARCD\AppData\Local"

New-Item -Path "$VARCD\AppData\Local\Temp" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:TEMP="$VARCD\AppData\Local\Temp"
$env:TMP="$VARCD\AppData\Local\Temp"

# fix for burp suite Documents Path
New-Item -Path "$VARCD\Documents" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null

 
Write-Message  -Message  "Setting ANDROID ENV Paths $VARCD" -Type "INFO"

$env:ANDROID_SDK_ROOT="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD"
$env:ANDROID_HOME="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD\avd"
New-Item -Path "$VARCD\avd" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:ANDROID_SDK_HOME="$VARCD"

# postgres paths
Write-Message  -Message  "Setting postgres ENV Paths $VARCD" -Type "INFO"
$env:PGDATA = "$VARCD\PG\data"
$env:PGDATABASE = "postgres"
$env:PGUSER = "postgres"
$env:PGPORT = "5439"
$env:PGLOCALEDIR = "$VARCD\PG\data"
$env:PGDATA = "$VARCD\PG\share\locale"
$env:PGLOG = "$VARCD\PG\postgres.log"

#java
Write-Message  -Message  "Setting JAVA ENV Paths $VARCD" -Type "INFO"
$env:JAVA_HOME = "$VARCD\jdk"

Write-Message  -Message  "Setting rootAVD ENV Paths $VARCD" -Type "INFO"
#Use this if you want to keep your %PATH% ...
#$env:Path = "$env:Path;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\python\tools\Scripts;$VARCD\python\tools;python\tools\Lib\site-packages;$VARCD\PortableGit\cmd"

Write-Message  -Message  "Resetting Path variables to not use local python,java,node,adb,git,java,postgres ..." -Type "WARNING"
$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem;$env:SystemRoot\System32\WindowsPowerShell\v1.0\;$VARCD\PG\bin;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\python\tools\Scripts;$VARCD\python\tools\Lib\venv\scripts\;$VARCD\python\tools;python\tools\Lib\site-packages;$VARCD\PortableGit\cmd;$VARCD\jdk\bin;$VARCD\node"

# python
$env:PYTHONHOME="$VARCD\python\tools"

# wsl don't use system32 path !

$env:WSLBIN= "C:\Windows\System32\wsl.exe"

#init stuff
Stop-process -name adb -Force -ErrorAction SilentlyContinue |Out-Null

# Setup Form
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.AutoSize = $true
$main_form.Text = "$VerNum"

$hShift = 0
$vShift = 0

### MAIN ###

################################# FUNCTIONS
 
############# CheckAdmin
Function CheckAdmin {
	
	If ((!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) -and ( $Global:NOGUI -eq $null )) {
		Write-Message  -Message  "Not running as admin" -Type "ERROR"
		if (($PSCommandPath -eq $null ) ) { function GetPSCommandPath() { return $MyInvocation.PSCommandPath; } $PSCommandPath = GetPSCommandPath }
			$wshell = New-Object -ComObject Wscript.Shell
			$pause = $wshell.Popup("Need to esclate to administrator to run the current Function!", 0, "Wait!", 48+1)	
			if ($pause -eq '1') {
				Write-Message  -Message  "Restarting $PSCommandPath as admin... " -Type "INFO"
				Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" " -WorkingDirectory "$VARCD" -Verb RunAs
    				exit
			}
			Elseif ($pause = '2') {
				Write-Message  -Message  "Not running as admin" -Type "ERROR"
    				Start-Sleep -Seconds 5
    				exit
			}
	}
}

############# WSLEnableUpdate
Function WSLEnableUpdate {
 
Start-Process -FilePath "$env:WSLBIN" -ArgumentList  " --version"  -NoNewWindow -RedirectStandardOutput "RedirectStandardOutput.txt"
Start-Sleep -Seconds 1
$wslInfo = Get-Content -Path "RedirectStandardOutput.txt" 
if (($wslInfo) -match  (".*:.2.*")  -or ($wslInfo) -match  (".*W.S.L. .v.e.r.s.i.o.n.:. .2.*"))  {
	Write-Message  -Message  "WSL version 2 found OK" -Type "INFO"
} else {
	Write-Message  -Message  "Updating WSL" -Type "WARNING"
    CheckAdmin
	Write-Message  -Message  "Setting up WSL 2" -Type "INFO"
	dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
	dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
	
    Start-Process -FilePath "$env:WSLBIN" -ArgumentList "--update "  -Wait
    Start-Process -FilePath "$env:WSLBIN" -ArgumentList "--set-default-version 2 "  
}

 }

############# WSLOracleLinux
Function WSLOracleLinux {
WSLEnableUpdate

Start-Process -FilePath "$env:WSLBIN" -ArgumentList  " --list"  -NoNewWindow -RedirectStandardOutput "RedirectStandardOutput.txt"
Start-Sleep -Seconds 1
$wslInfo = Get-Content -Path "RedirectStandardOutput.txt" 
if (($wslInfo) -match  (".*OracleLinux_9_1.*")  -or ($wslInfo) -match  (".*O.r.a.c.l.e.L.i.n.u.x.*"))  {
	Write-Message  -Message  "OracleLinux_9_1 found Starting..." -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d OracleLinux_9_1 -u root"  
} else {
	Write-Message  -Message  "OracleLinux_9_1 NOT found ..." -Type "WARNING"
	Write-Message  -Message  "Updating WSL. You may need to reboot for changes to take effect " -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --update "  -wait -NoNewWindow

	Write-Message  -Message  "Listing WSL options --list --online " -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --list --online " -wait -NoNewWindow

	Write-Message  -Message  "Removing OracleLinux_9_1" -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --shutdown -d OracleLinux_9_1 " -wait -NoNewWindow
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --unregister OracleLinux_9_1 " -wait -NoNewWindow
	
	Write-Message  -Message  "Waiting 10 seconds.." -Type "INFO"
	Start-Sleep -Seconds 10

	Write-Message  -Message  "Installing OracleLinux_9_1" -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --install -d OracleLinux_9_1 " -NoNewWindow

	Write-Message  -Message  "Waiting 10 seconds.." -Type "INFO"
	Start-Sleep -Seconds 10

	Write-Message  -Message  "Updating OracleLinux_9_1 this may take some time..." -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d OracleLinux_9_1 -u root -e bash -c `"yum -y update`" " -wait -NoNewWindow

	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d OracleLinux_9_1 -u root"   
}

}

############# CheckVolatility3
Function CheckVolatility3 {
   if (-not(Test-Path -Path "$VARCD\volatility3-develop" )) { 
        try {
            CheckPython
			Write-Message  -Message  "Downloading volatility3" -Type "INFO"
			downloadFile "https://github.com/volatilityfoundation/volatility3/archive/refs/heads/develop.zip" "$VARCD\develop.zip"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            		Add-Type -AssemblyName System.IO.Compression
			[System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\develop.zip", "$VARCD\")

   			Write-Message  -Message  "Downloading upx-3.96-win64.zip" -Type "INFO"
			downloadFile "https://github.com/upx/upx/releases/download/v3.96/upx-3.96-win64.zip" "$VARCD\upx.zip"
			[System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\upx.zip", "$VARCD\")
			
			
			Write-Message -Message "Installing Setuptools" -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " -m pip install setuptools " -wait -NoNewWindow
			Write-Message -Message "Installing pyinstaller " -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " -m pip install pyinstaller " -wait -NoNewWindow
			Write-Message -Message "Installing requirements.txt" -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " -m pip install -r requirements.txt " -wait -NoNewWindow
            
			
			Write-Message -Message "Building Volatility" -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " setup.py build " -wait -NoNewWindow
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " setup.py install " -wait -NoNewWindow
						
			Write-Message  -Message  "Running pyinstaller to create binary  " -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\Scripts\pyinstaller.exe" -WorkingDirectory "$VARCD\volatility3-develop\volatility3"  -ArgumentList "  --upx-dir `"$VARCD\upx-3.96-win64`" ..\vol.spec " -wait -NoNewWindow

			Write-Message  -Message  "Downloading Volatility Symbols ~800MB" -Type "INFO"
			downloadFile "https://downloads.volatilityfoundation.org/volatility3/symbols/windows.zip" "$VARCD\windows.zip"
			New-Item -Path "$VARCD\volatility3-develop\volatility3\dist\symbols" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
			[System.IO.Compression.ZipFile]::ExtractToDirectory( "$VARCD\windows.zip", "$VARCD\volatility3-develop\volatility3\dist\symbols")
			
			Write-Message  -Message  "Complete opening volatility3 folder example command line .\vol.exe -f  memory.dump windows.pslist " -Type "INFO"
			explorer "$VARCD\volatility3-develop\volatility3\dist"
			New-Item -Path "$VARCD\volatility3-develop\volatility3\dist\symbols" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
			
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Message  -Message  "$VARCD\volatility3-develop Already Exist" -Type "WARNING"
            }
} 

############# WSLUbuntu
Function WSLUbuntu {
WSLEnableUpdate

Start-Process -FilePath "$env:WSLBIN" -ArgumentList  " --list"  -NoNewWindow -RedirectStandardOutput "RedirectStandardOutput.txt"
Start-Sleep -Seconds 1
$wslInfo = Get-Content -Path "RedirectStandardOutput.txt" 
if (($wslInfo) -match  (".*Ubuntu.*")  -or ($wslInfo) -match  (".*U.b.u.n.t.u.*"))  {
		Write-Message  -Message  "Ubuntu found Starting bash shell" -Type "INFO"
		Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d Ubuntu -u root -e bash "  
} else {
	Write-Message  -Message  "Ubuntu NOT found ..." -Type "WARNING"
	Write-Message  -Message  "Updating WSL -update " -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --update "  -wait -NoNewWindow

	Write-Message  -Message  "Listing WSL options --list --online " -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --list --online " -wait -NoNewWindow

	Write-Message  -Message  "Removing Ubuntu" -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --shutdown -d Ubuntu " -wait -NoNewWindow
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --unregister Ubuntu " -wait -NoNewWindow
	
	Write-Message  -Message  "Waiting 10 seconds.." -Type "INFO"
	Start-Sleep -Seconds 10

	Write-Message  -Message  "Installing Ubuntu" -Type "INFO"
	Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --install -d Ubuntu " -NoNewWindow

	Write-Message  -Message  "Waiting 10 seconds.." -Type "INFO"
	Start-Sleep -Seconds 10
	}

}

############# CheckNode
Function CheckNode {
   if (-not(Test-Path -Path "$VARCD\node" )) {
        try {
			Write-Message  -Message  "Downloading latest node" -Type "INFO"
			$downloadUri = $downloadUri = (Invoke-RestMethod -Method GET -Uri "https://nodejs.org/dist/latest/")  -split '"' -match '.*node-.*-win-x64.zip.*' | ForEach-Object {$_ -ireplace '^\/','https://nodejs.org/' } | select -first 1
            downloadFile "$downloadUri" "$VARCD\node.zip"
			Write-Message  -Message  "Extracting Node" -Type "INFO"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\node.zip", "$VARCD")
			Get-ChildItem "$VARCD\node-*"  | Rename-Item -NewName "node"
			Write-Message  -Message  "Updating npm" -Type "INFO"
			Start-Process -FilePath "$VARCD\node\npm.cmd" -WorkingDirectory "$VARCD\node" -ArgumentList " install -g npm " -wait -NoNewWindow
			}
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
			Write-Message  -Message  "$VARCD\node already Exist" -Type "WARNING"
			}
}

############# CheckNodeRMS
Function CheckNodeRMS {
Write-Message  -Message  "Checking for node 22.9.0" -Type "WARNING"
$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem;$env:SystemRoot\System32\WindowsPowerShell\v1.0\;$VARCD\PG\bin;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\python\tools\Scripts;$VARCD\python\tools\Lib\venv\scripts\;$VARCD\python\tools;python\tools\Lib\site-packages;$VARCD\PortableGit\cmd;$VARCD\jdk\bin;$VARCD\nodeRMS"

 
   if (-not(Test-Path -Path "$VARCD\nodeRMS" )) {
        try {
			Write-Message  -Message  "Downloading 22.9.0 node" -Type "INFO"
			$downloadUri = $downloadUri = (Invoke-RestMethod -Method GET -Uri "https://nodejs.org/dist/latest/")  -split '"' -match '.*node-.*-win-x64.zip.*' | ForEach-Object {$_ -ireplace '^\/','https://nodejs.org/' } | select -first 1
            downloadFile "https://nodejs.org/dist/v22.9.0/node-v22.9.0-win-x64.zip" "$VARCD\node.zip"
			Write-Message  -Message  "Extracting Node" -Type "INFO"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\node.zip", "$VARCD")
			Get-ChildItem "$VARCD\node-*"  | Rename-Item -NewName "nodeRMS"
			Write-Message  -Message  "Updating npm" -Type "INFO"
			Start-Process -FilePath "$VARCD\nodeRMS\npm.cmd" -WorkingDirectory "$VARCD\nodeRMS" -ArgumentList " install -g npm " -wait -NoNewWindow
			}
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
			Write-Message  -Message  "$VARCD\nodeRMS already Exist" -Type "WARNING"
			}
}




############# StartRMS
Function StartRMS {
	CheckPython
	CheckNodeRMS
	
	if (-not(Test-Path -Path "$VARCD\nodeRMS\rms.cmd" )) {
	try {
		Start-Process -FilePath "$VARCD\nodeRMS\npm.cmd" -WorkingDirectory "$VARCD\nodeRMS" -ArgumentList " install -g rms-runtime-mobile-security " -wait -NoNewWindow
		}
			catch {
				throw $_.Exception.Message
		}
		}
	else {
		Write-Message  -Message  "$VARCD\nodeRMS\rms.cmd already exist" -Type "INFO"
	}
	
StartFrida
Write-Message  -Message  "Killing node " -Type "INFO"
Stop-process -name node -Force -ErrorAction SilentlyContinue |Out-Null

Write-Message  -Message  "Starting rms-runtime-mobile-security please wait....." -Type "INFO"
Start-Process -FilePath "$VARCD\nodeRMS\rms.cmd"    -WorkingDirectory "$VARCD\nodeRMS" -NoNewWindow
Start-Sleep -Seconds 5
Start-Process "http://127.0.0.1:5491/"
}

############# StartSillyTavern
Function StartSillyTavern {
	CheckGit
	Write-Message  -Message  "Killing node " -Type "INFO"
	Stop-process -name node -Force -ErrorAction SilentlyContinue |Out-Null
	CheckNode
	if (-not(Test-Path -Path "$VARCD\SillyTavern" )) {
	try {
		Write-Message  -Message  "Running git clone https://github.com/SillyTavern/SillyTavern -b staging" -Type "INFO"
  		# -b staging broke TTS Autogen!
		Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD\" -ArgumentList " clone `"https://github.com/SillyTavern/SillyTavern`" -b staging " -wait -NoNewWindow
		}
			catch {
				throw $_.Exception.Message
		}
		}
	else {
		Write-Message  -Message  "$VARCD\SillyTavern" -Type "WARNING"
	}
	
Write-Message  -Message  "Starting SillyTavern please wait....." -Type "INFO"
Start-Process -FilePath "$VARCD\SillyTavern\Start.bat"    -WorkingDirectory "$VARCD\SillyTavern" -NoNewWindow

}

############# CheckADB
function CheckADB {
if ((Get-Command adb -ErrorAction SilentlyContinue)) {
    $varadb =  (adb devices)
    Write-Message  -Message  "$varadb" -Type "INFO"  
    $varadb = $varadb -match 'device\b' -replace 'device','' -replace '\s',''
    Write-Message  -Message  "Online Device: $varadb" -Type "INFO"
        if (($varadb.length -lt 1 )) {
            Write-Message  -Message  "ADB Failed! Check for unauthorized devices listed in ADB UI or use ! AVD Wipe Button" -Type "ERROR"
			$wshShell = New-Object -ComObject Wscript.Shell
			$message = "Check for unauthorized devices listed in ADB UI or use ! AVD Wipe Button"
			$wshShell.Popup($message, 0, "ADB Failed!", 48)
			adb devices  
        }
	return $varadb

    }  
}

############# KillADB
function KillADB {
    Write-Message  -Message  "Killing ADB.exe " -Type "INFO"
    Stop-process -name adb -Force -ErrorAction SilentlyContinue |Out-Null
}

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
        #[System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
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
            Write-Message  -Message  "Downloading Java" -Type "INFO"
            # does not work for neo4j bloodhound wants java11 ... downloadFile "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip" "$VARCD\openjdk.zip"
            downloadFile "https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_windows-x64_bin.zip" "$VARCD\jdk_neo4j.zip"
			Write-Message  -Message  "Extracting Java" -Type "INFO"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\jdk_neo4j.zip", "$VARCD")
			Get-ChildItem "$VARCD\jdk-*"  | Rename-Item -NewName "jdk_neo4j"
			$env:JAVA_HOME = "$VARCD\jdk_neo4j"
			$env:Path = "$VARCD\jdk_neo4j;$env:Path"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\jdk_neo4j already exists" -Type "WARNING"
            $env:JAVA_HOME = "$VARCD\jdk_neo4j"
			
			}
}
############# CHECK JAVA
Function CheckJava {
Write-Message  -Message  "Checking for Java" -Type "INFO"
   if (-not(Test-Path -Path "$VARCD\jdk" )) {
            Write-Message  -Message  "Downloading Java" -Type "INFO"
            downloadFile "https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_windows-x64_bin.zip" "$VARCD\jdk.zip"
            Write-Message  -Message  "Extracting Java" -Type "INFO"
			Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\jdk.zip", "$VARCD")
			Get-ChildItem "$VARCD\jdk-*"  | Rename-Item -NewName { $_.Name -replace '-.*','' }
            $env:JAVA_HOME = "$VARCD\jdk"
            #$env:Path = "$VARCD\jdk;$env:Path"
            }
        else {
            Write-Message  -Message  "$VARCD\openjdk.zip already exists" -Type "WARNING"
            }
}

############# CHECK Frida tools
Function CheckFrida {
			# for frida/AVD
			Write-Message  -Message  "Installing objection and python-xz needed for AVD" -Type "INFO"
			
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install objection " -wait -NoNewWindow
            # for Frida Android Binary
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install python-xz " -wait -NoNewWindow
			Write-Message  -Message  "Installing frida-tools" -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install frida-tools==13.7.1 frida==16.7.19 " -wait -NoNewWindow
}			

############# CHECK PYTHON
Function CheckPython {
   if (-not(Test-Path -Path "$VARCD\python" )) {
            Write-Message  -Message  "Downloading Python nuget package" -Type "INFO"
            downloadFile "https://www.nuget.org/api/v2/package/python" "$VARCD\python.zip"
            New-Item -Path "$VARCD\python" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
            Write-Message  -Message  "Extracting Python nuget package" -Type "INFO"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\python.zip", "$VARCD\python")
			Write-Message  -Message  "Updating pip" -Type "INFO"
			Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install --upgrade pip " -wait -NoNewWindow

New-Item -ItemType Directory -Path "$VARCD\python\tools\Scripts" -ErrorAction SilentlyContinue |Out-Null
# DO NOT INDENT THIS PART
$PipBatch = @'
python -m pip %*
'@
$PipBatch | Out-File -Encoding Ascii -FilePath "$VARCD\python\tools\Scripts\pip.bat" -ErrorAction SilentlyContinue |Out-Null
# DO NOT INDENT THIS PART

            }
        else {
            Write-Message  -Message  "$VARCD\python already exists" -Type "WARNING"
            }
			Write-Message  -Message  "CheckPython Complete" -Type "INFO"
}

############# InstallAPKS
function InstallAPKS {

Write-Message  -Message  "Downloading Base APKS" -Type "INFO"
New-Item -Path "$VARCD\APKS" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null

Write-Message  -Message  "Downloading SAI Split Package Installer" -Type "INFO"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/Aefyr/SAI/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\SAI.apk"

Write-Message  -Message  "Downloading Amaze File Manager" -Type "INFO"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/TeamAmaze/AmazeFileManager/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\AmazeFileManager.apk"

Write-Message  -Message  "Downloading Duckduckgo" -Type "INFO"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/duckduckgo/Android/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\duckduckgo.apk"

Write-Message  -Message  "Downloading Gameguardian" -Type "INFO"
downloadFile "https://gameguardian.net/forum/files/file/2-gameguardian/?do=download&r=50314&confirm=1&t=1" "$VARCD\APKS\gameguardian.apk"

Write-Message  -Message  "Downloading Lucky Patcher" -Type "INFO"
downloadFile "https://chelpus.com/luckypatcher/LuckyPatcherInstaller.apk" "$VARCD\APKS\LP_Downloader.apk"

Write-Message  -Message  "Downloading YASNAC" -Type "INFO"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/RikkaW/YASNAC/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\yasnac.apk"

Write-Message  -Message  "Downloading App Manager - Android package manager" -Type "INFO"
$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/MuntashirAkon/AppManager/releases/latest").assets | Where-Object name -like *.apk ).browser_download_url
downloadFile "$downloadUri" "$VARCD\APKS\AppManager.apk"

Write-Message  -Message  "Downloading AndroGoat.apk" -Type "INFO"
downloadFile "https://github.com/satishpatnayak/MyTest/raw/master/AndroGoat.apk" "$VARCD\APKS\AndroGoat.apk"

SecListsCheck

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Message  -Message  "Installing Base APKS" -Type "INFO"

(Get-ChildItem -Path "$VARCD\APKS").FullName |ForEach-Object {
	Write-Message  -Message  "Installing $_" -Type "INFO"
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " install $_ "  -NoNewWindow -Wait
	
    }
Write-Message  -Message  "Complete Installing Base APKS" -Type "INFO"
}

############# CertPush
function CertPush {
Write-Message  -Message  "Starting CertPush" -Type "INFO"

$wshShell = New-Object -ComObject Wscript.Shell
$message = "Be sure to go to WiFi settings and set proxy to 10.0.2.2:8080"
$wshShell.Popup($message, 0, "Proxy Configuration Warning", 48)

AlwaysTrustUserCerts

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Message  -Message  "Converting $VARCD\BURP.der to $VARCD\BURP.pem" -Type "INFO"
Remove-Item -Path "$VARCD\BURP.pem" -Force -ErrorAction SilentlyContinue |Out-Null
Start-Process -FilePath "$env:SYSTEMROOT\System32\certutil.exe" -ArgumentList  " -encode `"$VARCD\BURP.der`"  `"$VARCD\BURP.pem`" "  -NoNewWindow -Wait

Write-Message  -Message  "Copying PEM to Androind format just in case its not standard burp suite cert Subject Hash" -Type "INFO"
# Rename a PEM in Android format (openssl -subject_hash_old ) with just certutil and powershell
$CertSubjectHash = (certutil "$VARCD\BURP.der")
$CertSubjectHash = $CertSubjectHash |Select-String  -Pattern 'Subject:.*' -AllMatches  -Context 1, 8
$CertSubjectHash = ($CertSubjectHash.Context.PostContext[7]).SubString(24,2)+($CertSubjectHash.Context.PostContext[7]).SubString(22,2)+($CertSubjectHash.Context.PostContext[7]).SubString(20,2)+($CertSubjectHash.Context.PostContext[7]).SubString(18,2)+"."+0
Copy-Item -Path "$VARCD\BURP.pem" -Destination "$VARCD\$CertSubjectHash" -Force

Write-Message  -Message "Pushing $VARCD\$CertSubjectHash to /sdcard " -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push `"$VARCD\$CertSubjectHash`"   /sdcard"  -NoNewWindow -Wait

Write-Message  -Message "Pushing $VARCD\BURP.der to  /data/local/tmp/cert-der.crt " -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push `"$VARCD\BURP.der`"   /data/local/tmp/cert-der.crt"  -NoNewWindow -Wait

Write-Message  -Message "Pushing Copying /scard/$CertSubjectHash /data/misc/user/0/cacerts-added " -Type "INFO"

Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c mkdir /data/misc/user/0/cacerts-added`" "  -NoNewWindow -Wait

Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c cp /sdcard/$CertSubjectHash /data/misc/user/0/cacerts-added`" " -NoNewWindow -Wait

Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c chown root:root /data/misc/user/0/cacerts-added/$CertSubjectHash"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c chmod 644 /data/misc/user/0/cacerts-added/$CertSubjectHash"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c ls -laht /data/misc/user/0/cacerts-added/$CertSubjectHash"  -NoNewWindow -Wait

Write-Message  -Message  "Reboot for changes to take effect!" -Type "INFO"
}

############# AlwaysTrustUserCerts
Function AlwaysTrustUserCerts {
Write-Message  -Message  "Checking for $VARCD\trustusercerts " -Type "INFO"
   if (-not(Test-Path -Path "$VARCD\trustusercerts" )) {
        try {
            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/NVISOsecurity/MagiskTrustUserCerts/releases/latest").assets | Where-Object name -like *.zip ).browser_download_url
            Write-Message  -Message  "Downloading Magisk Module AlwaysTrustUserCerts.zip" -Type "INFO"
            Invoke-WebRequest -Uri $downloadUri -Out "$VARCD\AlwaysTrustUserCerts.zip"
            Write-Message  -Message  "Extracting AlwaysTrustUserCerts.zip" -Type "INFO"
            Expand-Archive -Path  "$VARCD\AlwaysTrustUserCerts.zip" -DestinationPath "$VARCD\trustusercerts" -Force
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\AlwaysTrustUserCerts.zip already exists" -Type "INFO"
            }

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Message  -Message  "Pushing $VARCD\AlwaysTrustUserCerts.zip" -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push `"$VARCD\trustusercerts`"   /sdcard"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c cp -R /sdcard/trustusercerts /data/adb/modules`" " -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c find /data/adb/modules`" "  -NoNewWindow -Wait

}
Function StartFrida {
CheckPython
CheckFrida
   if (-not(Test-Path -Path "$VARCD\frida-server" )) {
        try {
            Write-Message  -Message  "Downloading  16.7.19 $downloadUri " -Type "INFO"
			
            # latest is broken ? $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/frida/frida/releases/latest").assets | Where-Object name -like frida-server-*-android-x86.xz ).browser_download_url
            #downloadFile  $downloadUri "$VARCD\frida-server-android_LATEST.xz"
			
			# fix this ..static binary bad !
			downloadFile  "https://github.com/frida/frida/releases/download/16.7.19/frida-server-16.7.19-android-x86.xz" "$VARCD\frida-server-android_LATEST.xz"
            Write-Message  -Message  "Extracting $downloadUri" -Type "INFO"
# don't mess with spaces for these lines for python ...
$PythonXZ = @'
import xz
import shutil

with xz.open('frida-server-android_LATEST.xz') as f:
    with open('frida-server', 'wb') as fout:
        shutil.copyfileobj(f, fout)
'@
# don't mess with spaces for these lines for python ...

            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD" -ArgumentList " `"$VARCD\frida-server-extract.py`" " -NoNewWindow 
            $PythonXZ | Out-File -FilePath frida-server-extract.py
            # change endoding from Windows-1252 to UTF-8
            Set-Content -Path "$VARCD\frida-server-extract.py" -Value $PythonXZ -Encoding UTF8 -PassThru -Force

            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\frida-server already exists" -Type "WARNING"
            }

$varadb=CheckADB
$env:ANDROID_SERIAL=$varadb

Write-Message  -Message  "Pushing $VARCD\frida-server" -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c killall frida-server;sleep 1`" "  -NoNewWindow -Wait -ErrorAction SilentlyContinue |Out-Null
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " push `"$VARCD\frida-server`"   /sdcard"  -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c cp -R /sdcard/frida-server /data/local/tmp`" " -NoNewWindow -Wait
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c chmod 777 /data/local/tmp/frida-server`" "  -NoNewWindow -Wait
Write-Message  -Message  "Starting /data/local/tmp/frida-server" -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c /data/local/tmp/frida-server &`" "  -NoNewWindow 

}

Function StartJAMBOREE_SSL_N_ANTIROOT {
CheckFrida
StartFrida

Write-Message  -Message  "Running Frida-ps select package to run JAMBOREE_SSL_N_ANTIROOT.JS:" -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c pm list packages  `" "  -NoNewWindow -RedirectStandardOutput "$VARCD\RedirectStandardOutput.txt"

Start-Sleep -Seconds 2
$PackageName = (Get-Content -Path "$VARCD\RedirectStandardOutput.txt") -replace 'package:',''    | Out-GridView -Title "Select Package to Run Objection" -OutputMode Single

Write-Message  -Message  "Downloading Frida Root/SSL Depinning JAMBOREE_SSL_N_ANTIROOT.JS" -Type "INFO"
downloadFile "https://raw.githubusercontent.com/freeload101/SCRIPTS/master/JS/JAMBOREE_SSL_N_ANTIROOT.JS" "$VARCD\JAMBOREE_SSL_N_ANTIROOT.JS"

Write-Message  -Message  "Starting Frida with JAMBOREE_SSL_N_ANTIROOT.JS" -Type "INFO"
Start-Process -FilePath "$VARCD\python\tools\Scripts\frida.exe" -WorkingDirectory "$VARCD\python\tools\Scripts" -ArgumentList " -l `"$VARCD\JAMBOREE_SSL_N_ANTIROOT.JS`" -f $PackageName -U " -NoNewWindow

start-sleep -Seconds 5

}

Function StartObjection {
CheckPython
StartFrida

Write-Message  -Message  "Running Frida-ps select package to run Objection on:" -Type "INFO"
Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell `"su -c pm list packages  `" "  -NoNewWindow -RedirectStandardOutput "$VARCD\RedirectStandardOutput.txt"
Start-Sleep -Seconds 2
$PackageName = (Get-Content -Path "$VARCD\RedirectStandardOutput.txt") -replace 'package:',''    | Out-GridView -Title "Select Package to Run Objection" -OutputMode Single

Write-Message  -Message  "Starting Objection" -Type "INFO"
Start-Process -FilePath "$VARCD\python\tools\Scripts\objection.exe" -WorkingDirectory "$VARCD\python\tools\Scripts" -ArgumentList " --gadget $PackageName explore " -NoNewWindow

#Send keys needd for objection or whatever...
#Add-Type -AssemblyName System.Windows.Forms
#[System.Windows.Forms.SendKeys]::SendWait("android sslpinning disable")
#start-sleep -Seconds 1
#[System.Windows.Forms.SendKeys]::SendWait("{enter}")
#[System.Windows.Forms.SendKeys]::SendWait("{enter}")

Start-sleep -Seconds 5
 
}

############# StartADB
function StartADB {
    $varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " logcat *:W  "
}

############# AVDDownload
Function AVDDownload {

    if (-not(Test-Path -Path "$VARCD\emulator" )) {
            Write-Message  -Message  "Downloading Android Command Line Tools" -Type "INFO"
            downloadFile "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip" "$VARCD\commandlinetools-win.zip"
            Write-Message  -Message  "Extracting AVD" -Type "INFO"
            Expand-Archive -Path  "$VARCD\commandlinetools-win.zip" -DestinationPath "$VARCD" -Force
            Write-Message  -Message  "Setting path to latest that AVD wants ..." -Type "INFO"
            Rename-Item -Path "$VARCD\cmdline-tools" -NewName "$VARCD\latest"
            New-Item -Path "$VARCD\cmdline-tools" -ItemType Directory
            Move-Item "$VARCD\latest" "$VARCD\cmdline-tools\"
			
			CheckJava
			CheckPython
			Write-Message  -Message  "Creating licenses Files" -Type "INFO"
			$licenseContentBase64 = "UEsDBBQAAAAAAKNK11IAAAAAAAAAAAAAAAAJAAAAbGljZW5zZXMvUEsDBAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQo2MDEwODViOTRjZDc3ZjBiNTRmZjg2NDA2OTU3MDk5ZWJlNzljNGQ2UEsDBAoAAAAAAKBK11LzQumJKgAAACoAAAAkAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlDQo4NTlmMzE3Njk2ZjY3ZWYzZDdmMzBhNTBhNTU2MGU3ODM0YjQzOTAzUEsDBAoAAAAAAKFK11IKSOJFKgAAACoAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQ0KMjQzMzNmOGE2M2I2ODI1ZWE5YzU1MTRmODNjMjgyOWIwMDRkMWZlZVBLAwQKAAAAAACiStdSec1a4SoAAAAqAAAAJAAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLXByZXZpZXctbGljZW5zZQ0KODQ4MzFiOTQwOTY0NmE5MThlMzA1NzNiYWI0YzljOTEzNDZkOGFiZFBLAwQKAAAAAACiStdSk6vQKCoAAAAqAAAAGwAAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQ0KMzNiNmEyYjY0NjA3ZjExYjc1OWYzMjBlZjlkZmY0YWU1YzQ3ZDk3YVBLAwQKAAAAAACiStdSrE3jESoAAAAqAAAAJAAAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZQ0KZDk3NWY3NTE2OThhNzdiNjYyZjEyNTRkZGJlZWQzOTAxZTk3NmY1YVBLAwQKAAAAAACjStdSkb1vWioAAAAqAAAAJgAAAGxpY2Vuc2VzL21pcHMtYW5kcm9pZC1zeXNpbWFnZS1saWNlbnNlDQplOWFjYWI1YjVmYmI1NjBhNzJjZmFlY2NlODk0Njg5NmZmNmFhYjlkUEsBAj8AFAAAAAAAo0rXUgAAAAAAAAAAAAAAAAkAJAAAAAAAAAAQAAAAAAAAAGxpY2Vuc2VzLwoAIAAAAAAAAQAYACIHOBcRaNcBIgc4FxFo1wHBTVQTEWjXAVBLAQI/AAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhACQAAAAAAAAAIAAAACcAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2UKACAAAAAAAAEAGACUEFUTEWjXAZQQVRMRaNcB6XRUExFo1wFQSwECPwAKAAAAAACgStdS80LpiSoAAAAqAAAAJAAkAAAAAAAAACAAAACQAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlCgAgAAAAAAABABgAsEM0FBFo1wGwQzQUEWjXAXb1MxQRaNcBUEsBAj8ACgAAAAAAoUrXUgpI4kUqAAAAKgAAABwAJAAAAAAAAAAgAAAA/AAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLWxpY2Vuc2UKACAAAAAAAAEAGAAsMGUVEWjXASwwZRURaNcB5whlFRFo1wFQSwECPwAKAAAAAACiStdSec1a4SoAAAAqAAAAJAAkAAAAAAAAACAAAABgAQAAbGljZW5zZXMvYW5kcm9pZC1zZGstcHJldmlldy1saWNlbnNlCgAgAAAAAAABABgA7s3WFRFo1wHuzdYVEWjXAfGm1hURaNcBUEsBAj8ACgAAAAAAokrXUpOr0CgqAAAAKgAAABsAJAAAAAAAAAAgAAAAzAEAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQoAIAAAAAAAAQAYAGRDRxYRaNcBZENHFhFo1wFfHEcWEWjXAVBLAQI/AAoAAAAAAKJK11KsTeMRKgAAACoAAAAkACQAAAAAAAAAIAAAAC8CAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UKACAAAAAAAAEAGADGsq0WEWjXAcayrRYRaNcBxrKtFhFo1wFQSwECPwAKAAAAAACjStdSkb1vWioAAAAqAAAAJgAkAAAAAAAAACAAAACbAgAAbGljZW5zZXMvbWlwcy1hbmRyb2lkLXN5c2ltYWdlLWxpY2Vuc2UKACAAAAAAAAEAGAA4LjgXEWjXATguOBcRaNcBIgc4FxFo1wFQSwUGAAAAAAgACACDAwAACQMAAAAA"
			$licenseContent = [System.Convert]::FromBase64String($licenseContentBase64)
			Set-Content -Path "$VARCD\android-sdk-licenses.zip" -Value $licenseContent -Encoding Byte
			Expand-Archive  "$VARCD\android-sdk-licenses.zip"  -DestinationPath "$VARCD\"  -Force
			Write-Message  -Message  "Running sdkmanager/Installing" -Type "INFO"
			
			# now we are using latest cmdline-tools ...!?
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "platform-tools" -Verbose -Wait -NoNewWindow
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "extras;intel;Hardware_Accelerated_Execution_Manager" -Verbose -Wait -NoNewWindow
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "platforms;android-30" -Verbose -Wait -NoNewWindow
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "emulator" -Verbose -Wait -NoNewWindow
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "system-images;android-30;google_apis_playstore;x86" -Verbose -Wait -NoNewWindow
			Write-Message  -Message  "AVD Install Complete Creating AVD Device" -Type "INFO"
			Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\avdmanager.bat" -ArgumentList  "create avd -n pixel_2 -k `"system-images;android-30;google_apis_playstore;x86`"  -d `"pixel_2`" --force" -Wait -Verbose -NoNewWindow
			Start-Sleep -Seconds 2
            }
        else {
            Write-Message  -Message  "AVDDownload: $VARCD\cmdline-tools already exists remove everything but this script to perform full reinstall/setup" -Type "WARNING"
            Write-Message  -Message  "Current Working Directory $VARCD" -Type "WARNING"
            Start-Sleep -Seconds 1
            }
 
   
  
}

############# HAXMInstall
Function HyperVInstall {
    $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
    # Check if Hyper-V is enabled
    if($hyperv.State -eq "Enabled") {
        Write-Message  -Message  "[!] Hyper-V is already enabled." -Type "INFO"
    } else {
        Write-Message  -Message  "Hyper-V not found, installing ..."         -Type "INFO"
        KillADB
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    }
}

############# HAXMInstall
Function HAXMInstall {
	Write-Message  -Message  "Killing ADB processes" -Type "INFO"
	KillADB
	Write-Message  -Message  "Downloading intel/haxm" -Type "INFO"
	# Upgrade to AEHD !?!?  https://github.com/intel/haxm/releases/download/v7.6.5/haxm-windows_v7_6_5.zip must be used $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/intel/haxm/releases/latest").assets | Where-Object name -like *windows*.zip ).browser_download_url
	downloadFile "https://github.com/intel/haxm/releases/download/v7.6.5/haxm-windows_v7_6_5.zip" "$VARCD\haxm-windows.zip"
	
	Write-Message  -Message  "Extracting haxm-windows.zip" -Type "INFO"
    Expand-Archive -Path  "$VARCD\haxm-windows.zip" -DestinationPath "$VARCD\haxm-windows" -Force
    	Write-Message  -Message  "Running $VARCD\haxm-windows\silent_install.bat" -Type "INFO"
	Start-Process -FilePath "$VARCD\haxm-windows\silent_install.bat" -WorkingDirectory "$VARCD\haxm-windows" -Wait -NoNewWindow
	
}

############# AVDStart
Function AVDStart {
	CheckProcess "Burp Suite" StartBurp
	if (-not(Test-Path -Path "$VARCD\emulator" )) {
			AVDDownload
			Write-Message  -Message  "$VARCD\emulator already exists remove everything but this script to perform full reinstall/setup" -Type "INFO"
			Write-Message  -Message  "Starting AVD emulator" -Type "INFO"
			Start-Sleep -Seconds 2
			Write-Message  -Message  "Do not run emulator with  -http-proxy 127.0.0.1:8080 it is not stable" -Type "INFO"
			# DO NOT USE THIS IT IS BUGGY ... Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -http-proxy 127.0.0.1:8080" -NoNewWindow
            Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system " -NoNewWindow
				Start-Sleep -Seconds 10
				Write-Message  -Message  "Enbleing keyboard in config.ini" -Type "INFO"
				(Get-Content "$VARCD\avd\pixel_2.avd\config.ini") `
				-replace 'hw.keyboard = no', 'hw.keyboard = yes' `
				-replace 'hw.camera.back.*', 'hw.camera.back = webcam0' `
				-replace 'hw.camera.front.*', 'hw.camera.front = none' ` |
				Out-File -Encoding Ascii "$VARCD\avd\pixel_2.avd\config.ini"
            }
    else {
            Write-Message  -Message  "AVDStart $VARCD\emulator already exists remove everything but this script to perform full reinstall/setup" -Type "WARNING"
			Write-Message  -Message  "Starting AVD emulator" -Type "INFO"
			Start-Sleep -Seconds 2
			Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system " -NoNewWindow
			
            }
}

############# AVDPoweroff
Function AVDPoweroff {
    $varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb
	
	
	$wshell = New-Object -ComObject Wscript.Shell
	$pause = $wshell.Popup("Are you sure you want to shutdown?", 0, "Wait!", 48+1)
	
	if ($pause -eq '1') {
		Write-Message  -Message  "Powering Off AVD" -Type "INFO"
		Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell -t  `"reboot -p`"" -Wait -NoNewWindow
		KillADB
	}
	Elseif ($pause = '2') {
		Write-Message  -Message  "Not rebooting..." -Type "INFO"
		return
	}
}

############# CMDPrompt
Function CMDPrompt {
	CheckJava
	CheckGit
	CheckPython
	CheckNode
	Start-Process -FilePath "cmd" -WorkingDirectory "$VARCD"

    if ((Get-Command adb -ErrorAction SilentlyContinue)) {		
		$varadb=CheckADB
		$env:ANDROID_SERIAL=$varadb
		Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  " shell  " -ErrorAction SilentlyContinue |Out-Null
	}
}

############# AUTOMATIC1111
Function AUTOMATIC1111 {
	#  --xformers --deepdanbooru --disable-safe-unpickle --listen --theme dark --enable-insecure-extension-access
	# stable-diffusion-webui\modules\processing.py  params.txt
	CheckGit
 	CheckPythonA1111
	
	# set env for A111 python
	Write-Message  -Message  "Resetting env for A111 python $VARCD" -Type "INFO"
	
	# env
	# Path python
	Write-Message  -Message  "Resetting Path variables to not use local python" -Type "INFO"
	$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem;$env:SystemRoot\System32\WindowsPowerShell\v1.0\;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\pythonA111\tools\Scripts;$VARCD\pythonA111\tools;pythonA111\tools\Lib\site-packages;$VARCD\PortableGit\cmd"

	# python
	$env:PYTHONHOME="$VARCD\pythonA111\tools"
	$env:PYTHONPATH="$VARCD\pythonA111\tools\Lib\site-packages"
	
	Write-Message  -Message  "Running pip install --upgrade pip" -Type "INFO"
	Start-Process -FilePath "$VARCD\pythonA111\tools\python.exe" -WorkingDirectory "$VARCD\pythonA111\tools" -ArgumentList " -m pip install --upgrade pip " -wait -NoNewWindow
           
	   
	Write-Message  -Message  "Cloning stable-diffusion-webui" -Type "INFO"
	Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD\" -ArgumentList " clone `"https://github.com/AUTOMATIC1111/stable-diffusion-webui.git`" " -wait -NoNewWindow
	
	Start-Process -FilePath "$VARCD\stable-diffusion-webui\webui-user.bat" -WorkingDirectory "$VARCD\stable-diffusion-webui"  -ArgumentList " "  -wait -NoNewWindow
	Write-Message  -Message  "Suggest creating hard links to your models with mklink /d DEST SORURCE" -Type "INFO"

 	Start-Process -FilePath "C:\Program Files\Chromium\Application\chrome.exe" -WorkingDirectory "$VARCD\" -ArgumentList " --disable-history-quick-provider --guest `"http://127.0.0.1:7860/`"" 
}

############# vladmandic_automatic
Function vladmandic_automatic {
	#  --xformers --deepdanbooru --disable-safe-unpickle --listen --theme dark --enable-insecure-extension-access
	# stable-diffusion-webui\modules\processing.py  params.txt
	CheckGit
 	CheckPythonA1111
	
	# set env for A111 python
	Write-Message  -Message  "Resetting env for vladmandic_automatic python $VARCD" -Type "INFO"
	
	# env
	# Path python
	Write-Message  -Message  "Resetting Path variables to not use local python" -Type "INFO"
	$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem;$env:SystemRoot\System32\WindowsPowerShell\v1.0\;$VARCD\platform-tools\;$VARCD\rootAVD-master;$VARCD\pythonA111\tools\Scripts;$VARCD\pythonA111\tools;pythonA111\tools\Lib\site-packages;$VARCD\PortableGit\cmd"

	# python
	$env:PYTHONHOME="$VARCD\pythonA111\tools"
	$env:PYTHONPATH="$VARCD\pythonA111\tools\Lib\site-packages"
	
	Write-Message  -Message  "Running pip install --upgrade pip" -Type "INFO"
	Start-Process -FilePath "$VARCD\pythonA111\tools\python.exe" -WorkingDirectory "$VARCD\pythonA111\tools" -ArgumentList " -m pip install --upgrade pip " -wait -NoNewWindow
           
	   
	Write-Message  -Message  "Cloning vladmandic_automatic" -Type "INFO"
	Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD\" -ArgumentList " clone `"https://github.com/vladmandic/automatic.git`" " -wait -NoNewWindow
	
	Start-Process -FilePath "$VARCD\automatic\webui.bat" -WorkingDirectory "$VARCD\automatic"  -ArgumentList "  "  -wait -NoNewWindow
	Write-Message  -Message  "Suggest creating hard links to your models with mklink /d " -Type "INFO"

 	Start-Process -FilePath "C:\Program Files\Chromium\Application\chrome.exe" -WorkingDirectory "$VARCD\" -ArgumentList " --disable-history-quick-provider --guest `"http://127.0.0.1:7860/`"" 
}

############# CHECK PYTHONA111
Function CheckPythonA1111 {
   if (-not(Test-Path -Path "$VARCD\pythonA111" )) {
        try {
            Write-Message  -Message  "Downloading Python nuget package for AUTOMATIC1111" -Type "INFO"
            downloadFile "https://www.nuget.org/api/v2/package/python/3.10.6" "$VARCD\python.zip"
            New-Item -Path "$VARCD\pythonA111" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
            Write-Message  -Message  "Extracting Python nuget package for AUTOMATIC1111" -Type "INFO"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\python.zip", "$VARCD\pythonA111")
                   
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Message  -Message  "$VARCD\pythonA111 already exists" -Type "WARNING"
            }
}
 

############# AutoGPTEnv
Function AutoGPTEnv {
	
	if (-not(Test-Path -Path "$VARCD\Auto-GPT\.env" )) {
        try {

	Write-Message  -Message  "Running pip install -r requirements.txt" -Type "INFO"
	Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\Auto-GPT"  -ArgumentList " -m pip install -r requirements.txt  " -wait -NoNewWindow

	Write-Message  -Message  "Updating AutoGPT .env config for YOLO and Gpt-3 because I'm cheap" -Type "INFO"
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
	-replace '# BROWSE_CHUNK_MAX_LENGTH=3000', 'BROWSE_CHUNK_MAX_LENGTH=2500'`
	-replace '# FAST_TOKEN_LIMIT=4000', 'FAST_TOKEN_LIMIT=3500'`
	-replace '# SMART_TOKEN_LIMIT=8000', 'SMART_TOKEN_LIMIT=3500'`	|
	Out-File -Encoding Ascii "$VARCD\Auto-GPT\.env"			
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Message  -Message  "$VARCD\Auto-GPT\.env already exists" -Type "WARNING"
            }
}

############# RootAVD
Function RootAVD {
    # I had to start the image before I enabled keyboard ....
	Start-Sleep -Seconds 2

if (-not(Test-Path -Path "$VARCD\rootAVD-master" )) {
    try {
            Write-Message  -Message  "Downloading rootAVD" -Type "INFO"
            # Just in cases : downloadFile "https://github.com/newbit1/rootAVD/archive/refs/heads/master.zip" "$VARCD\rootAVD-master.zip"
	    downloadFile "https://gitlab.com/newbit/rootAVD/-/archive/master/rootAVD-master.zip" "$VARCD\rootAVD-master.zip"
            Write-Message  -Message  "Extracting rootAVD (Turn On AVD 1st" -Type "INFO"
            Expand-Archive -Path  "$VARCD\rootAVD-master.zip" -DestinationPath "$VARCD" -Force
        }
            catch {
            throw $_.Exception.Message
            }
        }
        else {
            Write-Message  -Message  "$VARCD\rootAVD-master already exists" -Type "WARNING"
        }
   
	$varadb=CheckADB
	$env:ANDROID_SERIAL=$varadb

	cd "$VARCD\rootAVD-master"
	Write-Message  -Message  "Running installing magisk via rootAVD to ramdisk.img" -Type "INFO"
	Start-Process -FilePath "$VARCD\rootAVD-master\rootAVD.bat" -ArgumentList  "system-images\android-30\google_apis_playstore\x86\ramdisk.img FAKEBOOTIMG" -WorkingDirectory "$VARCD\rootAVD-master\"  -NoNewWindow

    Write-Message  -Message  "rootAVD Finished if the emulator did not close/poweroff try again" -Type "INFO"
}

############# AVDWipeData
Function AVDWipeData {
	Write-Message  -Message  "Starting AVD emulator" -Type "INFO"
	$wshell = New-Object -ComObject Wscript.Shell
	$pause = $wshell.Popup("Are you sure you want to wipe all data ?!?", 0, "Wait!", 48+1)

	if ($pause -eq '1') {
		Write-Message  -Message  "Wiping data you will need to rerun Magisk and push cert" -Type "INFO"
		Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system -wipe-data" -NoNewWindow
	}
	Elseif ($pause = '2') {
		Write-Message  -Message  "Not wiping data..." -Type "INFO"
		return
	}
}

############# CHECK BURP
Function CheckBurp {

Write-Message  -Message  "Setting up inital burp configs" -Type "INFO"
New-Item -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp -Name "free.suite.alertsdisabledforjre-1817240865" -Value "true" -Type String
Set-ItemProperty -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp -Name "eulacommunity" -Value "4" -Type String
Set-ItemProperty -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp -Name "free.suite.feedback/Reporting/Enabled" -Value "false" -Type String
Set-ItemProperty -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp -Name "free.suite.suppressupdatedialog" -Value "false" -Type String
New-Item -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp\community -Force
New-Item -Path HKCU:\SOFTWARE\JavaSoft\Prefs\burp\community\detached-frames -Force


Write-Message  -Message  "Creating folders for custom CloudFlare bypass and ZAP support" -Type "INFO"
New-Item -Path "$env:USERPROFILE\AppData\Roaming\BurpSuite\ConfigLibrary\" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
CheckJava
BurpConfigPush
BurpConfigProxy
   if (-not(Test-Path -Path "$VARCD\burpsuite_community.jar" )) {
        try {
            Write-Message  -Message  "Downloading Burpsuite Community" -Type "INFO"
            downloadFile "https://portswigger-cdn.net/burp/releases/download?product=community&type=Jar" "$VARCD\burpsuite_community.jar"
           }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\Burpsuite already exists" -Type "WARNING"
            }
			
			   if (-not(Test-Path -Path "$VARCD\burpsuite_pro.jar" )) {
        try {
            Write-Message  -Message  "Downloading Burpsuite Pro" -Type "INFO"
            downloadFile "https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar" "$VARCD\burpsuite_pro.jar"
           }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\Burpsuite Pro already exists" -Type "WARNING"
            }
}

############# StartBurp
Function StartBurp {
    CheckBurp
	Write-Message  -Message  "Setting $env:USERPROFILE back to $USERPROFILE_BACKUP to fix open dialog for Burp Suite" -Type "INFO"
	$env:USERPROFILE="$USERPROFILE_BACKUP"
    Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$VARCD\burpsuite_community.jar`" --disable-auto-update --use-defaults  && "  
	Write-Message  -Message  "Waiting for Burp Suite to download cert" -Type "INFO"
	Retry{PullCert "Error PullCert"} # -maxAttempts 10
}
 
############# StartBurpSocks
Function StartBurpSocks {
    CheckBurp
	Write-Message  -Message  "Setting $env:USERPROFILE back to $USERPROFILE_BACKUP to fix open dialog for Burp Suite" -Type "INFO"
	$env:USERPROFILE="$USERPROFILE_BACKUP"
	Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m   -jar `"$VARCD\burpsuite_community.jar`"  --use-defaults  --disable-auto-update --user-config-file=`"$VARCD\AppData\Roaming\BurpSuite\BurpConfigProxy.json` && " 
	Write-Message  -Message  "Waiting for Burp Suite to download cert" -Type "INFO"
	Retry{PullCert "Error PullCert"} # -maxAttempts 10
}

############# StartBurpPro
Function StartBurpPro {
    CheckBurp
	Write-Message  -Message  "Setting $env:USERPROFILE back to $USERPROFILE_BACKUP to fix open dialog for Burp Suite" -Type "INFO"
	$env:USERPROFILE="$USERPROFILE_BACKUP"
	$BurpProLatest = Get-ChildItem -Force -Recurse -File -Path "$VARCD" -Depth 0 -Filter *pro*.jar -ErrorAction SilentlyContinue | Sort-Object LastwriteTime -Descending | select -first 1
	Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$VARCD\$BurpProLatest`" --use-defaults  && "
	# wait for burp to setup env paths for config
	Start-Sleep -Seconds 2

	Write-Message  -Message  "Waiting for Burp Suite to download cert" -Type "INFO"
	Retry{PullCert "Error PullCert"} # -maxAttempts 10
}

############# StartBurpProSocks
Function StartBurpProSocks {
    CheckBurp
	Write-Message  -Message  "Setting $env:USERPROFILE back to $USERPROFILE_BACKUP to fix open dialog for Burp Suite" -Type "INFO"
	$env:USERPROFILE="$USERPROFILE_BACKUP"
	$BurpProLatest = Get-ChildItem -Force -Recurse -File -Path "$VARCD" -Depth 0 -Filter *pro*.jar -ErrorAction SilentlyContinue | Sort-Object LastwriteTime -Descending | select -first 1
	Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m   -jar `"$VARCD\$BurpProLatest`"  --user-config-file=`"$VARCD\AppData\Roaming\BurpSuite\BurpConfigProxy.json`"    && " 
	# wait for burp to setup env paths for config	
	Write-Message  -Message  "Waiting for Burp Suite to download cert" -Type "INFO"
	Retry{PullCert "Error PullCert"} # -maxAttempts 10
}

############# BurpWithZap
Function BurpWithZap {
	CheckBurp
	StartBurpSocks
	StartZAP
}

############# BurpProWithZap
Function BurpProWithZap {
	CheckBurp
	StartBurpProSocks
	StartZAP
}

############# BurpConfigPush
Function BurpConfigPush {
Write-Message  -Message  "Pushing Burp Crawler scan config for bypassing CloudFlare" -Type "INFO"
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

############# BurpConfigProxy
Function BurpConfigProxy {
Write-Message  -Message  "Pushing Burp Suite user config for Upstream Proxy for ZAP support" -Type "INFO"
# BurpConfigProxy.json
$BurpConfigProxy = @'
{
    "user_options":{
        "connections":{
            "platform_authentication":{
                "credentials":[],
                "do_platform_authentication":true,
                "prompt_on_authentication_failure":false
            },
            "socks_proxy":{
                "dns_over_socks":false,
                "host":"",
                "password":"",
                "port":0,
                "use_proxy":false,
                "username":""
            },
            "upstream_proxy":{
                "servers":[
                    {
                        "destination_host":"*",
                        "enabled":true,
                        "proxy_host":"localhost",
                        "proxy_port":8081
                    }
                ]
            }
        },
            "client_certificates":{
                "certificates":[]
            },
            "negotiation":{
                "disable_sni_extension":false,
                "enable_blocked_algorithms":true
            }
        }
}

'@
$BurpConfigProxy |set-Content "$env:USERPROFILE\AppData\Roaming\BurpSuite\BurpConfigProxy.json"
}

############# PullCert
Function PullCert {
    Invoke-WebRequest -Uri "http://burp/cert" -Proxy 'http://localhost:8080'  -Out "$VARCD\BURP.der" -Verbose
    Start-Process -FilePath "$env:SYSTEMROOT\System32\certutil.exe" -ArgumentList  " -user -addstore `"Root`"    `"$VARCD\BURP.der`"  "  -NoNewWindow -Wait
}

############# ZAPCheck
Function ZAPCheck {
    CheckJava
    if (-not(Test-Path -Path "$VARCD\ZAP.zip" )) {
        try {
            Write-Message  -Message  "Downloading ZAP" -Type "INFO"
            $xmlResponseIWR = Invoke-WebRequest -Method GET -Uri 'https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml' -OutFile ZapVersions.xml
            [xml]$xmlAttr = Get-Content -Path ZapVersions.xml
            Write-Message  -Message  ([xml]$xmlAttr).ZAP.core.daily.url  -Type "INFO"
            downloadFile ([xml]$xmlAttr).ZAP.core.daily.url "$VARCD\ZAP.zip"
	  
            Write-Message  -Message  "Extracting ZAP" -Type "INFO"
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
            Write-Message  -Message  "$VARCD\ZAP.zip already exists" -Type "WARNING"
            }
 
   
  
}

############# StartZAP
Function StartZAP {
    ZAPCheck
	Write-Message  -Message  "Starting ZAP" -Type "INFO"
    # https://www.zaproxy.org/faq/how-do-you-find-out-what-key-to-use-to-set-a-config-value-on-the-command-line/
    $ZAPJarPath = (Get-ChildItem "$VARCD\ZAP\*.jar")
    Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$ZAPJarPath`" -config network.localServers.mainProxy.address=localhost -config network.localServers.mainProxy.port=8081 "
	#Start-Process -FilePath "$VARCD\jdk\bin\javaw.exe" -WorkingDirectory "$VARCD\jdk\"  -ArgumentList " -Xms4000m -Xmx4000m  -jar `"$ZAPJarPath`" -config network.localServers.mainProxy.address=localhost -config network.localServers.mainProxy.port=8081 -config network.connection.httpProxy.host=localhost -config network.connection.httpProxy.port=8080 -config network.connection.httpProxy.enabled=true"
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
            Write-Message  -Message  $_.Exception.Message  -Type "INFO"
        }

        # exponential backoff delay
        $attempts++
        if ($attempts -le $maxAttempts) {
            $retryDelaySeconds = [math]::Pow(2, $attempts)
            $retryDelaySeconds = $retryDelaySeconds - 1  # Exponential Backoff Max == (2^n)-1
            Write-Message  -Message ("Action failed. Waiting " + $retryDelaySeconds + " seconds before attempt " + $attempts + " of " + $maxAttempts + ".")  -Type "INFO"
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
            Write-Message  -Message  "Downloading SecLists.zip PLEASE WAIT..." -Type "INFO"
            downloadFile "https://github.com/danielmiessler/SecLists/archive/refs/heads/master.zip" "$VARCD\SecLists.zip"
            Write-Message  -Message  "Extracting SecLists.zip" -Type "INFO"

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
            Write-Message  -Message  "$VARCD\SecLists.zip already exists" -Type "WARNING"
            }
 
   
  
}

############# SharpHoundRun
Function SharpHoundRun {
	Write-Message  -Message  "Example Runas Usage: runas /user:"nr.ad.COMPANY.com\USERNAME" /netonly cmd" -Type "INFO"
    if (-not(Test-Path -Path "$VARCD\SharpHound.exe" )) {
        try {
            Write-Message  -Message  "Sharphound Missing Downloading" -Type "INFO"
			downloadFile "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/DebugBuilds/SharpHound.exe" "$VARCD\SharpHound.exe"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
    Write-Message  -Message  "Starting SharpHound" -Type "INFO"
	Start-Process -FilePath "$VARCD\SharpHound.exe" -WorkingDirectory "$VARCD\"  -ArgumentList "  -s --CollectionMethods All --prettyprint true "
}

############# Neo4jRun
Function Neo4jRun {
    CheckJavaNeo4j
	# Neo4j
    if (-not(Test-Path -Path "$VARCD\Neo4j" )) {
        try {
            Write-Message  -Message  "Downloading Neo4j" -Type "INFO"
            downloadFile "https://dist.neo4j.org/neo4j-community-4.4.19-windows.zip" "$VARCD\Neo4j.zip"
			Write-Message  -Message  "Extracting Neo4j" -Type "INFO"
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
            Write-Message  -Message  "$VARCD\Neo4j.zip already exists" -Type "WARNING"
            }
	Write-Message  -Message  "Starting Neo4j" -Type "INFO"
	Start-Process -FilePath "$VARCD\jdk_neo4j\bin\java.exe" -WorkingDirectory "$VARCD\neo4j\lib"  -ArgumentList "  -cp `"$VARCD\neo4j/lib/*`" -Dbasedir=`"$VARCD\neo4j`" org.neo4j.server.startup.Neo4jCommand `"console`"  "
	Write-Message  -Message  "Wait for Neo4j You must change password at http://localhost:7474" -Type "INFO"
}

############# BloodhoundRun
Function BloodhoundRun {
    CheckJava
	# pull custom searches
	Stop-process -name BloodHound -Force -ErrorAction SilentlyContinue |Out-Null
	if (-not(Test-Path -Path "$VARCD\BloodHound-win32-x64" )) {
        try {
            Write-Message  -Message  "Downloading BloodHound" -Type "INFO"
			#downloadFile "https://github.com/BloodHoundAD/BloodHound/releases/download/4.2.0/BloodHound-win32-x64.zip" "$VARCD\BloodHound-win32-x64.zip"
			$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/BloodHoundAD/BloodHound/releases/latest").assets | Where-Object name -like BloodHound-win32-x64*.zip ).browser_download_url
			downloadFile  $downloadUri "$VARCD\BloodHound-win32-x64.zip"
			Write-Message  -Message  "Extracting BloodHound" -Type "INFO"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\BloodHound-win32-x64.zip", "$VARCD")
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\BloodHound-win32-x64 already exists" -Type "WARNING"
            }
	Write-Message  -Message  "Starting BloodHound" -Type "INFO"
	Start-Process -FilePath "$VARCD\BloodHound-win32-x64\BloodHound.exe" -WorkingDirectory "$VARCD\"
}

############# CHECK CheckGit
Function CheckGit {
	 Write-Message  -Message  "Checking Git" -Type "INFO"
   if (-not(Test-Path -Path "$VARCD\PortableGit" )) {
        try {
            Write-Message  -Message  "Downloading Git" -Type "INFO"

            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest").assets | Where-Object name -like *PortableGit*64*.exe ).browser_download_url | select -first 1
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
            Write-Message  -Message  "$VARCD\Git already exists" -Type "WARNING"
            }
}

############# CHECK StartAutoGPT
Function StartAutoGPT {
CheckPython
CheckGit

<#
 Weather2
Role:  tell me the weather for atlanta georgia using google.com website and no docker or APIs
Goals: ['tell me the weather for atlanta georgia using google.com website and no docker or APIs', 'output the results to a file called weather1']

#>

Write-Message  -Message  "Cloning https://github.com/Torantulino/Auto-GPT.git" -Type "INFO"
Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD\" -ArgumentList " clone `"https://github.com/Significant-Gravitas/Auto-GPT.git`" " -wait -NoNewWindow
$env:SystemRoot
AutoGPTEnv

Write-Message  -Message  "Current Working Directory $VARCD\Auto-GPT" -Type "INFO"
Set-Location -Path "$VARCD\Auto-GPT"

Write-Message  -Message  "Running  .\run.bat --debug --gpt3only" -Type "INFO"
Start-Process -FilePath "cmd.exe" -WorkingDirectory "$VARCD\Auto-GPT"  -ArgumentList " /c .\run.bat --debug --gpt3only " 

Write-Message  -Message  "EXIT" -Type "INFO"
}

############# CHECK pycharm
Function CheckPyCharm {
	Check7zip
	CheckGit
	CheckPython
   if (-not(Test-Path -Path "$VARCD\pycharm-community" )) {
        try {
            Write-Message  -Message  "Downloading latest PyCharm Community" -Type "INFO"
			$downloadUri = (Invoke-RestMethod -Method GET -Uri "https://data.services.jetbrains.com/products?code=PCP%2CPCC&release.type=release").releases.downloads.windows.link -match 'pycharm-community'| select -first 1
            downloadFile "$downloadUri" "$VARCD\pycharm-community.exe"
			Write-Message  -Message  "Extracting PyCharm" -Type "INFO"
			Start-Process -FilePath "$VARCD\7zip\7z.exe" -ArgumentList "x `"$VARCD\pycharm-community.exe`" -o`"$VARCD\pycharm-community`"" -NoNewWindow -Wait
			Start-Process -FilePath "$VARCD\pycharm-community\bin\pycharm64.exe" -WorkingDirectory "$VARCD\pycharm-community"   -NoNewWindow 
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\pycharm-community already exists starting PyCharm" -Type "WARNING"
			Start-Process -FilePath "$VARCD\pycharm-community\bin\pycharm64.exe" -WorkingDirectory "$VARCD\pycharm-community"   -NoNewWindow 
			}
}

############# CHECK 7zip
Function Check7zip {
   if (-not(Test-Path -Path "$VARCD\7zip" )) {
        try {
            Write-Message  -Message  "Downloading latest 7zip" -Type "INFO"
			$downloadUri = (Invoke-RestMethod -Method GET -Uri "https://www.7-zip.org/download.html")    -split '\n' -match '.*exe.*' | ForEach-Object {$_ -ireplace '.* href="','https://www.7-zip.org/' -ireplace  '".*',''}| select -first 1
            downloadFile "$downloadUri" "$VARCD\7zip.exe"
			$Env:__COMPAT_LAYER='RunAsInvoker'
			Start-Process -FilePath "$VARCD\7zip.exe" -ArgumentList "/S /D=$VARCD\7zip" -NoNewWindow -Wait
			}
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\7zip already exists " -Type "WARNING"
			
			}
}
 
############# CheckProcess
function CheckProcess($windowTitle, $ProcessName) {

	if (Get-Process | Where-Object { $_.MainWindowTitle -like "*$windowTitle*" }) {
		Write-Message  -Message  "Window with title '$windowTitle' is running." -Type "INFO"
	} else {
		Write-Message  -Message  "Starting $ProcessName" -Type "INFO"
		$ProcessName
}
}

############# CheckArduino
Function CheckArduino {
CheckGit
CheckPython

Write-Message  -Message  "Checking for Arduino" -Type "INFO"
   if (-not(Test-Path -Path "$VARCD\Arduino" )) {
        try {

            #Arduino stuff
            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/arduino/arduino-ide/releases/latest").assets | Where-Object name -like *Windows_64bit.zip ).browser_download_url
            Write-Message  -Message  "Downloading Arduino.zip" -Type "INFO"
            downloadFile "$downloadUri" "$VARCD\Arduino.zip" 
            Write-Message  -Message  "Extracting Arduino.zip" -Type "INFO"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
			Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\Arduino.zip", "$VARCD\Arduino")  
			
            # Digistump drivers 
            Write-Message  -Message  "Download/Installing Digistump Drivers ( ##### ADMIN REQUIRED ##### ) " -Type "WARNING"
            $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/digistump/DigistumpArduino/releases/latest").assets | Where-Object name -like *Digistump.Drivers.zip ).browser_download_url
            Write-Message  -Message  "Downloading Digistump.Drivers.zip" -Type "INFO"
            downloadFile "$downloadUri" "$VARCD\Digistump.Drivers.zip" 
            Write-Message  -Message  "Extracting Digistump.Drivers.zip" -Type "INFO"
            Expand-Archive -Path  "$VARCD\Digistump.Drivers.zip" -DestinationPath "$VARCD\" -Force

            Write-Message  -Message  "Installing Drivers" -Type "INFO"
			try {
				Start-Process -FilePath "$VARCD\Digistump Drivers\Install Drivers.exe" -WorkingDirectory "$VARCD" -ErrorAction SilentlyContinue
			} catch {
				Write-Message  -Message  "Not running as admin or driver faild install" -Type "WARNING"
			}

            # add Digistump board to Arduino
            Write-Message  -Message  "Adding Digistump board to Arduino IDE" -Type "INFO"
            Start-Process -FilePath "$VARCD\Arduino\resources\app\lib\backend\resources\arduino-cli.exe" -WorkingDirectory "$VARCD\Arduino\resources\app\lib\backend\resources\" -ArgumentList " config init " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\Arduino\resources\app\lib\backend\resources\arduino-cli.exe" -WorkingDirectory "$VARCD\Arduino\resources\app\lib\backend\resources\" -ArgumentList " config init " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\Arduino\resources\app\lib\backend\resources\arduino-cli.exe" -WorkingDirectory "$VARCD\Arduino\resources\app\lib\backend\resources\" -ArgumentList " core update-index " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\Arduino\resources\app\lib\backend\resources\arduino-cli.exe" -WorkingDirectory "$VARCD\Arduino\resources\app\lib\backend\resources\" -ArgumentList " core update-index --additional-urls `"https://raw.githubusercontent.com/digistump/arduino-boards-index/master/package_digistump_index.json`" " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\Arduino\resources\app\lib\backend\resources\arduino-cli.exe" -WorkingDirectory "$VARCD\Arduino\resources\app\lib\backend\resources\" -ArgumentList " core install digistump:avr --additional-urls `"https://raw.githubusercontent.com/digistump/arduino-boards-index/master/package_digistump_index.json`" " -wait -NoNewWindow
            
            # add   digiduck for duck to ino
            Write-Message  -Message  "Downloading digiduck" -Type "INFO"
            Start-Process -FilePath "$VARCD\PortableGit\cmd\git.exe" -WorkingDirectory "$VARCD" -ArgumentList " clone `"https://github.com/molatho/digiduck.git`" " -wait -NoNewWindow

            # get old payloads 
            $downloadUri = "https://github.com/hak5/usbrubberducky-payloads/archive/1d3e9be7ba3f80cdb008885fac49be2ba926649d.zip"
            Write-Message  -Message  "Downloading Old example payloads " -Type "INFO"
            downloadFile "$downloadUri" "$VARCD\1d3e9be7ba3f80cdb008885fac49be2ba926649d.zip" 
            Write-Message  -Message  "Extracting Old example payloads" -Type "INFO"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\1d3e9be7ba3f80cdb008885fac49be2ba926649d.zip", "$VARCD\_Old_Ducky_payloads") 

	    Write-Message  -Message  "Starting Arduino IDE" -Type "INFO"
            Start-Process -FilePath "$VARCD\Arduino\Arduino IDE.exe" -WorkingDirectory "$VARCD" -ArgumentList " `"$VARCD\digiduck\example.ino`" " 
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Message  -Message  "$VARCD\Arduino.zip already exists" -Type "INFO"
			Write-Message  -Message  "Starting Arduino IDE" -Type "INFO"
            Start-Process -FilePath "$VARCD\Arduino\Arduino IDE.exe" -WorkingDirectory "$VARCD" -ArgumentList " `"$VARCD\digiduck\example.ino`" " 

            }
}

############# PushDuckyLoad
Function PushDuckyLoad {
CheckGit
CheckPython
Write-Message  -Message  "Opening digiduck\example.duck" -Type "INFO"
Start-Process "notepad" -WorkingDirectory "$VARCD" -ArgumentList "`"$VARCD\digiduck\example.duck`" " -wait -NoNewWindow

Write-Message  -Message  "Encoding digiduck.py ..\duck2spark\example.duck  -ofile ..\duck2spark\example.ino " -Type "INFO"
Remove-Item -Path "$VARCD\digiduck\example.ino" -Force -ErrorAction SilentlyContinue |Out-Null
Start-Process -FilePath "python" -WorkingDirectory "$VARCD\digiduck\"  -ArgumentList  " `"$VARCD\digiduck\digiduck.py`"  `"$VARCD\digiduck\example.duck`"  -ofile `"$VARCD\digiduck\example.ino`"  "  -NoNewWindow -Wait  -RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt
}

function Get-ScriptPathFromCallStack {
    # Get the current call stack
    $callStack = Get-PSCallStack

    # Iterate through the call stack entries
    foreach ($stackFrame in $callStack) {
        # Check if the InvocationInfo.MyCommand.CommandType is ExternalScript, which indicates a script file
        if ($stackFrame.InvocationInfo.MyCommand.CommandType -eq 'ExternalScript') {
            # Return the script path
            return $stackFrame.InvocationInfo.MyCommand.Definition
        }
    }

    # If no script file was found in the call stack, return $null or an appropriate message
    return $null
}

############# UpdateJAMBO
Function UpdateJAMBO {
$JAMBOPATH = Get-ScriptPathFromCallStack
Write-Message  -Message  "Downloading latest JAMBOREE to $JAMBOPATH" -Type "INFO"
Invoke-WebRequest -Method GET -Uri 'https://github.com/freeload101/Java-Android-Magisk-Burp-Objection-Root-Emulator-Easy/raw/main/JAMBOREE.ps1' -OutFile "$JAMBOPATH"
Write-Host "Restarting"
Start-Sleep -Seconds 1
Set-Variable -Name ErrorActionPreference -Value SilentlyContinue

Start-Process -FilePath "powershell" -WorkingDirectory "$VARCD\" -ArgumentList " -File `"$JAMBOPATH`" "  -ErrorAction SilentlyContinue
#exit 0
}

############# CheckPostgres
Function CheckPostgres {
   if (-not(Test-Path -Path "$VARCD\PG" )) {
			New-Item -Path "$VARCD\PG" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
			$downloadUri = (Invoke-RestMethod -Method GET -Uri "https://www.enterprisedb.com/downloads/postgres-postgresql-downloads")    -split '>' -match '.*href.*sbp.enterprisedb.*'  | ForEach-Object {$_ -ireplace ".* href=`'",'' -ireplace  "`' onclick.*",''} |Select-Object -Index 1
			Write-Message  -Message  "Downloading postgres installer for windows $downloadUri" -Type "INFO"
			
			downloadFile "$downloadUri" "$VARCD\postgresql.exe"
			
			Write-Message  -Message  "setting __COMPAT_LAYER=RUNASINVOKER " -Type "INFO"
			$env:__COMPAT_LAYER = "RUNASINVOKER"
			Write-Message  -Message  "Extracting This takes a long time .. like 400 megs ..." -Type "INFO"
			Start-Process -FilePath "$VARCD\postgresql.exe" -WorkingDirectory "$VARCD\PG" -ArgumentList " --extract-only 1 --mode unattended --prefix `"$VARCD\PG`" " -wait -NoNewWindow
			
			Write-Message  -Message  "Wiping folder `"$VARCD\share\locale`" " -Type "INFO"
			Remove-Item -Path "$VARCD\PG\share\locale" -Force -ErrorAction SilentlyContinue  -Confirm:$false -Recurse |Out-Null
			Write-Message  -Message  "Init database... " -Type "INFO"
			
			Start-Process -FilePath "$VARCD\PG\bin\initdb.exe" -WorkingDirectory "$VARCD\PG" -ArgumentList " -U `"$env:PGUSER`" -A trust -E utf8 --locale=C "   -NoNewWindow -Wait
			Write-Message  -Message  "Starting pg_ctl.exe " -Type "INFO"
			Start-Process -FilePath "$VARCD\PG\bin\pg_ctl.exe" -WorkingDirectory "$VARCD\PG" -ArgumentList " -D `"$env:PGDATA`" -l `"$env:PGLOG`" -w start  " 
			Start-Sleep -Seconds 10			
			Write-Message  -Message  "Starting psql.exe " -Type "INFO"
			Start-Process -FilePath "$VARCD\PG\bin\psql.exe" -WorkingDirectory "$VARCD\PG" -ArgumentList " --port=`"$env:PGPORT`" --dbname=`"$env:PGDATABASE`" --username=`"$env:PGUSER`"  "  			
	
	}
    else {
			Write-Message  -Message  "Starting pg_ctl.exe " -Type "INFO"
			Start-Process -FilePath "$VARCD\PG\bin\pg_ctl.exe" -WorkingDirectory "$VARCD\PG" -ArgumentList " -D `"$env:PGDATA`" -l `"$env:PGLOG`" -w start  " 
			Start-Sleep -Seconds 10			
			Write-Message  -Message  "Starting psql.exe " -Type "INFO"
			Start-Process -FilePath "$VARCD\PG\bin\psql.exe" -WorkingDirectory "$VARCD\PG" -ArgumentList " --port=`"$env:PGPORT`" --dbname=`"$env:PGDATABASE`" --username=`"$env:PGUSER`"  "  			
	}
}

############# Ytdlp
Function Ytdlp {
CheckGit
if (-not(Test-Path -Path "$VARCD\ytdlp" )) {
    New-Item -Path "$VARCD\ytdlp" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null

    Write-Message  -Message  "Downloading Latest yt-dlp" -Type "INFO"
    $downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest").assets | Where-Object name -like yt-dlp.exe ).browser_download_url
    downloadFile "$downloadUri" "$VARCD\ytdlp\yt-dlp.exe"
    Copy-Item "$VARCD\ytdlp\yt-dlp.exe" "$USERPROFILE_BACKUP\AppData\Local\Microsoft\WindowsApps\yt-dlp.exe" -ErrorAction SilentlyContinue 
    Write-Message  -Message  "Downloading Latest ffmpeg-master-latest-win64-gpl-shared.zip" -Type "INFO"
    downloadFile "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip" "$VARCD\ytdlp\ffmpeg-master-latest-win64-gpl-shared.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
	Add-Type -AssemblyName System.IO.Compression
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\ytdlp\ffmpeg-master-latest-win64-gpl-shared.zip", "$VARCD\ytdlp")

    $env:Path = "$env:Path;$VARCD\C:\ROBERT\ytdlp\ffmpeg-master-latest-win64-gpl-shared\bin"

    Remove-Item -Path "$VARCD\ytdlp\ffmpeg-master-latest-win64-gpl-shared.zip" -Force -ErrorAction SilentlyContinue |Out-Null

}

Write-Message  -Message  "Opening $VARCD\ytdlp\LIST.txt" -Type "INFO"
New-Item -Path "$VARCD\ytdlp\LIST.txt" -ItemType "file"  -ErrorAction SilentlyContinue -Force 
start-sleep -Seconds 1
Start-Process "notepad" -WorkingDirectory "$VARCD" -ArgumentList " `"$VARCD\ytdlp\LIST.txt`" " -wait -NoNewWindow

    Get-Content "$VARCD\ytdlp\LIST.txt" | ForEach-Object { 
    Write-Message  -Message  "Downloading $_" -Type "INFO"

   $GetDate = Get-Date -Format yyyyMMddTHHmmss 
    Write-Message  -Message  " --ffmpeg-location `"$VARCD\ytdlp\ffmpeg-master-latest-win64-gpl-shared\bin`" -o `"$GetDate %(upload_date)s - %(title)s.%(ext)s`"  `"$_`"     " -Type "INFO"
    
    Start-Process "$VARCD\ytdlp\yt-dlp.exe" -WorkingDirectory "$VARCD\ytdlp" -ArgumentList " --ffmpeg-location `"$VARCD\ytdlp\ffmpeg-master-latest-win64-gpl-shared\bin`" -o `"$GetDate %(upload_date)s - %(title)s.%(ext)s`"  `"$_`"     " -wait -NoNewWindow
  
    
    
    # old multi stream downloading script don't use because multi threaded downloads do not always work ...  
	# wget -q -U "rmccurdy.com" -q -P aria2  -e robots=off  -nd -r  "https://github.com/aria2/aria2/releases/latest" --max-redirect 1 -l 1 -A "latest,aria*win*64*.zip" -R '*.gz,release*.*' --regex-type pcre --accept-regex "aria2-.*-win-64bit-build1.zip"
    # wget -q -U "rmccurdy.com" -q -P ffmpeg  -e robots=off  -nd -r  "https://github.com/BtbN/FFmpeg-Builds/releases/latest" --max-redirect 1 -l 1 -R '*shared*,*lgpl*,autobuild-*.*' --regex-type pcre --accept-regex "latest.*"  --regex-type pcre --accept-regex "autobuild.*" --regex-type pcre --accept-regex "ffmpeg-n.*-win64-gpl-[0-9].*.zip"
    # start "aria2c !UUID!"	 cmd /c yt-dlp.exe -w --no-continue  --merge-output-format mkv --ffmpeg-location .\ -o ".\downloads\%%(uploader)s - %%(title)s - %%(id)s_!UUID!.%%(ext)s" -i   --external-downloader aria2c --external-downloader-args " -x 16 -s 16 -k 1M" "%%A"  ^& pause
    
    }
    Invoke-Item "$VARCD\ytdlp"
}

############# WSLShrink
Function WSLShrink {
CheckAdmin
$distroNameArray = @()
Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" | 


ForEach-Object {
    $distroName = (Get-ItemProperty $_.PSPath).DistributionName
    $basePath = (Get-ItemProperty $_.PSPath).BasePath
    $distroNameArray += $distroName + "," + $basePath
}


$distroSelect  = ($distroNameArray  | Out-GridView -Title "Select WSL image to Shrink"  -OutputMode Single)
$Global:distroSelectPath = $distroSelect -replace '.*,','' -replace '\\\\\?\\',''
 
Write-Message -Message  "Global:distroSelectPath: $Global:distroSelectPath" -Type "INFO"
Write-Message -Message  "Shutting down wsl" -Type "INFO"
Start-Process -FilePath "wsl" -ArgumentList "  --shutdown " -wait -NoNewWindow
Start-Sleep -Seconds 10

Write-Message  -Message "Optimize-VHD $Global:distroSelectPath *.vhd* " -Type "INFO" 
Get-ChildItem -Path  "$distroSelectPath" -Filter *.vhdx -Recurse | Select-Object FullName | % {Mount-VHD $_.FullName -ReadOnly; Optimize-VHD $_.FullName -Mode full; Dismount-VHD $_.FullName}

Write-Message  -Message "COMPLETE: Optimize-VHD $Global:distroSelectPath *.vhd* " -Type "INFO" 


}
############# CheckImage
function CheckImage{
WSLEnableUpdate

    $env:WSL_UTF8 = 1
    $wslImage = "Ubuntu-22.04"
 
    Start-Process -FilePath "$env:WSLBIN" -ArgumentList  " --list"  -NoNewWindow -RedirectStandardOutput "RedirectStandardOutput.txt" -Wait
    Start-Sleep -Seconds 1
    
    $wslInfo = Get-Content -Path "RedirectStandardOutput.txt"
        
		# check for existing $wslImage
        if (($wslInfo) -match (".*$wslImage.*"))  {
			
			if ( $Global:NOGUI -ne '1' ) {
			$wshell = New-Object -ComObject Wscript.Shell
			$pause = $wshell.Popup("Do you want to use $wslImage as your base clean image for JAMBOREE?", 0, "Wait!", 4)
				if ($pause -eq '6') {
				return
				}
				Elseif ($pause = '7') {
				Write-Message  -Message  "You will need to create a base image $wslImage for JAMBOREE!" -Type "ERROR"
				Start-Sleep 10
				[Environment]::Exit(1)
				}
			}
        } ELSE {
        # create base image 
            Write-Message "No $wslImage image found. Installing base $wslImage WSL image" -Type "WARNING"
            Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --install -d $wslImage " -wait 
        }
}


############# SOCFortressCoPilotFast
function SOCFortressCoPilotFast{
Start-Sleep 10
 
    $env:WSL_UTF8 = 1
    $wslImage = "Ubuntu-22.04"
    Start-Process -FilePath "$env:WSLBIN" -ArgumentList  " --list"  -NoNewWindow -RedirectStandardOutput "RedirectStandardOutput.txt" -Wait
    Start-Sleep -Seconds 1
    $wslInfo = Get-Content -Path "RedirectStandardOutput.txt"
		# check for existing SOCFortress image
        if (($wslInfo) -match (".*SOCFortress.*"))  {
        # run socfortressstart
		Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d SOCFortress -u root -e bash -c `"bash  `" "  
	} ELSE {
		CheckImage
        # clone base image
        Write-Message "Cloning $wslImage to $wslImage.tar" -Type "INFO"
        Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --export $wslImage `"$VARCD\$wslImage.tar.gz`" " -NoNewWindow -Wait
        Write-Output "Cloaning base $wslImage to SOCFortress WSL image"
        Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --import SOCFortress SOCFortress `"$VARCD\$wslImage.tar.gz`" "  -NoNewWindow -Wait
        
        # run install script ...
        Write-Message  -Message "Downloading / running SOCFortress_CoPilot_Fast.bash " -Type "INFO"
		Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d SOCFortress -u root -e bash -c `"wget -O SOCFortress_CoPilot_Fast.bash  https://raw.githubusercontent.com/freeload101/SCRIPTS/master/Bash/SOCFortress_CoPilot_Fast.bash`" "   -wait 
        Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d SOCFortress -u root -e bash -c `"bash SOCFortress_CoPilot_Fast.bash `" "  -NoNewWindow
		
		#port fwd
		Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d SOCFortress -u root -e bash -c `" ip route get 1.1.1.1  `" " -NoNewWindow -RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt
		Start-Sleep 1
		Get-Content RedirectStandardOutput.txt
		
		Start-Process -FilePath "netsh" -ArgumentList " interface portproxy show all " -NoNewWindow 
		
		$INTERNETIP = Get-Content RedirectStandardOutput.txt | ForEach-Object { $elements = $_ -split ' '; $elements[6] }
		 
		Set-Content -Path NetSh.txt -Value "You need to run the following as administrator to reach the services from outside the host mashine" 
		Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=1514 listenaddress=0.0.0.0 connectport=1514 connectaddress=$INTERNETIP"
		Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=1515 listenaddress=0.0.0.0 connectport=1515 connectaddress=$INTERNETIP"
		Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=8889 listenaddress=0.0.0.0 connectport=8889 connectaddress=$INTERNETIP"
		Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=4433 listenaddress=0.0.0.0 connectport=4433 connectaddress=$INTERNETIP"
		Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=443 connectaddress=$INTERNETIP"
  		Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=$INTERNETIP"
		Invoke-Item -Path NetSh.txt 
        }
}

############# WSLCheckOllama
function WSLCheckOllama{
    $env:WSL_UTF8 = 1
    $wslImage = "Ubuntu-22.04"
    Start-Process -FilePath "$env:WSLBIN" -ArgumentList  " --list"  -NoNewWindow -RedirectStandardOutput "RedirectStandardOutput.txt" -Wait
    Start-Sleep -Seconds 1
    $wslInfo = Get-Content -Path "RedirectStandardOutput.txt"
     # check for existing Ollama_WSL image
        if (($wslInfo) -match (".*Ollama_WSL.*"))  {
		Write-Message "Existing Ollama_WSL Image found starting Ollama" -Type "INFO"
		Start-Process -FilePath "$env:WSLBIN" -ArgumentList ' -d Ollama_WSL -u root journalctl  -f -n 999999 --no-pager -u ollama.service'  -WindowStyle minimized
		
        } ELSE {
		WSLEnableUpdate
		CheckImage
		WSLInstallOllama
        }
}

############# WSLInstallOllama
function WSLInstallOllama{
		if ( $Global:NOGUI -ne '1' ) {
		$wshell = New-Object -ComObject Wscript.Shell
		$pause = $wshell.Popup("Do you want to also install OpenWebUI ?", 0, "Wait!", 4)
		if ($pause -eq '6') {
			# clone base image
			Write-Message "Cloning $wslImage to $wslImage.tar" -Type "INFO"
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --export $wslImage `"$VARCD\$wslImage.tar.gz`" " -NoNewWindow -Wait
			Write-Output "Cloaning base $wslImage to Ollama_WSL WSL image"
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --import Ollama_WSL Ollama_WSL `"$VARCD\$wslImage.tar.gz`" "  -NoNewWindow -Wait

			# run install script ...
			Write-Message  -Message "Downloading / running OpenWebUI_Fast.bash " -Type "INFO"
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d Ollama_WSL -u root -e bash -c `"wget -O OpenWebUI_Fast.bash  https://raw.githubusercontent.com/freeload101/SCRIPTS/refs/heads/master/Bash/OpenWebUI_Fast.bash`" "   -wait 
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d Ollama_WSL -u root -e bash -c `"bash OpenWebUI_Fast.bash `" "  -NoNewWindow

			# Run on boot for windows / persistance
			Register-ScheduledTask -Force -TaskName 'StartOpenWebUI' -Trigger (New-ScheduledTaskTrigger -AtStartup) -Action (New-ScheduledTaskAction -Execute 'wsl' -Argument "-d OpenWebUI_WSL_MASTER --exec dbus-launch true") -User $env:username -Password (Get-Credential $env:username).GetNetworkCredential().Password -EA Stop

			
			Copy-Item "$env:USERPROFILE\.wslconfig" "$env:USERPROFILE\.wslconfig.bak" -ErrorAction SilentlyContinue; "[wsl2]`nvmIdleTimeout=-1" | Out-File "$env:USERPROFILE\.wslconfig" -Encoding ASCII


		}
		Elseif ($pause = '7') {
			# clone base image
			Write-Message "Cloning $wslImage to $wslImage.tar" -Type "INFO"
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --export $wslImage `"$VARCD\$wslImage.tar.gz`" " -NoNewWindow -Wait
			Write-Output "Cloaning base $wslImage to Ollama_WSL WSL image"
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " --import Ollama_WSL Ollama_WSL `"$VARCD\$wslImage.tar.gz`" "  -NoNewWindow -Wait
			
			Write-Message  -Message "Downloading Ollama Installer" -Type "INFO"
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d Ollama_WSL -u root -e bash -c `"curl -fsSL https://ollama.com/install.sh | sh`" "   -wait  
		  
			Write-Message  -Message "Setting up Ollama systemd to start listening on 0.0.0.0" -Type "INFO"
			Start-Process -FilePath "wsl" -ArgumentList " -d Ollama_WSL -u root -e bash -c `"  sed -i `'/ExecStart/a Environment=OLLAMA_HOST=0.0.0.0`'   /etc/systemd/system/ollama.service `" "   -wait -NoNewWindow
			Start-Process -FilePath "wsl" -ArgumentList " -d Ollama_WSL -u root -e bash -c `"  systemctl daemon-reload `" "   -wait -NoNewWindow
			Write-Message  -Message "Restarting Ollama" -Type "INFO"
			Start-Process -FilePath "wsl" -ArgumentList " -d Ollama_WSL -u root -e bash -c `" systemctl restart ollama.service `" "   -wait -NoNewWindow
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList ' -d Ollama_WSL -u root journalctl  -f -n 999999 --no-pager -u ollama.service'  -WindowStyle minimized
		}

			#port fwd
			Start-Process -FilePath "$env:WSLBIN" -ArgumentList " -d Ollama_WSL -u root -e bash -c `" ip route get 1.1.1.1  `" " -NoNewWindow -RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt
			Start-Sleep 10
			Get-Content RedirectStandardOutput.txt

			$INTERNETIP = Get-Content RedirectStandardOutput.txt | ForEach-Object { $elements = $_ -split ' '; $elements[6] }
			Set-Content -Path NetSh.txt -Value "You need to run the following as administrator to reach the services from outside the host mashine exclude port 8080 if you are not running OpenWebUI" 
			Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=$INTERNETIP"
			Add-Content -Path NetSh.txt -Value "netsh interface portproxy add v4tov4 listenport=11434 listenaddress=0.0.0.0 connectport=11434 connectaddress=$INTERNETIP"
			Invoke-Item -Path NetSh.txt
		}
}

############# WipeForwardRules
Function WipeForwardRules {
			CheckAdmin
			Write-Message  -Message  "About to clear the following interface portproxy rules..." -Type "ERROR"
			Start-Process -FilePath "netsh"  -ArgumentList "  interface portproxy show all   " -wait -NoNewWindow
			Start-Sleep 10
			$output = netsh interface portproxy show all | ForEach-Object {
			$_ -replace '^\s+','' -replace '\s+$',''
			} | Where-Object {$_ -match '\S'} | ConvertFrom-String -PropertyNames @('ListenAddress','ListenPort','ConnectAddress','ConnectPort') -Delimiter '\s+'
			$output| ForEach-Object {
				netsh interface portproxy delete v4tov4 listenport=$($_.ListenPort)  listenaddress=$($_.ListenAddress)
			}
			Write-Message  -Message  "Cleared interface portproxy rules..." -Type "INFO"
}


############# lowerright
Function lowerright {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

$handle = [Win32]::GetForegroundWindow()
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$rect = New-Object Win32+RECT
[Win32]::GetWindowRect($handle, [ref]$rect)  |Out-Null
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
# Position window in lower right
$x = $screen.Right - $width
$y = $screen.Bottom - $height
[Win32]::MoveWindow($handle, $x, $y, $width, $height, $true) |Out-Null
}

  
############# CheckVer
Function CheckVer {
	Write-Message  -Message  "Checking for updates.." -Type "INFO"
    # Download the PS1 file content from GitHub
    $scriptContent = Invoke-WebRequest -Uri "https://github.com/freeload101/Java-Android-Magisk-Burp-Objection-Root-Emulator-Easy/raw/refs/heads/main/JAMBOREE.ps1" -UseBasicParsing | Select-Object -ExpandProperty Content


    if ($scriptContent -match '\$Global:VerNum\s+\=\s+''(.*)''') {
        $VerNumLatest = $matches[1]

        # Compare versions
        if ($VerNumLatest -ne $Global:VerNum) {
		Write-Message  -Message  "Version mismatch! Current version: $Global:VerNum, Latest version: $VerNumLatest" -Type "WARNING"
		$wshell = New-Object -ComObject Wscript.Shell
		$pause = $wshell.Popup("Version mismatch! Current version: $Global:VerNum, Latest version: $VerNumLatest . Would you like to Update JAMBOREE?", 0, "Update JAMBOREE?", 48+1)
			if ($pause -eq '1') {
			UpdateJAMBO
			}
			Elseif ($pause = '2') {
			Write-Message  -Message  "Not Updating JAMBOREE" -Type "WARNING"
			return
			}

			} else {
			Write-Message  -Message  "Running Latest $Global:VerNum !" -Type "INFO"
			}
    } else {
        Write-Message  -Message  "Could not find `$VerNum in the downloaded script" -Type "ERROR"
 
    }
}

############# EXECheckOllama
function EXECheckOllama{
  if (-not(Test-Path -Path "$VARCD\Ollama" )) {
	try {
		Write-Message "Downloading Ollama" -Type "INFO"
		New-Item -Path "$VARCD\Ollama\" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
		downloadFile "https://ollama.com/download/OllamaSetup.exe" "$VARCD\Ollama\OllamaSetup.exe"
		Write-Message "Installing Ollama to $VARCD\Ollama" -Type "INFO"
		Start-Process -FilePath "$VARCD\Ollama\OllamaSetup.exe" -WorkingDirectory "$VARCD\Ollama\" -ArgumentList " /SILENT /NORESTART /DIR=`"$VARCD\Ollama`" "  -NoNewWindow
		
		Write-Message "Waiting for Ollama to start" -Type "INFO"
		while(!(Get-Process "ollama app" -ErrorAction SilentlyContinue)){Start-Sleep -Seconds 5};Write-Message "Waiting for Ollama to start" -Type "INFO"

		Write-Message "Installing base models" -Type "INFO"
		Start-Process -FilePath "$VARCD\Ollama\Ollama.exe" -WorkingDirectory "$VARCD\Ollama\" -ArgumentList " pull nomic-embed-text " -wait -NoNewWindow
		Start-Process -FilePath "$VARCD\Ollama\Ollama.exe" -WorkingDirectory "$VARCD\Ollama\" -ArgumentList " pull hf.co/Sweaterdog/Andy-3.6:Q4_K_M " -wait -NoNewWindow
		
		Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Ollama.lnk" -Force -ErrorAction SilentlyContinue |Out-Null
		
		Write-Message "Setting .ollama OLLAMA_MODELS System.Environment to $VARCD\Ollama\ and listen on 0.0.0.0" -Type "INFO"
		[System.Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "$VARCD\Ollama\.ollama", [System.EnvironmentVariableTarget]::Machine)
		[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", [System.EnvironmentVariableTarget]::Machine)
		[System.Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "-1", [System.EnvironmentVariableTarget]::Machine)
		
		
		}
			catch {
				throw $_.Exception.Message
		}
		}
	else {
		
		Stop-process -name ollama -Force -ErrorAction SilentlyContinue |Out-Null
		Stop-process -name "ollama app" -Force -ErrorAction SilentlyContinue |Out-Null
		
		Write-Message "Downloading Latetst binary from github" -Type "INFO"
		$downloadUri = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/ollama/ollama/releases/latest").assets | Where-Object name -like ollama-windows-amd64.zip ).browser_download_url
		downloadFile  $downloadUri "$VARCD\ollama-windows-amd64.zip"
		Write-Message  -Message  "Extracting ollama-windows-amd64.zip" -Type "INFO"
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		Add-Type -AssemblyName System.IO.Compression
		[System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\ollama-windows-amd64.zip", "$VARCD\Ollama\")
		
		
		Write-Message "Starting Ollama ...." -Type "INFO"
		Stop-process -name ollama -Force -ErrorAction SilentlyContinue |Out-Null
		Stop-process -name "ollama app" -Force -ErrorAction SilentlyContinue |Out-Null
		Start-Sleep -Seconds 1
		Start-Process -FilePath "$VARCD\Ollama\ollama app.exe" -WorkingDirectory "$VARCD\Ollama\"
		while(!(Get-Process "ollama app" -ErrorAction SilentlyContinue)){Start-Sleep -Seconds 5};Write-Message "Waiting for Ollama to start" -Type "INFO"
		Start-Sleep -Seconds 2
  		Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Ollama.lnk" -Force -ErrorAction SilentlyContinue |Out-Null
		}
}


######################################################################################################################### FUNCTIONS END
lowerright
CheckVer

############# accel
$pname=(Get-WMIObject win32_Processor | Select-Object name)
if ($pname -like "*AMD*") {
    Write-Message  -Message  "AMD Processor detected" -Type "INFO"
    ############# Button
    ############# AMD PROCESSOR DETECTED
    $Button = New-Object System.Windows.Forms.Button
    $Button.AutoSize = $true
    $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
    # Check if Hyper-V is enabled
        if($hyperv.State -eq "Enabled") {
            Write-Message  -Message  "[!] Hyper-V is already enabled." -Type "INFO"
            # Already installed, disable button   
            $Button.Text = "2. Hyper-V Already Installed"
            $Button.Enabled = $false
        } else {

        $Button.Text = "Hyper-V Install (Reboot?)" # Install Hyper-V
        $Button.Enabled = $true
        }
    $Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
    $Button.Add_Click({HyperVInstall})
    $main_form.Controls.Add($Button)
	$vShift = $vShift + 30
}
else {
    ############# Button
    ############# INTEL PROCESSOR DETECTED
    $Button = New-Object System.Windows.Forms.Button
    $Button.AutoSize = $true
    $Button.Text = "HAXM Install" #HAXMInstall
    $Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
    $Button.Add_Click({HAXMInstall})
    $main_form.Controls.Add($Button)
	$vShift = $vShift + 30
}

############# StartBurp
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "BurpSuite Community"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({StartBurp})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# AVDStart
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Start AVD" #AVDStart
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({AVDStart})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# RootAVD
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "RootAVD/Install Magisk"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({RootAVD})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# #CertPush
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Upload BURP.pem as System Cert"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({CertPush})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# CheckRMS
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "RMS: Runtime Mobile Security"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({StartRMS})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartFrida
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Frida/AntiRoot/SSLDepinning"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({StartJAMBOREE_SSL_N_ANTIROOT})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartObjection
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "StartObjection"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({StartObjection})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30
 
############# CMDPrompt
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "CMD/ADB/Java/Python/Git/Node Prompt"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({CMDPrompt})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartBurpPro
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Burp Suite Pro"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({StartBurpPro})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# BurpWithZap
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Burp Suite Community/ZAP"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({BurpWithZap})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# BurpProWithZap
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Burp Suite Pro/ZAP"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({BurpProWithZap})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartZAP
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "ZAP"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({StartZAP})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartADB
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "ADB Logcat"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({StartADB})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# AVDPoweroff
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Shutdown AVD"
$Button.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button.Add_Click({AVDPoweroff})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# AVDWipeData
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "AVD -wipe-data (Fix unauthorized adb)"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({AVDWipeData})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# InstallAPKS
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Install Base APKs"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({InstallAPKS})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# Debloat
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Debloat UI Tool"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({Debloat})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############ KillADB
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Kill adb.exe"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({KillADB})
$main_form.Controls.Add($Button)
$vShift = 0
$hShift = $hShift + 250

############# SharpHoundRun
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "SharpHound"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({SharpHoundRun})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# Neo4jRun
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Neo4j"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({Neo4jRun})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# Bloodhound
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Bloodhound"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({BloodhoundRun})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartAutoGPT
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "AutoGPT"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({StartAutoGPT})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# AUTOMATIC1111
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "AUTOMATIC1111"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({AUTOMATIC1111})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# vladmandic_automatic
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "SD.Next Stable Diffusion"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({vladmandic_automatic})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# CheckPyCharm
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "PyCharm"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({CheckPyCharm})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# WSLOracleLinux
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "WSL OracleLinux"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({WSLOracleLinux})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# WSLUbuntu
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "WSL Ubuntu"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({WSLUbuntu})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# SOCFortressCoPilotFast
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "WSL SOCFortress CoPilot"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({SOCFortressCoPilotFast})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# EXECheckOllama
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Ollama Windows EXE"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({EXECheckOllama})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# WSLCheckOllama
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "WSL Ollama"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({WSLCheckOllama})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# WSLShrink
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "WSL Shrink"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({WSLShrink})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# StartSillyTavern
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "SillyTavern"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({StartSillyTavern})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# CheckPostgres
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "PostgreSQL"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({CheckPostgres})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# CheckArduino
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Arduino IDE"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({CheckArduino})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# PushDuckyLoad
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Duck2Spark"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({PushDuckyLoad})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# Ytdlp
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Ytdlp"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({Ytdlp})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# CheckVolatility3
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Volatility 3"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({CheckVolatility3})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# WipeForwardRules
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Clear netsh portproxy rules"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({WipeForwardRules})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

############# UpdateJAMBO
$Button = New-Object System.Windows.Forms.Button
$Button.AutoSize = $true
$Button.Text = "Update JAMBOREE"
$Button.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+0))
$Button.Add_Click({UpdateJAMBO})
$main_form.Controls.Add($Button)
$vShift = $vShift + 30

if ($Headless) {
	Write-Message  -Message  "Running in headless mode" -Type "WARNING"
	$Global:NOGUI = 1
    & $Headless
	exit
}

############# SHOW FORM
$main_form.ShowDialog()
