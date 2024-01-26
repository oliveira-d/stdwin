:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::           SCRIPT DE CONFIGURAÇÃO do WINDOWS                 ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Automaticamente checar e obter privilégios de Admin ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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

::::::::::::::::::::::::::::::
::     COMEÇO do SCRIPT     ::
::::::::::::::::::::::::::::::

:: Delayed Expansion will cause variables to be expanded at execution time rather than at parse time
setlocal EnableDelayedExpansion
chcp 65001 > nul
set first_winget_install=done
set winget_msixbundle=Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
set ui_xaml_appx=Microsoft.UI.Xaml.2.7.x64.appx
set vclib_appx=Microsoft.VCLibs.x64.14.00.Desktop.appx

:: Definição de variáveis a partir do arquivo config.txt
if not exist "%~dp0config\config.txt" (
	echo Arquivo^ config.txt^ no^ encontrado!
	pause
	exit
)
for /F "usebackq tokens=*" %%V in ( `type "%~dp0config\config.txt" ^| findstr /V "^::"` ) do ( set %%V )

:: Verificação do nome do computador
ver > nul
if %rename_computer%==always (
	if not exist "%~dp0config\MR" (
		echo Nome^ do^ computador^ no^ esta^ de^ acordo^ com^ o^ padrao^ requerido.
		"%~dp0Scripts\renamePC.cmd" %computer_name_pattern% 2>>errorlog.txt
		echo Maquina^ renomeada > "%~dp0config\MR"
		schtasks /create /tn "WindowsSTDSetup" /tr "%0" /sc onlogon /delay 0001:00 /rl highest
		echo Esse^ script^ sera^ interrompido^ e^ a^ maquina^ sera^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ proxima^ sessao^ apos^ confirmar^ que^ o^ nome^ do^ computador^ esta^ no^ padrao^ requerido
		:: remover expiração de passwd dos usuários - usuários criados pelo Rufus e pelo comando "net user" tem uma passwd com prazo e após esse prazo o sistema pede por uma nova passwd que seria escolhida pelo usuário
		wmic UserAccount where Name="%username%" set PasswordExpires=false > nul 2>>errorlog.txt
		shutdown /r /t 30
		pause
		exit
	)
) else if %rename_computer%==check (
	echo %computername% | findstr "%computer_name_pattern%" > nul
	if not '!errorlevel!' == '0' (
		echo Nome^ do^ computador^ no^ esta^ de^ acordo^ com^ o^ padrao^ requerido.
		"%~dp0Scripts\renamePC.cmd" %computer_name_pattern% 2>>errorlog.txt
		schtasks /create /tn "WindowsSTDSetup" /tr "%0" /sc onlogon /delay 0001:00 /rl highest
		echo Esse^ script^ sera^ interrompido^ e^ a^ maquina^ sera^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ proxima^ sessao^ apos^ confirmar^ que^ o^ nome^ do^ computador^ esta^ no^ padrao^ requerido
		:: remover expiração de passwd dos usuários - usuários criados pelo Rufus e pelo comando "net user" tem uma passwd com prazo e após esse prazo o sistema pede por uma nova passwd que seria escolhida pelo usuário
		wmic UserAccount where Name="%username%" set PasswordExpires=false > nul 2>>errorlog.txt
		shutdown /r /t 30
		pause
		exit
	)
) else if %rename_computer%==ignore (
	echo Ignorando^ verificacao^ de^ nome^ de^ maquina.
) else (
	echo Parametro^ "rename_computer"^ no^ reconhecido.
	pause
	exit
)

if not '%1' == 'programas-manuais-instalados' (
	for %%F in ( "%~dp0Files\*.exe" ) do ( "%%F" /S )
	for %%F in ( "%~dp0Files\*.msi" ) do ( "%%F" )
)

