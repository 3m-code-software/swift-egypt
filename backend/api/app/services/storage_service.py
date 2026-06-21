from io import BytesIO
from uuid import uuid4

import boto3
from botocore.config import Config as BotoConfig

from app.config import settings


class StorageService:
    def __init__(self):
        self.bucket = settings.aws_bucket_name
        self.endpoint_url = settings.aws_endpoint_url
        self.access_key = settings.aws_access_key
        self.secret_key = settings.aws_secret_key
        self.region = settings.aws_region
        self._client = None

    @property
    def client(self):
        if self._client is None:
            kwargs = dict(
                aws_access_key_id=self.access_key,
                aws_secret_access_key=self.secret_key,
                region_name=self.region,
                config=BotoConfig(signature_version="s3v4"),
            )
            if self.endpoint_url:
                kwargs["endpoint_url"] = self.endpoint_url
            self._client = boto3.client("s3", **kwargs)
        return self._client

    def ensure_bucket(self):
        try:
            self.client.head_bucket(Bucket=self.bucket)
        except Exception:
            self.client.create_bucket(Bucket=self.bucket)

    def upload(self, file_bytes: bytes, key: str, content_type: str | None = None) -> str:
        self.ensure_bucket()
        extra = {}
        if content_type:
            extra["ContentType"] = content_type
        self.client.put_object(Bucket=self.bucket, Key=key, Body=file_bytes, **extra)
        return key

    def generate_presigned_url(self, key: str, expiration: int = 3600) -> str:
        return self.client.generate_presigned_url(
            "get_object", Params={"Bucket": self.bucket, "Key": key}, ExpiresIn=expiration
        )

    def delete(self, key: str):
        self.client.delete_object(Bucket=self.bucket, Key=key)

    @staticmethod
    def build_key(shipment_id: str, original_filename: str) -> str:
        ext = original_filename.rsplit(".", 1)[-1] if "." in original_filename else "bin"
        return f"documents/{shipment_id}/{uuid4().hex}.{ext}"


storage = StorageService()
