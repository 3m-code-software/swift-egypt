from datetime import datetime
from uuid import UUID

from pydantic import BaseModel
from fastapi import UploadFile


class DocumentUpload(BaseModel):
    shipment_id: UUID
    document_type: str


class DocumentResponse(BaseModel):
    id: UUID
    shipment_id: UUID
    document_type: str
    file_name: str
    file_url: str
    file_size: int | None
    ocr_data: str | None
    uploaded_by: UUID | None
    created_at: datetime

    model_config = {"from_attributes": True}


class OcrResult(BaseModel):
    document_id: UUID
    ocr_data: dict
