import QtQuick
import QtQuick.Controls
import GameLogic 1.0

Window {
    width: 1000
    height: 800
    visible: true
    title: qsTr("银河帝国：疫情管理协议")

    // --- 【终极视觉】：星辰大海深空引擎 ---
    Item {
        id: spaceBackground
        anchors.fill: parent
        z: -100 // 焊死在最底层
        clip: true // 裁掉超出边界的宇宙

        // 1. 震撼底图：直接调用一张 4K 级别的真实暗黑银河摄影（需要联网）
        // 如果你觉得这张不够酷，可以换成你本地的摄影作品，写 source: "file:你图片的路径.jpg"

        Image {
            id: milkyWay
            anchors.fill: parent
            source: "yuzhou.png"
            fillMode: Image.PreserveAspectCrop // 保证图片完美撑满全屏，绝不变形

            // 电影级震撼感的来源：让整个银河进行周期为一分钟的极其缓慢的呼吸缩放
            scale: 1.05
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 60000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.05; duration: 60000; easing.type: Easing.InOutSine }
            }
        }

        // 2. 压暗滤镜：让底图不抢戏，确保前面的星球和贸易线清晰可见
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.75 // 如果觉得背景太亮，可以把这个数值调大（比如 0.8）
        }

        // 3. 【核心修复】：动态绑定的星尘层（绝对不会再缩在角落！）
        Repeater {
            model: 250 // 250颗闪烁的冷色星尘
            delegate: Rectangle {
                // 【QML 高阶技巧】：把随机数存成固定的比例属性
                property real randX: Math.random()
                property real randY: Math.random()

                // 动态绑定到 parent 的宽高！这样当你全屏放大窗口时，宇宙会瞬间跟着膨胀开来！
                x: randX * parent.width
                y: randY * parent.height

                width: Math.random() > 0.9 ? 2 : 1
                height: width
                radius: width / 2
                color: Math.random() > 0.5 ? "#bae6fd" : "#ffffff" // 幽蓝色与纯白色交织

                // 初始透明度极低，藏在银河里
                opacity: Math.random() * 0.3

                // 随机的明暗呼吸感
                SequentialAnimation on opacity {
                    running: Math.random() > 0.3
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.0; duration: 2000 + Math.random() * 5000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: Math.random() * 0.6 + 0.2; duration: 2000 + Math.random() * 5000; easing.type: Easing.InOutSine }
                }
            }
        }
    }

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

    // --- 【新增】：宇宙热重启协议 ---
    function rebootUniverse() {
        // 1. 物理清场：逐个引爆摧毁旧星系节点，防止内存泄漏
        for (let i = 0; i < visualStarItems.length; i++) {
            if (visualStarItems[i]) visualStarItems[i].destroy();
        }
        for (let j = 0; j < starObjects.length; j++) {
            if (starObjects[j]) starObjects[j].destroy();
        }

        // 2. 帝国档案彻底归零
        starObjects = []; visualStarItems = [];
        globalTradeLinks = []; severedTradeLinks = []; starLevels = [];
        globalA = 20; globalB = 5; currentTurn = 1;
        globalScore = 0; globalInfectionRate = 0; patientZeroId = -1;
        selectedStar = null; selectedLineIndex = -1; isAiming = false;

        // 3. 重新触发大爆炸（调用创世函数）
        universeMap.generateUniverse();

        // 4. 收起死亡遮罩，恢复全图交互
        gameOverOverlay.opacity = 0;
        gameOverOverlay.y = -gameOverOverlay.height;
        nextTurnBtn.enabled = true; // 解除之前的全局点击封锁
    }

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

    // --- 【高级改造 1】：顶部战术资源中枢 ---
    Rectangle {
        id: topBar
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20; z: 10
        width: 380; height: 60
        color: Qt.rgba(0.05, 0.08, 0.12, 0.85) // 极深的毛玻璃感
        border.color: "#38bdf8"
        border.width: 1
        radius: 30 // 科技感流线胶囊形状

        Row {
            anchors.centerIn: parent; spacing: 50

            // 经济模块 A
            Row {
                spacing: 12; anchors.verticalCenter: parent.verticalCenter
                Text { text: "A"; color: "#fbbf24"; font.pixelSize: 24; font.bold: true }
                Column {
                    Text { text: "ECONOMY"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                    Text { text: globalA; color: "white"; font.pixelSize: 22; font.bold: true }
                }
            }

            // 扫描分割线
            Rectangle {
                width: 2; height: 30; color: "#475569"; anchors.verticalCenter: parent.verticalCenter
            }

            // 政治模块 B
            Row {
                spacing: 12; anchors.verticalCenter: parent.verticalCenter
                Text { text: "B"; color: "#60a5fa"; font.pixelSize: 24; font.bold: true }
                Column {
                    Text { text: "POLITICS"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                    Text { text: globalB; color: "white"; font.pixelSize: 22; font.bold: true }
                }
            }
        }
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
        z: 5

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

                // 未选中时是极细的幽灵线，选中时变为发光的能量带
                height: selectedLineIndex === index ? 4 : 1.5

                transformOrigin: Item.Left
                rotation: Math.atan2(endY - startY, endX - startX) * 180 / Math.PI
                z: 0

                // 【高级感核心】：横向能量渐变，完美融合两端星球的色彩
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0;
                        color: vSource ? Qt.alpha(vSource.baseColor, selectedLineIndex === index ? 1.0 : 0.35) : "transparent"
                    }
                    GradientStop {
                        position: 1.0;
                        color: vTarget ? Qt.alpha(vTarget.baseColor, selectedLineIndex === index ? 1.0 : 0.35) : "transparent"
                    }
                }

                // 【生命力】：极度克制的全局错落呼吸，替代廉价的飞行粒子
                SequentialAnimation on opacity {
                    running: selectedLineIndex !== index // 选中时锁定高亮，停止呼吸
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 3000 + Math.random() * 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 3000 + Math.random() * 4000; easing.type: Easing.InOutSine }
                }
            }
        }

        // --- 【全息奇点帝国中枢】 ---
        Item {
            id: empireCore
            anchors.centerIn: parent
            width: 80; height: 80
            z: 000000

            // 1. 吸积盘辉光 (用多层纯色极低透明度叠加，模拟出无边界的柔和气体光晕，绝不使用死板的线条圈)
            Repeater {
                model: 5
                delegate: Rectangle {
                    anchors.centerIn: parent
                    // 每一层向外扩散
                    width: 30 + (index * 12)
                    height: width
                    radius: width / 2
                    color: "#bae6fd" // 极冷的恒星白蓝光
                    // 透明度向外呈指数级递减，最内层稍微亮一点，最外层几乎融进宇宙
                    opacity: 0.12 - (index * 0.02)

                    // 极其缓慢的潮汐呼吸，仿佛空间在扭曲
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.1 + (index * 0.02); duration: 4000 + index * 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 4000 + index * 800; easing.type: Easing.InOutSine }
                    }
                }
            }

            // 2. 事件视界：绝对的虚空 (没有任何高光、没有任何边框，就是一块纯粹的死黑)
            Rectangle {
                anchors.centerIn: parent
                width: 28; height: 28
                radius: width / 2
                color: "#000000" // 绝对纯黑，吞噬一切
                // 连 border 都不写，追求最极致的几何切割感
            }
        }

        function generateUniverse() {
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

                        Item {
                            id: nodeRoot
                            width: 46; height: 46 // 放大体积，告别小气
                            property var logic; property string baseColor: "${starData.color}"; property string starName: "${starData.name}";
                            property int myId: ${currentIdx};

                            // 【修复核心】：把颜色属性提上来，全局可用，绝不变黑
                            property color coreColor: logic.p_K === 0 ? baseColor : Qt.rgba(1, 1 - (logic.p_K/100), 1 - (logic.p_K/100), 1)

                            // 1. 实体化疫情光晕
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (logic.p_K / 2)
                                height: width; radius: width / 2
                                color: "#ef4444"
                                opacity: logic.p_K / 150

                                SequentialAnimation on scale {
                                    running: logic.p_K > 0
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1.15; duration: 800; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                }
                            }

                            // 2. 战术雷达锁定圈
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 12; height: width; radius: width / 2
                                color: "transparent"
                                border.color: isAiming ? "#f59e0b" : "#38bdf8"
                                border.width: 2
                                visible: selectedStar === logic

                                RotationAnimation on rotation {
                                    from: 0; to: 360; duration: 3000; loops: Animation.Infinite
                                }

                                Rectangle { width: 6; height: 6; color: "#0f172a"; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter }
                                Rectangle { width: 6; height: 6; color: "#0f172a"; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter }
                                Rectangle { width: 6; height: 6; color: "#0f172a"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { width: 6; height: 6; color: "#0f172a"; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // 3. 星球本体 (这次绝对是彩色的 3D 球！)
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                clip: true

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.lighter(nodeRoot.coreColor, 1.4) }
                                    GradientStop { position: 0.8; color: nodeRoot.coreColor }
                                    GradientStop { position: 1.0; color: Qt.darker(nodeRoot.coreColor, 2.5) }
                                }

                                border.color: "#1e293b"
                                border.width: 1
                            }

                            // 4. 数据标签 (字号加大，描边加粗)
                            Text {
                                text: logic.p_K > 0 ? "K:" + logic.p_K : starName;
                                anchors.centerIn: parent;
                                color: "white"
                                font.pixelSize: 12; // 字号加大
                                font.bold: true;
                                style: Text.Outline; styleColor: "black"
                            }

                            // 交互热区
                            MouseArea {
                                anchors.fill: parent; propagateComposedEvents: false;
                                onClicked: (mouse) => {
                                    if (isAiming) {
                                        let cId = myId; let oldBId = globalTradeLinks[selectedLineIndex].toId;
                                        if (cId === aimingSourceId || cId === oldBId) return;
                                        let links = [...globalTradeLinks];
                                        let oldBLvl = starLevels[oldBId]; let newCLvl = starLevels[cId];
                                        starObjects[oldBId].addM(-(oldBLvl * 10));
                                        starObjects[cId].addM(newCLvl * 10);
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

    Component.onCompleted: {
        universeMap.generateUniverse(); // 游戏刚启动时，自动调用一次创世
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
        id: nextTurnBtn
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
                nextTurnBtn.enabled = false; // 禁用“下一回合”按钮
                isAiming = false; // 取消瞄准状态
                infoPanel.x = -infoPanel.width - 20; // 把左侧面板收回去
                linePanel.x = -linePanel.width - 50; // 把航线面板收回去
            }
        }
    }

    // --- 【新增】：电影级终端登入界面 (盖在最上层) ---
        Rectangle {
            id: startMenu
            anchors.fill: parent
            z: 9998 // 盖住游戏的所有 UI

            // 极深的深渊渐变背景
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#000000" }
                GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.1, 0.15, 0.98) }
            }

            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -50 // 整体稍微偏上一点，视觉更稳
                spacing: 50

                // 主标题区
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 15
                    Text {
                        text: "银 河 帝 国"
                        color: "#e2e8f0"
                        font.pixelSize: 64
                        font.bold: true
                        font.letterSpacing: 25 // 极宽的字间距，拉满史诗感
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "疫 情 管 理 协 议 "
                        color: "#64748b"
                        font.pixelSize: 18
                        font.letterSpacing: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Rectangle { width: 400; height: 1; color: "#1e293b"; anchors.horizontalCenter: parent.horizontalCenter }

                // 交互指令区
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    // 1. 启动按钮
                    Rectangle {
                        width: 220; height: 50
                        color: startMouseArea.containsMouse ? "#ffffff" : "transparent"
                        border.color: startMouseArea.containsMouse ? "#ffffff" : "#475569"
                        border.width: 1
                        radius: 2

                        Text {
                            text: "启 动 协 议"
                            color: startMouseArea.containsMouse ? "#000000" : "#cbd5e1"
                            font.pixelSize: 16
                            font.bold: true
                            font.letterSpacing: 6
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: startMouseArea
                            anchors.fill: parent
                            hoverEnabled: true // 开启悬停检测
                            onClicked: {
                                // 触发渐隐动画
                                startMenu.opacity = 0
                            }
                        }
                    }

                    // 2. 切断按钮
                    Rectangle {
                        width: 220; height: 50
                        color: exitMouseArea.containsMouse ? "#ef4444" : "transparent"
                        border.color: exitMouseArea.containsMouse ? "#ef4444" : "#334155"
                        border.width: 1
                        radius: 2

                        Text {
                            text: "切 断 连 接"
                            color: exitMouseArea.containsMouse ? "#ffffff" : "#64748b"
                            font.pixelSize: 16
                            font.bold: true
                            font.letterSpacing: 6
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: exitMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.quit() // Qt 原生退出指令
                        }
                    }
                }
            }

            // 绑定透明度渐变动画，1.5秒丝滑消失
            Behavior on opacity {
                NumberAnimation { duration: 1500; easing.type: Easing.InOutCubic }
            }
            // 动画播完后，彻底销毁它的点击阻挡
            onOpacityChanged: {
                if (opacity === 0) visible = false;
            }
        }

    // --- 【新增】：Game Over 死亡遮罩层 ---
    Rectangle {
        id: gameOverOverlay
        width: parent.width; height: parent.height
        color: Qt.rgba(0.05, 0.05, 0.08, 0.95) // 极度压抑的深渊黑
        z: 9999 // 绝对的最高层级，覆盖一切

        onOpacityChanged: {
            if (opacity === 0) visible = false;
        }

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

            Rectangle { width: 400; height: 1; color: "#1e293b"; anchors.horizontalCenter: parent.horizontalCenter }

            // --- 【新增】：末日决断指令区 ---
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 30

                // 1. 重启按钮：抹除一切，重建帝国
                Rectangle {
                    width: 200; height: 50
                    color: restartMouseArea.containsMouse ? "#ffffff" : "transparent"
                    border.color: restartMouseArea.containsMouse ? "#ffffff" : "#475569"
                    border.width: 1; radius: 2

                    Text {
                        text: "重 建 帝 国"
                        color: restartMouseArea.containsMouse ? "#000000" : "#cbd5e1"
                        font.pixelSize: 18; font.bold: true; font.letterSpacing: 6
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: restartMouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: rebootUniverse() // 调用我们刚写的热重启协议
                    }
                }

                // 2. 彻底退出按钮
                Rectangle {
                    width: 200; height: 50
                    color: quitMouseArea.containsMouse ? "#ef4444" : "transparent"
                    border.color: quitMouseArea.containsMouse ? "#ef4444" : "#334155"
                    border.width: 1; radius: 2

                    Text {
                        text: "放 弃 抵 抗"
                        color: quitMouseArea.containsMouse ? "#ffffff" : "#ef4444"
                        font.pixelSize: 18; font.bold: true; font.letterSpacing: 6
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: quitMouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: Qt.quit() // Qt 原生退出指令
                    }
                }
            }
        }
    }
}