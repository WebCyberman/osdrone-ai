// =======================================================
// DRONE AUTONOME 3D
// VERSION IA COMPATIBLE AGENTBRIDGE
// Basée sur Air Vehicle 2.3
// =======================================================

integer DEBUG = FALSE;

float DETECTION_RANGE = 40.0;
float APPROACH_DISTANCE = 15.0;
float SCAN_ALTITUDE = 4.0;

float REGION_BORDER = 20.0;
float MIN_ALT = 60.0;
float MAX_ALT = 120.0;

float ARRIVAL_DISTANCE = 10.0;

integer obstacleTicks = 0;
integer STUCK_LIMIT = 50;

// =======================================================
// IA EXTENSION
// =======================================================

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

// =======================================================

integer mode = 0;

// =======================================================
// Modes originaux
// =======================================================

integer PATROL   = 0;
integer APPROACH = 1;
integer SCAN     = 2;
integer MANUAL   = 3;

// =======================================================

vector target;
vector home;

// =======================================================

vector randomPoint()
{
    vector size = osGetRegionSize();

    //llOwnerSay("Size Region = " + size); //DEBUG

    float x =
        REGION_BORDER +
        llFrand(size.x - 2.0 * REGION_BORDER);

    float y =
        REGION_BORDER +
        llFrand(size.y - 2.0 * REGION_BORDER);

    float z =
        MIN_ALT +
        llFrand(MAX_ALT - MIN_ALT);

    return <x,y,z>;
}

// =======================================================

integer getClosestAvatar(integer count)
{
    float best = 9999.0;

    integer bestIndex = -1;

    integer i;

    for (i = 0; i < count; i++)
    {
        float d =
            llVecDist(
                llGetPos(),
                llDetectedPos(i)
            );

        if (d < best)
        {
            best = d;
            bestIndex = i;
        }
    }

    return bestIndex;
}

// =======================================================

integer obstacleAhead()
{
    vector here = llGetPos();

    if (here.z < MIN_ALT - 10.0)
    {
        target =
            <here.x,
             here.y,
             MIN_ALT + 20.0>;
    }

    vector dir =
        llRot2Fwd(
            llGetRot()
        );

    vector start = here + dir * 2.5;

    list res =
        llCastRay(
            start,
            start + dir * 8.0,
            RC_REJECT_AGENTS |
            RC_REJECT_LAND |
            RC_REJECT_PHYSICAL
        );

    /*
    //DEBUG
    key hitKey = llList2Key(res, 0);

    llOwnerSay(
        "Ray result = " +
        llDumpList2String(res,",") + ", " +
        "Hit key = " +
        (string)hitKey + ", " +
        "Hit name = " +
        (string)llKey2Name(hitKey) + ", " +
        "Hit owner = " +
        (string)llGetOwnerKey(hitKey) + ", " +
        "Drone pos = " + (string)here
    );
    */

    integer hit =
        llList2Integer(
            res,
            -1
        );

    return (hit > 0);
}

// =======================================================

sendTargetUpdate()
{
    llMessageLinked(
        LINK_SET,
        MSG_TARGET_UPDATE,
        (string)target,
        NULL_KEY
    );
}

// =======================================================

sendModeUpdate()
{
    llMessageLinked(
        LINK_SET,
        MSG_MODE_UPDATE,
        (string)mode,
        NULL_KEY
    );
}

// =======================================================

