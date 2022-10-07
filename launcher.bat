@echo off


:::                                  .
:::     .              .   .'.     \   /
:::   \   /      .'. .' '.'   '  -=  o  =-
::: -=  o  =-  .'   '              / | \
:::   / | \                          |
:::     |        JAMBOREE            |
:::     |                            |
:::     |        LAUNCHER      .=====|
:::     |=====.                |.---.|
:::     |.---.|                ||=o=||
:::     ||=o=||                ||   ||
:::     ||___||                |[:::]|
:::     |[:::]|                '-----'
:::     '-----'   

:: ****************************************
:: * JAMBOREE LAUNCHER SCRIPT
:: * 
:: * Purpose: 
:: * 1. Ensure scripts is ran:
:: *   A. As Administrator
:: *   B. From a path without spaces
:: * 2. Launches JAMBOREE as Administrator
:: *
:: ****************************************

SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS


SET EXITFLAG=0
SET LAUNCHPATH=%CURRPATH%

:: Main execution

cd %~dp0
:: Elevate to Admin if needed
CALL :ElevateToAdminCheck

:: Verify program is ran as administrator
CALL :ExitOnCurrentUserNotAdministrator
if %EXITFLAG% EQU 1 (
    echo [*] - Exiting
    Exit /b 1
)



:: Verify program is ran from a path with spaces
CALL :ExitOnCurrentPathHasSpaces
if %EXITFLAG% EQU 1 (
    echo [*] - Exiting
    Exit /b 1
)
:: Display Welcome Banner
CALL :Welcome

:: Ask user if they are ready to launch
CALL :AreYouSurePrompt
if %EXITFLAG% EQU 1 (
    echo [*] - Exiting
    Exit /b 1
)

CALL :LaunchJAMBOREE
if %EXITFLAG% EQU 1 (
    echo [*] - Exiting
    Exit /b 1
)

goto End1

:: ***********************
:: Functions are Below

:: Check privileges
:ElevateToAdminCheck
NET SESSION
IF %ERRORLEVEL% NEQ 0 GOTO ELEVATE

:: Exit Function
goto :eof

:ELEVATE
CD /d %~dp0
MSHTA "javascript: var shell = new ActiveXObject('shell.application'); shell.ShellExecute('%~nx0', '', '', 'runas', 1);close();"
EXIT

:: Exit Function
goto :eof



:ExitOnCurrentUserNotAdministrator
WHOAMI /Groups | FIND "12288" >NUL
if '%errorlevel%' NEQ '0' (
    echo [*] - You must run this program as an administrator
    pause
    SET EXITFLAG=1
    exit /b 1    
    goto :End1
    goto :eof
) 
:: Exit Function
goto :eof

:ExitOnCurrentPathHasSpaces
set CURRPATH=%~dp0
if not "%CURRPATH%"=="%CURRPATH: =%" (
    echo [!] - This program MUST be ran from a location without spaces in the file Path
    pause
    SET EXITFLAG=1
    exit /b 1    
    goto :End1
    goto :eof
)
:: Exit Function
goto :eof

:AreYouSurePrompt
Choice /M "Ready to proceed?"
if '%errorlevel%' NEQ '1' (
    SET EXITFLAG=1
    exit /b 1    
    goto :End1
    goto :eof
) 
:: Exit Function
goto :eof


:Welcome
set CURRPATH=%~dp0

:: Print JAMBOREE ASCII ART
for /f "delims=: tokens=*" %%A in ('findstr /b ::: "%~f0"') do @echo(%%A

:: Echo out to user
echo -------------------------------
echo  Welcome to JAMBOREE launcher
echo -------------------------------
echo.  
echo [*] - Launch File [%CURRPATH%JAMBOREE.ps1]?
echo.  
:: Exit Function
goto :eof

: LaunchJAMBOREE
set PathJAMBOREE=%CURRPATH%JAMBOREE.ps1
if exist %PathJAMBOREE% (
    :: file exists
    echo.  
    echo [*] - Launching From: %CURRPATH%JAMBOREE.ps1
    echo.  
    call %WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -File %PathJAMBOREE%
) else (
    :: file doesn't exist
    echo [!] - ERROR - [JAMBOREE was not found at %PathJAMBOREE%]
    echo [*] - Exiting
    SET EXITFLAG=1
    exit /b 1    
    goto :End1
    goto :eof
)

:: Exit function
goto :eof


:End1
pause