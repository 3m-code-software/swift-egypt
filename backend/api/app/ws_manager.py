import asyncio
import json
import uuid
from typing import Optional

import redis.asyncio as aioredis
from fastapi import WebSocket

from app.config import settings

REDIS_CHANNEL = "ws:messages"


class WSConnectionManager:
    def __init__(self):
        self._connections: dict[str, list[WebSocket]] = {}
        self._worker_id = uuid.uuid4().hex[:8]
        self._redis: Optional[aioredis.Redis] = None
        self._pubsub: Optional[aioredis.client.PubSub] = None
        self._listener_task: Optional[asyncio.Task] = None

    async def connect(self, user_id: str, ws: WebSocket):
        await ws.accept()
        self._connections.setdefault(user_id, []).append(ws)

    def disconnect(self, user_id: str, ws: WebSocket):
        if user_id in self._connections:
            try:
                self._connections[user_id].remove(ws)
            except ValueError:
                pass
            if not self._connections[user_id]:
                del self._connections[user_id]

    async def send_to_user(self, user_id: str, message: dict):
        await self._send_local(user_id, message)
        await self._publish(user_id, message)

    async def _send_local(self, user_id: str, message: dict):
        if user_id not in self._connections:
            return
        for ws in self._connections[user_id][:]:
            try:
                await ws.send_json(message)
            except Exception:
                self.disconnect(user_id, ws)

    async def _publish(self, user_id: str, message: dict):
        if self._redis is None:
            return
        try:
            payload = json.dumps({
                "user_id": user_id,
                "message": message,
                "worker_id": self._worker_id,
            })
            await self._redis.publish(REDIS_CHANNEL, payload)
        except Exception:
            pass

    async def start_redis(self):
        if not settings.redis_url:
            return
        try:
            self._redis = aioredis.from_url(settings.redis_url, decode_responses=True)
            self._pubsub = self._redis.pubsub()
            await self._pubsub.subscribe(REDIS_CHANNEL)
            self._listener_task = asyncio.create_task(self._redis_listener())
        except Exception:
            self._redis = None
            self._pubsub = None

    async def stop_redis(self):
        if self._listener_task:
            self._listener_task.cancel()
            try:
                await self._listener_task
            except asyncio.CancelledError:
                pass
            self._listener_task = None
        if self._pubsub:
            await self._pubsub.unsubscribe(REDIS_CHANNEL)
            await self._pubsub.close()
            self._pubsub = None
        if self._redis:
            await self._redis.aclose()
            self._redis = None

    async def _redis_listener(self):
        if self._pubsub is None:
            return
        try:
            async for msg in self._pubsub.listen():
                if msg["type"] != "message":
                    continue
                try:
                    data = json.loads(msg["data"])
                except (json.JSONDecodeError, TypeError):
                    continue
                if data.get("worker_id") == self._worker_id:
                    continue
                user_id = data.get("user_id")
                message = data.get("message")
                if user_id and message:
                    await self._send_local(user_id, message)
        except asyncio.CancelledError:
            pass
        except Exception:
            pass


manager = WSConnectionManager()
