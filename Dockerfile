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
# torch 行は削除して別途 CPU 版のみをインストールする
RUN sed -i 's/faster-whisper==0\.10\.1/faster-whisper>=1.0.0/' requirements.txt \
    && sed -i '/^torch/d' requirements.txt

# CPU 版 torch を先にインストール（他のパッケージより先に固定する）
RUN pip install --no-cache-dir \
    torch==2.3.1+cpu torchaudio==2.3.1+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# 残りの依存パッケージをインストール（torch は既に入っているのでスキップされる）
RUN pip install --no-cache-dir -r requirements.txt

# triton は GPU カーネルコンパイル用で CPU 専用環境では不要かつ torch 2.3.1 と非互換
# (triton 3.6.0 が入ると torch が import できなくなるため削除)
RUN pip uninstall -y triton 2>/dev/null || true

# モデルファイルの保存先ディレクトリを作成
RUN mkdir -p /app/model_assets

# 起動スクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
