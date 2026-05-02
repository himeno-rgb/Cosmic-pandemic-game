import QtQuick
import QtQuick.Controls
import GameLogic 1.0

Window {
    width: 1000
    height: 800
    visible: true
    title: qsTr("星系复兴：链式管理系统 (复交机制版)")
    color: "#0f172a"

    // --- 全局核心数据 ---
    property var starObjects: []
    property var visualStarItems: []
    property var globalTradeLinks: []  // 活跃航线
    property var severedTradeLinks: [] // 【新增】：历史断交航线（复交档案）
    property int globalA: 20
    property int globalB: 5
    property int currentTurn: 1        // 【新增】：当前回合数，开局默认第 1 回合
    // --- 交互状态机 ---
    property var selectedStar: null
    property string selectedStarName: ""
    property int selectedLineIndex: -1
    property bool isAiming: false
    property int aimingSourceId: -1

    property int selectedStarId: {
        if (!selectedStar) return -1;
        for(let i = 0; i < starObjects.length; i++) {
            if(starObjects[i] === selectedStar) return i;
        }
        return -1;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            selectedStar = null;
            selectedLineIndex = -1;
            isAiming = false;
        }
    }

    Row {
        id: topBar
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20; spacing: 30; z: 10
        Text { text: "经济点数 (A): " + globalA; color: "#fbbf24"; font.bold: true; font.pixelSize: 24 }
        Text { text: "|"; color: "#475569"; font.pixelSize: 24 }
        Text { text: "政治点数 (B): " + globalB; color: "#60a5fa"; font.bold: true; font.pixelSize: 24 }
    }
    // --- 【新增】：右上角回合计数器 ---
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 120; height: 40
        color: Qt.rgba(0.12, 0.16, 0.22, 0.8) // 半透明深色底
        border.color: "#38bdf8" // 科技蓝边框
        border.width: 2
        radius: 6
        z: 10

        Text {
            text: "第 " + currentTurn + " 回合"
            color: "white"
            font.pixelSize: 16
            font.bold: true
            anchors.centerIn: parent
        }
    }

    Text {
        visible: isAiming
        text: "🎯 重新部署中：请在地图上点击新的接收星系 (C)"
        color: "#fbbf24"; font.pixelSize: 24; font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter; y: 60; z: 999
    }

    Item {
        id: universeMap
        // 【已修复坐标漂移】：锁死图层大小并永远居中
        width: 1000; height: 800
        anchors.centerIn: parent
        z: 2

        Repeater {
            model: globalTradeLinks
            delegate: Rectangle {
                property int fromIndex: modelData.fromId
                property int toIndex: modelData.toId
                property var vSource: visualStarItems[fromIndex]
                property var vTarget: visualStarItems[toIndex]

                property real startX: vSource ? vSource.x + vSource.width / 2 : 0
                property real startY: vSource ? vSource.y + vSource.height / 2 : 0
                property real endX: vTarget ? vTarget.x + vTarget.width / 2 : 0
                property real endY: vTarget ? vTarget.y + vTarget.height / 2 : 0

                x: startX; y: startY - height / 2
                width: Math.sqrt(Math.pow(endX-startX, 2) + Math.pow(endY-startY, 2))
                height: selectedLineIndex === index ? 6 : 2
                transformOrigin: Item.Left
                rotation: Math.atan2(endY - startY, endX - startX) * 180 / Math.PI
                z: 1
                color: vSource ? Qt.alpha(vSource.baseColor, selectedLineIndex === index ? 1.0 : 0.6) : "white"
            }
        }

        Rectangle {
            width: 60; height: 60; radius: 30; z: 5; anchors.centerIn: parent
            color: "transparent"; border.color: "#38bdf8"; border.width: 2; opacity: 0.8
            Rectangle {
                width: 20; height: 20; radius: 10; color: "#38bdf8"; anchors.centerIn: parent
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                }
            }
        }

        Component.onCompleted: {
            var pool = [];
            for (var p1 = 0; p1 < 10; p1++) pool.push({level: 1, color: "#22c55e", name: "一级星"});
            for (var p2 = 0; p2 < 7; p2++) pool.push({level: 2, color: "#eab308", name: "二级星"});
            for (var s = pool.length - 1; s > 0; s--) {
                var rIndex = Math.floor(Math.random() * (s + 1));
                var temp = pool[s]; pool[s] = pool[rIndex]; pool[rIndex] = temp;
            }

            var ringConfigs = [ {total: 3, r: 120}, {total: 7, r: 240}, {total: 10, r: 380} ];
            var centerX = width / 2; var centerY = height / 2;
            var allVisualStars = []; var tempVisualItems = [];

            for (var j = 0; j < ringConfigs.length; j++) {
                var ring = ringConfigs[j];
                var currentRingStars = [{level: 3, color: "#ef4444", name: "三级星"}];
                for (var k = 0; k < ring.total - 1; k++) currentRingStars.push(pool.pop());

                for (var i = 0; i < ring.total; i++) {
                    var starData = currentRingStars[i];
                    var angle = (i / ring.total) * Math.PI * 2;
                    var posX = centerX + ring.r * Math.cos(angle);
                    var posY = centerY + ring.r * Math.sin(angle);

                    var starLogic = Qt.createQmlObject('import GameLogic 1.0; Star {}', universeMap);
                    starObjects.push(starLogic);

                    var currentIdx = allVisualStars.length;
                    var circle = Qt.createQmlObject(`
                        import QtQuick
                        Rectangle {
                            width: 40; height: 40; radius: 20;
                            property var logic; property string baseColor: "${starData.color}"; property string starName: "${starData.name}";
                            property int myId: ${currentIdx};
                            border.width: selectedStar === logic ? 3 : 2;
                            border.color: selectedStar === logic ? "#ffffff" : "#475569";
                            color: logic.p_K === 0 ? baseColor : Qt.rgba(1, 1 - (logic.p_K/100), 1 - (logic.p_K/100), 1);
                            Text { text: logic.p_K > 0 ? "K:" + logic.p_K : starName; anchors.centerIn: parent; color: logic.p_K === 0 ? "white" : "black"; font.pixelSize: 10; font.bold: true; }
                            MouseArea {
                                anchors.fill: parent; propagateComposedEvents: false;
                                onClicked: (mouse) => {
                                    if (isAiming) {
                                        let cId = myId;
                                        let oldBId = globalTradeLinks[selectedLineIndex].toId;
                                        if (cId === aimingSourceId || cId === oldBId) return;

                                        let links = [...globalTradeLinks];
                                        starObjects[oldBId].addM(-30);
                                        starObjects[cId].addM(30);
                                        starObjects[aimingSourceId].addM(-10);

                                        // 【新增】：被改签掉的旧航线，记入断交档案！
                                        let severed = [...severedTradeLinks];
                                        severed.push({fromId: aimingSourceId, toId: oldBId});
                                        severedTradeLinks = severed;

                                        links[selectedLineIndex].toId = cId;
                                        globalTradeLinks = links;
                                        isAiming = false; selectedLineIndex = -1;
                                    } else {
                                        selectedStar = logic; selectedStarName = starName; selectedLineIndex = -1;
                                    }
                                    mouse.accepted = true;
                                }
                            }
                        }
                    `, universeMap);
                    circle.x = posX - 20; circle.y = posY - 20; circle.logic = starLogic;
                    tempVisualItems.push(circle);
                    allVisualStars.push({ id: currentIdx, level: starData.level, cx: posX, cy: posY });
                }
            }
            visualStarItems = tempVisualItems;

            var finalLinks = [];
            var outboundSlots = [];
            for (var idx = 0; idx < allVisualStars.length; idx++) {
                for (var slot = 0; slot < allVisualStars[idx].level; slot++) outboundSlots.push(idx);
            }
            for (var sIdx = 0; sIdx < outboundSlots.length; sIdx++) {
                var sourceId = outboundSlots[sIdx];
                var targetId = -1;
                for (var att = 0; att < 50; att++) {
                    var rId = Math.floor(Math.random() * allVisualStars.length);
                    if (rId !== sourceId) {
                        var exist = false;
                        for (var c = 0; c < finalLinks.length; c++) {
                            if ((finalLinks[c].fromId === sourceId && finalLinks[c].toId === rId) ||
                                (finalLinks[c].fromId === rId && finalLinks[c].toId === sourceId)) { exist = true; break; }
                        }
                        if (!exist) { targetId = rId; break; }
                    }
                }
                if (targetId !== -1) finalLinks.push({ fromId: sourceId, toId: targetId });
            }
            globalTradeLinks = finalLinks;
            for (var l = 0; l < finalLinks.length; l++) {
                starObjects[finalLinks[l].fromId].addM(30); starObjects[finalLinks[l].toId].addM(30);
            }
            // --- 在这里插入病毒种子 ---
            if (starObjects.length > 0) {
                var luckyIdx = Math.floor(Math.random() * starObjects.length);
                starObjects[luckyIdx].infect();
                console.log("零号病人降临在星系：" + luckyIdx);
            }
        }
    }

    // --- 1. 恒星主面板 (一级) ---
    Rectangle {
        id: infoPanel
        z: 100; width: 250; height: 570
        x: (selectedStar !== null) ? 20 : -width - 20; y: 80
        color: Qt.rgba(0.12, 0.16, 0.22, 0.95); border.color: "#334155"; border.width: 2; radius: 6
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            Text { text: "📡 " + selectedStarName; color: "white"; font.bold: true; font.pixelSize: 20 }
            Rectangle { width: parent.width; height: 1; color: "#475569" }
            Text { text: "☣️ 疫情指数 (K):  " + (selectedStar ? selectedStar.p_K : ""); color: selectedStar && selectedStar.p_K > 0 ? "#ef4444" : "#22c55e"; font.bold: true }
            Text { text: "🛡️ 稳定度 (P):  " + (selectedStar ? selectedStar.p_P : ""); color: "white" }
            // 【已找回】：独立度 Q
            Text { text: "🧱 独立度 (Q):  " + (selectedStar ? selectedStar.p_Q : ""); color: "white" }
            Text { text: "⚙️ 生产度 (N):  " + (selectedStar ? selectedStar.p_N : ""); color: "#fbbf24" }
            Text { text: "🤝 贸易度 (M):  " + (selectedStar ? selectedStar.p_M : ""); color: "#fbbf24" }

            // --- 辖下航线按钮列 ---
            Rectangle { width: parent.width; height: 1; color: "#475569" }
            Text { text: "🌌 辖下航线管理 (主权)"; color: "#94a3b8"; font.pixelSize: 12 }

            Column {
                width: parent.width; spacing: 5

                // 活跃航线
                Repeater {
                    model: globalTradeLinks.length
                    delegate: Button {
                        width: 210
                        visible: selectedStarId !== -1 && globalTradeLinks[index].fromId === selectedStarId
                        height: visible ? 30 : 0
                        text: "贸易线 -> 目标星系 " + (visible ? globalTradeLinks[index].toId : "")
                        onClicked: selectedLineIndex = (selectedLineIndex === index) ? -1 : index
                        background: Rectangle {
                            color: selectedLineIndex === index ? "#3b82f6" : "#334155"
                            radius: 4
                        }
                    }
                }

                // 【新增】：历史断交航线（可恢复）
                Repeater {
                    model: severedTradeLinks.length
                    delegate: Button {
                        width: 210
                        visible: selectedStarId !== -1 && severedTradeLinks[index].fromId === selectedStarId
                        height: visible ? 30 : 0
                        text: "🔧 恢复航线 -> 星系 " + (visible ? severedTradeLinks[index].toId + " (A-5)": "")
                        palette.buttonText: "#cbd5e1"
                        enabled: globalA >= 5
                        background: Rectangle {
                            color: "#475569" // 灰暗色调表示断交状态
                            border.color: "#64748b"
                            radius: 4
                        }
                        onClicked: {
                            globalA -= 5;
                            // 1. 恢复数据
                            let active = [...globalTradeLinks];
                            let restored = severedTradeLinks[index];
                            active.push(restored);
                            globalTradeLinks = active;

                            // 2. 扣除历史本
                            let sLinks = [...severedTradeLinks];
                            sLinks.splice(index, 1);
                            severedTradeLinks = sLinks;

                            // 3. 经济数值归还
                            starObjects[restored.fromId].addM(30);
                            starObjects[restored.toId].addM(30);
                        }
                    }
                }
            }

            // --- 【已完善】：双轨制行政干预矩阵 ---
            Rectangle { width: parent.width; height: 1; color: "#475569" }
            Text { text: "行政与经济指令 (资源 A:" + globalA + " B:" + globalB + ")"; color: "#94a3b8"; font.pixelSize: 12 }

            Row {
                width: parent.width; spacing: 10
                Button {
                    text: "经济渗透 (A-10)\n降独立(Q)"; width: (parent.width - 10) / 2
                    enabled: globalA >= 10 && selectedStar !== null
                    onClicked: { globalA -= 10; selectedStar.modifyAttribute("Q", -10); }
                }
                Button {
                    text: "商业补贴 (A-10)\n升贸易(M)"; width: (parent.width - 10) / 2
                    enabled: globalA >= 10 && selectedStar !== null
                    onClicked: { globalA -= 10; selectedStar.addM(15); }
                }
            }
            Row {
                width: parent.width; spacing: 10
                Button {
                    text: "维稳宣传 (B-5)\n升稳定(P)"; width: (parent.width - 10) / 2
                    enabled: globalB >= 5 && selectedStar !== null
                    onClicked: { globalB -= 5; selectedStar.modifyAttribute("P", 10); }
                }
                Button {
                    text: "生产动员 (B-5)\n升生产(N)"; width: (parent.width - 10) / 2
                    enabled: globalB >= 5 && selectedStar !== null
                    onClicked: { globalB -= 5; selectedStar.modifyAttribute("N", 15); }
                }
            }
            Button {
                text: "⚠️ 实施高压封锁 (B-5) -> 强压疫情"
                width: parent.width; background: Rectangle { color: "#b91c1c"; radius: 4 }
                palette.buttonText: "white"
                enabled: globalB >= 5 && selectedStar !== null
                onClicked: { globalB -= 5; selectedStar.enforceLockdown(); }
            }
        }
    }

    // --- 2. 航线面板 (二级链式) ---
    Rectangle {
        id: linePanel
        z: 99; width: 230; height: 260
        x: (selectedLineIndex !== -1 && !isAiming && selectedStar !== null) ? (infoPanel.x + infoPanel.width + 10) : -width - 50
        y: 80
        color: Qt.rgba(0.2, 0.1, 0.15, 0.95); border.color: "#3b82f6"; border.width: 2; radius: 6
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Column {
            anchors.fill: parent; anchors.margins: 15; spacing: 15
            Text { text: "🔗 航线档案 " + selectedLineIndex; color: "white"; font.bold: true }
            Text { text: "输入方: 星系 " + (selectedLineIndex !== -1 ? globalTradeLinks[selectedLineIndex].toId : ""); color: "#94a3b8" }
            Text { text: "经济贡献: 各 +30 M"; color: "#fbbf24" }
            Rectangle { width: parent.width; height: 1; color: "#475569" }
            Button {
                text: "✂️ 取消该贸易线"; width: parent.width
                onClicked: {
                    let links = [...globalTradeLinks]; let link = links[selectedLineIndex];

                    // 扣除经济
                    starObjects[link.fromId].addM(-30); starObjects[link.toId].addM(-30);

                    // 【新增】：被取消的线，记入断交档案！
                    let severed = [...severedTradeLinks];
                    severed.push({fromId: link.fromId, toId: link.toId});
                    severedTradeLinks = severed;

                    // 彻底删除活跃线
                    links.splice(selectedLineIndex, 1); globalTradeLinks = links; selectedLineIndex = -1;
                }
            }
            Button {
                text: "🎯 重新部署 (A-5)"; width: parent.width; background: Rectangle { color: "#eab308" }
                enabled: globalA >= 5
                onClicked: { globalA -= 5; aimingSourceId = globalTradeLinks[selectedLineIndex].fromId; isAiming = true; }
            }
        }
    }

    // --- 【已修复高大上 UI】：回合结算按钮 ---
    Button {
        text: "推进至下一回合 >>"
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 30
        width: 180; height: 50
        font.pixelSize: 16; font.bold: true
        palette.buttonText: "white"
        background: Rectangle {
            color: parent.down ? "#2563eb" : "#3b82f6"
            radius: 8
            border.color: "#60a5fa"
            border.width: 2
        }
        onClicked: {
            var turnA = 0; var sumK = 0; var sumQ = 0;
            var links = globalTradeLinks;
            for (var l = 0; l < links.length; l++) {
                var sA = starObjects[links[l].fromId]; var sB = starObjects[links[l].toId];
                if (sA.p_K > 15) sB.receiveInfection(sA.p_K);
                if (sB.p_K > 15) sA.receiveInfection(sB.p_K);
            }
            for (var i = 0; i < starObjects.length; i++) {
                var star = starObjects[i]; star.nextTurn();
                sumK += star.p_K; sumQ += star.p_Q;
                turnA += Math.floor((star.p_N + star.p_M) * (100 - star.p_K) / 10000);
            }
            globalA += turnA; globalB += (1 + Math.floor(sumK / 200));
            // 【新增】：结算完所有数据后，回合数 +1
            currentTurn += 1;
        }
    }
}