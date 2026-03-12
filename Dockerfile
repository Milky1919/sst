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
RUN sed -i 's/faster-whisper==0\.10\.1/faster-whisper>=1.0.0/' requirements.txt

# requirements.txt の torch 制約を CPU 版ビルドに固定し CUDA 版が選ばれないようにする
# torch<2.4 という上限は維持しつつ +cpu サフィックスで CPU ビルドを明示
RUN sed -i 's|^torch$|torch==2.3.1+cpu|' requirements.txt \
    && sed -i 's|^torch<.*|torch==2.3.1+cpu|' requirements.txt

# CPU 版 torch インデックスを参照しながら全依存パッケージを一括インストール
RUN pip install --no-cache-dir \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    -r requirements.txt

# モデルファイルの保存先ディレクトリを作成
RUN mkdir -p /app/model_assets

# 起動スクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
