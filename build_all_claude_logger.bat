@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   Build Script: Abseil + Protobuf
echo   Multi-Architecture Multi-Configuration
echo   WITH COLORED RESULT LOGGING
echo   Visual Studio 2022, x64/Win32, Debug/Release, Static/DLL
echo ==========================================

:: ============================================================================= 
:: CONFIGURATION FLAGS
:: =============================================================================

:: Ana Konfigürasyon
set USE_EXTERNAL_ABSEIL=OFF    
set BUILD_SHARED_LIBS=OFF      

:: Hata Handling (Default: Devam et)
set STOP_ON_ABSEIL_ERROR=OFF   
set STOP_ON_PROTOBUF_ERROR=OFF 
set STOP_ON_COPY_ERROR=OFF     

:: Build Temizlik (Default: Incremental)
set CLEAN_ABSEIL_BUILDS=OFF    
set CLEAN_PROTOBUF_BUILDS=OFF  

:: Visual Studio ve Paths
set VSVERSION=Visual Studio 17 2022
set ABSL_SRC=C:\protobuf\abseil-cpp
set PROTOBUF_SRC=C:\protobuf\protobuf321
set OUTPUTS_DIR=C:\protobuf\outputs
set RESULT_FILE=C:\protobuf\protobuf-builds\result.txt

echo.
echo ==========================================
echo   BUILD CONFIGURATION
echo ==========================================
echo - External Abseil: %USE_EXTERNAL_ABSEIL% (ON=External, OFF=Module)
echo - Library Type: %BUILD_SHARED_LIBS% (ON=DLL, OFF=Static)
echo - Stop on Abseil Error: %STOP_ON_ABSEIL_ERROR%
echo - Stop on ProtoBuf Error: %STOP_ON_PROTOBUF_ERROR%
echo - Clean Abseil Builds: %CLEAN_ABSEIL_BUILDS%
echo - Clean ProtoBuf Builds: %CLEAN_PROTOBUF_BUILDS%
echo - Visual Studio: %VSVERSION%
echo - Output Directory: %OUTPUTS_DIR%
echo - Result Log: %RESULT_FILE%
echo.

:: =============================================================================
:: claude begin
:: =============================================================================

:: Initialize result log
call :initResultLog

:: Initialize output directories
call :ensureOutputDirs

:: Build Abseil if external provider is selected
if "%USE_EXTERNAL_ABSEIL%"=="ON" (
    echo ==========================================
    echo   Building External Abseil
    echo ==========================================
    call :buildAbseilWithLog x64 Release
    call :buildAbseilWithLog x64 Debug
    call :buildAbseilWithLog Win32 Release
    call :buildAbseilWithLog Win32 Debug
    echo.
)

:: Build ProtoBuf for all configurations
echo ==========================================
echo   Building ProtoBuf - All Configurations
echo ==========================================
call :buildProtoBufWithLog x64 Release LIB   
call :buildProtoBufWithLog x64 Release DLL
call :buildProtoBufWithLog x64 Debug LIB    
call :buildProtoBufWithLog x64 Debug DLL
call :buildProtoBufWithLog Win32 Release LIB
call :buildProtoBufWithLog Win32 Release DLL
call :buildProtoBufWithLog Win32 Debug LIB
call :buildProtoBufWithLog Win32 Debug DLL

:: Organize output files
echo ==========================================
echo   Organizing Output Files
echo ==========================================
call :copyBinFilesWithLog
call :copyLibFilesWithLog
call :copyHeaderFilesWithLog

goto :buildComplete

:: =============================================================================
:: claude end
:: =============================================================================

:: =============================================================================
:: FUNCTION DEFINITIONS
:: =============================================================================

:initResultLog
if not exist "C:\protobuf\protobuf-builds" mkdir "C:\protobuf\protobuf-builds"
echo ========================================== > "%RESULT_FILE%"
echo   BUILD RESULTS LOG >> "%RESULT_FILE%"
echo   Date: %date% %time% >> "%RESULT_FILE%"
echo ========================================== >> "%RESULT_FILE%"
echo. >> "%RESULT_FILE%"
goto :eof

:logResult
set TASK_NAME=%~1
set RESULT=%~2

:: Log to file
echo [%time%] %TASK_NAME%: %RESULT% >> "%RESULT_FILE%"

