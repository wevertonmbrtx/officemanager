@setlocal DisableDelayedExpansion
@set uivr=v2
@echo off
chcp 850 >nul
mode con: cols=70 lines=7

@REM Office Manager - Script de gerenciamento do Microsoft 365 Apps
@REM Esse script Ç fornecido "no estado em que se encontra", sem garantias de qualquer tipo. Use por sua conta e risco.
@REM Desenvolvido por wevertonmbrtx (Code_4X)
@REM https://github.com/wevertonmbrtx/officemanager/blob/main/omanager.cmd

cls

:init
    set uac=-elevated
    for %%# in (All,C2R,UWP,M16,M15,M14,M12,M11) do set _u%%#=0
    set Unattend=0
    set qerel=
    set _elev=
    set _args=
    set _args=%*
    if not defined _args goto :noProgArgs
    if "%~1"=="" set "_args=" & goto :noProgArgs
    set "_args="
    for %%# in (%*) do (
        if /i "%%~#"=="%uac%"  set _elev=1
        if /i "%%~#"=="-wow"   set _rel1=1
        if /i "%%~#"=="-arm"   set _rel2=1
        if /i "%%~#"=="-qedit" set qerel=1
        if /i "%%~#"=="/A"     set _uAll=1 & set Unattend=1
        if /i "%%~#"=="/C"     set _uC2R=1 & set Unattend=1
        if /i "%%~#"=="/P"     set _uUWP=1 & set Unattend=1
        if /i "%%~#"=="/M6"    set _uM16=1 & set Unattend=1
        if /i "%%~#"=="/M5"    set _uM15=1 & set Unattend=1
        if /i "%%~#"=="/M4"    set _uM14=1 & set Unattend=1
        if /i "%%~#"=="/M2"    set _uM12=1 & set Unattend=1
        if /i "%%~#"=="/M1"    set _uM11=1 & set Unattend=1
    )

    goto :noProgArgs


:ensurePrereqs
    set "_hasNet=0"
    reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release >nul 2>&1 && set "_hasNet=1"
    set "_psver="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" /v PowerShellVersion 2^>nul ^| find /i "PowerShellVersion"') do set "_psver=%%v"

    cls
    echo.
    if "%_hasNet%"=="1" call :L %c7%   "   .NET Framework 4.5+: " %cA% "OK"
    if "%_hasNet%"=="0" call :L %c7%   "   .NET Framework 4.5+: " %cC% "AUSENTE"
    if defined _psver call :L %c7%     "      PowerShell / WMF: " %cA% "OK (" %cE% "v%_psver%" %cA% ")"
    if not defined _psver call :L %c7% "   PowerShell 3+ / WMF: " %cC% "AUSENTE"
    echo.

    if "%_leg%"=="1" (
        call :L %c6% "   Windows legado: seguindo sem alteracoes."
        timeout /t 2 /nobreak >nul
        cls
        goto :eof
    )
    if defined _psver (
        call :L %cA% "   Tudo certo para prosseguir."
        timeout /t 2 /nobreak >nul
        cls
        goto :eof
    )

    call :L %cE% "   PowerShell 3+ ausente. Preparando pre-requisitos (Windows 7+)..."
    timeout /t 1 /nobreak >nul
    call :enableTls
    call :installDotNet45
    call :installWMF
    goto :setupReboot


:enableTls
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v SecureProtocols /t REG_DWORD /d 0x00000A80 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DefaultSecureProtocols /t REG_DWORD /d 0x00000A80 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DefaultSecureProtocols /t REG_DWORD /d 0x00000A80 /f >nul 2>&1
    goto :eof


:installDotNet45
    reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release >nul 2>&1 && goto :eof
    
    cls
    echo.
    echo  Baixando .NET Framework 4.5 (~65 MB)...
    
    set "_dnFile=%TEMP%\dotnet45_setup.exe"
    call :download "https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe" "%_dnFile%"
    
    if not exist "%_dnFile%" (
        set "msg=ERRO: falha ao baixar o .NET 4.5." & goto :prereqFail
    )
    
    cls
    echo.
    echo  Instalando .NET Framework 4.5 (pode levar v†rios minutos)...
    
    "%_dnFile%" /q /norestart
    set "_ec=%errorlevel%"
    del /f /q "%_dnFile%" >nul 2>&1
    if "%_ec%"=="0" goto :eof
    if "%_ec%"=="3010" goto :setupReboot
    if "%_ec%"=="1641" goto :setupReboot

    set "msg=ERRO: falha na instalaá∆o do .NET 4.5 (c¢digo %_ec%)."
    
    goto :prereqFail


:installWMF
    set "_a=x86"
    if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "_a=x64"
    if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "_a=x64"
    set "_wmfFile=%TEMP%\wmf50_%_a%.msu"

    if /i "%_a%"=="x64" (
        set "_wmfUrl=https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win7AndW2K8R2-KB3134760-x64.msu"
    ) else (
        set "_wmfUrl=https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win7-KB3134760-x86.msu"
    )
    
    cls
    echo.
    echo  Baixando Windows Management Framework 5.0 (%_a%)...
    call :download "%_wmfUrl%" "%_wmfFile%"
    if not exist "%_wmfFile%" ( set "msg=ERRO: falha ao baixar o WMF 5.0." & goto :prereqFail )
    
    cls
    echo.
    echo  Instalando Windows Management Framework 5.0...
    
    wusa "%_wmfFile%" /quiet /norestart
    set "_ec=%errorlevel%"
    del /f /q "%_wmfFile%" >nul 2>&1
    
    if "%_ec%"=="2359302" goto :setupReboot
    if "%_ec%"=="0"       goto :setupReboot
    if "%_ec%"=="3010"    goto :setupReboot
    
    set "msg=ERRO: falha na instalaá∆o do WMF 5.0 (c¢digo %_ec%). Confirme que Ç Windows 7 SP1."
    goto :prereqFail


:download
    del /f /q %2 >nul 2>&1
    bitsadmin /transfer dl /download /priority foreground "%~1" "%~2" >nul 2>&1
    
    if exist %2 goto :eof
    where curl >nul 2>&1 && curl -L -s -o "%~2" "%~1" >nul 2>&1
    
    if exist %2 goto :eof
    %_psc% "[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor 3072; (New-Object Net.WebClient).DownloadFile(%1,%2)" >nul 2>&1
    
    goto :eof


:setupReboot
    mode con: cols=70 lines=7
    
    cls & echo.
    echo  PrÇ-requisitos configurados.
    echo  REINICIE o computador e execute este script novamente
    echo  para concluir.
    echo. & timeout /t 1 /nobreak > NUL
    exit


:prereqFail
    mode con: cols=70 lines=12
    
    cls & echo.
    echo  %msg%
    echo.
    echo  O TLS 1.2 foi configurado. REINICIE o computador e rode o
    echo  script novamente - o download autom†tico pode funcionar
    echo  ap¢s o rein°cio.
    echo.
    echo  Se persistir, instale manualmente e reinicie:
    echo    .NET 4.5: https://dotnet.microsoft.com/download/dotnet-framework/net452
    echo     WMF 5.1: https://www.microsoft.com/download/details.aspx?id=54616
    echo. & timeout /t 2 /nobreak > NUL
    exit


