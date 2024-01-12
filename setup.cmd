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
chcp 1252 > nul
set first_winget_install=done
set winget_msixbundle=Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
set ui_xaml_appx=Microsoft.UI.Xaml.2.7.x64.appx
set vclib_appx=Microsoft.VCLibs.x64.14.00.Desktop.appx

:: Definição de variáveis a partir do arquivo config.txt
for /F "usebackq tokens=*" %%V in ( `type "%~dp0config\config.txt" ^| findstr /V "^::"` ) do ( set %%V )

:: Verificação do nome do computador
ver > nul
if %renomear_maquina%==sempre (
	if not exist "%~dp0config\MR" (
		echo Nome^ do^ computador^ não^ está^ de^ acordo^ com^ o^ padrão^ requerido.
		"%~dp0Scripts\renamePC.cmd" %padrao_nome_maquina% 2>>errorlog.txt
		echo Máquina^ renomeada > "%~dp0config\MR"
		schtasks /create /tn "WindowsSTDSetup" /tr "%0" /sc onlogon
		echo Esse^ script^ será^ interrompido^ e^ a^ máquina^ será^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ próxima^ sessão^ após^ confirmar^ que^ o^ nome^ do^ computador^ está^ no^ padrão^ requerido
		shutdown /r /t 30
		pause
		exit
	)
) else if %renomear_maquina%==verificar (
	echo %computername% | findstr "%padrao_nome_maquina%" > nul
	if not '!errorlevel!' == '0' (
		echo Nome^ do^ computador^ não^ está^ de^ acordo^ com^ o^ padrão^ requerido.
		"%~dp0Scripts\renamePC.cmd" %padrao_nome_maquina% 2>>errorlog.txt
		schtasks /create /tn "WindowsSTDSetup" /tr "%0" /sc onlogon
		echo Esse^ script^ será^ interrompido^ e^ a^ máquina^ será^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ próxima^ sessão^ após^ confirmar^ que^ o^ nome^ do^ computador^ está^ no^ padrão^ requerido
		shutdown /r /t 30
		pause
		exit
	)
) else if %renomear_maquina%==ignorar (
	echo Ignorando^ verificação^ de^ nome^ de^ máquina.
) else (
	echo Parâmetro^ "renomear_maquina"^ não^ reconhecido.
	pause
	exit
)

if not '%1' == 'programas-manuais-instalados' (
	for %%F in ( "%~dp0Files\*.exe" ) do ( "%%F" )
	for %%F in ( "%~dp0Files\*.msi" ) do ( "%%F" )
)

:: verificar se winget está instalado e, se não, instalá-lo e relançar o script:
ver > nul
winget list --accept-source-agreements > nul
CLS
if not '%errorlevel%' == '0' (
	systeminfo | find "Windows 10" > nul
	if '!errorlevel!' == '0' (
		if not exist .\Files\%ui_xaml_appx% ( 
			echo Baixando^ Microsoft.UI.Xaml...
			powershell Invoke-WebRequest -Uri %ms_ui_xaml_url% -OutFile .\Files\%ui_xaml_appx% 2>>errorlog.txt
		)
		CLS
		if not exist .\Files\%vclib_appx% ( 
			echo Baixando^ Microsoft.VCLibs...
			powershell Invoke-WebRequest -Uri %ms_vclib_url% -OutFile .\Files\%vclib_appx% 2>>errorlog.txt
		)
		CLS
		echo Instalando^ Microsoft.UI.Xaml...
		powershell Add-AppXPackage -Path .\Files\%ui_xaml_appx% 2>>errorlog.txt
		CLS
		echo Instalando^ Microsoft.VCLibs...
		powershell Add-AppXPackage -Path .\Files\%vclib_appx% 2>>errorlog.txt
	)
	CLS
	if not exist .\Files\%winget_msixbundle% ( 
		echo Baixando^ Microsoft.DesktopAppInstaller...
		powershell Invoke-WebRequest -Uri %winget_url% -OutFile .\Files\%winget_msixbundle% 2>>errorlog.txt
	)
	CLS
	echo Instalando^ Microsoft.DesktopAppInstaller...
	powershell Add-AppXPackage -Path .\Files\%winget_msixbundle% 2>>errorlog.txt
	%0 programas-manuais-instalados
	exit
)

:: desabilitar suspensão automática antes de começar as instalações via winget (MS Office demora demais e as vezes o notebook suspende durante a instalação)
if '%desabilitar_suspensao_tomada%'=='sim' (
powercfg /x standby-timeout-ac 0
)
if '%desabilitar_suspensao_bateria%'=='sim' (
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
		echo %%P^ já está instalado!
	)
	if not '!errorlevel!' == '0' ( 
		echo Falha^ na^ instalação^ de^ %%P!
		echo winget^ install^ --force^ %%P >> "%~dp0fix-setup.cmd" 
	)
	CLS
)

