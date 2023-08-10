:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::           SCRIPT DE CONFIGURAÇÃO DO WINDOWS                 ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Automaticamente checar e obter privilégios de Admin ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO off
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
if '%1'=='ELEV' (ECHO ELEV & shift /1 & goto gotPrivileges)

ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

::::::::::::::::::::::::::::::
::     COMEÇO DO SCRIPT     ::
::::::::::::::::::::::::::::::

:: Delayed Expansion will cause variables to be expanded at execution time rather than at parse time
setlocal EnableDelayedExpansion
chcp 1252 > nul
set first_winget_install=done
set winget_msixbundle=Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
set ui_xaml_appx=Microsoft.UI.Xaml.2.7.x64.appx
set vclib_appx=Microsoft.VCLibs.x64.14.00.Desktop.appx

:: Definição de variáveis a partir do arquivo config.txt
FOR /F "usebackq tokens=*" %%V in ( `type "%~dp0config\config.txt" ^| findstr /V "^::"` ) DO ( set %%V )

:: verificar se winget está instalado e, se não, instalar winget e relançar o script:
ver > nul
where winget
CLS
IF '%ERRORLEVEL%' == '1' (
	
	systeminfo | find "Windows 10"
	IF '!ERRORLEVEL!' == '0' (
		IF NOT EXIST .\Files\%ui_xaml_appx% ( 
			ECHO Baixando^ Microsoft.UI.Xaml...
			powershell Invoke-WebRequest -Uri %ms_ui_xaml_url% -OutFile .\Files\%ui_xaml_appx%
		)
		IF NOT EXIST .\Files\%vclib_appx% ( 
			ECHO Baixando^ Microsoft.VCLibs...
			powershell Invoke-WebRequest -Uri %ms_vclib_url% -OutFile .\Files\%vclib_appx%
		)
		powershell Add-AppXPackage -Path .\Files\%ui_xaml_appx%
		powershell Add-AppXPackage -Path .\Files\%vclib_appx%
	)
	CLS
	IF NOT EXIST .\Files\%winget_msixbundle% ( 
		ECHO Baixando^ o^ Microsoft.DesktopAppInstaller^ winget...
		powershell Invoke-WebRequest -Uri %winget_url% -OutFile .\Files\%winget_msixbundle%
	)
	CLS
	ECHO Instalando^ o^ winget...
	powershell Add-AppXPackage -Path .\Files\%winget_msixbundle%
	%0
	exit
)

:: Verificação do nome do computador
ver > nul
IF %renomear_maquina%==sempre (
	IF NOT EXIST "%~dp0config\MR" (
		ECHO Nome^ do^ computador^ não^ está^ de^ acordo^ com^ o^ padrão^ requerido.
		"%~dp0Scripts\renamePC.cmd" %padrao_nome_maquina%
		ECHO Máquina^ renomeada > "%~dp0config\MR"
		ECHO Esse^ script^ será^ interrompido^ e^ a^ máquina^ será^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ próxima^ sessão^ após^ confirmar^ que^ o^ nome^ do^ computador^ está^ no^ padrão^ requerido
		shutdown /r /t 30
		pause
		exit
	)
) ELSE IF %renomear_maquina%==verificar (
	ECHO %computername% | findstr "%padrao_nome_maquina%" > nul
	IF NOT '!ERRORLEVEL!' == '0' (
		ECHO Nome^ do^ computador^ não^ está^ de^ acordo^ com^ o^ padrão^ requerido.
		"%~dp0Scripts\renamePC.cmd" %padrao_nome_maquina%
		ECHO Esse^ script^ será^ interrompido^ e^ a^ máquina^ será^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ próxima^ sessão^ após^ confirmar^ que^ o^ nome^ do^ computador^ está^ no^ padrão^ requerido
		shutdown /r /t 30
		pause
		exit
	)
) ELSE IF %renomear_maquina%==ignorar (
	ECHO Ignorando^ verificação^ de^ nome^ de^ máquina.
) ELSE (
	ECHO Parâmetro^ "renomear_maquina"^ não^ reconhecido.
	pause
	exit
)

FOR %%F IN ( "%~dp0Files\*.exe" ) DO ( "%%F" )
FOR %%F IN ( "%~dp0Files\*.msi" ) DO ( "%%F" )

