FROM python:3.10

# 必要なシステムパッケージをインストール
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Style-Bert-VITS2 のソースコードを取得
RUN git clone https://github.com/litagin02/Style-Bert-VITS2 .

# av==10.* の Cython ビルド問題を回避するため faster-whisper のバージョンを緩める
# torch のバージョン上限（<2.4）は transformers と競合するため削除
RUN sed -i 's/faster-whisper==0\.10\.1/faster-whisper>=1.0.0/' requirements.txt \
    && sed -i '/^torch/d' requirements.txt

# pipの依存解決グラフが大きすぎてエラー (resolution-too-deep) になるため、Rust製の高速な 'uv' を導入
RUN pip install --no-cache-dir uv

# uv を使って超高速かつ確実に依存関係を解決して一括インストール (--system でコンテナのシステムPythonに直接入れる)
RUN uv pip install --system --no-cache \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch torchaudio \
    -r requirements.txt

# triton は GPU カーネルコンパイル用で CPU 専用環境では不要かつ torch 2.3.1 と非互換
# (triton 3.6.0 が入ると import torch が失敗するため削除)
RUN pip uninstall -y triton 2>/dev/null || true

# モデルファイルの保存先ディレクトリを作成
RUN mkdir -p /app/model_assets

# 起動スクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
