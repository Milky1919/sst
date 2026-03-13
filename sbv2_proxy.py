"""Style-Bert-VITS2 + Whisper を OpenAI API 互換にする軽量プロキシ"""

import os

import httpx
from fastapi import FastAPI, Request, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response, JSONResponse

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

SBV2_URL = os.environ.get("SBV2_API_URL", "http://style-bert-vits2:5000")
WHISPER_URL = os.environ.get("WHISPER_API_URL", "http://host.docker.internal:8787")


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


@app.post("/v1/audio/transcriptions")
async def transcriptions(
    file: UploadFile = File(...),
    model: str = Form("base"),
    language: str = Form(None),
    response_format: str = Form("json"),
):
    file_content = await file.read()

    files = {"file": (file.filename, file_content, file.content_type)}
    data = {"model": model, "response_format": response_format}
    if language:
        data["language"] = language

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            f"{WHISPER_URL}/v1/audio/transcriptions",
            files=files,
            data=data,
        )

    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type", "application/json"),
    )


@app.get("/v1/models")
async def models():
    return {
        "data": [
            {"id": "tts-1", "object": "model"},
            {"id": "base", "object": "model"},
        ]
    }
