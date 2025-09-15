@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   TEST: Win32 Debug DLL Build Only
echo ==========================================

:: Configuration
set VSVERSION=Visual Studio 17 2022
set PROTOBUF_SRC=C:\protobuf\protobuf321
set PROTOBUF_BUILD_DIR=C:\protobuf\protobuf-builds\Win32-Debug-DLL-TEST

echo Testing Win32 Debug DLL build...
echo Build directory: %PROTOBUF_BUILD_DIR%

:: Clean and create directory
if exist "%PROTOBUF_BUILD_DIR%" rmdir /s /q "%PROTOBUF_BUILD_DIR%"
mkdir "%PROTOBUF_BUILD_DIR%"

cd /d "%PROTOBUF_BUILD_DIR%"

echo.
echo ==========================================
echo   CMake Configuration (Verbose)
echo ==========================================

:: CMake configuration with verbose output
cmake -G "%VSVERSION%" -A Win32 ^
    -DCMAKE_CXX_STANDARD=17 ^
    -Dprotobuf_BUILD_TESTS=OFF ^
    -Dprotobuf_BUILD_EXAMPLES=OFF ^
    -Dprotobuf_WITH_ZLIB=OFF ^
    -Dprotobuf_ABSL_PROVIDER=module ^
    -Dprotobuf_DISABLE_RTTI=OFF ^
    -Dprotobuf_BUILD_PROTOC_BINARIES=ON ^
    -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL ^
    -DBUILD_SHARED_LIBS=ON ^
    -Dprotobuf_BUILD_SHARED_LIBS=ON ^
    -Dprotobuf_MSVC_STATIC_RUNTIME=OFF ^
    "%PROTOBUF_SRC%"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo   CONFIGURATION FAILED!
    echo ==========================================
    echo.
    echo Check CMakeFiles\CMakeError.log for details:
    if exist "CMakeFiles\CMakeError.log" (
        echo.
        echo CMake Error Log:
        type "CMakeFiles\CMakeError.log"
    )
    echo.
    echo Check CMakeFiles\CMakeOutput.log for more info:
    if exist "CMakeFiles\CMakeOutput.log" (
        echo.
        echo CMake Output Log (last 20 lines):
        powershell -Command "Get-Content 'CMakeFiles\CMakeOutput.log' | Select-Object -Last 20"
    )
) else (
    echo.
    echo ==========================================
    echo   CONFIGURATION SUCCESSFUL!
    echo ==========================================
    echo Now trying to build...
    cmake --build . --config Debug --parallel
    
    if errorlevel 1 (
        echo BUILD FAILED!
    ) else (
        echo BUILD SUCCESSFUL!
    )
)

echo.
echo Test completed. Check the output above for error details.
pause

cd /d C:\protobuf
endlocal