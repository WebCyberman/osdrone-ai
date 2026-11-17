
from fastapi import FastAPI
from fastapi import Request
from fastapi import WebSocket

from fastapi.responses import (
    HTMLResponse,
    Response
)

from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from pydantic import BaseModel

import httpx
import asyncio

app = FastAPI(
    title="OSDrone-AI",
    version="1.0.0"
)

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
    "http://waydreams.ddns.net:9010/"
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
async def osdrone(request: Request):

    data = await request.json()

    print("OSDRONE >", data)

    event = data.get("event")

    if event == "telemetry":

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
async def goto(cmd: GotoCommand):

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
