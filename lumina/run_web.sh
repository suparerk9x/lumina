#!/bin/bash
# Demenish AI Web Dev Server — always port 8010
# Usage: bash run_web.sh
PORT=8010
export PATH="/d/flutter/bin:$PATH"
cd "$(dirname "$0")"

echo "=== Demenish AI Dev Server ==="
echo "กำลังปิด server เก่า..."
powershell.exe -Command "Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue | Select-Object OwningProcess | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force -ErrorAction SilentlyContinue }" 2>/dev/null
taskkill /F /IM dart.exe 2>/dev/null
sleep 2
echo "เปิด server ที่ http://localhost:$PORT ..."
flutter run -d web-server --web-port=$PORT
