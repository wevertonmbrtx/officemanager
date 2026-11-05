@setlocal DisableDelayedExpansion
@set uivr=v2
@echo off
chcp 850 >nul
if /i "%~1"=="/xmlwatch" goto :xmlWatch
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
    if "%_hasNet%"=="1" call :LC %c7% ".NET Framework 4.5+: " %cA% "OK"
    if "%_hasNet%"=="0" call :LC %c7% ".NET Framework 4.5+: " %cC% "AUSENTE"
    if defined _psver call :LC %c7% "PowerShell / WMF: " %cA% "OK (" %cE% "v%_psver%" %cA% ")"
    if not defined _psver call :LC %c7% "PowerShell 3+ / WMF: " %cC% "AUSENTE"
    echo.

    if "%_leg%"=="1" (
        call :LC %c6% "Windows legado: seguindo sem alteracoes."
        timeout /t 2 /nobreak >nul
        cls
        goto :eof
    )
    if defined _psver (
        call :LC %cA% "Tudo certo para prosseguir."
        timeout /t 2 /nobreak >nul
        cls
        goto :eof
    )

    call :LC %cE% "PowerShell 3+ ausente. Preparando pre-requisitos (Windows 7+)..."
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
    call :LC %c7% "Baixando .NET Framework 4.5 (~65 MB)..."
    
    set "_dnFile=%TEMP%\dotnet45_setup.exe"
    call :download "https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe" "%_dnFile%"
    
    if not exist "%_dnFile%" (
        set "msg=Falha ao baixar o .NET 4.5." & goto :prereqFail
    )
    
    cls
    echo.
    call :LC %c7% "Instalando .NET Framework 4.5 (pode levar v†rios minutos)..."
    
    "%_dnFile%" /q /norestart
    set "_ec=%errorlevel%"
    del /f /q "%_dnFile%" >nul 2>&1
    if "%_ec%"=="0" goto :eof
    if "%_ec%"=="3010" goto :setupReboot
    if "%_ec%"=="1641" goto :setupReboot

    set "msg=Falha na instalaá∆o do .NET 4.5 (c¢digo %_ec%)."
    
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
    call :LC %c7% "Baixando Windows Management Framework 5.0 (%_a%)..."
    call :download "%_wmfUrl%" "%_wmfFile%"
    if not exist "%_wmfFile%" ( set "msg=Falha ao baixar o WMF 5.0." & goto :prereqFail )
    
    cls
    echo.
    call :LC %c7% "Instalando Windows Management Framework 5.0..."
    
    wusa "%_wmfFile%" /quiet /norestart
    set "_ec=%errorlevel%"
    del /f /q "%_wmfFile%" >nul 2>&1
    
    if "%_ec%"=="2359302" goto :setupReboot
    if "%_ec%"=="0"       goto :setupReboot
    if "%_ec%"=="3010"    goto :setupReboot
    
    set "msg=Falha na instalaá∆o do WMF 5.0 (c¢digo %_ec%). Confirme que Ç Windows 7 SP1."
    goto :prereqFail


:download
    del /f /q %2 >nul 2>&1

    @REM curl primeiro: existe no Windows 10 1803+, respeita timeout e redirecionamento.
    where curl >nul 2>&1 && curl -L -f -s --connect-timeout 15 --retry 2 -o "%~2" "%~1" >nul 2>&1
    call :dlCheck %2
    if "%_dlok%"=="1" goto :eof

    @REM PowerShell/.NET com TLS 1.2 foráado.
    %_psc% "[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor 3072; (New-Object Net.WebClient).DownloadFile(%1,%2)" >nul 2>&1
    call :dlCheck %2
    if "%_dlok%"=="1" goto :eof

    @REM BITS por £ltimo: fallback para Windows 7/8, onde n∆o h† curl.
    bitsadmin /transfer dl /download /priority foreground "%~1" "%~2" >nul 2>&1
    call :dlCheck %2
    goto :eof


:dlCheck
    @REM Descarta arquivo vazio para que "if exist" n∆o vire falso positivo.
    set "_dlok=0"
    if not exist %1 goto :eof
    for %%S in (%1) do if %%~zS EQU 0 ( del /f /q %1 >nul 2>&1 & goto :eof )
    set "_dlok=1"
    goto :eof


:setupReboot
    mode con: cols=70 lines=7
    
    cls & echo.
    call :LC %c7% "PrÇ-requisitos configurados."
    call :LC %c7% "REINICIE o computador e execute este script novamente"
    call :LC %c7% "para concluir."
    echo. & timeout /t 1 /nobreak > NUL
    exit


:prereqFail
    mode con: cols=70 lines=15
    call :showError "%msg%"
    call :LC %c7% "O TLS 1.2 foi configurado. REINICIE o computador e rode o"
    call :LC %c7% "script novamente - o download autom†tico pode funcionar"
    call :LC %c7% "ap¢s o rein°cio."
    echo.
    call :LC %c7% "Se persistir, instale manualmente e reinicie:"
    call :LC %c7% ".NET 4.5: https://dotnet.microsoft.com/download/dotnet-framework/net452"
    call :LC %c7% "WMF 5.1: https://www.microsoft.com/download/details.aspx?id=54616"
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
    @REM Detecta o Office em Program Files (64-bit) ou Program Files (x86) (32-bit): ver :locateOffice
    call :locateOffice

    if exist "%WRD%" ( if exist "%EXC%" ( if exist "%PPT%" GOTO :changeInstallation ) )

    GOTO :setUpConfiguration


:changeInstallation
    mode con: cols=70 lines=7
    title Instalaá∆o existente detectada 

    set "_mTitle=Uma instalaá∆o existente do Office foi detectada."
    set "_mTitleColor=93"
    set "_mOpts=D|Desinstalar;A|Ativar;C|Continuar"
    call :arrowMenu
    
    if %errorlevel%==3 goto :setUpConfiguration
    if %errorlevel%==2 goto :activate
    if %errorlevel%==1 goto :uninstallOffice