:: check se winget est� instalado e, se n�o, instal�-lo e relan�ar o script:
ver > nul
winget list --accept-source-agreements > nul
CLS
if not '%errorlevel%' == '0' (
	systeminfo | find "Windows 10" > nul
	if '!errorlevel!' == '0' (
		if not exist .\temp\%ui_xaml_appx% ( 
			echo Baixando^ Microsoft.UI.Xaml...
			powershell Invoke-WebRequest -Uri %ms_ui_xaml_url% -OutFile .\temp\%ui_xaml_appx% 2>>errorlog.txt
		)
		CLS
		if not exist .\temp\%vclib_appx% ( 
			echo Baixando^ Microsoft.VCLibs...
			powershell Invoke-WebRequest -Uri %ms_vclib_url% -OutFile .\temp\%vclib_appx% 2>>errorlog.txt
		)
		CLS
		echo Instalando^ Microsoft.UI.Xaml...
		powershell Add-AppXPackage -Path .\temp\%ui_xaml_appx% 2>>errorlog.txt
		CLS
		echo Instalando^ Microsoft.VCLibs...
		powershell Add-AppXPackage -Path .\temp\%vclib_appx% 2>>errorlog.txt
	)
	CLS
	if not exist .\temp\%winget_msixbundle% ( 
		echo Baixando^ Microsoft.DesktopAppInstaller...
		powershell Invoke-WebRequest -Uri %winget_url% -OutFile .\temp\%winget_msixbundle% 2>>errorlog.txt
	)
	CLS
	echo Instalando^ Microsoft.DesktopAppInstaller...
	powershell Add-AppXPackage -Path .\temp\%winget_msixbundle% 2>>errorlog.txt
	%0 programas-manuais-instalados
	exit
)

:: disable suspensao automatica antes de começar as instalações via winget (MS Office demora demais e as vezes o notebook suspende durante a instalação)
if "%disable_ac_suspend%" == "yes " (
	powercfg /x standby-timeout-ac 0
)
if "%disable_bat_suspend%" == "yes " (
	powercfg /x standby-timeout-dc 0
)

:: instalação de programas via winget
winget list --accept-source-agreements > nul
ver > nul
echo Instalando^ programas^ via^ winget...
for /F "usebackq tokens=*" %%P in ( `type "%~dp0config\winget.txt" ^| findstr /V "^::"` ) do (
	winget list | find /i "%%P "
	if '!errorlevel!' == '1' ( 
		echo Instalando^ %%P...
		if '%first_winget_install%' == 'done' ( 
		winget install %%P 
		) else ( 
			winget install --accept-source-agreements %%P
			set first_winget_install=done
		)
	) else (
		echo %%P^ ja esta instalado!
	)
	if not '!errorlevel!' == '0' ( 
		echo Falha^ na^ instalacao^ de^ %%P!
		echo winget^ install^ --force^ %%P >> "%~dp0fix-setup.cmd" 
	)
	CLS
)