:noProgArgs
    set "_cmdf=%~f0"
    if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
        setlocal EnableDelayedExpansion
        start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" /UNINSTALL -wow %*"
        exit /b
    )

    if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
        setlocal EnableDelayedExpansion
        start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" /UNINSTALL -arm %*"
        exit /b
    )

    set "SysPath=%SystemRoot%\System32"
    set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
    if exist "%SystemRoot%\Sysnative\reg.exe" (
        set "SysPath=%SystemRoot%\Sysnative"
        set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
    )
    set "_psc=powershell -nop -c"
    set "_err===== ERRO ===="
    set "_ln============================================================="
    set "_sr=************************************************************"

    set _leg=0
    ver|findstr /C:" 5." >nul && set _leg=1
    
    set winmaj=0
    for /f "tokens=2 delims=[]" %%G in ( 'ver' ) do for /f "tokens=2,3 delims=. " %%H in ( "%%~G" ) do set "winmaj=%%H"
    if %winmaj% lss 6 set _leg=1
    
    set _wxp=0
    if %_leg% equ 1 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber |findstr /C:"2600" >nul && set _wxp=1
    
    set _sk=2
    if %_wxp% equ 1 set _sk=4

    set winbuild=1
    if %_leg% equ 0 for /f "tokens=6 delims=[]. " %%# in ( 'ver' ) do set winbuild=%%#
    if %_leg% equ 1 for /f "skip=%_sk% tokens=1,2,3 delims=. " %%i in (
        'reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLab 2^>nul' 
    ) do (
        if /i "%%i"=="BuildLab" if not "%%~k"=="" set "winbuild=%%~k"
    )

    set _cwmi=0
    for %%# in ( wmic.exe ) do @if not "%%~$PATH:#"=="" (
        wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
    )
    
    set _pwsh=1
    for %%# in ( powershell.exe ) do @if "%%~$PATH:#"=="" set _pwsh=0
    if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set _pwsh=0

    if %_leg% equ 1 goto :passed

    1>nul 2>nul reg.exe query HKU\S-1-5-19 && (
        goto :passed
    ) || (
        if defined _elev goto :E_Admin
    )

    set _PSarg="""%~f0""" %* %uac%
    set _PSarg=%_PSarg:'=''%

    ( 1>nul 2>nul cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %* %uac% ) && (
        exit /b
    ) || (
        call setlocal EnableDelayedExpansion
        1>nul 2>nul %SysPath%\WindowsPowerShell\v1.0\%_psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && (
            exit /b
        ) || (
            goto :E_Admin
        )
    )


:passed
    set _WSH=1
    reg.exe query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
    reg.exe query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
    if %_WSH% equ 0 goto :E_WSH
    if not exist "%SysPath%\vbscript.dll" goto :E_VBS
    set WMI_VBS=0
    if %_cwmi% equ 0 set WMI_VBS=1
    if %_leg% equ 1 set WMI_VBS=1
    set "_csq=cscript.exe //NoLogo //Job:WmiQuery "%~nx0?.wsf""
    set "_csm=cscript.exe //NoLogo //Job:WmiMethod "%~nx0?.wsf""

    if %winbuild% LSS 10586 (
    reg.exe query HKCU\Console /v QuickEdit 2>nul | find /i "0x0" >nul && set qerel=1
    )
    if defined qerel goto :skipQE
    if %_pwsh% equ 0 goto :skipQE
    if %winbuild% GEQ 17763 (
        set "launchcmd=start conhost.exe %_psc%"
    ) else (
        set "launchcmd=%_psc%"
    )
    set _PSarg="""%~f0""" %* -qedit
    set _PSarg=%_PSarg:'=''%
    set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
    set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
    set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
    set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"
    if %_uAll% equ 1 set "d5=$B=$Host.UI.RawUI.BufferSize;$B.Height=3000;$Host.UI.RawUI.BufferSize=$B;"
    setlocal EnableDelayedExpansion
    %launchcmd% "!d1! !d2! !d3! !d4! !d5! & cmd.exe '/c' '!_PSarg!'" &exit /b
    exit /b


:skipQE
    set "_oApp=0ff1ce15-a989-479d-af46-f275c6370663"
    set "_oA14=59a52881-a989-479d-af46-f275c6370663"
    set "OPPk=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
    set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
    set "_para=ALL /OSE /NOCANCEL /FORCE /ENDCURRENTINSTALLS /DELETEUSERSETTINGS /CLEARADDINREG /REMOVELYNC"
    if /i "%PROCESSOR_ARCHITECTURE%"=="amd64" set "xBit=x64" & set "xOS=x64"
    if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBit=x86" & set "xOS=A64"
    if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBit=x86" & set "xOS=x86"
    if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBit=x64" & set "xOS=x64"
    if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBit=x86" & set "xOS=A64"
    set "_Common=%CommonProgramFiles%"
    if defined PROCESSOR_ARCHITEW6432 set "_Common=%CommonProgramW6432%"
    
    set "_file=%_Common%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
    set "_fil2=%CommonProgramFiles(x86)%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
    set "_work=%~dp0bin"
    set "_Local=%LocalAppData%"
    set "_cscript=cscript //Nologo"
    set kO16=HKCU\SOFTWARE\Microsoft\Office\16.0
    setlocal EnableDelayedExpansion
    if not exist "!_work!" md "!_work!"
    pushd "!_work!"

    set "_Nul1=1>nul"
    set "_Nul2=2>nul"
    set "_Nul6=2^>nul"
    set "_Nul3=1>nul 2>nul"

    for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

    ::  "VR="BG;FGm""      COR            BACKGROUND FOREGROUND HEX
    set "c0="40;30m"" & :: Preto          40         30         0
    set "c1="40;34m"" & :: Azul           44         34         1
    set "c2="40;32m"" & :: Verde          42         32         2
    set "c3="40;36m"" & :: Ciano          46         36         3
    set "c4="40;31m"" & :: Vermelho       41         31         4
    set "c5="40;35m"" & :: Magenta        45         35         5
    set "c6="40;33m"" & :: Amarelo        43         33         6
    set "c7="40;37m"" & :: Branco         47         37         7
    set "c8="40;90m"" & :: Cinza Escuro   100        90         8
    set "c9="40;94m"" & :: Azul Claro     104        94         9
    set "cA="40;92m"" & :: Verde Claro    102        92         A
    set "cB="40;96m"" & :: Ciano Claro    106        96         B
    set "cC="40;91m"" & :: Vermelho Claro 101        91         C
    set "cD="40;95m"" & :: Magenta Claro  105        95         D
    set "cE="40;93m"" & :: Amarelo Claro  103        93         E
    set "cF="40;97m"" & :: Branco Claro   107        97         F


    call :ensurePrereqs


:verifyExistingInstallation
    %_Nul3% call :CloseC2R
    set "WRD=%PROGRAMFILES%\Microsoft Office\root\Office16\WINWORD.EXE"
    set "EXC=%PROGRAMFILES%\Microsoft Office\root\Office16\EXCEL.EXE"
    set "PPT=%PROGRAMFILES%\Microsoft Office\root\Office16\POWERPNT.EXE"

    if exist "%WRD%" ( if exist "%EXC%" ( if exist "%PPT%" GOTO :changeInstallation ) )

    GOTO :setUpConfiguration


:changeInstallation
    mode con: cols=70 lines=7
    title Instalaá∆o existente detectada 

    cls & echo.
    call :L %cA% "   Uma instalaá∆o existente do Office foi detectada."
    echo.
    call :L %cC% "   [D]" %c7% " Desinstalar, " 
    call :L %cB% "   [A]" %c7% " Ativar, " 
    call :L %cE% "   [C]" %c7% " Continuar"
    choice /C DAC /N 
    
    if %errorlevel%==3 goto :setUpConfiguration
    if %errorlevel%==2 goto :activate
    if %errorlevel%==1 goto :uninstallOffice


