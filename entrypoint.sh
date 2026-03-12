#!/bin/bash
set -e

INITIALIZED_FLAG="/app/model_assets/.initialized"

# 初回起動時のみ initialize.py を実行
if [ ! -f "$INITIALIZED_FLAG" ]; then
    echo "[entrypoint] 初回起動: initialize.py を実行します..."
    python initialize.py
    touch "$INITIALIZED_FLAG"
    echo "[entrypoint] 初期化完了"
fi

echo "[entrypoint] TTSサーバーを起動します..."
exec python server_fastapi.py --cpu