:: instalação de programas via winget | o parâmetro --force é necessário porque às vezes os desenvolvedores não atualizam a hash de verificação do instalador. Mesmo com o parâmetro --force, ainda pode ser necessário instalar algo manualmente nesses casos
winget list --accept-source-agreements > nul
ver > nul
ECHO Instalando^ programas^ via^ winget...
FOR /F "usebackq tokens=*" %%P in ( `type "%~dp0config\winget.txt" ^| findstr /V "^::"` ) DO (
	winget list | find /i "%%P "
	IF '!errorlevel!' == '1' ( 
		ECHO Instalando^ %%P...
		IF '%first_winget_install%' == 'done' ( 
		winget install %%P 
		) ELSE ( 
			winget install --accept-source-agreements %%P
			set first_winget_install=done
		)
	) ELSE (
		ECHO %%P^ já está instalado!
	)
	IF NOT '!errorlevel!' == '0' ( 
		ECHO Falha^ na^ instalação^ de^ %%P!
		ECHO winget^ install^ --force^ %%P >> "%~dp0fix-setup.cmd" 
	)
	CLS
)

:: copiar atalhos de URL para a área de trabalho e para o Menu Iniciar
FOR %%F IN ( "%~dp0Files\*.url" ) DO ( xcopy /Y "%%F" "%appdata%\Microsoft\Windows\Start Menu\Programs\" > nul )
FOR %%F IN ( "%~dp0Files\*.url" ) DO ( xcopy /Y "%%F" "%userprofile%\Desktop\" > nul )

:: PERMITIR EXECUÇÃO DOS SCRIPTS DE POWERSHELL
powershell Set-ExecutionPolicy unrestricted

:: Aplicar papel de parede
powershell -File "%~dp0Scripts\Set-Wallpaper.ps1" %wallpaperPath%

:: Aplicar tela de bloqueio
powershell -File "%~dp0Scripts\Set-Lockscreen.ps1" %lockscreenPath%

:: RESTRINGIR EXECUÇÃO DE SCRIPTS DE POWERSHELL
powershell Set-ExecutionPolicy restricted

:: desabilitar OneDrive
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v OneDrive /t REG_SZ /d NoOneDrive
netsh advfirewall firewall add rule name="BlockOneDrive0" action=block dir=out program="C:\ProgramFiles (x86)\Microsoft OneDrive\OneDrive.exe"

:: desabilitar Teams
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /f /v com.squirrel.Teams.Teams /t REG_SZ /d NoTeamsCurrentUser
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /f /v TeamsMachineInstaller /t REG_SZ /d NoTeamsLocalMachine

:: desabilitar serviço de hostpot
sc config icssvc start=disabled

:: desabilitar programas da Samsung em modelos 550X*
ver > nul
wmic computersystem get model | findstr "550X" > nul
IF '%ERRORLEVEL%' == '0' (
	ECHO Desabilitando^ serviços^ da^ Samsung...
	sc config SamsungPlatformEngine start=disabled
	sc config SamsungSecuritySupportService start=disabled
	sc config SamsungSystemSupportService start=disabled
	:: powershell Set-Service -Name "SamsungPlatformEngine" -StartupType "disabled"
	:: powershell Set-Service -Name "SamsungSecuritySupportService" -StartupType "disabled"
	:: powershell Set-Service -Name "SamsungSystemSupportService" -StartupType "disabled"
	CLS
)
@ECHO on

:: criação de usuários Super e Suporte
net user super /add
net user suporte /add

:: definição de senhas de usuários Super e Suporte
net user super %senha_super%
net user suporte %senha_suporte%

:: remover expiração de senha dos usuários - usuários criados pelo Rufus e pelo comando acima têm uma senha com prazo e após esse prazo o sistema pede por uma nova senha que seria escolhida pelo usuário
wmic UserAccount where Name='super' set PasswordExpires=false
wmic UserAccount where Name='suporte' set PasswordExpires=false
wmic UserAccount where Name=%usuario% set PasswordExpires=false

:: conceder/remover privilégios de admin dos usuários
net localgroup Administradores super /add
net localgroup Administradores suporte /add
net localgroup Administradores %usuario% /delete

:: o script pausa antes de fechar o cmd e deleta o arquivo de configuração para que usuários não tenham acesso às senhas escritas nele
del "%~dp0config\config.txt"
del "%~dp0config\MR"

rundll32.exe user32.dll,LockWorkStation

IF EXIST "%~dp0fix-setup.cmd" (
ECHO :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
ECHO ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
ECHO ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
ECHO :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
ECHO ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
ECHO ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
ECHO :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
ECHO ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
ECHO ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
ECHO :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
)
pause
exit