:setUpConfiguration
    cd /d "%~dp0bin"
    title Configurando instalaá∆o do Office

    if exist "Configuration.xml" (
        cls & echo.
        call :L %c7% "                   Arquivo de configuraá∆o " %cA% "encontrado." 
        timeout /t 1 /nobreak > NUL
        cls
        goto :setUpInstaller
    )

    cls & echo.
    call :L %cA% "   [1]" %c7% " Selecione a arquitetura do Office a ser instalada:"
    if %xBit%==x64 (
        call :L %c7% "      1 - 64-bits" %cA% " Recomendado"
        echo       2 - 32-bits 
    ) else (
        echo       1 - 64-bits
        call :L %c7% "      2 - 32-bits" %cA% " Recomendado"
    )
    choice /c 12 /n /m "> "
    if %errorlevel%==1 set "ARCH=64"
    if %errorlevel%==2 set "ARCH=32"

    cls & echo.
    call :L %cA% "   [2]" %c7% " Selecione o canal de atualizaá∆o:"
    echo       1 - Current (Mensal)
    echo       2 - MonthlyEnterprise (Mensal Empresarial)
    echo       3 - SemiAnnual (Semestral)
    choice /c 123 /n /m "> "
    if %errorlevel%==1 set "CHANNEL=Current"
    if %errorlevel%==2 set "CHANNEL=MonthlyEnterprise"
    if %errorlevel%==3 set "CHANNEL=SemiAnnual"

    cls & echo.
    call :L %cA% "    [3]" %c7% " Selecione o produto:"
    echo       1 - Microsoft 365 (Sem Teams)
    echo       2 - Microsoft 365 (Com Teams)
    choice /c 12 /n /m "> "
    if %errorlevel%==1 set "PRODUCT=O365ProPlusEEANoTeamsRetail"
    if %errorlevel%==2 set "PRODUCT=O365ProPlusRetail"

    cls & echo.
    call :L %cA% "   [4]" %c7% " Selecione o idioma:"
    echo       1 - Portuguàs (Brasil) [pt-BR]
    echo       2 - Inglàs (EUA) [en-US]
    echo       3 - Personalizado (ex.: en-GB, es-ES, etc.)
    choice /c 123 /n /m "> "
    if %errorlevel%==1 set "LANG=pt-BR"
    if %errorlevel%==2 set "LANG=en-US"
    if %errorlevel%==3 (
        cls & echo.
        set /p "LANG=   Digite o idioma personalizado: "
    )

    call :setupAsk & set "EXC_ACCS=1" & choice /c EM /n /m "> Access: "
    if %errorlevel%==2 set "EXC_ACCS=0"

    @REM call :setupAsk & set "EXC_EXCL=1" & choice /c EM /n /m "> Excel: "
    @REM if %errorlevel%==2 set "EXC_EXCL=0"

    call :setupAsk & set "EXC_ONED=1" & choice /c EM /n /m "> OneDrive: "
    if %errorlevel%==2 set "EXC_ONED=0"

    call :setupAsk & set "EXC_OUTL=1" & choice /c EM /n /m "> Outlook: "
    if %errorlevel%==2 set "EXC_OUTL=0"

    call :setupAsk & set "EXC_NOUT=1" & choice /c EM /n /m "> Novo Outlook: "
    if %errorlevel%==2 set "EXC_NOUT=0"

    @REM call :setupAsk & set "EXC_POWP=1" & choice /c EM /n /m "> PowerPoint: "
    @REM if %errorlevel%==2 set "EXC_POWP=0"

    call :setupAsk & set "EXC_PUBL=1" & choice /c EM /n /m "> Publisher: "
    if %errorlevel%==2 set "EXC_PUBL=0"

    call :setupAsk & set "EXC_NOTE=1" & choice /c EM /n /m "> OneNote: "
    if %errorlevel%==2 set "EXC_NOTE=0"

    call :setupAsk & set "EXC_SKYP=1" & choice /c EM /n /m "> Skype for Business: "
    if %errorlevel%==2 set "EXC_SKYP=0"

    @REM call :setupAsk & set "EXC_WORD=1" & choice /c EM /n /m "> Word: "
    @REM if %errorlevel%==2 set "EXC_WORD=0"

    call :setupAsk & set "EXC_GROO=1" & choice /c EM /n /m "> OneDrive for Business: "
    if %errorlevel%==2 set "EXC_GROO=0"

    call :setupAsk & set "EXC_BING=1" & choice /c EM /n /m "> Bing (Pesquisa no Bing): "
    if %errorlevel%==2 set "EXC_BING=0"

    call :setupAsk & set "EXC_TEAM=0"
    if not "%PRODUCT%"=="O365ProPlusRetail" goto :genSetUpXML
    set "EXC_TEAM=1"
    choice /c EM /n /m "> Teams: "
    if %errorlevel%==2 set "EXC_TEAM=0"
    
    :genSetUpXML
        cls & echo.
        echo.
        call :L %c7% "                   Gerando arquivo de configuraá∆o..." 

        (
            echo ^<Configuration^>
            echo   ^<Add OfficeClientEdition="%ARCH%" Channel="%CHANNEL%"^>
            echo     ^<Product ID="%PRODUCT%"^>
            echo       ^<Language ID="%LANG%" /^>
            
            if "%EXC_ACCS%"=="1" echo       ^<ExcludeApp ID="Access" /^>
            @REM if "%EXC_EXCL%"=="1" echo       ^<ExcludeApp ID="Excel" /^>
            if "%EXC_ONED%"=="1" echo       ^<ExcludeApp ID="OneDrive" /^>
            if "%EXC_OUTL%"=="1" echo       ^<ExcludeApp ID="Outlook" /^>
            if "%EXC_NOUT%"=="1" echo       ^<ExcludeApp ID="OutlookForWindows" /^>
            if "%EXC_PUBL%"=="1" echo       ^<ExcludeApp ID="Publisher" /^>
            @REM if "%EXC_POWP%"=="1" echo       ^<ExcludeApp ID="PowerPoint" /^> 
            if "%EXC_NOTE%"=="1" echo       ^<ExcludeApp ID="OneNote" /^>
            if "%EXC_SKYP%"=="1" echo       ^<ExcludeApp ID="Lync" /^>
            if "%EXC_GROO%"=="1" echo       ^<ExcludeApp ID="Groove" /^>
            @REM if "%EXC_WORD%"=="1" echo       ^<ExcludeApp ID="Word" /^>
            if "%EXC_BING%"=="1" echo       ^<ExcludeApp ID="Bing" /^>
            if "%EXC_TEAM%"=="1" echo       ^<ExcludeApp ID="Teams" /^>
            
            echo     ^</Product^>
            echo   ^</Add^>
            echo   ^<Updates Enabled="TRUE" /^>
            echo   ^<RemoveMSI /^>
            echo   ^<Display Level="Full" AcceptEULA="TRUE" /^>
            echo ^</Configuration^>
        ) > Configuration.xml

        cls & echo.
        echo.
        call :L %c7% "                   Arquivo de configuraá∆o criado."
        timeout /t 2 /nobreak > NUL
        

    goto :setUpInstaller