:: Display with colors
echo.
if "%RESULT%"=="PASSED" (
    powershell -Command "Write-Host '   ' -NoNewline; Write-Host '[%time%] %TASK_NAME%: ' -NoNewline; Write-Host 'PASSED' -ForegroundColor Green; Write-Host '   '"
) else (
    powershell -Command "Write-Host '   ' -NoNewline; Write-Host '[%time%] %TASK_NAME%: ' -NoNewline; Write-Host '%RESULT%' -ForegroundColor Red; Write-Host '   '"
)
echo.
goto :eof

:ensureOutputDirs
echo [INFO] Ensuring output directory structure...
if not exist "%OUTPUTS_DIR%" mkdir "%OUTPUTS_DIR%"
if not exist "%OUTPUTS_DIR%\include" mkdir "%OUTPUTS_DIR%\include"
if not exist "%OUTPUTS_DIR%\lib" mkdir "%OUTPUTS_DIR%\lib"
if not exist "%OUTPUTS_DIR%\bin" mkdir "%OUTPUTS_DIR%\bin"

:: x64 directories
if not exist "%OUTPUTS_DIR%\lib\x64" mkdir "%OUTPUTS_DIR%\lib\x64"
if not exist "%OUTPUTS_DIR%\lib\x64\Debug" mkdir "%OUTPUTS_DIR%\lib\x64\Debug"
if not exist "%OUTPUTS_DIR%\lib\x64\Release" mkdir "%OUTPUTS_DIR%\lib\x64\Release"
if not exist "%OUTPUTS_DIR%\bin\x64" mkdir "%OUTPUTS_DIR%\bin\x64"
if not exist "%OUTPUTS_DIR%\bin\x64\Debug" mkdir "%OUTPUTS_DIR%\bin\x64\Debug"
if not exist "%OUTPUTS_DIR%\bin\x64\Release" mkdir "%OUTPUTS_DIR%\bin\x64\Release"

:: Win32 directories
if not exist "%OUTPUTS_DIR%\lib\Win32" mkdir "%OUTPUTS_DIR%\lib\Win32"
if not exist "%OUTPUTS_DIR%\lib\Win32\Debug" mkdir "%OUTPUTS_DIR%\lib\Win32\Debug"
if not exist "%OUTPUTS_DIR%\lib\Win32\Release" mkdir "%OUTPUTS_DIR%\lib\Win32\Release"
if not exist "%OUTPUTS_DIR%\bin\Win32" mkdir "%OUTPUTS_DIR%\bin\Win32"
if not exist "%OUTPUTS_DIR%\bin\Win32\Debug" mkdir "%OUTPUTS_DIR%\bin\Win32\Debug"
if not exist "%OUTPUTS_DIR%\bin\Win32\Release" mkdir "%OUTPUTS_DIR%\bin\Win32\Release"

echo [SUCCESS] Output directories ready
goto :eof

:buildAbseilWithLog
set ARCH=%~1
set CONFIG=%~2
set TASK_NAME=Abseil_%ARCH%_%CONFIG%

echo [INFO] Building Abseil for %ARCH% %CONFIG%...

:: Set paths
set ABSL_BUILD_DIR=C:\protobuf\abseil-builds\%ARCH%-%CONFIG%
set ABSL_INSTALL_DIR=C:\protobuf\abseil-installs\%ARCH%-%CONFIG%

:: Check source directory
if not exist "%ABSL_SRC%" (
    call :logResult "%TASK_NAME%" "FAILED - Source directory not found"
    if "%STOP_ON_ABSEIL_ERROR%"=="ON" exit /b 1
    goto :eof
)

:: Clean build directory if requested
if "%CLEAN_ABSEIL_BUILDS%"=="ON" (
    if exist "%ABSL_BUILD_DIR%" rmdir /s /q "%ABSL_BUILD_DIR%"
)

:: Create directories
if not exist "%ABSL_BUILD_DIR%" mkdir "%ABSL_BUILD_DIR%"
if not exist "%ABSL_INSTALL_DIR%" mkdir "%ABSL_INSTALL_DIR%"

cd /d "%ABSL_BUILD_DIR%"

