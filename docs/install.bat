@echo off
setlocal enabledelayedexpansion

REM 🔧 Ustaw katalog skryptu jako bieżący
cd /d "%~dp0"


REM === Krok 1: Import certyfikatu do magazynu systemowego ===
set "CERT_FILE=cert.cer"
if not exist "%CERT_FILE%" (
    echo ❌ Nie znaleziono pliku %CERT_FILE%
    pause
    exit /b 1
)

echo 🔐 Import certyfikatu do TrustedPeople (komputer lokalny)...
certutil -addstore TrustedPeople "%CERT_FILE%"
if %errorlevel% neq 0 (
    echo ❌ Błąd przy dodawaniu certyfikatu do TrustedPeople
    pause
    exit /b 1
)

echo 🔐 Import certyfikatu do Trusted Root Certification Authorities (komputer lokalny)...
certutil -addstore Root "%CERT_FILE%"
if %errorlevel% neq 0 (
    echo ❌ Błąd przy dodawaniu certyfikatu do Trusted Root
    pause
    exit /b 1
)

echo ✅ Certyfikat został poprawnie dodany do magazynów systemowych.


REM === Krok 2: Sprawdzenie obecności .NET 8.0 Desktop Runtime ===
echo 🔍 Sprawdzanie obecności .NET 8.0 Desktop Runtime...

where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    set FOUND_RUNTIME=0
) else (
    set FOUND_RUNTIME=0
    for /f "tokens=*" %%i in ('dotnet --list-runtimes ^| findstr /C:"Microsoft.WindowsDesktop.App 8.0"') do (
        set FOUND_RUNTIME=1
    )
)

set "RUNTIME_URL=https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.19/windowsdesktop-runtime-8.0.19-win-x64.exe"
set "RUNTIME_INSTALLER=windowsdesktop-runtime-8.0.19-win-x64.exe"

if %FOUND_RUNTIME%==0 (
    echo ⬇️ .NET 8.0 Desktop Runtime nie znaleziono. Pobieranie instalatora...
    echo 🔽 Pobieranie instalatora .NET Runtime za pomocą curl...
    curl -L -o "%RUNTIME_INSTALLER%" "%RUNTIME_URL%"
    if %errorlevel% neq 0 (
        echo ❌ Nie udało się pobrać instalatora .NET Runtime.
        pause
        exit /b 1
    )
    if exist "%RUNTIME_INSTALLER%" (
        echo ▶️ Uruchamianie instalatora .NET Runtime...
        start /wait "" "%RUNTIME_INSTALLER%"
    ) else (
        echo ❌ Plik instalatora .NET Runtime nie został pobrany.
        pause
        exit /b 1
    )
) else (
    echo ✅ .NET 8.0 Desktop Runtime już zainstalowany.
)

REM === Krok 3: Pobranie i uruchomienie OllamaSetup.exe ===
if exist "%LocalAppData%\Ollama" (
    echo ✅ Ollama jest już zainstalowana.
) else (
    echo ⬇️ Pobieranie instalatora Ollama...
    set "OLLAMA_URL=https://ollama.com/download/OllamaSetup.exe"
    set "OLLAMA_INSTALLER=OllamaSetup.exe"
    echo 🔽 Pobieranie instalatora Ollama za pomocą curl...
    curl -L -o "%OLLAMA_INSTALLER%" "%OLLAMA_URL%"
    if %errorlevel% neq 0 (
        echo ❌ Nie udało się pobrać instalatora Ollama.
        pause
        exit /b 1
    )
    if exist "%OLLAMA_INSTALLER%" (
        echo ▶️ Uruchamianie instalatora Ollama...
        start /wait "" "%OLLAMA_INSTALLER%"
    ) else (
        echo ❌ Plik instalatora Ollama nie został pobrany.
        pause
        exit /b 1
    )
)

REM === Krok 3a: Wyszukaj Ollama.exe dynamicznie ===
set "OLLAMA_DIR=%LocalAppData%\Programs\Ollama"
set "OLLAMA_EXE="

REM szukamy pliku zaczynając od katalogu instalacyjnego
for %%F in ("%OLLAMA_DIR%\ollama*.exe") do (
    set "OLLAMA_EXE=%%F"
)

if not defined OLLAMA_EXE (
    echo ❌ Nie znaleziono Ollama.exe w %OLLAMA_DIR%.
    pause
    exit /b 1
)

echo ✅ Znaleziono Ollama.exe: %OLLAMA_EXE%

REM --- natychmiastowe dodanie katalogu do PATH bieżącej sesji ---
echo %PATH% | find /I "%OLLAMA_DIR%" >nul
if errorlevel 1 (
    set "PATH=%PATH%;%OLLAMA_DIR%"
    echo ✅ Dodano Ollama do PATH bieżącej sesji.
)


REM === Krok 4: Pobranie modelu Ollama ===
set /p MODEL_NAME=📦 Podaj nazwę modelu do pobrania (np. gemma:2b): 

REM jeśli nic nie wpisano, pomijamy pobieranie
if "%MODEL_NAME%"=="" (
    echo ℹ️ Nie podano nazwy modelu. Pomijam pobieranie.
    goto :after_pull
)

echo ⬇️ Pobieranie modelu: %MODEL_NAME% ...
"%OLLAMA_EXE%" pull %MODEL_NAME%

:after_pull


echo ⬇️ Pobieranie modelu: %MODEL_NAME% ...
"%OLLAMA_EXE%" pull %MODEL_NAME%

REM === Krok 5: Uruchomienie pliku .appinstaller ===
set "appinstaller_FILE="
for %%f in (*.appinstaller) do (
    set "appinstaller_FILE=%%f"
    goto found
)
:found
if defined appinstaller_FILE (
    echo 🚀 Uruchamianie instalatora AppInstaller: %appinstaller_FILE%
    start "" "%appinstaller_FILE%"
) else (
    echo ❌ Nie znaleziono pliku .appinstaller w folderze.
    exit /b 1
)

exit /b 0
