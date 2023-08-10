:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::           SCRIPT DE CONFIGURAÇÃO DO WINDOWS                 ::
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
:: Definição de variáveis a partir do arquivo config.txt
FOR /F "usebackq tokens=*" %%V in ( `type "%~dp0config\config.txt" ^| findstr /V "^::"` ) DO ( set %%V )

:: verificar se winget está instalado e, se não, instalar winget e relançar o script:
ver > nul
where winget
CLS
IF '%ERRORLEVEL%' == '1' (
	
	systeminfo | find "Windows 11"
	IF NOT '!ERRORLEVEL!' == '0' (
		ECHO Foi^ detectado^ que^ o^ sistema^ instalado^ não^ é^ Windows^ 11.^ Instale^ manualmente^ o^ 'Instalador^ de^ Aplicativos'^ disponível^ na^ Microsoft^ Store^ e^ execute^ esse^ script^ novamente.
		pause
		exit
	)
	
	powershell Invoke-WebRequest -Uri %winget_url% -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
	powershell Add-AppXPackage -Path .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
	%0
	exit
)

:: Verificação do nome do computador
@echo off
ver > nul
IF %renomear_maquina%==sempre (
	IF NOT EXIST .\config\MR (
		echo Nome^ do^ computador^ não^ está^ de^ acordo^ com^ o^ padrão^ requerido.
		"%~dp0Scripts\renamePC.cmd" %padrao_nome_maquina%
		echo Máquina^ renomeada > .\config\MR
		echo Esse^ script^ será^ interrompido^ e^ a^ máquina^ será^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ próxima^ sessão^ após^ confirmar^ que^ o^ nome^ do^ computador^ está^ no^ padrão^ requerido
		shutdown /r /t 30
		pause
		exit
	)
) ELSE IF %renomear_maquina%==verificar (
	echo %computername% | findstr "%padrao_nome_maquina%" > nul
	IF NOT '!ERRORLEVEL!' == '0' (
		echo Nome^ do^ computador^ não^ está^ de^ acordo^ com^ o^ padrão^ requerido.
		"%~dp0Scripts\renamePC.cmd" %padrao_nome_maquina%
		echo Máquina^ renomeada > .\config\MR
		echo Esse^ script^ será^ interrompido^ e^ a^ máquina^ será^ reiniciada^ em^ 30^ segundos.^ Execute^ esse^ script^ novamente^ na^ próxima^ sessão^ após^ confirmar^ que^ o^ nome^ do^ computador^ está^ no^ padrão^ requerido
		shutdown /r /t 30
		pause
		exit
	)
) ELSE IF %renomear_maquina%==ignorar (
	echo Ignorando^ verificação^ de^ nome^ de^ máquina.
) ELSE (
	ECHO Parâmetro^ "renomear_maquina"^ não^ reconhecido.
	pause
	exit
)

FOR %%F IN ( "%~dp0Files\*.exe" ) DO ( "%%F" )
FOR %%F IN ( "%~dp0Files\*.msi" ) DO ( "%%F" )

@echo on
:: instalação de programas via winget | o parâmetro --force é necessário porque às vezes os desenvolvedores não atualizam a hash de verificação do instalador. Mesmo com o parâmetro --force, ainda pode ser necessário instalar algo manualmente nesses casos
ver > nul
FOR /F "usebackq tokens=*" %%P in ( `type "%~dp0config\winget.txt" ^| findstr /V "^::"` ) DO (
	winget list | find /i "%%P "
	IF '!errorlevel!' == '1' ( 
		winget install %%P
	)
	IF NOT '!errorlevel!' == '0' ( echo winget^ install^ --force^ %%P >> fix-setup.cmd )
)

:: copiar atalhos de URL para a área de trabalho e para o Menu Iniciar
FOR %%F IN ( "%~dp0Files\*.url" ) DO ( xcopy /Y "%%F" "%appdata%\Microsoft\Windows\Start Menu\Programs\" )
FOR %%F IN ( "%~dp0Files\*.url" ) DO ( xcopy /Y "%%F" "%userprofile%\Desktop\" )

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
@echo off
ver > nul
:: a linha acima serve apenas para resetar o valor de %errorlevel% para 0, caso algum dos comandos anteriores tenha retornado código de erro - set ERRORLEVEL=0 não pode ser usado porque o valor se torna persistente e não se altera com erros seguintes
wmic computersystem get model | findstr "550X" > nul
IF '%ERRORLEVEL%' == '0' (
	powershell Set-Service -Name "SamsungPlatformEngine" -StartupType "disabled"
	powershell Set-Service -Name "SamsungSecuritySupportService" -StartupType "disabled"
	powershell Set-Service -Name "SamsungSystemSupportService" -StartupType "disabled"
)
@echo on

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
rundll32.exe user32.dll,LockWorkStation
IF EXIST fix-setup.cmd (
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
echo ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
echo ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo ::^ ERROS^ FORAM^ ENCONTRADOS^ DURANTE^ A^ INSTALAÇÃO^ DE^ PROGRAMAS^ VIA^ WINGET.
echo ::^ Para^ consertá-los^ execute,^ sem^ privilégio^ de^ administrador^ o^ script^ fix-setup.cmd
echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
)
pause
exit