:setupAsk
    cls
    echo.
    call :L %c7% "   " %cA% "[5]" %c7% " Selecione apps para" %c4% " EXCLUIR" %c7% ":"
    call :L %c7% "      " "41;33m" "[E]" %c7% " - Excluir"
    call :L %c7% "      " "42;96m" "[M]" %c7% " - Manter"
    echo.
    goto :eof


:setUpInstaller
    title Verificando arquivo existente...
    del /S /Q "%PROGRAMFILES%\Common Files\microsoft shared\ClickToRun" 2> NUL

    cls
    echo.
    echo.
    echo.
    call :L %c7% "                   Verificando arquivo existente..."
    timeout /t 1 > NUL
    
    cls
    dir setup.exe > NUL 2>NUL
    if %ERRORLEVEL%==0 (
        echo.
        echo.
        echo.
        call :L %c7% "               Instalador local" %c2% " encontrado." %c6% " Atualizando..."
        echo.
        echo.
        del /F /Q setup.exe > NUL
        goto :downloadSetup
    ) else (
        echo.
        echo.
        echo.
        call :L %c7% "                   Baixando o instalador do Office..."
        goto :downloadSetup
    )

:downloadSetup
    TITLE Conectando...
    CLS
    echo.
    echo.
    echo. 
    call :L %c8% "                Conectando ao servidor da MICROSOFT..."
    echo.
    echo. & timeout /t 2 > NUL
    ping officecdn.microsoft.com | find "TTL=" > NUL
    IF %ERRORLEVEL%==0 (  
        CLS
        echo.
        echo.
        echo.
        call :L %c2% "                                Conectado."
        echo.
        echo. & timeout /t 1 > NUL
        call :download "https://officecdn.microsoft.com/pr/wsus/setup.exe" "%~dp0bin\setup.exe"
        if not exist "%~dp0bin\setup.exe" goto :downloadFail
        for %%S in ("%~dp0bin\setup.exe") do if %%~zS LSS 1000000 goto :downloadFail
        CLS
        echo.
        echo.
        echo.
        call :L %cA% "                    Download finalizado com sucesso." 
        echo.
        echo. & timeout /t 1 > NUL
        GOTO :Install
    ) ELSE (
        goto :downloadFail
    )
    
:downloadFail
    CLS
    call :L "44;31m" "                                ERRO                                  "
    echo.
    ECHO  Falha ao baixar o setup.exe. Verifique sua conex∆o com a internet.
    echo.
    ECHO  Deseja tentar novamente? [S/N] & CHOICE /C SN /N /M ""
    IF ERRORLEVEL 2 GOTO :cleanUp
    IF ERRORLEVEL 1 GOTO :downloadSetup

:Install
    title Instalando Office
    if not exist "%~dp0bin\setup.exe" goto :installError
    cls & echo.
    echo.
    echo.
    call :L %c7% "                   Iniciando a instalaá∆o do Office..."
    timeout /t 2 > NUL
    GOTO :aWait 


:aWait
    cls & echo.
    call :L "44;37m" " Instalando o Office. Isso pode levar v†rios minutos...               "
    echo.
    call :L %c6% " Aguarde a conclus∆o; n∆o feche esta janela.                          "
    echo.
    "%~dp0bin\setup.exe" /configure "%~dp0bin\Configuration.xml"

    set /a "_w=0"


:aWaitStart
    tasklist /FI "IMAGENAME eq OfficeC2RClient.exe" 2>NUL | find /I "OfficeC2RClient.exe" >NUL && goto :aWaitRun
    if exist "%WRD%" goto :aWaitRun
    set /a "_w+=1"
    if %_w% GEQ 40 goto :installError
    timeout /t 3 >NUL
    goto :aWaitStart


:aWaitRun
    tasklist /FI "IMAGENAME eq OfficeC2RClient.exe" 2>NUL | find /I "OfficeC2RClient.exe" >NUL && ( timeout /t 5 >NUL & goto :aWaitRun )
    set /a "_f=0"


:aWaitConfirm
    if exist "%WRD%" goto :verifyInstallation
    set /a "_f+=1"
    if %_f% GEQ 12 goto :installError
    timeout /t 5 >NUL
    goto :aWaitConfirm


:verifyInstallation
    cls & echo.
    echo  Verificando instalaá∆o do Office... & timeout /t 2 > NUL

    if not exist "%WRD%" goto :installError
    if not exist "%EXC%" goto :installError
    if not exist "%PPT%" goto :installError
    goto :activate


:activate
    cls & echo.
    echo  Instalaá∆o verificada. Ativando Office
    call :L %c7% " via " %c2% "MASSGRAVE" %c7% "..."
    timeout /t 2 > NUL

    cls & echo.
    powershell -Command "irm https://get.activated.win | iex"

    goto :cleanUp


:installError
    cls
    call :L "44;31m" "                                ERRO                                  "
    echo.
    echo  Ocorreu um erro durante a instalaá∆o do Office. Tente novamente.
    echo.
    choice /c sn /n /m "Tentar novamente? [S/N] "
    
    if ERRORLEVEL 2 goto :cleanUp
    if ERRORLEVEL 1 goto :setUpInstaller


