
from fastapi import APIRouter
from fastapi import Request

from memory.cognitive_map import CognitiveMap

router = APIRouter()

cognitive_map = CognitiveMap()

@router.post("/api/osdrone")
async def osdrone(request: Request):

    data = await request.json()

    print("OSDRONE >", data)

    if data.get("event") == "telemetry":

        pos = data["position"]

        cognitive_map.add_position(
            pos[0],
            pos[1],
            pos[2]
        )

        print(
            "Points mémorisés :",
            len(cognitive_map.positions)
        )

    return {
        "command": "explore"
    }
