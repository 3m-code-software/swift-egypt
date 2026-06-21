from contextlib import asynccontextmanager
from pathlib import Path
from tempfile import NamedTemporaryFile

from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.reader = None
    try:
        import easyocr
        app.state.reader = easyocr.Reader(["ar", "en"], gpu=False)
    except Exception as e:
        print(f"EasyOCR init failed: {e}. Will use fallback.")
    yield


app = FastAPI(title="Swift Egypt OCR Service", version="1.0.0", lifespan=lifespan)


class OcrResult(BaseModel):
    text: str
    confidence: float
    language: str = "ar+en"
    raw_segments: list[dict] = []


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "Swift Egypt OCR Service"}


@app.post("/ocr", response_model=OcrResult)
async def ocr(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "Only image files are supported")

    contents = await file.read()

    if app.state.reader is None:
        return _fallback_ocr(contents)

    try:
        suffix = Path(file.filename or "image.png").suffix or ".png"
        with NamedTemporaryFile(delete=True, suffix=suffix) as tmp:
            tmp.write(contents)
            tmp.flush()
            results = app.state.reader.readtext(tmp.name)

        segments = []
        full_text_parts = []
        conf_sum = 0.0

        for bbox, text, conf in results:
            segments.append({
                "text": text,
                "confidence": round(conf, 4),
                "bbox": bbox,
            })
            full_text_parts.append(text)
            conf_sum += conf

        n = len(segments)
        return OcrResult(
            text="\n".join(full_text_parts),
            confidence=round(conf_sum / n, 4) if n > 0 else 0,
            raw_segments=segments,
        )
    except Exception as e:
        return _fallback_ocr(contents, str(e))


def _fallback_ocr(image_bytes: bytes, error: str | None = None) -> OcrResult:
    try:
        from PIL import Image
        from io import BytesIO

        img = Image.open(BytesIO(image_bytes))
        width, height = img.size
        text = f"[Image {width}x{height} — OCR engine unavailable"
        if error:
            text += f": {error}"
        text += "]"
    except Exception:
        text = "[Unable to process image]"

    return OcrResult(text=text, confidence=0.0)