:setUpConfiguration
    cd /d "%~dp0bin"
    title Configurando instalaá∆o do Office

    if exist "Configuration.xml" (
        cls & echo.
        call :LC %c7% "Arquivo de configuraá∆o " %cA% "encontrado." 
        timeout /t 1 /nobreak > NUL
        cls
        goto :setUpInstaller
    )

    @REM O XML e montado a cada resposta em Configuration.partial e so vira Configuration.xml no fim.
    if exist "Configuration.partial" del /f /q "Configuration.partial"
    call :xmlViewer

    set "_mTitle=Selecione a arquitetura do Office a ser instalada:"
    set "_mOpts="
    if %xBit%==x64 (
        call :addOpt 1 "64-bits" 1 "Recomendado"
        call :addOpt 2 "32-bits" 2
    ) else (
        call :addOpt 1 "64-bits" 1
        call :addOpt 2 "32-bits" 2 "Recomendado"
    )
    call :arrowMenu
    if %errorlevel%==1 set "ARCH=64"
    if %errorlevel%==2 set "ARCH=32"

    set "_mTitle=Selecione o canal de atualizaá∆o:"
    set "_mOpts="
    call :addOpt 1 "Current (Mensal)" 1
    call :addOpt 2 "MonthlyEnterprise (Mensal Empresarial)" 2
    call :addOpt 3 "SemiAnnual (Semestral)" 3
    call :arrowMenu
    if %errorlevel%==1 set "CHANNEL=Current"
    if %errorlevel%==2 set "CHANNEL=MonthlyEnterprise"
    if %errorlevel%==3 set "CHANNEL=SemiAnnual"
    (
        echo ^<Configuration^>
        echo   ^<Add OfficeClientEdition="%ARCH%" Channel="%CHANNEL%"^>
    ) > Configuration.partial

    set "_mTitle=Selecione o produto:"
    set "_mOpts="
    call :addOpt 1 "Microsoft 365 (Sem Teams)" 1
    call :addOpt 2 "Microsoft 365 (Com Teams)" 2
    call :arrowMenu
    if %errorlevel%==1 set "PRODUCT=O365ProPlusEEANoTeamsRetail"
    if %errorlevel%==2 set "PRODUCT=O365ProPlusRetail"
    >> Configuration.partial echo     ^<Product ID="%PRODUCT%"^>

    set "_mTitle=Selecione o idioma:"
    set "_mOpts="
    call :addOpt 1 "Portuguàs (Brasil) [pt-BR]" 1
    call :addOpt 2 "Inglàs (EUA) [en-US]" 2
    call :addOpt 3 "Personalizado (ex.: en-GB, es-ES, etc.)" 3
    call :arrowMenu
    if %errorlevel%==1 set "LANG=pt-BR"
    if %errorlevel%==2 set "LANG=en-US"
    if %errorlevel%==3 (
        cls & echo.
        call :center "Digite o idioma personalizado: "
        set /p "LANG=%_ctr%"
    )
    >> Configuration.partial echo       ^<Language ID="%LANG%" /^>

    call :askExclude EXC_ACCS "Access" Access

    @REM call :askExclude EXC_EXCL "Excel" Excel

    call :askExclude EXC_ONED "OneDrive" OneDrive

    call :askExclude EXC_OUTL "Outlook" Outlook

    call :askExclude EXC_NOUT "Novo Outlook" OutlookForWindows

    @REM call :askExclude EXC_POWP "PowerPoint" PowerPoint

    call :askExclude EXC_PUBL "Publisher" Publisher

    call :askExclude EXC_NOTE "OneNote" OneNote

    call :askExclude EXC_SKYP "Skype for Business" Lync

    @REM call :askExclude EXC_WORD "Word" Word

    call :askExclude EXC_GROO "OneDrive for Business" Groove

    call :askExclude EXC_BING "Bing (Pesquisa no Bing)" Bing

    set "EXC_TEAM=0"
    if "%PRODUCT%"=="O365ProPlusRetail" call :askExclude EXC_TEAM "Teams" Teams
    
    :genSetUpXML
        call :showInfo "Gerando arquivo de configuraá∆o..."

        (
            echo     ^</Product^>
            echo   ^</Add^>
            echo   ^<Updates Enabled="TRUE" /^>
            echo   ^<RemoveMSI /^>
            echo   ^<Display Level="Full" AcceptEULA="TRUE" /^>
            echo ^</Configuration^>
        ) >> Configuration.partial
        move /y Configuration.partial Configuration.xml >nul

        call :showInfo "Arquivo de configuraá∆o criado."
        timeout /t 2 /nobreak > NUL
        

    goto :setUpInstaller


