:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::              WINDOWS CONFIGURATION SCRIPT                   ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Automatically check and get admin privilege
@echo off
CLS

:init
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)

echo Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
echo args = "ELEV " >> "%vbsGetPrivileges%"
echo For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
echo args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
echo Next >> "%vbsGetPrivileges%"
echo UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

:: start of the script

:: Delayed Expansion will cause variables to be expanded at execution time rather than at parse time
setlocal EnableDelayedExpansion
chcp 65001 > nul
set first_winget_install=done
set winget_msixbundle=Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
set ui_xaml_appx=Microsoft.UI.Xaml.2.7.x64.appx
set vclib_appx=Microsoft.VCLibs.x64.14.00.Desktop.appx

:: get variables from config.txt
if not exist "%~dp0config\config.txt" (
	echo File^ config.txt^ not^ found!
	pause
	exit
)
for /F "usebackq tokens=*" %%V in ( `type "%~dp0config\config.txt" ^| findstr /V "^::"` ) do ( set %%V )

:: check and rename computer
ver > nul
if %rename_computer%==always (
	if not exist "%~dp0config\MR" (
		"%~dp0Scripts\renamePC.cmd" %computer_name_pattern% 2>>errorlog.txt
		echo Maquina^ renomeada > "%~dp0config\MR"
		schtasks /create /tn "WindowsSTDSetup" /tr "%0" /sc onlogon /delay 0001:00 /rl highest
		echo This^ script^ will^ be^ interrupted^ and^ the^ computer^ will^ be restarted^ in^ 30^ seconds.^ This^ script^ will^ be^ automatically^ executed^ on^ next^ reboot.
		:: remove password expiration of the user - users created by Rufus and by net user command have passwordexpires=true
		wmic UserAccount where Name="%username%" set PasswordExpires=false > nul 2>>errorlog.txt
		shutdown /r /t 30
		pause
		exit
	)
) else if %rename_computer%==check (
	echo %computername% | findstr "%computer_name_pattern%" > nul
	if not '!errorlevel!' == '0' (
		echo Computer^ name^ is^ not^ according^ to^ required^ standard.
		"%~dp0Scripts\renamePC.cmd" %computer_name_pattern% 2>>errorlog.txt
		schtasks /create /tn "WindowsSTDSetup" /tr "%0" /sc onlogon /delay 0001:00 /rl highest
		echo This^ script^ will^ be^ interrupted^ and^ the^ computer^ will^ be restarted^ in^ 30^ seconds.^ This^ script^ will^ be^ automatically^ executed^ on^ next^ reboot.
		:: remove password expiration of the user - users created by Rufus and by net user command have passwordexpires=true
		wmic UserAccount where Name="%username%" set PasswordExpires=false > nul 2>>errorlog.txt
		shutdown /r /t 30
		pause
		exit
	)
) else if %rename_computer%==ignore (
	echo Proceeding^ without^ changing^ computer^ name
) else (
	echo Parameter^ "rename_computer"^ not^ recognized
	pause
	exit
)

if not '%1' == 'skip-exe' (
	for %%F in ( "%~dp0Files\*.exe" ) do ( "%%F" /S )
	for %%F in ( "%~dp0Files\*.msi" ) do ( "%%F" )
)

:: check if winget is installed and, if not, install it and relaunch script
ver > nul
winget list --accept-source-agreements > nul
CLS
if not '%errorlevel%' == '0' (
	systeminfo | find "Windows 10" > nul
	if '!errorlevel!' == '0' (
		if not exist .\temp\%ui_xaml_appx% ( 
			echo Downloading^ Microsoft.UI.Xaml...
			powershell Invoke-WebRequest -Uri %ms_ui_xaml_url% -OutFile .\temp\%ui_xaml_appx% 2>>errorlog.txt
		)
		CLS
		if not exist .\temp\%vclib_appx% ( 
			echo Downloading^ Microsoft.VCLibs...
			powershell Invoke-WebRequest -Uri %ms_vclib_url% -OutFile .\temp\%vclib_appx% 2>>errorlog.txt
		)
		CLS
		echo Installing^ Microsoft.UI.Xaml...
		powershell Add-AppXPackage -Path .\temp\%ui_xaml_appx% 2>>errorlog.txt
		CLS
		echo Installing^ Microsoft.VCLibs...
		powershell Add-AppXPackage -Path .\temp\%vclib_appx% 2>>errorlog.txt
	)
	CLS
	if not exist .\temp\%winget_msixbundle% ( 
		echo Downloading^ Microsoft.DesktopAppInstaller...
		powershell Invoke-WebRequest -Uri %winget_url% -OutFile .\temp\%winget_msixbundle% 2>>errorlog.txt
	)
	CLS
	echo Installing^ Microsoft.DesktopAppInstaller...
	powershell Add-AppXPackage -Path .\temp\%winget_msixbundle% 2>>errorlog.txt
	%0 skip-exe
	exit
)

