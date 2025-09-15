@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   TEST: x64 Release LIB Build Only
echo ==========================================

:: Configuration
set VSVERSION=Visual Studio 17 2022
set PROTOBUF_SRC=C:\protobuf\protobuf321
set PROTOBUF_BUILD_DIR=C:\protobuf\protobuf-builds\x64-Release-LIB-TEST

echo Testing x64 Release LIB build...
echo Build directory: %PROTOBUF_BUILD_DIR%

:: Clean and create directory
if exist "%PROTOBUF_BUILD_DIR%" rmdir /s /q "%PROTOBUF_BUILD_DIR%"
mkdir "%PROTOBUF_BUILD_DIR%"

cd /d "%PROTOBUF_BUILD_DIR%"

echo.
echo ==========================================
echo   CMake Configuration
echo ==========================================

:: CMake configuration for Release Static LIB
cmake -G "%VSVERSION%" -A x64 ^
    -DCMAKE_CXX_STANDARD=17 ^
    -Dprotobuf_BUILD_TESTS=OFF ^
    -Dprotobuf_BUILD_EXAMPLES=OFF ^
    -Dprotobuf_WITH_ZLIB=OFF ^
    -Dprotobuf_ABSL_PROVIDER=module ^
    -Dprotobuf_DISABLE_RTTI=OFF ^
    -Dprotobuf_BUILD_PROTOC_BINARIES=ON ^
    -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL ^
    -DBUILD_SHARED_LIBS=OFF ^
    -Dprotobuf_BUILD_SHARED_LIBS=OFF ^
    "%PROTOBUF_SRC%"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo   CONFIGURATION FAILED!
    echo ==========================================
    echo.
    if exist "CMakeFiles\CMakeError.log" (
        echo CMake Error Log:
        type "CMakeFiles\CMakeError.log"
    )
) else (
    echo.
    echo ==========================================
    echo   CONFIGURATION SUCCESSFUL!
    echo ==========================================
    echo Now building Release...
    
    cmake --build . --config Release --parallel
    
    if errorlevel 1 (
        echo BUILD FAILED!
    ) else (
        echo BUILD SUCCESSFUL!
        echo.
        echo Generated files:
        dir Release\*.lib /b 2>nul
        dir Release\*.exe /b 2>nul
    )
)

echo.
pause

cd /d C:\protobuf
endlocal