echo Copiando^ atalhos...
:: copiar atalhos de URL para a área de trabalho e para o Menu Iniciar
for %%F in ( "%~dp0Files\*.url" ) do ( xcopy /Y "%%F" "%appdata%\Microsoft\Windows\Start Menu\Programs\" > nul )
for %%F in ( "%~dp0Files\*.url" ) do ( xcopy /Y "%%F" "%userprofile%\Desktop\" > nul )

echo Aplicando^ papel^ de^ parede^ e^ tela^ de^ bloqueio...
:: PERMITIR EXECUÇÃO DOS SCRIPTS DE POWERSHELL
powershell Set-ExecutionPolicy unrestricted

:: Aplicar papel de parede
if not '%wallpaperPath%'=='' (
powershell -File "%~dp0Scripts\Set-Wallpaper.ps1" %wallpaperPath%
)

:: Aplicar tela de bloqueio
if not '%lockscreenPath%'=='' (
powershell -File "%~dp0Scripts\Set-Lockscreen.ps1" %lockscreenPath%
)

:: RESTRINGIR EXECUÇÃO DE SCRIPTS DE POWERSHELL
powershell Set-ExecutionPolicy restricted

echo Desabilitando^ OneDrive...
:: desabilitar OneDrive
if '%desabilitar_onedrive%'=='sim' (
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v OneDrive /t REG_SZ /d NoOneDrive
netsh advfirewall firewall add rule name="BlockOneDrive0" action=block dir=out program="C:\ProgramFiles (x86)\Microsoft OneDrive\OneDrive.exe"
)

echo Desabilitando^ Teams...
:: desabilitar Teams
if '%desabilitar_teams%'=='sim' (
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v com.squirrel.Teams.Teams /t REG_SZ /d NoTeamsCurrentUser
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /f /v TeamsMachineInstaller /t REG_SZ /d NoTeamsLocalMachine
)

echo Desabilitando^ serviço^ de^ hotspot...
:: desabilitar serviço de hostpot
if '%desabilitar_hotspot%'=='sim' (
sc config icssvc start=disabled > nul 2>>errorlog.txt
)

:: desabilitar programas da Samsung em modelos 550X*
ver > nul
wmic computersystem get model | findstr "550X" > nul
if '%errorlevel%' == '0' (
	echo Desabilitando^ serviços^ da^ Samsung...
	sc config SamsungPlatformEngine start=disabled
	sc config SamsungSecuritySupportService start=disabled
	sc config SamsungSystemSupportService start=disabled
	:: powershell Set-Service -Name "SamsungPlatformEngine" -StartupType "disabled"
	:: powershell Set-Service -Name "SamsungSecuritySupportService" -StartupType "disabled"
	:: powershell Set-Service -Name "SamsungSystemSupportService" -StartupType "disabled"
	CLS
)

:: criação de usuários Super e Suporte
if '%remover_privilegio_adm%'=='sim' (
echo Criando^ usuários^ administradores...
net user super /add > nul 2>>errorlog.txt
net user suporte /add > nul 2>>errorlog.txt
:: definição de senhas de usuários Super e Suporte
net user super %senha_super% > nul 2>>errorlog.txt
net user suporte %senha_suporte% > nul 2>>errorlog.txt
:: remover expiração de senha dos usuários - usuários criados pelo Rufus e pelo comando acima têm uma senha com prazo e após esse prazo o sistema pede por uma nova senha que seria escolhida pelo usuário
wmic UserAccount where Name='super' set PasswordExpires=false > nul 2>>errorlog.txt
wmic UserAccount where Name='suporte' set PasswordExpires=false > nul 2>>errorlog.txt
:: conceder/remover privilégios de admin dos usuários
net localgroup Administradores super /add > nul 2>>errorlog.txt
net localgroup Administradores suporte /add > nul 2>>errorlog.txt
net localgroup Administradores "%username%" /delete > nul 2>>errorlog.txt
:: usuário padrão some se não estiver no grupo "Usuários"
ver > nul
net localgroup Usuários | find "%username%"
if not '%errorlevel%' == '0' (
	net localgroup Usuários "%username%" /add > nul 2>>errorlog.txt
)
)

if not '%senha'=='' (
net user "%username%" %senha% > nul 2>>errorlog.txt
)

:: remover expiração de senha dos usuários - usuários criados pelo Rufus e pelo comando "net user" têm uma senha com prazo e após esse prazo o sistema pede por uma nova senha que seria escolhida pelo usuário
wmic UserAccount where Name="%username%" set PasswordExpires=false > nul 2>>errorlog.txt

:: o script pausa antes de fechar o cmd e deleta o arquivo de configuração para que usuários não tenham acesso às senhas escritas nele
del "%~dp0config\config.txt"
del "%~dp0config\MR"
schtasks /delete /tn "WindowsSTDSetup"

rundll32.exe user32.dll,LockWorkStation > nul 2>>errorlog.txt

if exist "%~dp0fix-setup.cmd" (
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::^ ERROS^ forAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
echo ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::^ ERROS^ forAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
echo ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::^ ERROS^ forAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
echo ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
)
pause
exit