@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   Build Script: Abseil + Protobuf
echo   Visual Studio 2022, Debug and Release
echo ==========================================

:: Visual Studio ve mimari
set VSVERSION=Visual Studio 17 2022
set ARCH=x64

:: Abseil yolları
set ABSL_SRC=C:\protobuf\abseil-cpp
set ABSL_BUILD=%ABSL_SRC%\build
set ABSL_INSTALL=C:\protobuf\abseil-install

:: Protobuf yolları
set PROTOBUF_SRC=C:\protobuf\protobuf321
set PROTOBUF_BUILD=%PROTOBUF_SRC%\build

:: Build seçenekleri (varsayılan değerler)
set SKIP_ABSL=1
set SKIP_PROTOBUF=0
set BUILD_SHARED_LIBS=ON
REM - DLL için: set BUILD_SHARED_LIBS=ON
REM - Static LIB için: set BUILD_SHARED_LIBS=OFF

echo.
echo Build Configuration:
echo - Skip Abseil: %SKIP_ABSL%
echo - Skip Protobuf: %SKIP_PROTOBUF%
echo - Build Type: %BUILD_SHARED_LIBS% (ON=DLL, OFF=Static LIB)
echo - Architecture: %ARCH%
echo - Visual Studio: %VSVERSION%
echo.

:: =============================================================================
:: ABSEIL BUILD
:: =============================================================================

if "%SKIP_ABSL%"=="1" (
    echo [INFO] Skipping Abseil build...
    goto :protobuf_build
)

echo ==========================================
echo   Building Abseil-cpp
echo ==========================================

:: Abseil dizinlerinin varlığını kontrol et
if not exist "%ABSL_SRC%" (
    echo [ERROR] Abseil source directory not found: %ABSL_SRC%
    exit /b 1
)

:: Build dizinini temizle ve oluştur
echo [INFO] Preparing Abseil build directory...
if exist "%ABSL_BUILD%" rmdir /s /q "%ABSL_BUILD%"
mkdir "%ABSL_BUILD%"

:: Install dizinini oluştur
if not exist "%ABSL_INSTALL%" mkdir "%ABSL_INSTALL%"

:: Abseil CMake konfigürasyonu
echo [INFO] Configuring Abseil with CMake...
cd /d "%ABSL_BUILD%"

cmake -G "%VSVERSION%" -A %ARCH% ^
    -DCMAKE_INSTALL_PREFIX="%ABSL_INSTALL%" ^
    -DABSL_BUILD_TESTING=OFF ^
    -DABSL_USE_GOOGLETEST_HEAD=OFF ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DABSL_PROPAGATE_CXX_STD=ON ^
    -DBUILD_SHARED_LIBS=%BUILD_SHARED_LIBS% ^
    "%ABSL_SRC%"

if errorlevel 1 (
    echo [ERROR] Abseil CMake configuration failed!
    exit /b 1
)

:: Abseil Debug derleme
echo [INFO] Building Abseil (Debug)...
cmake --build . --config Debug --parallel

if errorlevel 1 (
    echo [ERROR] Abseil Debug build failed!
    exit /b 1
)

:: Abseil Release derleme
echo [INFO] Building Abseil (Release)...
cmake --build . --config Release --parallel

if errorlevel 1 (
    echo [ERROR] Abseil Release build failed!
    exit /b 1
)

:: Abseil kurulum (Debug)
echo [INFO] Installing Abseil Debug to %ABSL_INSTALL%...
cmake --install . --config Debug

if errorlevel 1 (
    echo [ERROR] Abseil Debug installation failed!
    exit /b 1
)

:: Abseil kurulum (Release)
echo [INFO] Installing Abseil Release to %ABSL_INSTALL%...
cmake --install . --config Release

if errorlevel 1 (
    echo [ERROR] Abseil Release installation failed!
    exit /b 1
)

echo [SUCCESS] Abseil build completed successfully!

:: =============================================================================
:: PROTOBUF BUILD
:: =============================================================================

:protobuf_build

if "%SKIP_PROTOBUF%"=="1" (
    echo [INFO] Skipping Protobuf build...
    goto :end
)

echo ==========================================
echo   Building ProtoBuf
echo ==========================================

:: Protobuf dizinlerinin varlığını kontrol et
if not exist "%PROTOBUF_SRC%" (
    echo [ERROR] Protobuf source directory not found: %PROTOBUF_SRC%
    exit /b 1
)

:: Abseil kurulum dizininin varlığını kontrol et
if not exist "%ABSL_INSTALL%" (
    echo [ERROR] Abseil installation not found: %ABSL_INSTALL%
    echo [ERROR] Please build Abseil first or check the installation path.
    exit /b 1
)

:: Build dizinini temizle ve oluştur
echo [INFO] Preparing Protobuf build directory...
if exist "%PROTOBUF_BUILD%" rmdir /s /q "%PROTOBUF_BUILD%"
mkdir "%PROTOBUF_BUILD%"

cd /d "%PROTOBUF_BUILD%"

:: Protobuf CMake konfigürasyonu
echo [INFO] Configuring Protobuf with CMake...

cmake -G "%VSVERSION%" -A %ARCH% ^
    -DCMAKE_CXX_STANDARD=17 ^
    -Dprotobuf_BUILD_TESTS=OFF ^
    -Dprotobuf_BUILD_EXAMPLES=OFF ^
    -Dprotobuf_WITH_ZLIB=OFF ^
    -Dprotobuf_ABSL_PROVIDER=module ^
    -Dprotobuf_DISABLE_RTTI=OFF ^
    -Dprotobuf_BUILD_PROTOC_BINARIES=ON ^
    -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL ^
    -DBUILD_SHARED_LIBS=%BUILD_SHARED_LIBS% ^
    -Dprotobuf_BUILD_SHARED_LIBS=%BUILD_SHARED_LIBS% ^
    "%PROTOBUF_SRC%"

if errorlevel 1 (
    echo [ERROR] Protobuf CMake configuration failed!
    exit /b 1
)

:: Protobuf Debug derleme
echo [INFO] Building Protobuf (Debug)...
cmake --build . --config Debug --parallel

if errorlevel 1 (
    echo [ERROR] Protobuf Debug build failed!
    exit /b 1
)

:: Protobuf Release derleme
echo [INFO] Building Protobuf (Release)...
cmake --build . --config Release --parallel

if errorlevel 1 (
    echo [ERROR] Protobuf Release build failed!
    exit /b 1
)

echo [SUCCESS] Protobuf build completed successfully!

:: =============================================================================
:: BUILD SUMMARY
:: =============================================================================

:end

echo.
echo ==========================================
echo   BUILD SUMMARY
echo ==========================================

if "%SKIP_ABSL%"=="0" (
    echo [✓] Abseil-cpp: Built Debug and Release modes
    echo     - Installation directory: %ABSL_INSTALL%
) else (
    echo [⚠] Abseil-cpp: Skipped
)

if "%SKIP_PROTOBUF%"=="0" (
    echo [✓] ProtoBuf: Built in Debug and Release modes
    echo     - Build directory: %PROTOBUF_BUILD%
    echo     - Debug binaries: %PROTOBUF_BUILD%\Debug\
    echo     - Release binaries: %PROTOBUF_BUILD%\Release\
) else (
    echo [⚠] ProtoBuf: Skipped
)

echo.
echo ==========================================
echo   Build process completed!
echo ==========================================

:: Ana dizine geri dön
cd /d C:\protobuf

endlocal