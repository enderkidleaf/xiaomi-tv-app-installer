#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -x "$TASK_ROOT/.build/toolchains/dotnet/dotnet" ]; then TASK_DOTNET="$TASK_ROOT/.build/toolchains/dotnet/dotnet"; else TASK_DOTNET="$(command -v dotnet)"; fi
mkdir -p "$TASK_ROOT/.build/windows-adb" "$TASK_ROOT/Windows/Resources/adb" "$TASK_ROOT/dist/windows"
if [ ! -f "$TASK_ROOT/Windows/Resources/adb/adb.exe" ]; then
    curl --fail --location https://dl.google.com/android/repository/platform-tools-latest-windows.zip -o "$TASK_ROOT/.build/windows-adb.zip"
    unzip -q -o "$TASK_ROOT/.build/windows-adb.zip" -d "$TASK_ROOT/.build/windows-adb"
    cp "$TASK_ROOT/.build/windows-adb/platform-tools/adb.exe" "$TASK_ROOT/Windows/Resources/adb/"
    cp "$TASK_ROOT/.build/windows-adb/platform-tools/"*.dll "$TASK_ROOT/Windows/Resources/adb/"
    cp "$TASK_ROOT/.build/windows-adb/platform-tools/NOTICE.txt" "$TASK_ROOT/Windows/Resources/adb/"
fi
export DOTNET_CLI_HOME="$TASK_ROOT/.build/dotnet-home"
export NUGET_PACKAGES="$TASK_ROOT/.build/nuget"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_GENERATE_ASPNET_CERTIFICATE=false
"$TASK_DOTNET" publish "$TASK_ROOT/Windows/TVAppInstaller.csproj" -c Release -r win-x64 \
    --self-contained true -p:PublishSingleFile=true -p:DebugType=None -p:DebugSymbols=false \
    -o "$TASK_ROOT/dist/windows"
python3 - "$TASK_ROOT" <<'PY'
import pathlib,sys,zipfile
root=pathlib.Path(sys.argv[1]); source=root/'dist/windows'
with zipfile.ZipFile(root/'dist/xiaomi-tv-app-installer-Windows-x64.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as zip:
    for file in sorted(source.rglob('*')):
        if file.is_file():zip.write(file,'TVAppInstaller/'+str(file.relative_to(source)))
print('Windows package built')
PY
