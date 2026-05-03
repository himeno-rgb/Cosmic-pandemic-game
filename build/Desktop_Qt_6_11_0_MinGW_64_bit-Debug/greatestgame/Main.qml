import QtQuick
import QtQuick.Controls
import GameLogic 2.0

Window {
    width: 1000
    height: 800
    visible: true
    title: qsTr("银河帝国：疫情管理")
    color: "#0f172a"

    // --- 全局核心数据 ---
    property var starObjects: []
    property var visualStarItems: []
    property var globalTradeLinks: []  // 活跃航线
    property var severedTradeLinks: [] // 历史断交航线（复交档案）
    property var starLevels: []        // 【新增】：用来存储每个星系对应的等级 (1, 2, 3)
    property int globalA: 20
    property int globalB: 5
    property int currentTurn: 1        // 当前回合数，开局默认第 1 回合

    // --- 【新增】：全局动态指标数据 ---
    property int globalScore: 0
    property int globalInfectionRate: 0

    property int patientZeroId: -1     // 【新增】：记录零号病人身份，犹如悬在头顶的剑

    // 帝国高维监控探头：每秒刷新 10 次，实时捕捉你任何操作带来的连锁反应
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (starObjects.length === 0) return;

            var totalK = 0;
            var totalProsperity = 0;

            for (var i = 0; i < starObjects.length; i++) {
                totalK += starObjects[i].p_K;
                totalProsperity += (starObjects[i].p_N + starObjects[i].p_M);
            }

            // 算术平均值就是百分比，因为单星 K 值上限就是 100
            globalInfectionRate = Math.round(totalK / starObjects.length);

            // 帝国霸权实时评分 = 绝对繁荣度 * 健康系数
            globalScore = Math.round(totalProsperity * ((100 - globalInfectionRate) / 100));
        }
    }

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

    // --- 【新增】：左上角全局态势仪表盘 ---
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        spacing: 12
        z: 10

        Text {
            text: "🏆 帝国霸权分数: " + globalScore
            color: "#c084fc" // 神秘且高级的紫色
            font.pixelSize: 22
            font.bold: true

            // 加点动态反馈：分数变化时给个呼吸灯效果
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: parent; property: "opacity"; to: 0.5; duration: 100 }
                    NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 100 }
                }
            }
        }

        Text {
            text: "☣️ 全局疫情指数: " + globalInfectionRate + "%"
            // 根据灾难程度变色：绿 -> 黄 -> 刺眼的红
            color: globalInfectionRate > 50 ? "#ef4444" : (globalInfectionRate > 20 ? "#f59e0b" : "#10b981")
            font.pixelSize: 20
            font.bold: true
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

    // --- 右上角回合计数器 ---
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 120; height: 40
        color: Qt.rgba(0.12, 0.16, 0.22, 0.8)
        border.color: "#38bdf8"
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
                    starLevels.push(starData.level); // 【新增】：存储星系等级

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

                                        // 【修改】：计算旧目标和新目标的星级差异
                                        let oldBLvl = starLevels[oldBId];
                                        let newCLvl = starLevels[cId];
                                        starObjects[oldBId].addM(-(oldBLvl * 10)); // 旧邻居掉钱
                                        starObjects[cId].addM(newCLvl * 10);       // 新邻居赚钱

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

            // 【修改】：动态计算初始贸易加成
            for (var l = 0; l < finalLinks.length; l++) {
                var fId = finalLinks[l].fromId;
                var tId = finalLinks[l].toId;
                starObjects[fId].addM(starLevels[fId] * 10);
                starObjects[tId].addM(starLevels[tId] * 10);
            }

            // --- 在这里插入病毒种子 ---
            if (starObjects.length > 0) {
                var luckyIdx = Math.floor(Math.random() * starObjects.length);
                starObjects[luckyIdx].infect();
                patientZeroId = luckyIdx;
                console.log("零号病人降临在星系：" + luckyIdx);
            }
        }
    }

    // --- 1. 恒星主面板 (一级) ---
    Rectangle {
        id: infoPanel
        z: 100; width: 270; height: 680 // 【UI修复】：拉高变宽，防止局促
        x: (selectedStar !== null) ? 20 : -width - 20; y: 80
        color: Qt.rgba(0.12, 0.16, 0.22, 0.95); border.color: "#334155"; border.width: 2; radius: 6
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        // 【UI修复】：引入 ScrollView 和裁剪机制
        ScrollView {
            anchors.fill: parent
            anchors.margins: 15
            clip: true // 强行切断溢出，启动内部滚动

            // --- 【终结丑陋】：强行隐藏滚动条实体，但保留滚轮功能 ---
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                width: 245
                spacing: 12

                Text { text: "📡 " + selectedStarName; color: "white"; font.bold: true; font.pixelSize: 20 }
                Rectangle { width: parent.width; height: 1; color: "#475569" }
                Text { text: "☣️ 疫情指数 (K):  " + (selectedStar ? selectedStar.p_K : ""); color: selectedStar && selectedStar.p_K > 0 ? "#ef4444" : "#22c55e"; font.bold: true }
                Text { text: "🛡️ 稳定度 (P):  " + (selectedStar ? selectedStar.p_P : ""); color: "white" }
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
                            width: parent.width // 自适应列宽
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

                    // 历史断交航线（可恢复）
                    Repeater {
                        model: severedTradeLinks.length
                        delegate: Button {
                            width: parent.width // 自适应列宽
                            visible: selectedStarId !== -1 && severedTradeLinks[index].fromId === selectedStarId
                            height: visible ? 30 : 0
                            text: "🔧 恢复航线 -> 星系 " + (visible ? severedTradeLinks[index].toId + " (A-5)": "")
                            palette.buttonText: "#cbd5e1"
                            enabled: globalA >= 5
                            background: Rectangle {
                                color: "#475569"
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

                                // 3. 经济数值归还 (【修改】：动态读取双方星级)
                                let fLvl = starLevels[restored.fromId];
                                let tLvl = starLevels[restored.toId];
                                starObjects[restored.fromId].addM(fLvl * 10);
                                starObjects[restored.toId].addM(tLvl * 10);
                            }
                        }
                    }
                }

                // --- 双轨制行政干预矩阵 ---
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
                        text: "维稳宣传 (B-3)\n升稳定(P)"; width: (parent.width - 10) / 2
                        enabled: globalB >= 3 && selectedStar !== null
                        onClicked: { globalB -= 3; selectedStar.modifyAttribute("P", 10); }
                    }
                    Button {
                        text: "生产动员 (B-3)\n升生产(N)"; width: (parent.width - 10) / 2
                        enabled: globalB >= 3 && selectedStar !== null
                        onClicked: { globalB -= 3; selectedStar.modifyAttribute("N", 15); }
                    }
                }
                Button {
                    text: "⚠️ 实施高压封锁 (B-5) -> 强压疫情"
                    width: parent.width; background: Rectangle { color: "#b91c1c"; radius: 4 }
                    palette.buttonText: "white"
                    enabled: globalB >= 5 && selectedStar !== null
                    onClicked: { globalB -= 5; selectedStar.enforceLockdown(); }
                }

                // --- 【新增】：终极协议 (改变游戏规则的极端手段) ---
                Rectangle { width: parent.width; height: 1; color: "#475569" }
                Text { text: "💀 终极协议 (高风险/高收益)"; color: "#f87171"; font.pixelSize: 12; font.bold: true }

                Button {
                    text: "💰 设立星际黑市 (A-50)\n[贸易度狂飙, 独立度永久极高]"
                    width: parent.width; height: 50
                    background: Rectangle { color: "#854d0e"; radius: 4 } // 暗金色
                    palette.buttonText: "white"
                    enabled: globalA >= 50 && selectedStar !== null
                    onClicked: {
                        globalA -= 50;
                        // 1. 贸易额发生爆炸式增长 (+80)
                        selectedStar.addM(80);
                        // 2. 付出惨痛代价：独立度直接拉满，中央政府彻底失去监管
                        selectedStar.modifyAttribute("Q", 100);
                        // (由于Q拉满，只要感染一丝病毒，就会在这个星球上以恐怖的速度爆发)
                    }
                }

                Button {
                    text: "💥 轨道焦土指令 (B-15)\n[物理毁灭：强制全网断交并镇压]"
                    width: parent.width; height: 50
                    background: Rectangle { color: "#7f1d1d"; radius: 4 } // 暗血红色
                    palette.buttonText: "white"
                    enabled: globalB >= 15 && selectedStar !== null
                    onClicked: {
                        globalB -= 15;

                        // 1. 物理毁灭：生产和稳定彻底归零
                        selectedStar.modifyAttribute("N", -100);
                        selectedStar.modifyAttribute("P", -100);

                        // 2. 三重高压封锁强行把 K 值砸进地心
                        selectedStar.enforceLockdown();
                        selectedStar.enforceLockdown();
                        selectedStar.enforceLockdown();

                        // 3. 终极隔离：暴力切断该星球身上的【所有】活跃航线
                        let links = [...globalTradeLinks];
                        let newLinks = [];
                        let severed = [...severedTradeLinks];

                        for(let i = 0; i < links.length; i++) {
                            if(links[i].fromId === selectedStarId || links[i].toId === selectedStarId) {
                                // 记入断交档案
                                severed.push(links[i]);
                                // 强制扣除双方的星级贸易值
                                let fLvl = starLevels[links[i].fromId];
                                let tLvl = starLevels[links[i].toId];
                                starObjects[links[i].fromId].addM(-(fLvl * 10));
                                starObjects[links[i].toId].addM(-(tLvl * 10));
                            } else {
                                // 不相关的航线保留
                                newLinks.push(links[i]);
                            }
                        }
                        globalTradeLinks = newLinks;
                        severedTradeLinks = severed;
                    }
                }
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

            // 【修改】：动态显示这条线两端的真实贸易价值
            Text {
                text: selectedLineIndex !== -1 ?
                      "经济贡献: 源 +" + (starLevels[globalTradeLinks[selectedLineIndex].fromId] * 10) +
                      " M, 目标 +" + (starLevels[globalTradeLinks[selectedLineIndex].toId] * 10) + " M" : ""
                color: "#fbbf24"
            }

            Rectangle { width: parent.width; height: 1; color: "#475569" }

            Button {
                // 【稳健写法】：利用派生属性建立绝对安全的依赖，自带越界保护
                property var currentLink: (selectedLineIndex >= 0 && selectedLineIndex < globalTradeLinks.length) ? globalTradeLinks[selectedLineIndex] : null
                property bool isFatal: currentLink ? (currentLink.fromId === patientZeroId || currentLink.toId === patientZeroId) : false

                text: isFatal ? "⚠️ 疫源地锁定 (无法切断)" : "✂️ 取消该贸易线(A-20)"
                width: parent.width
                palette.buttonText: isFatal ? "#9ca3af" : "#ef4444"
                enabled: globalA >= 20 && currentLink !== null && !isFatal

                onClicked: {
                    globalA -= 20;
                    let links = [...globalTradeLinks];
                    let link = links[selectedLineIndex];

                    let fLvl = starLevels[link.fromId];
                    let tLvl = starLevels[link.toId];
                    starObjects[link.fromId].addM(-(fLvl * 10));
                    starObjects[link.toId].addM(-(tLvl * 10));

                    let severed = [...severedTradeLinks];
                    severed.push({fromId: link.fromId, toId: link.toId});
                    severedTradeLinks = severed;

                    // 【核心修复】：必须先清空选中状态，再更新底层数组！
                    let cacheIndex = selectedLineIndex;
                    selectedLineIndex = -1; // 1. 先让 UI 视角移开
                    links.splice(cacheIndex, 1); // 2. 动刀子
                    globalTradeLinks = links; // 3. 完美更新
                }
            }

            Button {
                // 同样共享安全的属性判定
                property var currentLink: (selectedLineIndex >= 0 && selectedLineIndex < globalTradeLinks.length) ? globalTradeLinks[selectedLineIndex] : null
                property bool isFatal: currentLink ? (currentLink.fromId === patientZeroId || currentLink.toId === patientZeroId) : false

                text: isFatal ? "⚠️ 疫源地锁定 (无法改签)" : "🎯 重新部署 (A-15)"
                width: parent.width
                background: Rectangle { color: isFatal ? "#334155" : "#eab308" }
                enabled: globalA >= 15 && currentLink !== null && !isFatal

                onClicked: {
                    globalA -= 15;
                    aimingSourceId = globalTradeLinks[selectedLineIndex].fromId;
                    isAiming = true;
                }
            }
        }
    }

    // --- 回合结算按钮 ---
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
                turnA += Math.floor((star.p_N + star.p_M) * (100 - star.p_K) / 13500);
            }
            globalA += turnA; globalB += (1 + Math.floor(sumK / 200));
            currentTurn += 1;

            // --- 【新增】：死亡红线判定 ---
            // 这里我们需要手动算一下最新的平均K，因为那个 Timer 是100ms跑一次，可能会有微小的时间差
            var currentGlobalK = Math.round(sumK / starObjects.length);

            if (currentGlobalK >= 90) {
                // 拉响警报！触发死亡遮罩层动画
                gameOverOverlay.visible = true;
                gameOverOverlay.y = 0;
                gameOverOverlay.opacity = 1;

                // 为了防止玩家在死亡画面下还能乱点，禁用核心按钮
                enabled = false; // 禁用“下一回合”按钮
                isAiming = false; // 取消瞄准状态
                infoPanel.x = -infoPanel.width - 20; // 把左侧面板收回去
                linePanel.x = -linePanel.width - 50; // 把航线面板收回去
            }
        }
    }
    // --- 【新增】：Game Over 死亡遮罩层 ---
    Rectangle {
        id: gameOverOverlay
        width: parent.width; height: parent.height
        color: Qt.rgba(0.05, 0.05, 0.08, 0.95) // 极度压抑的深渊黑
        z: 9999 // 绝对的最高层级，覆盖一切

        // 初始状态：悬挂在屏幕上方，完全透明
        y: -height
        opacity: 0
        visible: false

        // 砸下来的压迫感动画
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBounce } }
        Behavior on opacity { NumberAnimation { duration: 1000 } }

        Column {
            anchors.centerIn: parent
            spacing: 30

            Text {
                text: "GAME OVER"
                color: "#7f1d1d" // 暗血红色
                font.pixelSize: 60
                font.bold: true
                font.letterSpacing: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "中央政权已解体 · 帝国全面沦陷"
                color: "#9ca3af"
                font.pixelSize: 24
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle { width: 400; height: 1; color: "#475569"; anchors.horizontalCenter: parent.horizontalCenter }

            // 战果统计面板
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2; spacing: 20

                Text { text: "存活回合："; color: "#94a3b8"; font.pixelSize: 20 }
                Text { text: currentTurn; color: "white"; font.pixelSize: 20; font.bold: true }

                Text { text: "终局疫情 (K)："; color: "#94a3b8"; font.pixelSize: 20 }
                Text { text: globalInfectionRate + " %"; color: "#ef4444"; font.pixelSize: 20; font.bold: true }

                Text { text: "帝国霸权总分："; color: "#94a3b8"; font.pixelSize: 20 }
                Text { text: globalScore; color: "#c084fc"; font.pixelSize: 24; font.bold: true }
            }
        }
    }
}