@echo off
setlocal

:: Varsayılan build türü Release
set BUILD_TYPE=Debug

:: Eğer parametre verdiysek (debug / release), BUILD_TYPE ona göre ayarlanır
if /I "%1"=="debug" set BUILD_TYPE=Debug
if /I "%1"=="release" set BUILD_TYPE=Release

echo Using build type: %BUILD_TYPE%

:: Protoc yolu
set PROTOC=C:\protobuf\protobuf321\build\%BUILD_TYPE%\protoc.exe

:: Proto kaynak dosyası
set PROTO_SRC=C:\protobuf\protobuf321InstallationTest\GoogleProtobufInstallTest\GoogleProtobufInstallTest\src\person\person.proto

:: Çıktı dizini (main.cpp ile aynı dizin)
set PROTO_DST=C:\protobuf\protobuf321InstallationTest\GoogleProtobufInstallTest\GoogleProtobufInstallTest

:: Protoc çağrısı
echo Running: "%PROTOC%" --cpp_out="%PROTO_DST%" "%PROTO_SRC%"
"%PROTOC%" --proto_path="%PROTO_DST%" --cpp_out="%PROTO_DST%" "%PROTO_SRC%"


if %ERRORLEVEL% NEQ 0 (
    echo Error: protoc failed!
    exit /b %ERRORLEVEL%
)

echo Done. Files generated in: %PROTO_DST%
pause
