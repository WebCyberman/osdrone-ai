
console.log(
    "APP JS VERSION TEST"
);

const canvas =
    document.getElementById("map");

const ctx =
    canvas.getContext("2d");

/*
 * Carte OpenSimulator
 */

const mapImage =
    new Image();

mapImage.src =
    "/map";

/*
 * Région
 */

const REGION_SIZE = 512;

/*
 * Données reçues du serveur
 */

let drone = null;
let history = [];

/*
 * Conversion coordonnées monde → carte
 */

function worldToMapX(x)
{
    return (x / REGION_SIZE)
        * canvas.width;
}

function worldToMapY(y)
{
    return canvas.height -
        ((y / REGION_SIZE)
        * canvas.height);
}

/*
 * Websocket
 */

const ws =
    new WebSocket(
        `ws://${location.host}/ws`
    );

ws.onmessage =
    (event) =>
{
    const data =
        JSON.parse(
            event.data
        );

    drone =
        data.telemetry;

    history =
        data.path || [];

    draw();
};

/*
 * Dessin principal
 */

function draw()
{
    ctx.clearRect(
        0,
        0,
        canvas.width,
        canvas.height
    );

    /*
     * Carte
     */

    if (mapImage.complete)
    {
        ctx.drawImage(
            mapImage,
            0,
            0,
            canvas.width,
            canvas.height
        );
    }

    /*
     * Trajectoire
     */

    if (history.length > 1)
    {
        ctx.strokeStyle =
            "#00ffff";

        ctx.lineWidth = 2;

        ctx.beginPath();

        for
        (
            let i = 0;
            i < history.length;
            i++
        )
        {
            const p =
                history[i];

            const x =
                worldToMapX(
                    p[0]
                );

            const y =
                worldToMapY(
                    p[1]
                );

            if (i === 0)
            {
                ctx.moveTo(
                    x,
                    y
                );
            }
            else
            {
                ctx.lineTo(
                    x,
                    y
                );
            }
        }

        ctx.stroke();
    }

    if (!drone)
        return;

    /*
     * Coordonnées drone
     */

    const dx =
        worldToMapX(
            drone.x
        );

    const dy =
        worldToMapY(
            drone.y
        );

    /*
     * Drone
     */

    ctx.fillStyle = "#00ff00";

    ctx.beginPath();

    ctx.arc(
        dx,
        dy,
        6,
        0,
        Math.PI * 2
    );

    ctx.fill();

    /*
     * Cap
     */

    if
    (
        drone.heading !== undefined
    )
    {
        const angle =
            (
                drone.heading - 90
            )
            *
            Math.PI
            / 180;

        const hx =
            dx +
            Math.cos(angle) *
            20;

        const hy =
            dy +
            Math.sin(angle) *
            20;

        ctx.strokeStyle =
            "#00ff00";

        ctx.lineWidth =
            3;

        ctx.beginPath();

        ctx.moveTo(
            dx,
            dy
        );

        ctx.lineTo(
            hx,
            hy
        );

        ctx.stroke();
    }

    /*
     * Cible
     */

    if
    (
        drone.target_x !== undefined
    )
    {
        const tx =
            worldToMapX(
                drone.target_x
            );

        const ty =
            worldToMapY(
                drone.target_y
            );

        ctx.fillStyle =
            "#ff0000";

        ctx.beginPath();

        ctx.arc(
            tx,
            ty,
            5,
            0,
            Math.PI * 2
        );

        ctx.shadowBlur = 15;
        ctx.shadowColor = "#00ff00";

        ctx.fill();

        ctx.shadowBlur = 0;

        /*
         * Ligne drone -> cible
         */

        ctx.strokeStyle =
            "#ffff00";

        ctx.lineWidth =
            1;

        ctx.beginPath();

        ctx.moveTo(
            dx,
            dy
        );

        ctx.lineTo(
            tx,
            ty
        );

        ctx.stroke();
    }

    /*
     * HUD
     */

    ctx.fillStyle =
        "rgba(0,0,0,0.45)";

    ctx.fillRect(
        5,
        5,
        100,
        115
    );

    ctx.fillStyle =
        "#ffffff";

    ctx.font =
        "10px Arial";

    ctx.fillText(
        `X : ${drone.x.toFixed(1)}`,
        10,
        15
    );

    ctx.fillText(
        `Y : ${drone.y.toFixed(1)}`,
        10,
        25
    );

    ctx.fillText(
        `Z : ${drone.z.toFixed(1)}`,
        10,
        35
    );

    ctx.fillText(
        `VX:${drone.vx.toFixed(1)}`,
        10,
        45
    );

    ctx.fillText(
        `VY:${drone.vy.toFixed(1)}`,
        10,
        55
    );

    ctx.fillText(
        `TX: ${drone.target_x.toFixed(0)}`,
        10,
        65
    );

    ctx.fillText(
        `TY: ${drone.target_y.toFixed(0)}`,
        10,
        75
    );

    ctx.fillText(
        `TZ: ${drone.target_z.toFixed(0)}`,
        10,
        85
    );

    const distance =
    Math.sqrt(
        Math.pow(
            drone.target_x - drone.x,
            2
        )
        +
        Math.pow(
            drone.target_y - drone.y,
            2
        )
    );

    ctx.fillText(
        `D: ${distance.toFixed(0)}m`,
        10,
        105
    );

    ctx.fillText(
        `Mode: ${drone.mode}`,
        10,
        115
    );

    if
    (
        drone.heading !== undefined
    )
    {
        ctx.fillText(
            `Cap : ${drone.heading.toFixed(1)}°`,
            10,
            95
        );
    }

    const dxt = drone.target_x - drone.x;
    const dyt = drone.target_y - drone.y;

    let targetAngle =
        Math.atan2(dxt, dyt) * 180 / Math.PI;

    if (targetAngle < 0)
        targetAngle += 360;

    ctx.fillText(
        `Target: ${targetAngle.toFixed(0)}°`,
        10,
        130
    );
}

/*
 * Préparation futur pilotage
 */

canvas.addEventListener(
    "click",
    (event) =>
    {
        const rect =
            canvas.getBoundingClientRect();

        const px =
            event.clientX -
            rect.left;

        const py =
            event.clientY -
            rect.top;

        const worldX =
            (px / canvas.width)
            *
            REGION_SIZE;

        const worldY =
            REGION_SIZE -
            (
                (py / canvas.height)
                *
                REGION_SIZE
            );

        console.log(
            "Goto",
            worldX,
            worldY
        );

        /*
        Future API :

        fetch('/goto',
        {
            method:'POST',
            headers:
            {
                'Content-Type':
                'application/json'
            },
            body:JSON.stringify(
            {
                x:worldX,
                y:worldY,
                z:100
            })
        });
        */
    }
);
