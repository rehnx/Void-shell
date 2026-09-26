import QtQuick

Canvas {
    id: root
    property string name: "wifi"
    property color ink: "white"
    implicitWidth: 24
    implicitHeight: 24
    onNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 24, height / 24);
        ctx.strokeStyle = ink;
        ctx.fillStyle = ink;
        ctx.lineWidth = 1.8;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        if (name === "wifi") {
            ctx.moveTo(3, 8); ctx.quadraticCurveTo(12, 0, 21, 8);
            ctx.moveTo(6, 12); ctx.quadraticCurveTo(12, 6, 18, 12);
            ctx.moveTo(9, 16); ctx.quadraticCurveTo(12, 13, 15, 16);
            ctx.stroke(); ctx.beginPath(); ctx.arc(12, 20, 1.2, 0, Math.PI * 2); ctx.fill();
        } else if (name === "bluetooth") {
            ctx.moveTo(7, 7); ctx.lineTo(17, 17); ctx.lineTo(12, 22);
            ctx.lineTo(12, 2); ctx.lineTo(17, 7); ctx.lineTo(7, 17); ctx.stroke();
        } else if (name === "sun") {
            ctx.arc(12, 12, 4, 0, Math.PI * 2); ctx.stroke();
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4;
                ctx.beginPath(); ctx.moveTo(12 + Math.cos(a) * 8, 12 + Math.sin(a) * 8);
                ctx.lineTo(12 + Math.cos(a) * 10, 12 + Math.sin(a) * 10); ctx.stroke();
            }
        } else if (name === "volume") {
            ctx.moveTo(3, 9); ctx.lineTo(7, 9); ctx.lineTo(12, 5); ctx.lineTo(12, 19);
            ctx.lineTo(7, 15); ctx.lineTo(3, 15); ctx.closePath(); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 12, 6, -0.8, 0.8); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 12, 10, -0.8, 0.8); ctx.stroke();
        } else {
            ctx.moveTo(3, 7); ctx.lineTo(21, 7); ctx.moveTo(3, 17); ctx.lineTo(21, 17); ctx.stroke();
            ctx.beginPath(); ctx.arc(8, 7, 3, 0, Math.PI * 2); ctx.fill();
            ctx.beginPath(); ctx.arc(16, 17, 3, 0, Math.PI * 2); ctx.fill();
        }
    }
}