:xmlViewer
    @REM Abre a janela auxiliar (ver :xmlWatch) ao lado da principal, sem tirar o foco do menu.
    @REM Atencao: nao usar %CD% aqui; este script define a variavel "cD" (cor), que sobrescreve o %CD% dinamico.
    @REM Com PowerShell: posiciona a janela; sem ele: abre uma janela comum (o Windows escolhe o lugar).
    set "_xa="%~f0" /xmlwatch "%~dp0bin\Configuration.partial" "%~dp0bin\Configuration.xml""
    if not defined _psver start "Configuration.xml" cmd /c "%_xa%" & goto :eof
    @REM Declaracoes Win32 (QQ vira aspas)
    set "_xc=using System;using System.Text;using System.Runtime.InteropServices;public delegate bool EW(IntPtr h,IntPtr l);public struct R{public int L,T,Rt,B;}public class W{[DllImport(QQuser32.dllQQ)]public static extern bool GetWindowRect(IntPtr h,out R r);[DllImport(QQuser32.dllQQ)]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int ht,bool p);[DllImport(QQuser32.dllQQ)]public static extern bool ShowWindow(IntPtr h,int c);[DllImport(QQuser32.dllQQ)]public static extern bool SetForegroundWindow(IntPtr h);[DllImport(QQuser32.dllQQ)]static extern bool EnumWindows(EW f,IntPtr l);[DllImport(QQuser32.dllQQ,CharSet=CharSet.Auto)]static extern int GetWindowText(IntPtr h,StringBuilder b,int n);public static IntPtr Find(string s){IntPtr r=IntPtr.Zero;EnumWindows((h,l)=>{StringBuilder b=new StringBuilder(256);GetWindowText(h,b,256);if(b.ToString().IndexOf(s)>=0){r=h;return false;}return true;},IntPtr.Zero);return r;}[DllImport(QQkernel32.dllQQ)]public static extern IntPtr GetConsoleWindow();[DllImport(QQuser32.dllQQ)]public static extern IntPtr GetForegroundWindow();}"
    @REM Mede a janela principal (a do proprio console; se vier zerada, a em primeiro plano) e abre o visualizador MINIMIZADO (assim ele nao rouba o foco do menu)
    set "_xl=try{$q=[char]34;Add-Type $env:_xc.Replace('QQ',[string]$q);$m=[W]::GetConsoleWindow();$r=New-Object R;[void][W]::GetWindowRect($m,[ref]$r);if($r.Rt -le 0){$m=[W]::GetForegroundWindow();[void][W]::GetWindowRect($m,[ref]$r)};"
    set "_xl=%_xl%[void](Start-Process cmd -ArgumentList ('/c '+$q+$env:_xa+$q) -WindowStyle Minimized);"
    @REM A janela de console pertence ao conhost.exe (Process.MainWindowHandle do cmd e 0): localiza varrendo as janelas pelo titulo definido em :xmlWatch (em console elevado o titulo ganha o prefixo Administrador:)
    set "_xl=%_xl%$h=[IntPtr]::Zero;for($i=0;$i -lt 50 -and $h -eq [IntPtr]::Zero;$i++){Start-Sleep -Milliseconds 100;$h=[W]::Find('Configuration.xml (ao vivo)')};"
    @REM Restaura SEM ativar (ShowWindow 4), posiciona a direita da principal mantendo o tamanho definido por mode con, e devolve o foco
    set "_xl=%_xl%$v=New-Object R;if($h -ne [IntPtr]::Zero){[void][W]::ShowWindow($h,4);Start-Sleep -Milliseconds 400;[void][W]::GetWindowRect($h,[ref]$v);"
    set "_xl=%_xl%if($r.Rt -gt 0){[void][W]::MoveWindow($h,$r.Rt,$r.T,$v.Rt-$v.L,$v.B-$v.T,$true)}};[void][W]::SetForegroundWindow($m);"
    @REM Registro de diagnostico em %TEMP%\omxml.log (principal, retangulo, janela do XML); erros do lancador caem no catch
    set "_xl=%_xl%Set-Content (Join-Path $env:TEMP 'omxml.log') ('m='+$m+' r='+$r.L+','+$r.T+','+$r.Rt+','+$r.B+' h='+$h+' v='+$v.L+','+$v.T+','+$v.Rt+','+$v.B)}"
    set "_xl=%_xl%catch{Set-Content (Join-Path $env:TEMP 'omxml.log') ('ERRO: '+$_.Exception.Message)}"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "%_xl%"
    goto :eof

:xmlWatch
    @REM Modo auxiliar (chamado por :xmlViewer): %2 = XML parcial | %3 = XML final.
    @REM A cada segundo compara o tamanho do arquivo; se mudou, limpa a tela e mostra o conteudo.
    @REM Encerra 4 s depois de o parcial virar Configuration.xml, ou se o parcial sumir (execucao cancelada).
    mode con: cols=90 lines=42
    title Configuration.xml (ao vivo)
    set "_last=x"
    set "_seen=0"

    :xw_loop
    set "_src="
    if exist "%~2" set "_src=%~2"
    if exist "%~2" set "_seen=1"
    if not defined _src if exist "%~3" set "_src=%~3"
    if not defined _src if "%_seen%"=="1" exit
    set "_cur="
    if defined _src for %%a in ("%_src%") do set "_cur=%%~za"
    if not "%_cur%"=="%_last%" cls
    if not "%_cur%"=="%_last%" if defined _src type "%_src%"
    set "_last=%_cur%"
    if defined _src if "%_src%"=="%~3" ( ping -n 5 127.0.0.1 >nul & exit )
    ping -n 2 127.0.0.1 >nul
    goto :xw_loop


:askExclude
    @REM %1 = variavel que recebe 1 (excluir) ou 0 (manter) | %2 = nome do app | %3 = ID do app no XML
    set "_mTitle=Excluir %~2?"
    set "_mFoot="
    set "_mOpts="
    @REM "Manter" vem primeiro: o Enter sozinho mantem o app (instala). Os codigos nao mudam: 1 = excluir, 2 = manter.
    call :addOpt M "Manter"  2
    call :addOpt E "Excluir" 1
    call :arrowMenu
    if %errorlevel%==1 (
        set "%~1=1"
        >> Configuration.partial echo       ^<ExcludeApp ID="%~3" /^>
    ) else (
        set "%~1=0"
    )
    goto :eof


:setUpInstaller
    title Verificando arquivo existente...
    @REM Remove o cliente C2R antigo POR INTEIRO. Apagar so os arquivos que nao estao em uso (del /S /Q com o servico
    @REM rodando) deixa o cliente incompleto e o setup falha com o erro 0-2031 (0xC06D007E, modulo nao encontrado).
    @REM Por isso o servico e os processos sao encerrados antes e a pasta e removida com rd /s /q.
    net stop ClickToRunSvc /y >nul 2>&1
    taskkill /f /im OfficeClickToRun.exe >nul 2>&1
    taskkill /f /im OfficeC2RClient.exe >nul 2>&1
    if exist "%PROGRAMFILES%\Common Files\microsoft shared\ClickToRun" rd /s /q "%PROGRAMFILES%\Common Files\microsoft shared\ClickToRun" 2>nul

    call :showInfo "Verificando arquivo existente..."
    timeout /t 1 > NUL
    
    cls
    dir setup.exe > NUL 2>NUL
    if %ERRORLEVEL%==0 (
        echo.
        echo.
        echo.
        call :LC %c7% "Instalador local" %c2% " encontrado." %c6% " Atualizando..."
        echo.
        echo.
        del /F /Q setup.exe > NUL
        goto :downloadSetup
    ) else (
        call :showInfo "Baixando o instalador do Office..."
        goto :downloadSetup
    )

:downloadSetup
    TITLE Conectando...
    call :showInfo "Conectando ao servidor da MICROSOFT..." %c8%
    timeout /t 2 > NUL

    call :netCheck
    if "%_net%"=="1" (
        call :showInfo "Conectado." %c2%
        timeout /t 1 > NUL
    )

    call :download "https://officecdn.microsoft.com/pr/wsus/setup.exe" "%~dp0bin\setup.exe"
    if not exist "%~dp0bin\setup.exe" goto :downloadFail
    for %%S in ("%~dp0bin\setup.exe") do if %%~zS LSS 1000000 goto :downloadFail

    call :showInfo "Download finalizado com sucesso." %cA%
    timeout /t 1 > NUL
    GOTO :Install


