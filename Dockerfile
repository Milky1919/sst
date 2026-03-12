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
# torch は CPU 版を明示インストールするため requirements.txt から削除
# transformers>=5 は BERT API に破壊的変更があるため <5 に制限
RUN sed -i 's/faster-whisper==0\.10\.1/faster-whisper>=1.0.0/' requirements.txt \
    && sed -i '/^torch/d' requirements.txt \
    && sed -i 's/^transformers$/transformers<5/' requirements.txt

# pipの依存解決グラフが大きすぎてエラー (resolution-too-deep) になるため、Rust製の高速な 'uv' を導入
RUN pip install --no-cache-dir uv

# uv を使って超高速かつ確実に依存関係を解決して一括インストール (--system でコンテナのシステムPythonに直接入れる)
# torch/torchaudio: 上流要件 (<2.4) に合わせて CPU 版を明示ピン留め
# transformers<5: sed が効かない場合の確実なフォールバック
# soxr: transformers が 5.x に解決された場合の安全策
RUN uv pip install --system --no-cache \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    "torch==2.3.1+cpu" "torchaudio==2.3.1+cpu" "transformers<5" soxr \
    -r requirements.txt

# triton は GPU カーネル用で CPU 環境では不要 (入ると torch が壊れるため削除)
RUN uv pip uninstall --system triton 2>/dev/null || true

# モデルファイルの保存先ディレクトリを作成
RUN mkdir -p /app/model_assets

# 起動スクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
