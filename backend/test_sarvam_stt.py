import asyncio
import websockets
import base64
import json
import os
from dotenv import load_dotenv

load_dotenv("d:\\Nithin\\College Works\\Final Year Project\\Krushi Setu\\backend\\.env")
SARVAM_API_KEY = os.getenv("SARVAM_API_KEY")

async def test_ws(payload_format):
    url = "wss://api.sarvam.ai/speech-to-text/ws?model=saaras:v3&language_code=kn-IN&mode=transcribe"
    headers = {"api-subscription-key": SARVAM_API_KEY}
    try:
        async with websockets.connect(url, additional_headers=headers) as ws:
            dummy_pcm = b'\x00' * 1024
            b64 = base64.b64encode(dummy_pcm).decode("utf-8")
            
            if payload_format == "content":
                msg = {"audio": {"content": b64}, "encoding": "audio/wav", "sample_rate": 16000}
            elif payload_format == "data":
                msg = {"audio": {"data": b64, "encoding": "audio/wav", "sample_rate": 16000}}
            else:
                msg = {"audio": b64}
                
            await ws.send(json.dumps(msg))
            resp = await ws.recv()
            print(f"Format {payload_format}: {resp}")
    except Exception as e:
        print(f"Format {payload_format} exception: {e}")

async def main():
    await test_ws("raw")
    await test_ws("content")
    await test_ws("data")

asyncio.run(main())
