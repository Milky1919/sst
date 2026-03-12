#!/bin/bash
set -e

# 起動時に必要なモデルが存在するか確認
REQUIRED_MODEL="/app/bert/deberta-v2-large-japanese-char-wwm/pytorch_model.bin"
REQUIRED_MODEL_SAFE="/app/bert/deberta-v2-large-japanese-char-wwm/model.safetensors"

# どちらも存在しない場合、または model_assets が空の場合は初期化を実行
if [ ! -f "$REQUIRED_MODEL" ] && [ ! -f "$REQUIRED_MODEL_SAFE" ]; then
    echo "[entrypoint] 必要なモデルファイルが見つかりません。initialize.py を実行してダウンロードします..."
    python initialize.py
    echo "[entrypoint] 初期化完了"
else
    echo "[entrypoint] モデルファイルは既に存在します。"
fi

echo "[entrypoint] TTSサーバーを起動します..."
exec python server_fastapi.py --cpu
