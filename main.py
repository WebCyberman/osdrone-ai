
import os

from fastapi import FastAPI
from fastapi import WebSocket
from fastapi import Depends

from fastapi import Request, Header, HTTPException

from fastapi.responses import (
    HTMLResponse,
    Response
)

from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from pydantic import BaseModel

from dotenv import load_dotenv

from pathlib import Path
import logging
from logging.handlers import RotatingFileHandler
import json

import httpx
import asyncio

# --------------------------------------------------
# HEADER
# --------------------------------------------------

app = FastAPI(
    title="OSDrone-AI",
    version="1.0.0"
)

# --------------------------------------------------
# APIKEY
# --------------------------------------------------

load_dotenv()

API_KEY = os.getenv("API_KEY")

def check_api_key(
    request: Request,
    x_api_key: str = Header(None)
):
    client_ip = (
        request.client.host
        if request.client
        else "unknown"
    )

    if not x_api_key:
        logger.warning(
            f"API KEY MISSING FROM {client_ip}"
        )
        raise HTTPException(
            status_code=401,
            detail="API key missing"
        )

    if x_api_key != API_KEY:
        logger.warning(
            f"BAD API KEY FROM {client_ip}"
        )
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )

# --------------------------------------------------
# DEBUG
# --------------------------------------------------

DEBUG = os.getenv(
    "DEBUG",
    "false"
).lower() == "true"

# --------------------------------------------------
# DOSSIERS
# --------------------------------------------------

Path("data").mkdir(
    exist_ok=True
)

Path("logs").mkdir(
    exist_ok=True
)

# --------------------------------------------------
# LOGGING
# --------------------------------------------------

logger = logging.getLogger("osdrone-ai")
logger.setLevel(logging.INFO)

handler = RotatingFileHandler(
    "logs/osdrone-ai.log",
    maxBytes=5 * 1024 * 1024,  # 5 MB
    backupCount=5,
    encoding="utf-8"
)

handler.setFormatter(
    logging.Formatter(
        "%(asctime)s - %(levelname)s - %(message)s"
    )
)

logger.addHandler(handler)

# --------------------------------------------------
# STATIC
# --------------------------------------------------

app.mount(
    "/static",
    StaticFiles(directory="static"),
    name="static"
)

templates = Jinja2Templates(
    directory="templates"
)

# --------------------------------------------------
# CARTE REGION
# --------------------------------------------------

MAP_URL = (
    "http://192.168.18.21:9010/"
    "index.php?"
    "method=regionImage5ac88c84e532440b92c85e7578020f02"
)

# --------------------------------------------------
# TELEMETRIE PARTAGEE
# --------------------------------------------------

telemetry = {
    "x": 0.0,
    "y": 0.0,
    "z": 0.0,

    "vx": 0.0,
    "vy": 0.0,
    "vz": 0.0,

    "heading": 0.0,

    "target_x": 0.0,
    "target_y": 0.0,
    "target_z": 0.0,

    "mode": "WAIT"
}

path_history = []

# --------------------------------------------------
# COMMANDES EN ATTENTE
# --------------------------------------------------

pending_command = None

# --------------------------------------------------
# PAGE PRINCIPALE
# --------------------------------------------------

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):

    return templates.TemplateResponse(
        request=request,
        name="index.html"
    )

# --------------------------------------------------
# SERVER HEALTH
# --------------------------------------------------

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "project": "OSDrone-AI",
        "websocket": True
    }

# --------------------------------------------------
# IMAGE REGION
# --------------------------------------------------

@app.get("/map")
async def get_map():

    async with httpx.AsyncClient() as client:

        response = await client.get(MAP_URL)

        return Response(
            content=response.content,
            media_type="image/jpeg"
        )

# --------------------------------------------------
# ENDPOINT DRONE EXISTANT
# --------------------------------------------------

@app.post("/api/osdrone")
async def osdrone(
    request: Request,
    _ = Depends(check_api_key)
):

    data = await request.json()

    if DEBUG:
        print("OSDRONE >", data)

    event = data.get("event")

    if event == "telemetry":

        if DEBUG:
            logger.info(
                f"Telemetry : {data}"
            )

        with open(
                "data/telemetry.json",
                "w",
                encoding="utf-8"
        ) as f:
            json.dump(
                data,
                f,
                indent=2
            )

        pos = data.get("position")

        if pos and len(pos) >= 3:

            telemetry["x"] = pos[0]
            telemetry["y"] = pos[1]
            telemetry["z"] = pos[2]

            path_history.append(
                (
                    pos[0],
                    pos[1]
                )
            )

            if len(path_history) > 1000:
                path_history.pop(0)

        vel = data.get("velocity")

        if vel and len(vel) >= 3:
            telemetry["vx"] = vel[0]
            telemetry["vy"] = vel[1]
            telemetry["vz"] = vel[2]

        target = data.get("target")

        if target and len(target) >= 3:

            telemetry["target_x"] = target[0]
            telemetry["target_y"] = target[1]
            telemetry["target_z"] = target[2]

        heading = data.get("heading")

        if heading is not None:
            telemetry["heading"] = heading

        mode = data.get("mode")

        if mode:
            telemetry["mode"] = mode

    else:

        logger.info(
            f"Event : {data}"
        )

    global pending_command

    if pending_command:
        cmd = pending_command
        pending_command = None
        return cmd

    return {
        #"command": "explore"
        "command": "none"
    }

class GotoCommand(BaseModel):
    x: float
    y: float
    z: float

@app.post("/goto")
async def goto(
    cmd: GotoCommand,
    _ = Depends(check_api_key)
):

    global pending_command

    pending_command = {
        "command": "goto",
        "position": [
            cmd.x,
            cmd.y,
            cmd.z
        ]
    }

    return {
        "status": "queued"
    }

# --------------------------------------------------
# WEBSOCKET
# --------------------------------------------------

@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket
):

    await websocket.accept()

    try:

        while True:

            await websocket.send_json(
                {
                    "telemetry": telemetry,
                    "path": path_history
                }
            )

            await asyncio.sleep(0.25)

    except Exception:

        print(
            "Websocket disconnected"
        )
