"""Style-Bert-VITS2 を OpenAI TTS API 互換にする軽量プロキシ"""

import os

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import Response

app = FastAPI()

SBV2_URL = os.environ.get("SBV2_API_URL", "http://style-bert-vits2:5000")


@app.post("/v1/audio/speech")
async def speech(request: Request):
    body = await request.json()
    text = body.get("input", "")

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            f"{SBV2_URL}/voice",
            params={
                "text": text,
                "model_name": os.environ.get("SBV2_MODEL_NAME", "jvnv-F1-jp"),
                "language": os.environ.get("SBV2_LANGUAGE", "JP"),
            },
        )

    if resp.status_code != 200:
        return Response(content=resp.content, status_code=resp.status_code)

    return Response(content=resp.content, media_type="audio/wav")


@app.get("/v1/models")
async def models():
    return {"data": [{"id": "tts-1", "object": "model"}]}