:netCheck
    @REM Sonda de conectividade apenas informativa; o download Ç tentado de
    @REM qualquer forma. N«O usar 'ping | find "TTL="': a resposta IPv6 n∆o traz
    @REM "TTL=" e o texto do ping muda conforme o idioma do Windows.
    set "_net=0"
    where curl >nul 2>&1 && curl -s -f -I -L --connect-timeout 8 --max-time 20 "https://officecdn.microsoft.com/pr/wsus/setup.exe" >nul 2>&1 && set "_net=1"
    if "%_net%"=="1" goto :eof
    ping -n 1 -w 4000 officecdn.microsoft.com >nul 2>&1 && set "_net=1"
    goto :eof
    
:downloadFail
    CLS
    call :showError "Falha ao baixar o setup.exe. Verifique sua conex∆o com a internet."
    call :LC %c7% "Deseja tentar novamente? [S/N]"
    CHOICE /C SN /N
    IF ERRORLEVEL 2 GOTO :cleanUp
    IF ERRORLEVEL 1 GOTO :downloadSetup

:Install
    title Instalando Office
    if not exist "%~dp0bin\setup.exe" goto :installError
    call :showInfo "Iniciando a instalaá∆o do Office..."
    timeout /t 2 > NUL
    GOTO :aWait 


:aWait
    cls & echo.
    call :center "Instalando o Office. Isso pode levar v†rios minutos..." fill
    call :L "44;37m" "%_ctr%"
    echo.
    call :LC %c6% "Aguarde a conclus∆o; n∆o feche esta janela."
    echo.
    "%~dp0bin\setup.exe" /configure "%~dp0bin\Configuration.xml"

    set /a "_w=0"


:aWaitStart
    call :locateOffice
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
    call :locateOffice
    if exist "%WRD%" goto :verifyInstallation
    set /a "_f+=1"
    if %_f% GEQ 12 goto :installError
    timeout /t 5 >NUL
    goto :aWaitConfirm


:locateOffice
    @REM Office 32-bit em Windows 64-bit fica em "Program Files (x86)", e o 64-bit em "Program Files".
    @REM Define _O16 e WRD/EXC/PPT conforme a pasta onde o Word realmente estiver (usado na espera pela
    @REM instalacao e na verificacao; sem isso, uma instalacao 32-bit bem sucedida era dada como erro).
    set "_O16=%PROGRAMFILES%\Microsoft Office\root\Office16"
    if not exist "%_O16%\WINWORD.EXE" if exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\WINWORD.EXE" set "_O16=%ProgramFiles(x86)%\Microsoft Office\root\Office16"
    set "WRD=%_O16%\WINWORD.EXE"
    set "EXC=%_O16%\EXCEL.EXE"
    set "PPT=%_O16%\POWERPNT.EXE"
    goto :eof


:verifyInstallation
    call :locateOffice
    cls & echo.
    call :LC %c7% "Verificando instalaá∆o do Office..." & timeout /t 2 > NUL

    if not exist "%WRD%" goto :installError
    if not exist "%EXC%" goto :installError
    if not exist "%PPT%" goto :installError
    call :purgeExcludedApps
    goto :activate


:purgeExcludedApps
    @REM O C2R das builds atuais ignora <ExcludeApp ID="Publisher"> no
    @REM O365ProPlusRetail: a exclusao e gravada no registro, mas o instalador
    @REM entrega o MSPUB.EXE e cria atalho e App Path assim mesmo.
    @REM Aqui removemos os pontos de entrada dos apps que o XML pediu excluir
    @REM e que ainda assim vieram instalados.
    if not exist "%~dp0bin\Configuration.xml" goto :eof
    call :locateOffice

    call :purgeApp Publisher MSPUB.EXE    Publisher
    call :purgeApp Access    MSACCESS.EXE Access
    call :purgeApp OneNote   ONENOTE.EXE  OneNote
    call :purgeApp Outlook   OUTLOOK.EXE  Outlook

    goto :eof


:purgeApp
    @REM %1 = ID usado no ExcludeApp | %2 = executavel | %3 = nome do atalho
    findstr /i /r /c:"ExcludeApp ID=.%~1." "%~dp0bin\Configuration.xml" >nul 2>&1 || goto :eof
    if not exist "%_O16%\%~2" goto :eof

    cls & echo.
    call :LC %c7% "Removendo " %cA% "%~3" %c7% " ignorado pelo C2R..."

    del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\%~3.lnk" >nul 2>&1
    del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\%~3.lnk" >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%~2" /f >nul 2>&1

    if /i "%~1"=="Publisher" (
        for %%# in (Publisher.Document.16 Publisher.Template.16 Publisher.MacroEnabledDocument.16) do reg delete "HKCR\%%#" /f >nul 2>&1
        for %%# in (.pub .pubhtml .pubmhtml) do (
            reg delete "HKCR\%%#" /f >nul 2>&1
            reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\%%#" /f >nul 2>&1
        )
    )

    @REM Renomear em vez de apagar: o C2R nao acusa corrupcao e da para reverter.
    ren "%_O16%\%~2" "%~2.excluded" >nul 2>&1

    timeout /t 1 /nobreak >nul
    goto :eof


:activate
    cls & echo.
    call :LC %c7% "Instalaá∆o verificada. Ativando Office via " %c2% "MASSGRAVE" %c7% "..."
    timeout /t 2 > NUL

    cls & echo.
    powershell -Command "irm https://get.activated.win | iex"

    goto :cleanUp


:installError
    cls
    call :showError "Ocorreu um erro durante a instalaá∆o do Office. Tente novamente."
    call :LC %c7% "Tentar novamente? [S/N]"
    choice /c sn /n >nul
    
    if ERRORLEVEL 2 goto :cleanUp
    if ERRORLEVEL 1 goto :setUpInstaller


