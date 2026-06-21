from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException
from app.models.document import Document
from app.services.storage_service import storage


class DocumentService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def upload_document(
        self,
        shipment_id: UUID,
        document_type: str,
        file_name: str,
        file_bytes: bytes,
        content_type: str | None = None,
        uploaded_by: UUID | None = None,
    ) -> Document:
        key = storage.build_key(str(shipment_id), file_name)
        storage.upload(file_bytes, key, content_type)
        file_url = storage.generate_presigned_url(key)
        document = Document(
            shipment_id=shipment_id,
            document_type=document_type,
            file_name=file_name,
            file_url=file_url,
            file_size=len(file_bytes),
            uploaded_by=uploaded_by,
            storage_key=key,
        )
        self.db.add(document)
        await self.db.flush()
        return document

    async def get_shipment_documents(self, shipment_id: UUID) -> list[Document]:
        result = await self.db.execute(
            select(Document).where(Document.shipment_id == shipment_id).order_by(Document.created_at.desc())
        )
        return list(result.scalars().all())

    async def delete_document(self, document_id: UUID) -> None:
        result = await self.db.execute(select(Document).where(Document.id == document_id))
        document = result.scalar_one_or_none()
        if not document:
            raise NotFoundException("Document not found")
        if document.storage_key:
            storage.delete(document.storage_key)
        await self.db.delete(document)
        await self.db.flush()