:uninstallOffice
    title Desinstalando Office
    
    call :ensureBin
    
    cls & echo.
    echo.
    echo.
    echo               Desinstalando a vers∆o existente do Office...
    set OsppHook=1
    sc query osppsvc %_Nul3%
    if %ERRORLEVEL% equ 1060 set OsppHook=0

    for %%A in ( 11,12,14,15,16 ) do call :officeMSI %%A

    call :officeCTR

    set tOCTR=0&set "dOCTR="
    set tOM16=0&set "dOM16="
    set tOM15=0&set "dOM15="
    set tOM14=0&set "dOM14="
    set tOM12=0&set "dOM12="
    set tOM11=0&set "dOM11="
    set tOUWP=0&set "dOUWP="
    set "dONXT="
    if %_O15CTR% equ 1 set tOCTR=1 & set "dOCTR=< 2013"
    if %_O16CTR% equ 1 set tOCTR=1 & set "dOCTR=<"
    if %_O16MSI% equ 1 set tOM16=1 & set "dOM16=<"
    if %_O15MSI% equ 1 set tOM15=1 & set "dOM15=<"
    if %_O14CTR% equ 1 set tOM14=1 & set "dOM14=< C2R"
    if %_O14MSI% equ 1 set tOM14=1 & set "dOM14=<"
    if %_O12MSI% equ 1 set tOM12=1 & set "dOM12=<"
    if %_O11MSI% equ 1 set tOM11=1 & set "dOM11=<"
    if %_O16UWP% equ 1 set tOUWP=1 & set "dOUWP=<"
    if %_O16NXT% equ 1 set "dONXT=<"

    if %_uAll% equ 1 (
        if %winbuild% GEQ 7600 set tOCTR=1
        if %winbuild% GEQ 7600 set tOM16=1
        if %winbuild% LSS 7600 set tOM14=1
        if %_uM15% equ 1 if %winbuild% GEQ 7600 set tOM15=1
        if %_uM14% equ 1 set tOM14=1
        if %_uM12% equ 1 set tOM12=1
        if %_uM11% equ 1 set tOM11=1
        if %_uUWP% equ 1 if %winbuild% GEQ 10240 set tOUWP=1
        goto :sOALL
    )
    if %_uC2R% equ 1 if %winbuild% GEQ 7600 goto :sOCTR
    if %_uM16% equ 1 if %winbuild% GEQ 7600 goto :sOM16
    if %_uM15% equ 1 if %winbuild% GEQ 7600 goto :sOM15
    if %_uM14% equ 1 goto :sOM14
    if %_uM12% equ 1 goto :sOM12
    if %_uM11% equ 1 goto :sOM11
    if %_uUWP% equ 1 if %winbuild% GEQ 10240 goto :sOUWP


    :Menu
        mode con: cols=70 lines=23
        set _er=0
        set _pt=
        call :Hdr
        cls & echo.
        call :L %c7% "                    "     %cC% "[1]" %c7% " Limpar TODOS"
        if %winbuild% GEQ 7600 (
            call :L %c7% "                    " %cC% "[2]" %c7% " Limpar Office C2R  " %cA% "%dOCTR%"
            call :L %c7% "                    " %cC% "[3]" %c7% " Limpar Office 2016 " %cA% "%dOM16%"
            call :L %c7% "                    " %cC% "[4]" %c7% " Limpar Office 2013 " %cA% "%dOM15%"
        )
        call :L %c7% "                    "     %cC% "[5]" %c7% " Limpar Office 2010 " %cA% "%dOM14%"
        call :L %c7% "                    "     %cC% "[6]" %c7% " Limpar Office 2007 " %cA% "%dOM12%"
        call :L %c7% "                    "     %cC% "[7]" %c7% " Limpar Office 2003 " %cA% "%dOM11%"
        if %winbuild% GEQ 10240 ( 
            call :L %c7% "                    " %cC% "[8]" %c7% " Limpar Office UWP  " %cA% "%dOUWP%"
        )
        if %winbuild% GEQ 7600 (
            call :L %c7% "                    " %cC% "[9]" %c7% " Voltar ao Menu Principal"
            echo.
            echo                    Office 2016 e posteriores
            echo.
            call :L %c7% "                    " %cC% "[L]" %c7% " Limpar Licenáas vNext " %cA% "%dONXT%"
            call :L %c7% "                    " %cC% "[A]" %c7% " Apagar todas as Licenáas"
            call :L %c7% "                    " %cC% "[R]" %c7% " Resetar Licenáas C2R"
            call :L %c7% "                    " %cC% "[D]" %c7% " Desinstalar todas as Chaves"
            call :L %c7% "                    " %cC% "[0]" %c7% " SAIR"    
        )
        echo.
        call :L %c7% "   [" %cA% "<" %c7% "] Instalaá∆o detectada."
        echo.

        if %_wxp% equ 0 (
            choice /c 123456789LARD0 /n /m "> "
            set _er=!ERRORLEVEL!
            cls & echo.
            echo    Aguarde...
        ) else (
            set /p _pt="Selecione uma opá∆o e pressione Enter, ou 0 para sair: "
        )

        if defined _pt (
            if /i "%_pt%"=="0" set _pt=13
            if /i "%_pt%"=="D" set _pt=12
            if /i "%_pt%"=="R" set _pt=11
            if /i "%_pt%"=="A" set _pt=10
            if /i "%_pt%"=="L" set _pt=9
            set _er=!_pt!
        )

        if "%_er%"=="13" goto :eof

        if %winbuild% GEQ 7600 (
            if "%_er%"=="12" goto :KeysU
            if "%_er%"=="11" goto :LcnsT
            if "%_er%"=="10" goto :LcnsR
            if "%_er%"=="9" goto :verifyExistingInstallation
        )

        if "%_er%"=="8" if %winbuild% GEQ 10240 goto :sOUWP
        if "%_er%"=="7" goto :sOM11
        if "%_er%"=="6" goto :sOM12
        if "%_er%"=="5" goto :sOM14
        if %winbuild% GEQ 7600 (
            if "%_er%"=="4" goto :sOM15
            if "%_er%"=="3" goto :sOM16
            if "%_er%"=="2" goto :sOCTR
            if "%_er%"=="1" set tOCTR=1 & set tOM16=1 & goto :mALL
        )
            if %winbuild% LSS 7600 (
            if "%_er%"=="1" set tOM14=1 & goto :mALL
        )
        goto :Menu


    :mALL
        mode con: cols=70 lines=21
        set "aOCTR=N«O  %dOCTR%" & if %tOCTR% equ 1 set "aOCTR=SIM %dOCTR%"
        set "aOM16=N«O  %dOM16%" & if %tOM16% equ 1 set "aOM16=SIM %dOM16%"
        set "aOM15=N«O  %dOM15%" & if %tOM15% equ 1 set "aOM15=SIM %dOM15%"
        set "aOM14=N«O  %dOM14%" & if %tOM14% equ 1 set "aOM14=SIM %dOM14%"
        set "aOM12=N«O  %dOM12%" & if %tOM12% equ 1 set "aOM12=SIM %dOM12%"
        set "aOM11=N«O  %dOM11%" & if %tOM11% equ 1 set "aOM11=SIM %dOM11%"
        set "aOUWP=N«O  %dOUWP%" & if %tOUWP% equ 1 set "aOUWP=SIM %dOUWP%"

        set _er=0
        set _pt=
        
        call :Hdr
        
        echo.
        call :L %c7% "                    "     %c6% "[1]" %c7% " Iniciar a operaá∆o"
        if %winbuild% GEQ 7600 (
            call :L %c7% "                    " %c6% "[2]" %c7% " Office C2R:  %aOCTR%"
            call :L %c7% "                    " %c6% "[3]" %c7% " Office 2016: %aOM16%"
            call :L %c7% "                    " %c6% "[4]" %c7% " Office 2013: %aOM15%"
        )
        call :L %c7% "                    "     %c6% "[5]" %c7% " Office 2010: %aOM14%"
        call :L %c7% "                    "     %c6% "[6]" %c7% " Office 2007: %aOM12%"
        call :L %c7% "                    "     %c6% "[7]" %c7% " Office 2003: %aOM11%"
        if %winbuild% GEQ 10240 (
            call :L %c7% "                    " %c6% "[8]" %c7% " Office UWP:  %aOUWP%"
        )
        call :L %c7% "                    "     %c6% "[9]" %c7% " Voltar ao Menu Anterior"
        call :L %c7% "                    "     %c6% "[0]" %c7% " SAIR"
        echo.
        echo  Aviso: Limpar todos pode demorar. 
        echo.
        
        if %_wxp% equ 0 (
            choice /c 1234567890 /n /m "> "
            set _er=!ERRORLEVEL!
        ) else (
            set /p _pt="Selecione uma opá∆o e pressione Enter, ou 0 para sair: "
        )

        if defined _pt (
            if /i "%_pt%"=="0" set _pt=9
            set _er=!_pt!
        )
        
        if "%_er%"=="9" goto :Menu
        if "%_er%"=="8" if %winbuild% GEQ 10240 ( if %tOUWP% equ 1 ( set tOUWP=0 ) else ( set tOUWP=1 ) & goto :mALL)
        if "%_er%"=="7" ( if %tOM11% equ 1 ( set tOM11=0 ) else ( set tOM11=1 ) & goto :mALL )
        if "%_er%"=="6" ( if %tOM12% equ 1 ( set tOM12=0 ) else ( set tOM12=1 ) & goto :mALL )
        if "%_er%"=="5" ( if %tOM14% equ 1 ( set tOM14=0 ) else ( set tOM14=1 ) & goto :mALL )
        if %winbuild% GEQ 7600 (
            if "%_er%"=="4" ( if %tOM15% equ 1 ( set tOM15=0 ) else ( set tOM15=1 ) & goto :mALL )
            if "%_er%"=="3" ( if %tOM16% equ 1 ( set tOM16=0 ) else ( set tOM16=1 ) & goto :mALL )
            if "%_er%"=="2" ( if %tOCTR% equ 1 ( set tOCTR=0 ) else ( set tOCTR=1 ) & goto :mALL )
        )
        
        if "%_er%"=="1" goto :sOALL
        goto :mALL


    :Hdr
        cls
        echo.
        goto :eof


    :sOALL
        call :Hdr

        cls
        echo.
        echo Desinstalando chaves de produto...
        call :cKMS %_Nul3%
        
        if %winbuild% GEQ 7600 (
            if %tOCTR% equ 1 echo. & echo %_sr% & call :rOCTR
            if %tOM16% equ 1 echo. & echo %_sr% & call :rOM16
            if %tOM15% equ 1 echo. & echo %_sr% & call :rOM15
        )
        if %tOM14% equ 1 echo. & echo %_sr% & call :rOM14
        if %tOM12% equ 1 echo. & echo %_sr% & call :rOM12
        if %tOM11% equ 1 echo. & echo %_sr% & call :rOM11
        if %tOUWP% equ 1 if %winbuild% GEQ 10240 if %_pwsh% equ 1 echo. & echo %_sr% & call :rOUWP
        
        call :cSPP
        goto :Fin


    :sOCTR
        call :Hdr
        call :rOCTR
        if %_O15MSI% equ 0 call :cSPP
        goto :Fin


    :sOM16
        call :Hdr
        call :rOM16
        if %_O15MSI% equ 0 call :cSPP
        goto :Fin


    :sOM15
        call :Hdr
        call :rOM15
        if %_O16MSI% equ 0 if %_O16CTR% equ 0 if %_O16UWP% equ 0 call :cSPP
        goto :Fin


    :sOM14
        call :Hdr
        call :rOM14
        goto :Fin


    :sOM12
        call :Hdr
        call :rOM12
        goto :Fin


    :sOM11
        call :Hdr
        call :rOM11
        goto :Fin


    :sOUWP
        call :Hdr
        
        if %_pwsh% equ 0 (
            set "msg=ERRO: Problemas ao localizar o PowerShell."
            goto :theEnd
        )

        call :rOUWP
        set "msg=Finalizado."
        goto :cleanUp


    :rOCTR
        if exist "!_file!" (
            cls
            echo.
            echo Executando OfficeClickToRun.exe...
            
            %_Nul3% call :CloseC2R
            %_Nul3% start "" /WAIT "!_file!" platform=%_plat% productstoremove=AllProducts displaylevel=False
        )
        
        if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" (
            cls
            echo.
            echo Executando OfficeClickToRun.exe...
            
            %_Nul3% call :CloseC2R
            %_Nul3% start "" /WAIT "!_fil2!" platform=%_plat% productstoremove=AllProducts displaylevel=False
        )
        
        cls
        echo.
        echo Limpando Office C2R...
        
        for %%A in ( 16,19,21,24 ) do call :cKpp %%A
        if %_O15CTR% equ 1 call :cKpp 15
        %_cscript% OffScrubC2R.vbs ALL /OFFLINE
        %_Nul3% call :vNextDir
        %_Nul3% call :officeREG 16
        goto :eof


    :CloseC2R
        title Encerrando processos do Office
        
        cls & echo.
        echo  Encerrando processos relacionados ao Office...

        net stop OfficeSvc /y
        net stop ClickToRunSvc /y
        for %%# in (
            appvshnotify
            integratedoffice
            integrator
            firstrun
            communicator
            msosync
            OneNoteM
            iexplore
            mavinject32
            werfault
            perfboost
            roamingoffice
            officeclicktorun
            officeondemand
            OfficeC2RClient
            msaccess
            excel
            groove
            lync
            onenote
            outlook
            powerpnt
            mspub
            winword
            winproj
            visio
            mstore
            setlang
            msouc
            ois
            graph
        ) do (
            tasklist /FI "IMAGENAME eq %%#.exe" | find /i "%%#.exe" && taskkill /t /f /IM %%#.exe
        )
        net start OfficeSvc /y
        net start ClickToRunSvc /y
        title Processos encerrados, aguarde...
        goto :eof


    :ensureBin
        set "_need=0"
        for %%# in (
            OffScrubC2R.vbs OffScrub_O16msi.vbs OffScrub_O15msi.vbs OffScrub10.vbs OffScrub07.vbs OffScrub03.vbs CleanOffice.txt
        ) do if not exist "!_work!\%%#" set "_need=1"
        
        if !_need! equ 0 goto :eof
        if %_pwsh% equ 0 ( set "msg=ERRO: PowerShell Ç necess†rio para baixar a pasta bin." & goto :theEnd )

        cls & echo.
        echo  Pasta 'bin' incompleta. Baixando ferramentas de remoá∆o do
        echo  Office a partir do abbodi1406/BatUtil...

        if not exist "!_work!" md "!_work!"
        %_psc% "[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor 3072; $d='!_work!'; $u='https://raw.githubusercontent.com/abbodi1406/BatUtil/master/OfficeScrubber/bin/'; $wc=New-Object Net.WebClient; foreach($f in 'CleanOffice.txt','OffScrub03.vbs','OffScrub07.vbs','OffScrub10.vbs','OffScrubC2R.vbs','OffScrub_O15msi.vbs','OffScrub_O16msi.vbs'){ try{$wc.DownloadFile($u+$f,(Join-Path $d $f))}catch{} }"
        set "_need=0"
        
        for %%# in (
            OffScrubC2R.vbs OffScrub_O16msi.vbs OffScrub_O15msi.vbs OffScrub10.vbs OffScrub07.vbs OffScrub03.vbs CleanOffice.txt
        ) do if not exist "!_work!\%%#" set "_need=1"
        
        if !_need! equ 1 ( set "msg=ERRO: Falha ao baixar a pasta bin. Verifique a conex∆o com a internet." & goto :theEnd )
        
        cls & echo.
        echo  Ferramentas baixadas com sucesso.
        timeout /t 1 > NUL
        goto :eof


    :rOUWP
        cls
        echo.
        echo  Removendo aplicativos UWP Office...
        %_Nul3% %_psc% "Get-AppXPackage -Name '*Microsoft.Office.Desktop*' | Foreach {Remove-AppxPackage $_.PackageFullName}"
        %_Nul3% %_psc% "Get-AppXProvisionedPackage -Online | Where DisplayName -Like '*Microsoft.Office.Desktop*' | Remove-AppXProvisionedPackage -Online"
        @title Office Scrubber %uivr%
        goto :eof


    :rOM16
        cls
        echo.
        echo  Limpando Office 2016 MSI...
        call :cKpp 16
        %_cscript% OffScrub_O16msi.vbs %_para%
        %_Nul3% call :officeREG 16
        goto :eof


    :rOM15
        cls
        echo.
        echo  Limpando Office 2013 MSI...
        call :cKpp 15
        %_cscript% OffScrub_O15msi.vbs %_para%
        %_Nul3% call :officeREG 15
        goto :eof


    :rOM14
        cls
        echo.
        echo  Limpando Office 2010...
        call :cK14
        %_cscript% OffScrub10.vbs %_para%
        %_Nul3% call :officeREG 14
        goto :eof


    :rOM12
        cls
        echo.
        echo  Limpando Office 2007...
        %_cscript% OffScrub07.vbs %_para%
        %_Nul3% call :officeREG 12
        goto :eof


    :rOM11
        cls
        echo.
        echo  Limpando Office 2003...
        %_cscript% OffScrub03.vbs %_para%
        %_Nul3% call :officeREG 11
        goto :eof


        :cSPP
            cls
            echo.
            echo  Removendo Licenáas do Office...
            call :oppcln
            call :slmgr
            goto :eof


    :oppcln
        %_Nul3% %_psc% "cd -Lit ($env:__CD__); $f=[IO.File]::ReadAllText('.\CleanOffice.txt') -split ':embed\:.*'; iex ($f[1])"
        @title Office Scrubber %uivr%
        goto :eof

        :slmgr
        if exist "%SysPath%\spp\store_test\2.0\tokens.dat" (
            cls
            echo.
            echo Atualizando Licenáas do Windows Insider Preview...
            %_cscript% //B %SysPath%\slmgr.vbs /rilc %_Nul3%
            if !ERRORLEVEL! NEQ 0 %_cscript% //B %SysPath%\slmgr.vbs /rilc %_Nul3%
        )
        goto :eof

    :Fin
        for /f %%# in ( '"dir /b %SystemRoot%\temp\ose*.exe" %_Nul6%' ) do taskkill /t /f /IM %%# %_Nul3%
        del /f /q "%SystemRoot%\temp\ose*.exe" %_Nul3%
        set "msg=Finalizado. Reinicie o computador para concluir."
        goto :cleanUp

    :officeCTR
        set _O16CTR=0
        set _O15CTR=0
        set _O14CTR=0
        set _O16UWP=0
        set _O16NXT=0

        if %_wxp% equ 0 (
            if %xOS%==x86 reg.exe query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set _O14CTR=1
            if not %xOS%==x86 reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set _O14CTR=1
        ) else (
            reg.exe query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH %_Nul2% | findstr /I "Click2run" %_Nul1% && set _O14CTR=1
        )
        
        if %winbuild% LSS 7600 goto :eof
        
        reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
            set _O16CTR=1
            for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "_plat=%%b"
        )
        if not %xOS%==x86 if %_O16CTR% equ 0 reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
            set _O16CTR=1
            for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "_plat=%%b"
        )
        if exist "!_file!" set _O16CTR=1
        if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set _O16CTR=1
        if %_O16CTR% equ 1 if not defined _plat (
            if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS" ( set "_plat=x86" ) else (set "_plat=%xBit%")
        )
        reg.exe query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && (
            set _O15CTR=1
        )
        if %_O15CTR% equ 0 reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && (
            set _O15CTR=1
        )
        if %_O15CTR% equ 0 reg.exe query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && (
            set _O15CTR=1
        )
        if %_O15CTR% equ 0 reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && (
            set _O15CTR=1
        )

        if %winbuild% GEQ 10240 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msoxmled.exe" %_Nul3% && (
            dir /b "%ProgramFiles%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
            if not %xOS%==x86 dir /b "%ProgramW6432%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
            if not %xOS%==x86 dir /b "%ProgramFiles(x86)%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
        )

        set kNxt=%kO16%\Common\Licensing\LicensingNext
        dir /b /s /a:-d "!_Local!\Microsoft\Office\Licenses\*" %_Nul3% && set _O16NXT=1
        dir /b /s /a:-d "!ProgramData!\Microsoft\Office\Licenses\*" %_Nul3% && set _O16NXT=1
        reg.exe query %kNxt% %_Nul3% && (
        reg.exe query %kNxt% /v MigrationToV5Done %_Nul2% | find /i "0x1" %_Nul1% && set _O16NXT=1
        reg.exe query %kNxt% | findstr /i /r ".*retail" %_Nul3% && set _O16NXT=1
        reg.exe query %kNxt% | findstr /i /r ".*volume" %_Nul3% && set _O16NXT=1
        )

        goto :eof

    :officeMSI
        set _O%1MSI=0
        if %winbuild% LSS 7600 (
        if %1 equ 15 goto :eof
        if %1 equ 16 goto :eof
        )
        for /f "skip=%_sk% tokens=1,2*" %%i in (
            '"reg.exe query HKLM\SOFTWARE\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%'
        ) do (
            if /i "%%i"=="Path" if not "%%~k"=="" if exist "%%~k\*.dll" set _O%1MSI=1
        )

        if exist "%ProgramFiles%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
        if %xOS%==x86 goto :eof
        for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\*.dll" set _O%1MSI=1
        if exist "%ProgramW6432%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
        if exist "%ProgramFiles(x86)%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
        goto :eof

    :officeREG
        reg delete HKCU\Software\Microsoft\Office\%1.0 /f
        reg delete HKCU\Software\Policies\Microsoft\Office\%1.0 /f
        reg delete HKCU\Software\Policies\Microsoft\Cloud\Office\%1.0 /f
        reg delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f
        reg delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f
        reg delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f /reg:32
        reg delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f /reg:32
        goto :eof


    :cK14
        if %WMI_VBS% NEQ 0 cd ..
        set _spp=OfficeSoftwareProtectionProduct
        if %OsppHook% NEQ 0 (
            call :cKEY 14
        )

        if %WMI_VBS% NEQ 0 cd bin
        goto :eof


    :cKpp
        if %WMI_VBS% NEQ 0 cd ..
        set _spp=SoftwareLicensingProduct
        if %winbuild% GEQ 9200 (
            call :cKEY %1
        )

        set _spp=OfficeSoftwareProtectionProduct
        if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
            call :cKEY %1
        )

        if %WMI_VBS% NEQ 0 cd bin
        goto :eof


    :cKMS
        if %WMI_VBS% NEQ 0 cd ..

        set _spp=SoftwareLicensingProduct
        
        if %winbuild% GEQ 9200 (
            reg delete "HKLM\%SPPk%\%_oApp%" /f
            reg delete "HKLM\%SPPk%\%_oApp%" /f /reg:32
            reg delete "HKU\S-1-5-20\%SPPk%\%_oApp%" /f
            for %%A in ( 15,16,19,21,24 ) do call :cKEY %%A
        )

        set _spp=OfficeSoftwareProtectionProduct
        if %winbuild% GEQ 9200 if %OsppHook% NEQ 0 (
            call :cKEY 14
        )

        if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
            reg delete "HKLM\%OPPk%\%_oApp%" /f
            reg delete "HKLM\%OPPk%\%_oApp%" /f /reg:32
            for %%A in ( 14,15,16,19,21,24 ) do call :cKEY %%A
        )
        
        reg delete "HKLM\%OPPk%\%_oA14%" /f
        reg delete "HKU\S-1-5-20\%OPPk%" /f
        if %WMI_VBS% NEQ 0 cd bin
        goto :eof


    :cKEY
        set "_ocq=Name LIKE 'Office %~1%%' AND PartialProductKey is not NULL"
        set "_qr="wmic path %_spp% where (%_ocq%) get ID /VALUE""
        if %WMI_VBS% NEQ 0 set "_qr=%_csq% %_spp% "%_ocq%" ID"
        for /f "tokens=2 delims==" %%# in ( '%_qr% %_Nul6%' ) do ( set "aID=%%#"&call :cAPP )
        goto :eof


    :cAPP
        set "_qr=wmic path %_spp% where ID='%aID%' call UninstallProductKey"
        if %WMI_VBS% NEQ 0 set "_qr=%_csm% "%_spp%.ID='%aID%'" UninstallProductKey"
        %_qr% %_Nul3%
        goto :eof


    :vNextDir
        attrib -R "!ProgramData!\Microsoft\Office\Licenses"
        attrib -R "!_Local!\Microsoft\Office\Licenses"
        rd /s /q "!ProgramData!\Microsoft\Office\Licenses\"
        rd /s /q "!_Local!\Microsoft\Office\Licenses\"
        goto :eof


    :vNextREG
        reg delete "%kO16%\Common\Licensing" /f
        reg delete "%kO16%\Registration" /f
        goto :eof


    :LcnsC
        call :Hdr

        cls
        echo.
        echo  Limpando Licenáas vNext...
        %_Nul3% call :vNextDir
        %_Nul3% call :vNextREG
        set "msg=Finalizado."
        goto :cleanUp


    :KeysU
        call :Hdr

        cls
        echo.
        echo  Desinstalando Chaves de Produto...
        for %%A in (15,16,19,21,24) do call :cKpp %%A
        set "msg=Finalizado."
        goto :cleanUp


    :LcnsR
        call :Hdr
        call :cSPP
        set "msg=Finalizado."
        goto :cleanUp


    :LcnsT
        call :Hdr
        echo.
        echo Resetando Licenáas do Office C2R...
        
        if %_O16CTR% equ 0 (
            set "msg=ERRO: Office ClickToRun n∆o detectado."
            goto :cleanUp
        )
        
        set "_InstallRoot="
        
        for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
        
        if not "%_InstallRoot%"=="" (
            for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
            set "_PRIDs=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs"
        ) else (
            for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
            for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
            set "_PRIDs=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\ProductReleaseIDs"
        )
        
        set "_Integrator=%_InstallRoot%\integration\integrator.exe"
        
        for /f "skip=2 tokens=2*" %%a in ( '"reg.exe query %_PRIDs% /v ActiveConfiguration" %_Nul6%' ) do set "_PRIDs=%_PRIDs%\%%b"
        
        if not exist "%_Integrator%" (
            set "msg=ERRO: N∆o foi poss°vel detectar o integrator.exe"
            goto :verifyExistingInstallation
        )

        for /f "tokens=8 delims=\" %%a in ( 'reg.exe query "%_PRIDs%" /f ".16" /k %_Nul6% ^| find /i "ClickToRun"' ) do (
            if not defined _SKUs ( set "_SKUs=%%a" ) else ( set "_SKUs=!_SKUs!,%%a" )
        )

        if not defined _SKUs (
            set "msg=ERRO: N∆o foi poss°vel detectar produtos Office instalados originalmente."
            goto :verifyExistingInstallation
        )

        call :cSPP
        
        cls
        echo.
        echo Instalando Licenáas do Office C2R...
        
        for %%a in ( %_SKUs% ) do (
            "!_Integrator!" /R /License PRIDName=%%a.16 PackageGUID="%_GUID%" PackageRoot="!_InstallRoot!" %_Nul1%
        )

        set "msg=Finalizado."
        goto :cleanUp


    :E_Admin
        cls
        echo %_err%
        echo  Este script precisa ser iniciado como administrador.
        echo  Para isso, clique com o bot∆o direito neste script e selecione 'Executar como administrador'
        goto :cleanUp


    :E_VBS
        cls
        echo %_err%
        echo  Motor VBScript inexistente.
        echo  Ele Ç necess†rio para que este script funcione.
        goto :cleanUp


    :E_WSH
        cls
        echo %_err%
        echo O Windows Script Host est† desabilitado.
        echo Ele Ç necess†rio para que este script funcione.
        goto :cleanUp


    <!-- Inicio do script wsf --->
    <package>
    <job id="WmiQuery">
        <script language="VBScript">
            If WScript.Arguments.Count = 3 Then
                wExc = "Select " & WScript.Arguments.Item(2) & " from " & WScript.Arguments.Item(0) & " where " & WScript.Arguments.Item(1)
                wGet = WScript.Arguments.Item(2)
            Else
                wExc = "Select " & WScript.Arguments.Item(1) & " from " & WScript.Arguments.Item(0)
                wGet = WScript.Arguments.Item(1)
            End If
            Set objCol = GetObject("winmgmts:\\.\root\CIMV2").ExecQuery(wExc,,48)
            For Each objItm in objCol
                For each Prop in objItm.Properties_
                If LCase(Prop.Name) = LCase(wGet) Then
                    WScript.Echo Prop.Name & "=" & Prop.Value
                    Exit For
                End If
                Next
            Next
        </script>
    </job>
    <job id="WmiMethod">
        <script language="VBScript">
            On Error Resume Next
            wPath = WScript.Arguments.Item(0)
            wMethod = WScript.Arguments.Item(1)
            Set objCol = GetObject("winmgmts:\\.\root\CIMV2:" & wPath)
            objCol.ExecMethod_(wMethod)
            WScript.Quit Err.Number
        </script>
    </job>
    <job id="ELAV">
        <script language="VBScript">
            Set strArg=WScript.Arguments.Named
            Set strRdlproc = CreateObject("WScript.Shell").Exec("rundll32 kernel32,Sleep")
            With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & strRdlproc.ProcessId & "'")
                With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & .ParentProcessId & "'")
                If InStr (.CommandLine, WScript.ScriptName) <> 0 Then
                    strLine = Mid(.CommandLine, InStr(.CommandLine , "/File:") + Len(strArg("File")) + 8)
                End If
                End With
                .Terminate
            End With
            CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
        </script>
    </job>
    </package>