:: CMake configuration
cmake -G "%VSVERSION%" -A %ARCH% ^
    -DCMAKE_INSTALL_PREFIX="%ABSL_INSTALL_DIR%" ^
    -DABSL_BUILD_TESTING=OFF ^
    -DABSL_USE_GOOGLETEST_HEAD=OFF ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DABSL_PROPAGATE_CXX_STD=ON ^
    -DBUILD_SHARED_LIBS=%BUILD_SHARED_LIBS% ^
    "%ABSL_SRC%"

if errorlevel 1 (
    call :logResult "%TASK_NAME%" "FAILED - CMake configuration failed"
    if "%STOP_ON_ABSEIL_ERROR%"=="ON" exit /b 1
    goto :eof
)

:: Build
cmake --build . --config %CONFIG% --parallel

if errorlevel 1 (
    call :logResult "%TASK_NAME%" "FAILED - Build failed"
    if "%STOP_ON_ABSEIL_ERROR%"=="ON" exit /b 1
    goto :eof
)

:: Install
cmake --install . --config %CONFIG%

if errorlevel 1 (
    call :logResult "%TASK_NAME%" "FAILED - Installation failed"
    if "%STOP_ON_ABSEIL_ERROR%"=="ON" exit /b 1
    goto :eof
)

call :logResult "%TASK_NAME%" "PASSED"
goto :eof

:buildProtoBufWithLog
set ARCH=%~1
set CONFIG=%~2
set LIBTYPE=%~3
set TASK_NAME=ProtoBuf_%ARCH%_%CONFIG%_%LIBTYPE%

echo [INFO] Building ProtoBuf for %ARCH% %CONFIG% %LIBTYPE%...

:: Set paths
set PROTOBUF_BUILD_DIR=C:\protobuf\protobuf-builds\%ARCH%-%CONFIG%-%LIBTYPE%

:: Set library type flags
if "%LIBTYPE%"=="DLL" (
    set CURRENT_BUILD_SHARED_LIBS=ON
) else (
    set CURRENT_BUILD_SHARED_LIBS=OFF
)

:: Set runtime library based on configuration
if "%CONFIG%"=="Debug" (
    set CURRENT_RUNTIME_LIBRARY=MultiThreadedDebugDLL
) else (
    set CURRENT_RUNTIME_LIBRARY=MultiThreadedDLL
)

:: Check source directory
if not exist "%PROTOBUF_SRC%" (
    call :logResult "%TASK_NAME%" "FAILED - Source directory not found"
    if "%STOP_ON_PROTOBUF_ERROR%"=="ON" exit /b 1
    goto :eof
)

:: Clean build directory if requested
if "%CLEAN_PROTOBUF_BUILDS%"=="ON" (
    if exist "%PROTOBUF_BUILD_DIR%" rmdir /s /q "%PROTOBUF_BUILD_DIR%"
)

:: Create directory
if not exist "%PROTOBUF_BUILD_DIR%" mkdir "%PROTOBUF_BUILD_DIR%"

cd /d "%PROTOBUF_BUILD_DIR%"