:: disable auto suspend before starting winget installations - MS Office, for example, takes too long and computer may suspend during install
if "%disable_ac_suspend%" == "yes " (
	powercfg /x standby-timeout-ac 0
)
if "%disable_bat_suspend%" == "yes " (
	powercfg /x standby-timeout-dc 0
)

:: instalação de programas via winget
winget list --accept-source-agreements > nul
ver > nul
echo Installing^ software^ via^ winget...
for /F "usebackq tokens=*" %%P in ( `type "%~dp0config\winget.txt" ^| findstr /V "^::"` ) do (
	winget list | find /i "%%P "
	if '!errorlevel!' == '1' ( 
		echo Installing^ %%P...
		if '%first_winget_install%' == 'done' ( 
		winget install %%P 
		) else ( 
			winget install --accept-source-agreements %%P
			set first_winget_install=done
		)
	) else (
		echo %%P^ already^ installed!
	)
	if not '!errorlevel!' == '0' ( 
		echo Failed^ to^ install^ %%P!
		echo winget^ install^ --force^ %%P >> "%~dp0fix-setup.cmd" 
	)
	CLS
)

:: copy URL shortcuts to Desktop and Start Menu
echo Copying^ shortcuts...
for %%F in ( "%~dp0Files\*.url" ) do ( xcopy /Y "%%F" "%appdata%\Microsoft\Windows\Start Menu\Programs\" > nul )
for %%F in ( "%~dp0Files\*.url" ) do ( xcopy /Y "%%F" "%userprofile%\Desktop\" > nul )

:: ALLOW EXECUTION OF POWERSHELL SCRIPTS
powershell Set-ExecutionPolicy unrestricted

:: Apply wallpaper
if not "%wallpaperPath%" == " " (
	if exist "%~dp0Files\%wallpaper_file_name%" (
		echo Applying^ wallpaper...
		powershell -File "%~dp0Scripts\Set-Wallpaper.ps1" "%~dp0Files\%wallpaper_file_name%"
	)
)

:: Apply lockscreen
if not "%lockscreenPath%" == " " (
	if exist "%~dp0Files\%lockscreen_file_name%" (
		echo Applying^ lockscreen...
		powershell -File "%~dp0Scripts\Set-Lockscreen.ps1" "%~dp0Files\%lockscreen_file_name%"
	)
)

:: RESTRICT EXECUTION OF POWERSHELL SCRIPTS
powershell Set-ExecutionPolicy restricted

:: disable OneDrive
if "%disable_onedrive%" == "yes " (
	echo Disabling^ OneDrive...
	reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v OneDrive /t REG_SZ /d NoOneDrive
	netsh advfirewall firewall add rule name="BlockOneDrive0" action=block dir=out program="C:\ProgramFiles (x86)\Microsoft OneDrive\OneDrive.exe"
)

:: disable Teams
if "%disable_teams%" == "yes " (
	echo Disabling^ Teams...
	reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v com.squirrel.Teams.Teams /t REG_SZ /d NoTeamsCurrentUser
	reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /f /v TeamsMachineInstaller /t REG_SZ /d NoTeamsLocalMachine
)

:: disable serviço de hostpot
if "%disable_hotspot%" == "yes " (
	echo Disabling^ hotspot^ service...
	sc config icssvc start=disabled > nul 2>>errorlog.txt
)

:: enable windows sandbox
if "%enable_windows_sandbox" == "yes" (
	echo Enabling^ Windows^ Sandbox...
	powershell -command "Enable-WindowsOptionalFeature -FeatureName 'Containers-DisposableClientVM' -All -Online"
)

:: create root user and drop privileges
if "%drop_admin_privilege%" == "yes " (
	echo Creating^ administrators^ users...
	net user root /add > nul 2>>errorlog.txt
	net user root %root_passwd% > nul 2>>errorlog.txt
	wmic UserAccount where Name='root' set PasswordExpires=false > nul 2>>errorlog.txt
	net localgroup %admin_group% root /add > nul 2>>errorlog.txt
	net localgroup %admin_group% "%username%" /delete > nul 2>>errorlog.txt
	ver > nul
	net localgroup %users_group% | find "%username%"
	if not '%errorlevel%' == '0' (
		net localgroup %users_group% "%username%" /add > nul 2>>errorlog.txt
	)
)

if not "%passwd%" == " " (
	net user "%username%" %passwd% > nul 2>>errorlog.txt
)

:: script pauses before exiting and deletes config file so that users can't access admin passwords
del "%~dp0config\config.txt"
if exist "%~dp0config\MR" (
	del "%~dp0config\MR"
)
del /q "%~dp0temp\*"
schtasks /delete /tn "WindowsSTDSetup" /f

rundll32.exe user32.dll,LockWorkStation > nul 2>>errorlog.txt

if exist "%~dp0fix-setup.cmd" (
	echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo ::^             ERRORS^ FOUND^ DURING^ INSTALLATION^ OF^ SOFTWARE^ VIA^ WINGET^                  ::
	echo ::^                              CHECK^ fix-setup.cmd^ FILE^                                     ::
	echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
)
pause
exit