echo Copiando^ atalhos...
:: copiar atalhos de URL para a área de trabalho e para o Menu Iniciar
for %%F in ( "%~dp0Files\*.url" ) do ( xcopy /Y "%%F" "%appdata%\Microsoft\Windows\Start Menu\Programs\" > nul )
for %%F in ( "%~dp0Files\*.url" ) do ( xcopy /Y "%%F" "%userprofile%\Desktop\" > nul )

:: PERMITIR EXECUÇÃO DOS SCRIPTS DE POWERSHELL
powershell Set-ExecutionPolicy unrestricted

:: Aplicar papel de parede
if not "%wallpaperPath%" == " " (
	if exist "%~dp0Files\%wallpaper_file_name%" (
		echo Aplicando^ papel^ de^ parede...
		powershell -File "%~dp0Scripts\Set-Wallpaper.ps1" "%~dp0Files\%wallpaper_file_name%"
	)
)

:: Aplicar tela de bloqueio
if not "%lockscreenPath%" == " " (
	if exist "%~dp0Files\%lockscreen_file_name%" (
		echo Aplicando^ tela^ de^ bloqueio...
		powershell -File "%~dp0Scripts\Set-Lockscreen.ps1" "%~dp0Files\%lockscreen_file_name%"
	)
)

:: RESTRINGIR EXECUÇÃO DE SCRIPTS DE POWERSHELL
powershell Set-ExecutionPolicy restricted

:: disable OneDrive
if "%disable_onedrive%" == "yes " (
	echo Desabilitando^ OneDrive...
	reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v OneDrive /t REG_SZ /d NoOneDrive
	netsh advfirewall firewall add rule name="BlockOneDrive0" action=block dir=out program="C:\ProgramFiles (x86)\Microsoft OneDrive\OneDrive.exe"
)

:: disable Teams
if "%disable_teams%" == "yes " (
	echo Desabilitando^ Teams...
	reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v com.squirrel.Teams.Teams /t REG_SZ /d NoTeamsCurrentUser
	reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /f /v TeamsMachineInstaller /t REG_SZ /d NoTeamsLocalMachine
)

:: disable serviço de hostpot
if "%disable_hotspot%" == "yes " (
	echo Desabilitando^ servico^ de^ hotspot...
	sc config icssvc start=disabled > nul 2>>errorlog.txt
)

:: enable windows sandbox
if "%enable_windows_sandbox" == "yes" (
	powershell -command "Enable-WindowsOptionalFeature -FeatureName 'Containers-DisposableClientVM' -All -Online"
)

:: criação de usuários Super e Suporte
if "%drop_admin_privilege%" == "yes " (
	echo Criando^ usuarios^ administradores...
	net user root /add > nul 2>>errorlog.txt
	net user suporte /add > nul 2>>errorlog.txt
	:: definição de passwds de usuarios Super e Suporte
	net user root %root_passwd% > nul 2>>errorlog.txt
	net user suporte %passwd_suporte% > nul 2>>errorlog.txt
	:: remover expiração de passwd dos usuarios - usuarios criados pelo Rufus e pelo comando acima tem uma passwd com prazo e apos esse prazo o sistema pede por uma nova passwd que seria escolhida pelo usuario
	wmic UserAccount where Name='root' set PasswordExpires=false > nul 2>>errorlog.txt
	wmic UserAccount where Name='suporte' set PasswordExpires=false > nul 2>>errorlog.txt
	:: conceder/remover privilegios de admin dos usuarios
	net localgroup %admin_group% root /add > nul 2>>errorlog.txt
	net localgroup %admin_group% suporte /add > nul 2>>errorlog.txt
	net localgroup %admin_group% "%username%" /delete > nul 2>>errorlog.txt
	:: usuario padrao some se no estiver no grupo "Usuarios"
	ver > nul
	net localgroup %users_group% | find "%username%"
	if not '%errorlevel%' == '0' (
		net localgroup %users_group% "%username%" /add > nul 2>>errorlog.txt
	)
)

if not "%passwd" == " " (
	net user "%username%" %passwd% > nul 2>>errorlog.txt
)

:: o script pausa antes de fechar o cmd e deleta o arquivo de configuração para que usuários n�o tenham acesso às passwds escritas nele
del "%~dp0config\config.txt"
if exist "%~dp0config\MR" (
	del "%~dp0config\MR"
)
del /q "%~dp0temp\*"
schtasks /delete /tn "WindowsSTDSetup" /f

rundll32.exe user32.dll,LockWorkStation > nul 2>>errorlog.txt

if exist "%~dp0fix-setup.cmd" (
	echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALACAO^ DE^ PROGRAMAS^ VIA^ WINGET.^              ::
	echo ::^ Para^ conserta-los^ execute,^ sem^ privilegio^ de^ administrador^ o^ script^ fix-setup.cmd^  ::
	echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALACAO^ DE^ PROGRAMAS^ VIA^ WINGET.^              ::
	echo ::^ Para^ conserta-los^ execute,^ sem^ privilegio^ de^ administrador^ o^ script^ fix-setup.cmd^  ::
	echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALACAO^ DE^ PROGRAMAS^ VIA^ WINGET.^              ::
	echo ::^ Para^ conserta-los^ execute,^ sem^ privilegio^ de^ administrador^ o^ script^ fix-setup.cmd^  ::
	echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
)
pause
exit