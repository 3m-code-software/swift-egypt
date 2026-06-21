from uuid import UUID

import httpx
from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_operations_user, get_db
from app.config import settings
from app.models.document import Document
from app.models.user import User
from app.schemas.document import DocumentResponse
from app.services.document_service import DocumentService

router = APIRouter(prefix="/documents", tags=["Documents"])


@router.post("/upload", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    shipment_id: str = Form(...),
    document_type: str = Form(...),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    """Upload a document for a shipment."""
    file_bytes = await file.read()
    service = DocumentService(db)
    document = await service.upload_document(
        shipment_id=UUID(shipment_id),
        document_type=document_type,
        file_name=file.filename or "unnamed",
        file_bytes=file_bytes,
        content_type=file.content_type,
        uploaded_by=current_user.id,
    )
    return DocumentResponse.model_validate(document)


@router.get("/shipment/{shipment_id}", response_model=list[DocumentResponse])
async def get_shipment_documents(shipment_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get all documents for a shipment."""
    service = DocumentService(db)
    documents = await service.get_shipment_documents(shipment_id)
    return [DocumentResponse.model_validate(d) for d in documents]


@router.get("/", response_model=list[DocumentResponse])
async def list_all_documents(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """List all documents."""
    result = await db.execute(select(Document).order_by(Document.created_at.desc()).limit(100))
    return [DocumentResponse.model_validate(d) for d in result.scalars().all()]


@router.post("/{document_id}/ocr", response_model=dict)
async def run_ocr(document_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Run OCR on a document using the external OCR service."""
    result = await db.execute(select(Document).where(Document.id == document_id))
    document = result.scalar_one_or_none()
    if not document:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Document not found")

    if not document.storage_key:
        return {"document_id": str(document_id), "ocr_data": {"text": "No file uploaded", "confidence": 0}}

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            ocr_resp = await client.get(
                f"{settings.ocr_service_url}/ocr",
                params={"storage_key": document.storage_key},
            )
            if ocr_resp.is_success:
                ocr_data = ocr_resp.json()
            else:
                ocr_data = {"text": "OCR service unavailable", "confidence": 0}
    except httpx.RequestError:
        ocr_data = {"text": "OCR service unavailable", "confidence": 0}

    document.ocr_data = str(ocr_data)
    await db.commit()

    return {"document_id": str(document_id), "ocr_data": ocr_data}


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(document_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Delete a document."""
    service = DocumentService(db)
    await service.delete_document(document_id)