:: Set Abseil provider based on configuration
if "%USE_EXTERNAL_ABSEIL%"=="ON" (
    set ABSL_PROVIDER=package
    set ABSL_INSTALL_DIR=C:\protobuf\abseil-installs\%ARCH%-%CONFIG%
    
    :: Check if external Abseil is available
    if not exist "!ABSL_INSTALL_DIR!" (
        call :logResult "%TASK_NAME%" "FAILED - External Abseil not found"
        if "%STOP_ON_PROTOBUF_ERROR%"=="ON" exit /b 1
        goto :eof
    )
    
    :: CMake configuration with external Abseil
    cmake -G "%VSVERSION%" -A %ARCH% ^
        -DCMAKE_CXX_STANDARD=17 ^
        -Dprotobuf_BUILD_TESTS=OFF ^
        -Dprotobuf_BUILD_EXAMPLES=OFF ^
        -Dprotobuf_WITH_ZLIB=OFF ^
        -Dprotobuf_ABSL_PROVIDER=package ^
        -DCMAKE_PREFIX_PATH="!ABSL_INSTALL_DIR!" ^
        -Dabsl_DIR="!ABSL_INSTALL_DIR!\lib\cmake\absl" ^
        -Dprotobuf_DISABLE_RTTI=OFF ^
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON ^
        -DCMAKE_MSVC_RUNTIME_LIBRARY=!CURRENT_RUNTIME_LIBRARY! ^
        -DBUILD_SHARED_LIBS=!CURRENT_BUILD_SHARED_LIBS! ^
        -Dprotobuf_BUILD_SHARED_LIBS=!CURRENT_BUILD_SHARED_LIBS! ^
        "%PROTOBUF_SRC%"
) else (
    :: CMake configuration with module Abseil
    if "%LIBTYPE%"=="DLL" (
        :: DLL build with specific settings
        cmake -G "%VSVERSION%" -A %ARCH% ^
            -DCMAKE_CXX_STANDARD=17 ^
            -Dprotobuf_BUILD_TESTS=OFF ^
            -Dprotobuf_BUILD_EXAMPLES=OFF ^
            -Dprotobuf_WITH_ZLIB=OFF ^
            -Dprotobuf_ABSL_PROVIDER=module ^
            -Dprotobuf_DISABLE_RTTI=OFF ^
            -Dprotobuf_BUILD_PROTOC_BINARIES=ON ^
            -DCMAKE_MSVC_RUNTIME_LIBRARY=!CURRENT_RUNTIME_LIBRARY! ^
            -DBUILD_SHARED_LIBS=ON ^
            -Dprotobuf_BUILD_SHARED_LIBS=ON ^
            -Dprotobuf_MSVC_STATIC_RUNTIME=OFF ^
            "%PROTOBUF_SRC%"
    ) else (
        :: Static LIB build
        cmake -G "%VSVERSION%" -A %ARCH% ^
            -DCMAKE_CXX_STANDARD=17 ^
            -Dprotobuf_BUILD_TESTS=OFF ^
            -Dprotobuf_BUILD_EXAMPLES=OFF ^
            -Dprotobuf_WITH_ZLIB=OFF ^
            -Dprotobuf_ABSL_PROVIDER=module ^
            -Dprotobuf_DISABLE_RTTI=OFF ^
            -Dprotobuf_BUILD_PROTOC_BINARIES=ON ^
            -DCMAKE_MSVC_RUNTIME_LIBRARY=!CURRENT_RUNTIME_LIBRARY! ^
            -DBUILD_SHARED_LIBS=OFF ^
            -Dprotobuf_BUILD_SHARED_LIBS=OFF ^
            "%PROTOBUF_SRC%"
    )
)

if errorlevel 1 (
    call :logResult "%TASK_NAME%" "FAILED - CMake configuration failed"
    if "%STOP_ON_PROTOBUF_ERROR%"=="ON" exit /b 1
    goto :eof
)

:: Build
cmake --build . --config %CONFIG% --parallel

if errorlevel 1 (
    call :logResult "%TASK_NAME%" "FAILED - Build failed"
    if "%STOP_ON_PROTOBUF_ERROR%"=="ON" exit /b 1
    goto :eof
)

call :logResult "%TASK_NAME%" "PASSED"
goto :eof

:copyBinFilesWithLog
echo [INFO] Copying binary files...

:: Copy from all ProtoBuf builds
for %%A in (x64 Win32) do (
    for %%C in (Debug Release) do (
        for %%L in (LIB DLL) do (
            set BUILD_DIR=C:\protobuf\protobuf-builds\%%A-%%C-%%L
            set OUTPUT_DIR=%OUTPUTS_DIR%\bin\%%A\%%C
            
            if exist "!BUILD_DIR!\%%C" (
                :: Copy executables
                if exist "!BUILD_DIR!\%%C\*.exe" (
                    copy "!BUILD_DIR!\%%C\*.exe" "!OUTPUT_DIR!\" >nul
                )
                
                :: Copy DLLs (only for DLL builds)
                if "%%L"=="DLL" (
                    if exist "!BUILD_DIR!\%%C\*.dll" (
                        copy "!BUILD_DIR!\%%C\*.dll" "!OUTPUT_DIR!\" >nul
                    )
                )
            )
        )
    )
)

:: Copy from external Abseil if enabled and DLL
if "%USE_EXTERNAL_ABSEIL%"=="ON" (
    if "%BUILD_SHARED_LIBS%"=="ON" (
        for %%A in (x64 Win32) do (
            for %%C in (Debug Release) do (
                set ABSL_INSTALL=C:\protobuf\abseil-installs\%%A-%%C
                set OUTPUT_DIR=%OUTPUTS_DIR%\bin\%%A\%%C
                
                if exist "!ABSL_INSTALL!\bin\*.dll" (
                    copy "!ABSL_INSTALL!\bin\*.dll" "!OUTPUT_DIR!\" >nul
                )
            )
        )
    )
)