:theEnd
    mode con: cols=70 lines=7
    echo.
    echo  %msg%
    echo.
    timeout /t 5 > NUL
    EXIT


:cleanUp
    mode con: cols=70 lines=7
    echo.
    if defined msg ( 
        echo  %msg% 
        echo. 
    )
    echo    Realizando limpeza final... & timeout /t 1 >nul

    %_Nul3% call :CloseC2R 2>nul
    del /f /q "setup.exe" 2>nul
    del /f /q "Configuration.xml" 2>nul

    cls
    echo.
    echo    Removendo arquivos temporarios... & timeout /t 1 >nul
    
    del /s /f /q "%TEMP%\*" 2>nul
    del /s /f /q "C:\Windows\Temp\*" 2>nul
    del /s /f /q "C:\Windows\Prefetch\*" 2>nul

    for /d %%p in ( "%TEMP%\*" ) do rmdir /s /q "%%p" 2>nul
    for /d %%p in ( "C:\Windows\Temp\*" ) do rmdir /s /q "%%p" 2>nul
    for /d %%p in ( "C:\Windows\Prefetch\*" ) do rmdir /s /q "%%p" 2>nul

    cls
    goto :endScript

    
:L
    setlocal EnableDelayedExpansion
    set "_LINE="
    set "i=0"

    for %%a in (%*) do (
        set /A i+=1
        set /A _pair=!i! %% 2
        
        if !_pair! equ 1 (
            set "_LINE=!_LINE!!ESC![%%~a"
        ) else (
            set "_LINE=!_LINE!%%~a"
        )
    )

    echo !_LINE!!ESC![0m
    endlocal
    exit /b


:endScript
    echo.
    echo    Limpeza finalizada. Fechando janela. & timeout /t 2 > NUL
    EXIT
