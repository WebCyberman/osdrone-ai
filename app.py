from fastapi import FastAPI

from api.osdrone import router

app = FastAPI(
    title="OSDrone-IA",
    version="0.1.0"
)

app.include_router(router)