:uninstallOffice
    title Desinstalando Office
    
    call :ensureBin
    
    call :showInfo "Desinstalando a vers∆o existente do Office..."
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
        @REM Altura = linhas de _mOpts (ver :menuOpts) + rodape + folga; se faltar, a tela rola e o menu deixa residuos.
        mode con: cols=70 lines=26
        set _er=0
        set _pt=
        call :Hdr
        if defined _psver (
            call :menuOpts
            call :arrowMenu
            set _er=!ERRORLEVEL!
            cls & echo.
            call :LC %c7% "Aguarde..."
            goto :menuDispatch
        )
        cls & echo.
        call :LC %cC% "[1]" %c7% " Limpar TODOS"
        if %winbuild% GEQ 7600 (
            call :LC %cC% "[2]" %c7% " Limpar Office C2R  " %cA% "%dOCTR%"
            call :LC %cC% "[3]" %c7% " Limpar Office 2016 " %cA% "%dOM16%"
            call :LC %cC% "[4]" %c7% " Limpar Office 2013 " %cA% "%dOM15%"
        )
        call :LC %cC% "[5]" %c7% " Limpar Office 2010 " %cA% "%dOM14%"
        call :LC %cC% "[6]" %c7% " Limpar Office 2007 " %cA% "%dOM12%"
        call :LC %cC% "[7]" %c7% " Limpar Office 2003 " %cA% "%dOM11%"
        if %winbuild% GEQ 10240 ( 
            call :LC %cC% "[8]" %c7% " Limpar Office UWP  " %cA% "%dOUWP%"
        )
        if %winbuild% GEQ 7600 (
            call :LC %cC% "[9]" %c7% " Voltar ao Menu Principal"
            echo.
            call :LC %c7% "Office 2016 e posteriores"
            echo.
            call :LC %cC% "[L]" %c7% " Limpar Licenáas vNext " %cA% "%dONXT%"
            call :LC %cC% "[A]" %c7% " Apagar todas as Licenáas"
            call :LC %cC% "[R]" %c7% " Resetar Licenáas C2R"
            call :LC %cC% "[D]" %c7% " Desinstalar todas as Chaves"
            call :LC %cC% "[0]" %c7% " SAIR"
        )
        echo.
        call :LC %c7% "[" %cA% "<" %c7% "] Instalaá∆o detectada."
        echo.

        if %_wxp% equ 0 (
            choice /c 123456789LARD0 /n /m "> "
            set _er=!ERRORLEVEL!
            cls & echo.
            call :LC %c7% "Aguarde..."
        ) else (
            call :center "Selecione uma opá∆o e pressione Enter, ou 0 para sair: "
            set /p _pt="%_ctr%"
        )

        if defined _pt (
            if /i "%_pt%"=="0" set _pt=14
            if /i "%_pt%"=="D" set _pt=13
            if /i "%_pt%"=="R" set _pt=12
            if /i "%_pt%"=="A" set _pt=11
            if /i "%_pt%"=="L" set _pt=10
            set _er=!_pt!
        )

    :menuDispatch
        @REM Numeraá∆o alinhada a 'choice /c 123456789LARD0': L=10, A=11,
        @REM R=12, D=13, 0=14. Antes estava deslocada em 1, ent∆o cada letra
        @REM executava a aá∆o da opá∆o seguinte, [D] sa°a e [0] n∆o sa°a.
        if "%_er%"=="14" goto :eof

        if %winbuild% GEQ 7600 (
            if "%_er%"=="13" goto :KeysU
            if "%_er%"=="12" goto :LcnsT
            if "%_er%"=="11" goto :LcnsR
            if "%_er%"=="10" goto :LcnsC
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
        call :LC %c6% "[1]" %c7% " Iniciar a operaá∆o"
        if %winbuild% GEQ 7600 (
            call :LC %c6% "[2]" %c7% " Office C2R:  %aOCTR%"
            call :LC %c6% "[3]" %c7% " Office 2016: %aOM16%"
            call :LC %c6% "[4]" %c7% " Office 2013: %aOM15%"
        )
        call :LC %c6% "[5]" %c7% " Office 2010: %aOM14%"
        call :LC %c6% "[6]" %c7% " Office 2007: %aOM12%"
        call :LC %c6% "[7]" %c7% " Office 2003: %aOM11%"
        if %winbuild% GEQ 10240 (
            call :LC %c6% "[8]" %c7% " Office UWP:  %aOUWP%"
        )
        call :LC %c6% "[9]" %c7% " Voltar ao Menu Anterior"
        call :LC %c6% "[0]" %c7% " SAIR"
        echo.
        call :LC %c7% "Aviso: Limpar todos pode demorar."
        echo.
        
        if %_wxp% equ 0 (
            choice /c 1234567890 /n /m "> "
            set _er=!ERRORLEVEL!
        ) else (
            call :center "Selecione uma opá∆o e pressione Enter, ou 0 para sair: "
            set /p _pt="%_ctr%"
        )

        if defined _pt (
            if /i "%_pt%"=="0" set _pt=10
            set _er=!_pt!
        )
        
        @REM 'choice /c 1234567890' devolve 10 na tecla 0; sem este caso a
        @REM opá∆o [0] SAIR apenas recarregava o menu.
        if "%_er%"=="10" goto :eof
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


    :menuOpts
        @REM Opcoes do menu de limpeza: call :addOpt "tecla" "texto" [codigo] [sufixo].
        @REM O codigo e o ERRORLEVEL devolvido (mesma numeracao do antigo 'choice /c 123456789LARD0').
        set "_mTitle="
        set "_mFoot=[<] Instalaá∆o detectada."
        set "_mOpts="

        call :addOpt -
        call :addOpt - "Desinstalar Office"
        call :addOpt -
        call :addOpt 1 "Limpar TODOS" 1
        if %winbuild% GEQ 7600 (
            call :addOpt 2 "Limpar Office C2R"  2 "%dOCTR%"
            call :addOpt 3 "Limpar Office 2016" 3 "%dOM16%"
            call :addOpt 4 "Limpar Office 2013" 4 "%dOM15%"
        )
        call :addOpt 5 "Limpar Office 2010" 5 "%dOM14%"
        call :addOpt 6 "Limpar Office 2007" 6 "%dOM12%"
        call :addOpt 7 "Limpar Office 2003" 7 "%dOM11%"
        if %winbuild% GEQ 10240 call :addOpt 8 "Limpar Office UWP" 8 "%dOUWP%"
        if %winbuild% GEQ 7600 (
            call :addOpt 9 "Voltar ao Menu Principal" 9
            call :addOpt -
            call :addOpt - "Office 2016 e posteriores"
            call :addOpt -
            call :addOpt L "Limpar Licenáas vNext"       10 "%dONXT%"
            call :addOpt A "Apagar todas as Licenáas"    11
            call :addOpt R "Resetar Licenáas C2R"        12
            call :addOpt D "Desinstalar todas as Chaves" 13
        )
        call :addOpt -
        call :addOpt 0 "SAIR" 14
        goto :eof


    :addOpt
        @REM %1=tecla ("-" = cabecalho/linha em branco) | %2=texto | %3=codigo | %4=sufixo
        if defined _mOpts ( set "_mOpts=%_mOpts%;%~1|%~2|%~3|%~4" ) else set "_mOpts=%~1|%~2|%~3|%~4"
        goto :eof


    :Hdr
        cls
        echo.
        goto :eof


    :sOALL
        call :Hdr

        cls
        echo.
        call :LC %c7% "Desinstalando chaves de produto..."
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
            set "msg=Problemas ao localizar o PowerShell."
            goto :theEnd
        )

        call :rOUWP
        set "msg=Finalizado."
        goto :cleanUp


    :rOCTR
        if exist "!_file!" (
            cls
            echo.
            call :LC %c7% "Executando OfficeClickToRun.exe..."
            
            %_Nul3% call :CloseC2R
            %_Nul3% start "" /WAIT "!_file!" platform=%_plat% productstoremove=AllProducts displaylevel=False
        )
        
        if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" (
            cls
            echo.
            call :LC %c7% "Executando OfficeClickToRun.exe..."
            
            %_Nul3% call :CloseC2R
            %_Nul3% start "" /WAIT "!_fil2!" platform=%_plat% productstoremove=AllProducts displaylevel=False
        )
        
        cls
        echo.
        call :LC %c7% "Limpando Office C2R..."
        
        for %%A in ( 16,19,21,24 ) do call :cKpp %%A
        if %_O15CTR% equ 1 call :cKpp 15
        %_cscript% OffScrubC2R.vbs ALL /OFFLINE
        %_Nul3% call :vNextDir
        %_Nul3% call :officeREG 16
        goto :eof


    :CloseC2R
        title Encerrando processos do Office
        
        cls & echo.
        call :LC %c7% "Encerrando processos relacionados ao Office..."

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
        if %_pwsh% equ 0 ( set "msg=PowerShell Ç necess†rio para baixar a pasta bin." & goto :theEnd )

        cls & echo.
        call :LC %c7% "Pasta 'bin' incompleta. Baixando ferramentas de remoá∆o do"
        call :LC %c7% "Office a partir do abbodi1406/BatUtil..."

        if not exist "!_work!" md "!_work!"
        %_psc% "[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor 3072; $d='!_work!'; $u='https://raw.githubusercontent.com/abbodi1406/BatUtil/master/OfficeScrubber/bin/'; $wc=New-Object Net.WebClient; foreach($f in 'CleanOffice.txt','OffScrub03.vbs','OffScrub07.vbs','OffScrub10.vbs','OffScrubC2R.vbs','OffScrub_O15msi.vbs','OffScrub_O16msi.vbs'){ try{$wc.DownloadFile($u+$f,(Join-Path $d $f))}catch{} }"
        set "_need=0"
        
        for %%# in (
            OffScrubC2R.vbs OffScrub_O16msi.vbs OffScrub_O15msi.vbs OffScrub10.vbs OffScrub07.vbs OffScrub03.vbs CleanOffice.txt
        ) do if not exist "!_work!\%%#" set "_need=1"
        
        if !_need! equ 1 ( set "msg=Falha ao baixar a pasta bin. Verifique a conex∆o com a internet." & goto :theEnd )
        
        cls & echo.
        call :LC %c7% "Ferramentas baixadas com sucesso."
        timeout /t 1 > NUL
        goto :eof


    :rOUWP
        cls
        echo.
        call :LC %c7% "Removendo aplicativos UWP Office..."
        %_Nul3% %_psc% "Get-AppXPackage -Name '*Microsoft.Office.Desktop*' | Foreach {Remove-AppxPackage $_.PackageFullName}"
        %_Nul3% %_psc% "Get-AppXProvisionedPackage -Online | Where DisplayName -Like '*Microsoft.Office.Desktop*' | Remove-AppXProvisionedPackage -Online"
        @title Office Scrubber %uivr%
        goto :eof


    :rOM16
        cls
        echo.
        call :LC %c7% "Limpando Office 2016 MSI..."
        call :cKpp 16
        %_cscript% OffScrub_O16msi.vbs %_para%
        %_Nul3% call :officeREG 16
        goto :eof


    :rOM15
        cls
        echo.
        call :LC %c7% "Limpando Office 2013 MSI..."
        call :cKpp 15
        %_cscript% OffScrub_O15msi.vbs %_para%
        %_Nul3% call :officeREG 15
        goto :eof


    :rOM14
        cls
        echo.
        call :LC %c7% "Limpando Office 2010..."
        call :cK14
        %_cscript% OffScrub10.vbs %_para%
        %_Nul3% call :officeREG 14
        goto :eof


    :rOM12
        cls
        echo.
        call :LC %c7% "Limpando Office 2007..."
        %_cscript% OffScrub07.vbs %_para%
        %_Nul3% call :officeREG 12
        goto :eof


    :rOM11
        cls
        echo.
        call :LC %c7% "Limpando Office 2003..."
        %_cscript% OffScrub03.vbs %_para%
        %_Nul3% call :officeREG 11
        goto :eof


        :cSPP
            cls
            echo.
            call :LC %c7% "Removendo Licenáas do Office..."
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
            call :LC %c7% "Atualizando Licenáas do Windows Insider Preview..."
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
        call :LC %c7% "Limpando Licenáas vNext..."
        %_Nul3% call :vNextDir
        %_Nul3% call :vNextREG
        set "msg=Finalizado."
        goto :cleanUp


    :KeysU
        call :Hdr

        call :showInfo "Desinstalando Chaves de Produto..." %c2%
        timeout /t 1 > NUL
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
        call :showWarn "Resetando Licenáas do Office C2R..."
        timeout /t 1 > NUL
        
        if %_O16CTR% equ 0 (
            call :showError "Office ClickToRun n∆o detectado." & timeout /t 3 >nul
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
            call :showError "N∆o foi poss°vel detectar o integrator.exe" & timeout /t 3 >nul
            goto :verifyExistingInstallation
        )

        for /f "tokens=8 delims=\" %%a in ( 'reg.exe query "%_PRIDs%" /f ".16" /k %_Nul6% ^| find /i "ClickToRun"' ) do (
            if not defined _SKUs ( set "_SKUs=%%a" ) else ( set "_SKUs=!_SKUs!,%%a" )
        )

        if not defined _SKUs (
            call :showError "N∆o foi poss°vel detectar produtos Office instalados originalmente." & timeout /t 3 >nul
            goto :verifyExistingInstallation
        )

        call :cSPP
        call :Hdr
        call :showWarn "Instalando Licenáas do Office C2R..."
        timeout /t 1 > NUL        
        cls
        echo.
        call :LC %c7% "Instalando Licenáas do Office C2R..."
        
        for %%a in ( %_SKUs% ) do (
            "!_Integrator!" /R /License PRIDName=%%a.16 PackageGUID="%_GUID%" PackageRoot="!_InstallRoot!" %_Nul1%
        )

        set "msg=Finalizado."
        goto :cleanUp


    :E_Admin
        cls
        call :center "%_err%"
        echo %_ctr%
        call :center "Este script precisa ser iniciado como administrador."
        echo %_ctr%
        call :center "Para isso, clique com o bot∆o direito neste script e selecione 'Executar como administrador'"
        echo %_ctr%
        goto :cleanUp


    :E_VBS
        cls
        call :center "%_err%"
        echo %_ctr%
        call :center "Motor VBScript inexistente."
        echo %_ctr%
        call :center "Ele Ç necess†rio para que este script funcione."
        echo %_ctr%
        goto :cleanUp


    :E_WSH
        cls
        call :center "%_err%"
        echo %_ctr%
        call :center "O Windows Script Host est† desabilitado."
        echo %_ctr%
        call :center "Ele Ç necess†rio para que este script funcione."
        echo %_ctr%
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
    call :showError "%msg%"
    timeout /t 5 > NUL
    EXIT