default
{
    state_entry()
    {
        llSetStatus(
            STATUS_PHYSICS,
            TRUE
        );

        llSleep(0.2);

        home = llGetPos();

        // ===================================================
        // CONFIG VEHICULE
        // ===================================================

        llSetVehicleType(
            VEHICLE_TYPE_AIRPLANE
        );

        rotation ref =
            llEuler2Rot(
                <0,90,0> * DEG_TO_RAD
            );

        llSetVehicleRotationParam(
            VEHICLE_REFERENCE_FRAME,
            ref
        );

        llSetVehicleVectorParam(
            VEHICLE_LINEAR_FRICTION_TIMESCALE,
            <200,10,5>
        );

        llSetVehicleFloatParam(
            VEHICLE_ANGULAR_FRICTION_TIMESCALE,
            20
        );

        llSetVehicleFloatParam(
            VEHICLE_LINEAR_MOTOR_TIMESCALE,
            1.5
        );

        llSetVehicleFloatParam(
            VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE,
            60
        );

        llSetVehicleFloatParam(
            VEHICLE_ANGULAR_MOTOR_TIMESCALE,
            4
        );

        llSetVehicleFloatParam(
            VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE,
            8
        );

        llSetVehicleFloatParam(
            VEHICLE_BUOYANCY,
            0.95
        );

        llSensorRepeat(
            "",
            "",
            AGENT,
            DETECTION_RANGE,
            PI,
            1.0
        );

        llSetTimerEvent(0.2);

        target = randomPoint();

        sendModeUpdate();
        sendTargetUpdate();
    }

    // ===================================================
    // COMMANDES IA
    // ===================================================

    link_message(
        integer sender,
        integer num,
        string str,
        key id
    )
    {
        if (num == CMD_GOTO)
        {
            target = (vector)str;

            mode = MANUAL;

            if(DEBUG)
            {
                llOwnerSay(
                    "CMD_GOTO -> " +
                    (string)target
                );
            }

            sendTargetUpdate();
            sendModeUpdate();
        }

        else if (num == CMD_HOVER)
        {
            mode = SCAN;
            sendModeUpdate();

            llSetVehicleVectorParam(
                VEHICLE_LINEAR_MOTOR_DIRECTION,
                ZERO_VECTOR
            );
        }

        else if (num == CMD_EXPLORE)
        {
            mode = PATROL;

            target = randomPoint();

            if(DEBUG)
            {
                llOwnerSay(
                    "RETOUR PATROL -> " +
                    (string)target
                );
            }

            sendModeUpdate();
            sendTargetUpdate();
        }

        else if (num == CMD_RETURN_HOME)
        {
            mode = APPROACH;
            sendModeUpdate();
            target = home;
            sendTargetUpdate();
        }

    }

    // ===================================================
    // DETECTION AVATARS
    // ===================================================

    sensor(integer count)
    {
        if (mode == MANUAL)
            return;

        integer idx =
            getClosestAvatar(count);

        vector pos =
            llDetectedPos(idx);

        // ===============================================
        // IA EXTENSION
        // ===============================================

        llMessageLinked(
            LINK_SET,
            MSG_AVATAR_DETECTED,
            (string)pos,
            llDetectedKey(idx)
        );

        float dist =
            llVecDist(
                llGetPos(),
                pos
            );

        if (dist > APPROACH_DISTANCE)
        {
            mode = APPROACH;

            float z =
                pos.z +
                SCAN_ALTITUDE;

            if (z > MAX_ALT)
                z = MAX_ALT - 2.0;

            target = <pos.x,pos.y,z>;

            if(DEBUG)
            {
                llOwnerSay(
                    "TARGET SENSOR -> " +
                    (string)target
                );
            }

            sendModeUpdate();
            sendTargetUpdate();
        }
        else
        {
            mode = SCAN;
        }
    }

    no_sensor()
    {
        if (mode == SCAN)
        {
            mode = PATROL;

            target = randomPoint();

            if(DEBUG)
            {
                llOwnerSay(
                    "RANDOM FROM NOSENSOR -> " +
                    (string)target
                );
            }

            sendModeUpdate();
            sendTargetUpdate();
        }
    }

    timer()
    {
        vector here =
            llGetPos();

        // ===============================================
        // CONFINEMENT
        // ===============================================

        vector size =
            osGetRegionSize();

        float margin = 5.0;

        if (here.x < margin)
            target =
                <margin + 5,
                 here.y,
                 here.z>;

        if (here.x > size.x - margin)
            target =
                <size.x - margin - 5,
                 here.y,
                 here.z>;

        if (here.y < margin)
            target =
                <here.x,
                 margin + 5,
                 here.z>;

        if (here.y > size.y - margin)
            target =
                <here.x,
                 size.y - margin - 5,
                 here.z>;

        // ===============================================
        // LIMITE ALTITUDE
        // ===============================================

        if (here.z > MAX_ALT)
        {
            target =
                <here.x,
                 here.y,
                 MAX_ALT - 5>;
        }

        // ===============================================
        // ARRIVEE
        // ===============================================

        if
        (
            llVecDist(
                here,
                target
            ) < ARRIVAL_DISTANCE
        )
        {
            llMessageLinked(
                LINK_SET,
                MSG_TARGET_REACHED,
                "",
                NULL_KEY
            );

            if (mode == MANUAL)
            {
                llOwnerSay(
                    "Destination manuelle atteinte"
                );

                mode = PATROL;

                target = randomPoint();

                sendTargetUpdate();
            }
            else
            {
                target = randomPoint();

                sendTargetUpdate();
            }
        }

        sendModeUpdate();

        // ===============================================
        // MODES
        // ===============================================

        if (mode == PATROL)
        {
            // on garde la cible jusqu'à l'arrivée
        }
        else if (mode == APPROACH)
        {
            if
            (
                llVecDist(
                    here,
                    target
                ) < APPROACH_DISTANCE + 1.0
            )
            {
                mode = SCAN;
            }
        }
        else if (mode == SCAN)
        {
            llSetText(
                "SCAN EN COURS...",
                <0,1,1>,
                1.0
            );

            return;
        }
        else if (mode == MANUAL)
        {
            if
            (
                llVecDist(
                    here,
                    target
                ) < ARRIVAL_DISTANCE
            )
            {
                mode = PATROL;
            }
        }

        // ===============================================
        // OBSTACLES
        // ===============================================

        if (obstacleAhead())
        {
            obstacleTicks++;

            llMessageLinked(
                LINK_SET,
                MSG_OBSTACLE,
                "",
                NULL_KEY
            );

            vector side =
                llRot2Left(
                    llGetRot()
                );

            llSetVehicleVectorParam(
                VEHICLE_LINEAR_MOTOR_DIRECTION,
                side * 2.0 + <0,0,1>
            );

            if (obstacleTicks > STUCK_LIMIT)
            {
                if (mode == PATROL)
                {
                    target = randomPoint();
                }

                if (mode == MANUAL)
                {
                    llOwnerSay(
                        "Impossible d'atteindre la cible"
                    );
                }
            }

            return;
        }
        else
        {
            obstacleTicks = 0;
        }

        // ===============================================
        // DEPLACEMENT
        // ===============================================

        vector dir =
            llVecNorm(
                target - here
            );

        rotation desired =
            llRotBetween(
                llRot2Fwd(llGetRot()),
                dir
            );

        /*llRotLookAt(
            desired,
            3.0,
            0.5
        );*/

        float dist =
            llVecDist(
                here,
                target
            );

        float speed = 3.0;

        if (dist < 50.0)
            speed = 2.0;

        if (dist < 20.0)
            speed = 1.0;

        if (dist < 10.0)
            speed = 0.5;

        llSetVehicleVectorParam(
            VEHICLE_LINEAR_MOTOR_DIRECTION,
            dir * speed
        );
    }
}
