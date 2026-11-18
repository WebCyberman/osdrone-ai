// ============================================================
// OSDrone AgentBridge v0.1
//
// Communication OpenSimulator <-> IA Python
//
// Envoi télémétrie
// Réception commandes
// Relais FlightController
//
// ============================================================

// URL FastAPI
string AI_URL = "http://192.168.18.100:8000/api/osdrone";

float TELEMETRY_INTERVAL = 1.0;

// ============================================================
// Codes messages internes
// ============================================================

integer MSG_AVATAR_DETECTED = 1001;
integer MSG_OBSTACLE        = 1002;
integer MSG_TARGET_REACHED  = 1003;
integer MSG_TARGET_UPDATE   = 1004;
integer MSG_MODE_UPDATE     = 1005;

integer CMD_GOTO            = 2001;
integer CMD_HOVER           = 2002;
integer CMD_EXPLORE         = 2003;
integer CMD_FOLLOW          = 2004;
integer CMD_RETURN_HOME     = 2005;

// ============================================================

key gLastRequest;
list gKnownAvatars;
vector gTarget;
string gMode = "PATROL";

// ============================================================

sendEvent(string json)
{
    gLastRequest =
        llHTTPRequest(
            AI_URL,
            [
                HTTP_METHOD,
                "POST",

                HTTP_MIMETYPE,
                "application/json"
            ],
            json
        );
}

// ============================================================

sendTelemetry()
{
    vector pos = llGetPos();
    vector vel = llGetVel();
    rotation rot = llGetRot();

    //vector fwd = llRot2Fwd(rot); //DEBUG
    vector vel = llGetVel();     //Vecteur vitesse

    float heading =
    llAtan2(
        vel.x,
        vel.y
    ) * RAD_TO_DEG;

    /*float heading =
        llAtan2(
            fwd.x,
            fwd.y
        ) * RAD_TO_DEG;*/

    if (heading < 0.0)
    {
        heading += 360.0;
    }

    string json =
        llList2Json(
            JSON_OBJECT,
            [
                "event", "telemetry",

                "object",
                llGetObjectName(),

                "position",
                llList2Json(
                    JSON_ARRAY,
                    [
                        pos.x,
                        pos.y,
                        pos.z
                    ]
                ),

                "target",
                llList2Json(
                    JSON_ARRAY,
                    [
                        gTarget.x,
                        gTarget.y,
                        gTarget.z
                    ]
                ),

                "heading",
                heading,

                "mode",
                gMode,

                "velocity",
                llList2Json(
                    JSON_ARRAY,
                    [
                        vel.x,
                        vel.y,
                        vel.z
                    ]
                ),

                "rotation",
                llList2Json(
                    JSON_ARRAY,
                    [
                        rot.x,
                        rot.y,
                        rot.z,
                        rot.s
                    ]
                )
            ]
        );

    sendEvent(json);
}

// ============================================================

sendAvatarDetected(
    key avatarId,
    vector avatarPos
)
{
    if (~llListFindList(gKnownAvatars,[avatarId]))
        return;

    gKnownAvatars += avatarId;

    string json =
        llList2Json(
            JSON_OBJECT,
            [
                "event",
                "avatar_detected",

                "avatar_uuid",
                (string)avatarId,

                "avatar_name",
                llKey2Name(avatarId),

                "position",
                llList2Json(
                    JSON_ARRAY,
                    [
                        avatarPos.x,
                        avatarPos.y,
                        avatarPos.z
                    ]
                )
            ]
        );

    sendEvent(json);
}

// ============================================================

sendObstacle()
{
    string json =
        llList2Json(
            JSON_OBJECT,
            [
                "event",
                "obstacle"
            ]
        );

    sendEvent(json);
}

// ============================================================

processCommand(string body)
{
    string cmd =
        llJsonGetValue(
            body,
            ["command"]
        );

    if (cmd == JSON_INVALID)
        return;

    // --------------------------------------------------------

    if (cmd == "goto")
    {
        vector target =
            <
                (float)llJsonGetValue(body,["position",0]),
                (float)llJsonGetValue(body,["position",1]),
                (float)llJsonGetValue(body,["position",2])
            >;

        llMessageLinked(
            LINK_SET,
            CMD_GOTO,
            (string)target,
            NULL_KEY
        );
    }

    // --------------------------------------------------------

    else if (cmd == "hover")
    {
        llMessageLinked(
            LINK_SET,
            CMD_HOVER,
            "",
            NULL_KEY
        );
    }

    // --------------------------------------------------------

    else if (cmd == "explore")
    {
        llMessageLinked(
            LINK_SET,
            CMD_EXPLORE,
            "",
            NULL_KEY
        );
    }

    // --------------------------------------------------------

    else if (cmd == "return_home")
    {
        llMessageLinked(
            LINK_SET,
            CMD_RETURN_HOME,
            "",
            NULL_KEY
        );
    }

    // --------------------------------------------------------

    else if (cmd == "say")
    {
        string txt =
            llJsonGetValue(
                body,
                ["message"]
            );

        llSay(0, txt);
    }
}

// ============================================================

default
{
    state_entry()
    {
        llOwnerSay(
            "SphereBot AgentBridge online"
        );

        llSetTimerEvent(
            TELEMETRY_INTERVAL
        );
    }

    timer()
    {
        sendTelemetry();
    }

    // --------------------------------------------------------
    // Réception évènements FlightController
    // --------------------------------------------------------

    link_message(
        integer sender,
        integer num,
        string str,
        key id
    )
    {
        /*
        //DEBUG
        if (num == MSG_AVATAR_DETECTED)
        {
            llOwnerSay("EVENT AVATAR");
        }
        else if (num == MSG_OBSTACLE)
        {
            llOwnerSay("EVENT OBSTACLE");
        }
        else if (num == MSG_TARGET_REACHED)
        {
            llOwnerSay("EVENT TARGET");
        }
        else
        {
            llOwnerSay("EVENT OTHER " + (string)num);
        }
        */

        if (num == MSG_OBSTACLE)
        {
            sendObstacle();
        }

        else if (num == MSG_AVATAR_DETECTED)
        {
            sendAvatarDetected(
                id,
                (vector)str
            );
        }

        else if (num == MSG_TARGET_REACHED)
        {
            string json =
                llList2Json(
                    JSON_OBJECT,
                    [
                        "event",
                        "target_reached"
                    ]
                );

            sendEvent(json);
        }

        else if (num == MSG_TARGET_UPDATE)
        {
            gTarget = (vector)str;

            /*llOwnerSay(
                "TARGET UPDATE = " +
                (string)gTarget
            );*/
        }
        else if (num == MSG_MODE_UPDATE)
        {
            integer m = (integer)str;

            if (m == 0)
                gMode = "PATROL";
            else if (m == 1)
                gMode = "APPROACH";
            else if (m == 2)
                gMode = "SCAN";
            else if (m == 3)
                gMode = "MANUAL";
        }
    }

    // --------------------------------------------------------
    // Réponse du serveur IA
    // --------------------------------------------------------

    http_response(
        key request_id,
        integer status,
        list metadata,
        string body
    )
    {
        if (request_id != gLastRequest)
            return;

        if (status != 200)
            return;

        processCommand(body);
    }
}
