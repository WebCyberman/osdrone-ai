from fastapi import FastAPI

from api.osdrone import router

app = FastAPI(
    title="OSDrone-AI",
    version="1.0.0"
)

app.include_router(router)
