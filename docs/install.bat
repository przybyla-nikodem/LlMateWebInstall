@echo off
setlocal enabledelayedexpansion

REM === Krok 1: Import certyfikatu ===
set CERT_FILE=cert.cer
if not exist "%CERT_FILE%" (
    echo ❌ Nie znaleziono pliku %CERT_FILE%
    exit /b 1
)

echo 🔐 Import certyfikatu do TrustedPeople...
certutil -user -addstore TrustedPeople "%CERT_FILE%"
if %errorlevel% neq 0 (
    echo ❌ Błąd przy importowaniu certyfikatu
    exit /b %errorlevel%
)
echo ✅ Certyfikat dodany.

REM === Krok 2: Sprawdzenie obecności .NET 8.0 Desktop Runtime ===
echo 🔍 Sprawdzanie obecności .NET 8.0 Desktop Runtime...
for /f "tokens=*" %%i in ('dotnet --list-runtimes ^| findstr /C:"Microsoft.WindowsDesktop.App 8.0"') do (
    set FOUND_RUNTIME=1
)

if not defined FOUND_RUNTIME (
    echo ⬇️ .NET 8.0 Desktop Runtime nie znaleziono. Pobieranie instalatora...
    set RUNTIME_URL=https://download.visualstudio.microsoft.com/download/pr/7d7dceec-b60f-4bc1-b37d-e3241bbedac1/f7c8306b307b03c4be663e93521f12a4/windowsdesktop-runtime-8.0.0-win-x64.exe
    set RUNTIME_INSTALLER=windowsdesktop-runtime-8.0.0-win-x64.exe

    powershell -Command "Invoke-WebRequest -Uri '%RUNTIME_URL%' -OutFile '%RUNTIME_INSTALLER%'"
    if exist "%RUNTIME_INSTALLER%" (
        echo ▶️ Uruchamianie instalatora .NET Runtime...
        start /wait "" "%RUNTIME_INSTALLER%"
    ) else (
        echo ❌ Nie udało się pobrać instalatora.
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
    set OLLAMA_URL=https://ollama.com/download/OllamaSetup.exe
    set OLLAMA_INSTALLER=OllamaSetup.exe

    powershell -Command "Invoke-WebRequest -Uri '%OLLAMA_URL%' -OutFile '%OLLAMA_INSTALLER%'"
    if exist "%OLLAMA_INSTALLER%" (
        echo ▶️ Uruchamianie instalatora Ollama...
        start /wait "" "%OLLAMA_INSTALLER%"
    ) else (
        echo ❌ Nie udało się pobrać instalatora Ollama.
        exit /b 1
    )
)

REM === Krok 4: Pobranie modelu Ollama podanego przez użytkownika ===
set /p MODEL_NAME=📦 Podaj nazwę modelu do pobrania (np. gemma:2b): 

if "%MODEL_NAME%"=="" (
    echo ❌ Nie podano nazwy modelu. Pomijam pobieranie.
    goto :after_pull
)

echo ⬇️ Pobieranie modelu: %MODEL_NAME% ...
ollama pull %MODEL_NAME%

REM Czekaj aż model pojawi się w liście
echo 🕒 Oczekiwanie na zakończenie pobierania...
:wait_loop
timeout /t 5 >nul
for /f %%M in ('ollama list ^| findstr /C:"%MODEL_NAME%"') do (
    echo ✅ Model %MODEL_NAME% jest gotowy.
    goto :after_pull
)
goto :wait_loop

:after_pull


REM === Krok 5: Uruchomienie pliku .appinstaller===
for %%f in (*.appinstaller) do (
    set appinstaller_FILE=%%f
    goto :foundmsix
)

:foundmsix
if defined MSIX_FILE (
    echo 🚀 Uruchamianie instalatora AppInstaller: %appinstaller_FILE%
    start "" "%appinstaller_FILE%"
) else (
    echo ❌ Nie znaleziono pliku .msix w folderze.
    exit /b 1
)

exit /b 0