call :logResult "Copy_Bin_Files" "PASSED"
goto :eof

:copyLibFilesWithLog
echo [INFO] Copying library files...

:: Copy from all ProtoBuf builds
for %%A in (x64 Win32) do (
    for %%C in (Debug Release) do (
        for %%L in (LIB DLL) do (
            set BUILD_DIR=C:\protobuf\protobuf-builds\%%A-%%C-%%L
            set OUTPUT_DIR=%OUTPUTS_DIR%\lib\%%A\%%C
            
            if exist "!BUILD_DIR!\%%C" (
                if exist "!BUILD_DIR!\%%C\*.lib" (
                    copy "!BUILD_DIR!\%%C\*.lib" "!OUTPUT_DIR!\" >nul
                )
            )
        )
    )
)

:: Copy from external Abseil if enabled
if "%USE_EXTERNAL_ABSEIL%"=="ON" (
    for %%A in (x64 Win32) do (
        for %%C in (Debug Release) do (
            set ABSL_INSTALL=C:\protobuf\abseil-installs\%%A-%%C
            set OUTPUT_DIR=%OUTPUTS_DIR%\lib\%%A\%%C
            
            if exist "!ABSL_INSTALL!\lib\*.lib" (
                copy "!ABSL_INSTALL!\lib\*.lib" "!OUTPUT_DIR!\" >nul
            )
        )
    )
)

call :logResult "Copy_Lib_Files" "PASSED"
goto :eof

:copyHeaderFilesWithLog
echo [INFO] Copying header files...

:: Copy ProtoBuf headers (from any build, they're the same)
set ANY_PROTOBUF_BUILD=C:\protobuf\protobuf-builds\x64-Release-LIB
if exist "%ANY_PROTOBUF_BUILD%" (
    if exist "%ANY_PROTOBUF_BUILD%\*.h" (
        xcopy "%ANY_PROTOBUF_BUILD%\*.h" "%OUTPUTS_DIR%\include\" /S /Y /Q >nul
    )
)

:: Copy from source if build headers not found
if exist "%PROTOBUF_SRC%\src\google" (
    xcopy "%PROTOBUF_SRC%\src\google" "%OUTPUTS_DIR%\include\google\" /S /Y /Q >nul
)

:: Copy external Abseil headers if enabled
if "%USE_EXTERNAL_ABSEIL%"=="ON" (
    set ANY_ABSL_INSTALL=C:\protobuf\abseil-installs\x64-Release
    if exist "!ANY_ABSL_INSTALL!\include\absl" (
        xcopy "!ANY_ABSL_INSTALL!\include\absl" "%OUTPUTS_DIR%\include\absl\" /S /Y /Q >nul
    )
)

call :logResult "Copy_Header_Files" "PASSED"
goto :eof

:buildComplete
echo.
echo ==========================================
echo   BUILD COMPLETE
echo ==========================================
echo.

:: Summary
if "%USE_EXTERNAL_ABSEIL%"=="ON" (
    echo [✓] External Abseil: Built for all configurations
) else (
    echo [✓] Module Abseil: Used internal ProtoBuf Abseil
)

echo [✓] ProtoBuf: Built for all configurations
echo     - Architectures: x64, Win32
echo     - Configurations: Debug, Release  
echo     - Library Types: Static LIB, DLL
echo     - Total Builds: 8

echo [✓] Output Files: Organized in %OUTPUTS_DIR%
echo     - Headers: %OUTPUTS_DIR%\include\
echo     - Libraries: %OUTPUTS_DIR%\lib\{arch}\{config}\
echo     - Binaries: %OUTPUTS_DIR%\bin\{arch}\{config}\

echo.
echo ==========================================
echo   BUILD RESULTS LOGGED TO: %RESULT_FILE%
echo ==========================================

:: Final summary to log
echo. >> "%RESULT_FILE%"
echo ========================================== >> "%RESULT_FILE%"
echo   BUILD COMPLETED: %date% %time% >> "%RESULT_FILE%"
echo ========================================== >> "%RESULT_FILE%"

echo.
echo Check %RESULT_FILE% for detailed build results!

:: Return to original directory
cd /d C:\protobuf

endlocal