:cleanUp
    mode con: cols=70 lines=7
    if defined msg call :showInfo "%msg%" %cA%

    %_Nul3% call :CloseC2R 2>nul
    del /f /q "setup.exe" 2>nul
    del /f /q "Configuration.xml" 2>nul
    del /f /q "Configuration.partial" 2>nul

    call :showWarn "Excluindo arquivos tempor†rios."
    timeout /t 1 > NUL
    
    del /s /f /q "%TEMP%\*" 2>nul
    del /s /f /q "C:\Windows\Temp\*" 2>nul
    del /s /f /q "C:\Windows\Prefetch\*" 2>nul

    for /d %%p in ( "%TEMP%\*" ) do rmdir /s /q "%%p" 2>nul
    for /d %%p in ( "C:\Windows\Temp\*" ) do rmdir /s /q "%%p" 2>nul
    for /d %%p in ( "C:\Windows\Prefetch\*" ) do rmdir /s /q "%%p" 2>nul

    cls
    goto :endScript


:L
    @REM Pares cor/texto. Percorre com SHIFT (um 'for' sobre %* descartaria textos com ? ou *).
    setlocal EnableDelayedExpansion
    set "_LINE="

    :L_next
    if "%~1"=="" goto :L_print
    set "_LINE=!_LINE!!ESC![%~1%~2"
    shift & shift
    goto :L_next

    :L_print
    echo !_LINE!!ESC![0m
    endlocal
    exit /b


:arrowMenu
    @REM Menu navegavel por setas (Cima/Baixo + Enter) ou pela letra da opcao.
    @REM Entrada: _mOpts ("Tecla|Texto|Codigo|Sufixo;..."; Codigo e Sufixo opcionais; Tecla "-" = cabecalho/linha em branco),
    @REM _mTitle, _mTitleColor (codigo ANSI) e _mFoot opcionais. Saida: ERRORLEVEL = Codigo da opcao (ou seu indice 1..n).
    @REM Sem PowerShell 3+, cai no choice (teclas de letra apenas).
    if defined _psver goto :arrowMenuPS

    setlocal EnableDelayedExpansion
    set "_keys="
    cls & echo.
    call :LC %cA% "!_mTitle!"
    echo.
    for %%o in ("%_mOpts:;=" "%") do for /f "tokens=1,2 delims=|" %%k in (%%o) do (
        call :LC %cC% "[%%k]" %c7% " %%l"
        set "_keys=!_keys!%%k"
    )
    choice /C !_keys! /N
    endlocal & exit /b %errorlevel%


    :arrowMenuPS
        @REM Script PowerShell montado em partes (uma instrucao por 'set') e executado de uma vez.
        @REM Le as opcoes de _mOpts (Tecla|Texto|Codigo|Sufixo;...)
        set "_ps=$o=@($env:_mOpts.Split(';')|ForEach-Object{$p=$_.Split('|');[pscustomobject]@{K=$p[0];T=$p[1];C=$p[2];S=$p[3]}});"
        @REM Largura da janela, indices selecionaveis (sem cabecalhos '-') e selecao atual
        set "_ps=%_ps%$w=[Console]::WindowWidth;$sel=@(0..($o.Count-1)|Where-Object{$o[$_].K -ne '-'});$s=0;"
        @REM Recuo comum da lista (bloco centralizado) e funcao P = recuo para centralizar um texto
        set "_ps=%_ps%$mx=($o|ForEach-Object{('['+$_.K+'] '+$_.T+' '+$_.S).Length}|Measure-Object -Maximum).Maximum;"
        set "_ps=%_ps%function P($n){' '*[Math]::Max(0,[int](($w-$n)/2))};$bp=P $mx;"
        @REM Ln = linha centralizada e preenchida ate a borda (apaga restos do redesenho)
        set "_ps=%_ps%function Ln($t,$c){$pp=P $t.Length;Write-Host ($pp+$t+(' '*[Math]::Max(0,$w-$pp.Length-$t.Length-1))) -ForegroundColor $c};"
        @REM Pick = encerra devolvendo o codigo da opcao $i (ou o indice+1, se nao houver codigo)
        set "_ps=%_ps%function Pick($i){$x=$o[$i];[Console]::CursorVisible=$true;if($x.C){exit [int]$x.C}else{exit ($i+1)}};"
        @REM Altura necessaria (linhas da lista + titulo + rodape + folga): se a janela for menor, a tela rola
        @REM e o redesenho por posicao do cursor deixa residuos; entao a janela e ampliada.
        set "_ps=%_ps%$need=$o.Count+$(if($env:_mTitle){2}else{0})+$(if($env:_mFoot){2}else{0})+3;"
        set "_ps=%_ps%if([Console]::WindowHeight -lt $need){try{[Console]::SetBufferSize($w,$need);[Console]::SetWindowSize($w,$need)}catch{}};"
        @REM Tela inicial: titulo opcional, centralizado; cor ANSI em _mTitleColor (padrao laranja 38;5;208)
        set "_ps=%_ps%Clear-Host;Write-Host;if($env:_mTitle){$e=[char]27;$tc=$env:_mTitleColor;if(-not $tc){$tc='38;5;208'};$pp=P $env:_mTitle.Length;Write-Host ($pp+$e+'['+$tc+'m'+$env:_mTitle+$e+'[0m');Write-Host};"
        set "_ps=%_ps%$top=[Console]::CursorTop;[Console]::CursorVisible=$false;"
        @REM Laco principal: redesenha a lista a cada tecla
        set "_ps=%_ps%while($true){[Console]::SetCursorPosition(0,$top);"
        @REM   cabecalhos e linhas em branco
        set "_ps=%_ps%for($i=0;$i -lt $o.Count;$i++){$x=$o[$i];if($x.K -eq '-'){Ln $x.T 'Gray';continue};"
        @REM   opcao: selecionada (fundo claro) ou normal ([tecla] vermelha) + sufixo verde
        set "_ps=%_ps%$t='['+$x.K+'] '+$x.T;Write-Host $bp -NoNewline;"
        set "_ps=%_ps%if($i -eq $sel[$s]){Write-Host $t -ForegroundColor Black -BackgroundColor White -NoNewline}"
        set "_ps=%_ps%else{Write-Host ('['+$x.K+']') -ForegroundColor Red -NoNewline;Write-Host (' '+$x.T) -NoNewline};"
        set "_ps=%_ps%$u=$t.Length;if($x.S){Write-Host (' '+$x.S) -ForegroundColor Green -NoNewline;$u+=1+$x.S.Length};"
        set "_ps=%_ps%Write-Host (' '*[Math]::Max(0,$w-$bp.Length-$u-1))};"
        @REM   rodape opcional
        set "_ps=%_ps%if($env:_mFoot){Ln '' 'Gray';$f=$env:_mFoot;$pp=P $f.Length;$i=$f.IndexOf('<');"
        set "_ps=%_ps%Write-Host ($pp+$f.Substring(0,$i)) -NoNewline;Write-Host '<' -ForegroundColor Green -NoNewline;"
        set "_ps=%_ps%Write-Host ($f.Substring($i+1)+(' '*[Math]::Max(0,$w-$pp.Length-$f.Length-1)))};"
        @REM   teclas: setas movem a selecao, Enter confirma, letra/numero escolhe direto
        set "_ps=%_ps%$k=[Console]::ReadKey($true);"
        set "_ps=%_ps%switch($k.Key){'UpArrow'{$s=($s+$sel.Count-1)%%$sel.Count}'DownArrow'{$s=($s+1)%%$sel.Count}'Enter'{Pick $sel[$s]}"
        set "_ps=%_ps%default{foreach($i in $sel){if($o[$i].K -eq $k.KeyChar.ToString().ToUpper()){Pick $i}}}}}"
        powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "%_ps%"
        set "_rc=%errorlevel%"
        @REM 'set "var="' zera o ERRORLEVEL; por isso o codigo e guardado antes de limpar.
        set "_mTitle=" & set "_mTitleColor=" & set "_mFoot="
        exit /b %_rc%


:showInfo
    @REM %1 = texto | %2 = cor opcional (padrao: branco)
    set "_c=%~2"
    if not defined _c set "_c=40;37m"
    call :center "%~1"
    cls & echo.
    echo.
    echo.
    call :L "%_c%" "%_ctr%"
    echo.
    echo.
    goto :eof


:showWarn
    @REM %1 = texto
    call :center "%~1"
    cls & echo.
    echo.
    echo.
    call :L "40;93m" "%_ctr%"
    echo.
    echo.
    goto :eof


:showError
    @REM %1 = texto
    call :center "ERRO" fill
    set "_ban=%_ctr%"
    call :center "%~1"
    cls & echo.
    call :L "44;31m" "%_ban%"
    echo.
    echo %_ctr%
    echo.
    goto :eof


:LC
    @REM Igual a :L (pares cor/texto), mas centralizada na largura da janela (_cols).
    setlocal EnableDelayedExpansion
    set "_cols=70"
    set "_tot=0"

    :LC_next
    if "%~1"=="" goto :LC_pad
    set "_s=%~2#"
    set "_n=0"
    for %%P in (64 32 16 8 4 2 1) do if not "!_s:~%%P,1!"=="" set /a "_n+=%%P" & set "_s=!_s:~%%P!"
    set /a "_tot+=_n"
    shift & shift
    goto :LC_next

    :LC_pad
    set /a "_l=(_cols-_tot)/2"
    set "_sp="
    for /l %%i in (1,1,!_l!) do set "_sp=!_sp! "
    call :L "40;37m" "!_sp!" %*
    goto :eof


:center
    @REM %1 = texto | %2 = "fill" completa a direita com espacos (faixa colorida)
    @REM Devolve em _ctr o texto centralizado na largura da janela (_cols).
    setlocal EnableDelayedExpansion
    set "_cols=70"
    set "_t=%~1"
    set "_s=!_t!#"
    set "_n=0"
    for %%P in (64 32 16 8 4 2 1) do if not "!_s:~%%P,1!"=="" set /a "_n+=%%P" & set "_s=!_s:~%%P!"
    set /a "_l=(_cols-_n)/2, _r=_cols-_n-_l"
    set "_sp="
    for /l %%i in (1,1,!_l!) do set "_sp=!_sp! "
    set "_rp="
    if "%~2"=="fill" for /l %%i in (1,1,!_r!) do set "_rp=!_rp! "
    endlocal & set "_ctr=%_sp%%_t%%_rp%"
    goto :eof


:endScript
    call :showInfo "Limpeza finalizada. Fechando terminal." %c2%
    timeout /t 1 > NUL
    exit
