import QtQuick
import QtQuick.Controls
import GameLogic 1.0

Window {
    width: 1000
    height: 800
    visible: true
    title: qsTr("银河帝国：疫情管理协议")

    // ========================================================================
    // [01] 视觉渲染引擎 (Visual Rendering Engine)
    // 负责底层宇宙背景的动态生成与视差滚动效果
    // ========================================================================
    Item {
        id: spaceBackground
        anchors.fill: parent
        z: -100 // 置于最底层渲染
        clip: true

        // 1.1 基础深空贴图与宏观呼吸动画
        Image {
            id: milkyWay
            anchors.fill: parent
            source: "yuzhou.png"
            fillMode: Image.PreserveAspectCrop

            scale: 1.05
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 60000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.05; duration: 60000; easing.type: Easing.InOutSine }
            }
        }

        // 1.2 亮度遮罩，确保前景 UI 组件的高对比度
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.75
        }

        // 1.3 响应式动态星尘层 (基于相对坐标演算，适配窗口缩放)
        Repeater {
            model: 250
            delegate: Rectangle {
                // 将随机因子固化为属性，确保 Resize 时星系相对位置不变
                property real randX: Math.random()
                property real randY: Math.random()

                x: randX * parent.width
                y: randY * parent.height
                width: Math.random() > 0.9 ? 2 : 1
                height: width
                radius: width / 2
                color: Math.random() > 0.5 ? "#bae6fd" : "#ffffff"
                opacity: Math.random() * 0.3

                // 星尘低频闪烁算法
                SequentialAnimation on opacity {
                    running: Math.random() > 0.3
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.0; duration: 2000 + Math.random() * 5000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: Math.random() * 0.6 + 0.2; duration: 2000 + Math.random() * 5000; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ========================================================================
    // [02] 全局状态机与数据总线 (Global State & Data Bus)
    // 管理内存对象池、图论关联矩阵以及宏观经济指标
    // ========================================================================
    property var starObjects: []       // 逻辑对象实例池 (C++ 后端映射)
    property var visualStarItems: []   // 视觉节点实例池 (QML 前端渲染)
    property var globalTradeLinks: []  // 活跃拓扑边集合 (当前存在的航线)
    property var severedTradeLinks: [] // 隔离拓扑边集合 (历史断交的航线)
    property var starLevels: []        // 星系等级字典表 (1, 2, 3级)

    property int globalA: 20           // 宏观经济点数 (Economy)
    property int globalB: 5            // 宏观政治点数 (Politics)
    property int currentTurn: 1        // 离散时间轴 (回合数)

    property int globalScore: 0        // 帝国繁荣度综合评分
    property int globalInfectionRate: 0// 宏观感染率均值
    property int patientZeroId: -1     // 溯源节点 ID (零号病人)

    // ========================================================================
    // [03] 核心控制器 (Core Controllers)
    // ========================================================================

    // 3.1 内存管理：宇宙热重启协议 (物理清场与数据重置)
    function rebootUniverse() {
        // 显式调用 destroy() 触发垃圾回收，防止内存泄漏
        for (let i = 0; i < visualStarItems.length; i++) {
            if (visualStarItems[i]) visualStarItems[i].destroy();
        }
        for (let j = 0; j < starObjects.length; j++) {
            if (starObjects[j]) starObjects[j].destroy();
        }

        // 清空对象指针与状态总线
        starObjects = []; visualStarItems = [];
        globalTradeLinks = []; severedTradeLinks = []; starLevels = [];
        globalA = 20; globalB = 5; currentTurn = 1;
        globalScore = 0; globalInfectionRate = 0; patientZeroId = -1;
        selectedStar = null; selectedLineIndex = -1; isAiming = false;

        // 重新执行拓扑生成算法
        universeMap.generateUniverse();

        // 重置 UI 阻塞层
        gameOverOverlay.opacity = 0;
        gameOverOverlay.y = -gameOverOverlay.height;
        nextTurnBtn.enabled = true;
    }

    // 3.2 轮询线程：高频状态监听与指标聚合
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (starObjects.length === 0) return;

            var totalK = 0;
            var totalProsperity = 0;

            // 遍历聚合当前全网节点状态
            for (var i = 0; i < starObjects.length; i++) {
                totalK += starObjects[i].p_K;
                totalProsperity += (starObjects[i].p_N + starObjects[i].p_M);
            }

            globalInfectionRate = Math.round(totalK / starObjects.length);
            // 评分公式：总产能 * (1 - 感染率百分比)
            globalScore = Math.round(totalProsperity * ((100 - globalInfectionRate) / 100));
        }
    }

    // ========================================================================
    // [04] 交互状态机 (Interaction State Machine)
    // ========================================================================
    property var selectedStar: null       // 当前选中的目标节点
    property string selectedStarName: ""  // 当前节点标识
    property int selectedLineIndex: -1    // 当前选中的拓扑边索引
    property bool isAiming: false         // 航线重定向瞄准状态
    property int aimingSourceId: -1       // 航线重定向始发节点

    // 通过对象匹配反查数组索引
    property int selectedStarId: {
        if (!selectedStar) return -1;
        for(let i = 0; i < starObjects.length; i++) {
            if(starObjects[i] === selectedStar) return i;
        }
        return -1;
    }

    // 全局点击监听，用于取消所有 UI 焦点
    MouseArea {
        anchors.fill: parent
        onClicked: {
            selectedStar = null;
            selectedLineIndex = -1;
            isAiming = false;
        }
    }

    // ========================================================================
    // [05] 顶层信息仪表盘 (Heads Up Display)
    // ========================================================================

    // 5.1 全局态势监测模块
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        spacing: 12
        z: 10

        Text {
            text: "🏆 帝国霸权分数: " + globalScore
            color: "#c084fc"
            font.pixelSize: 22; font.bold: true
            // 数值变化时的视觉回馈
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: parent; property: "opacity"; to: 0.5; duration: 100 }
                    NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 100 }
                }
            }
        }

        Text {
            text: "☣️ 全局疫情指数: " + globalInfectionRate + "%"
            // 基于阈值的动态警报色彩渲染
            color: globalInfectionRate > 50 ? "#ef4444" : (globalInfectionRate > 20 ? "#f59e0b" : "#10b981")
            font.pixelSize: 20; font.bold: true
        }
    }

    // 5.2 宏观资源调度枢纽
    Rectangle {
        id: topBar
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20; z: 10
        width: 380; height: 60
        color: Qt.rgba(0.05, 0.08, 0.12, 0.85)
        border.color: "#38bdf8"; border.width: 1
        radius: 30

        Row {
            anchors.centerIn: parent; spacing: 50
            // 经济参数展示区
            Row {
                spacing: 12; anchors.verticalCenter: parent.verticalCenter
                Text { text: "A"; color: "#fbbf24"; font.pixelSize: 24; font.bold: true }
                Column {
                    Text { text: "ECONOMY"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                    Text { text: globalA; color: "white"; font.pixelSize: 22; font.bold: true }
                }
            }
            Rectangle { width: 2; height: 30; color: "#475569"; anchors.verticalCenter: parent.verticalCenter }
            // 政治参数展示区
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

    // 5.3 离散时间轴计数器
    Rectangle {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 20
        width: 120; height: 40; radius: 6; z: 10
        color: Qt.rgba(0.12, 0.16, 0.22, 0.8); border.color: "#38bdf8"; border.width: 2
        Text {
            text: "第 " + currentTurn + " 回合"
            color: "white"; font.pixelSize: 16; font.bold: true; anchors.centerIn: parent
        }
    }

    // 5.4 瞄准系统 UI 提示
    Text {
        visible: isAiming
        text: "🎯 重新部署中：请在地图上点击新的接收星系 (C)"
        color: "#fbbf24"; font.pixelSize: 24; font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter; y: 60; z: 999
    }

    // ========================================================================
    // [06] 宇宙拓扑容器与生成算法 (Topology Container & Generator)
    // ========================================================================
    Item {
        id: universeMap
        width: 1000; height: 800
        anchors.centerIn: parent
        z: 5

        // 6.1 图论连线渲染：由数据驱动的动态量子航线
        Repeater {
            model: globalTradeLinks
            delegate: Rectangle {
                // 顶点解包与属性推导
                property int fromIndex: modelData.fromId
                property int toIndex: modelData.toId
                property var vSource: visualStarItems[fromIndex]
                property var vTarget: visualStarItems[toIndex]

                // 基于源目标坐标的动态锚定 (适配节点未来可能的位移)
                property real startX: vSource ? vSource.x + vSource.width / 2 : 0
                property real startY: vSource ? vSource.y + vSource.height / 2 : 0
                property real endX: vTarget ? vTarget.x + vTarget.width / 2 : 0
                property real endY: vTarget ? vTarget.y + vTarget.height / 2 : 0

                // 欧几里得距离与反正切角度计算
                x: startX; y: startY - height / 2
                width: Math.sqrt(Math.pow(endX-startX, 2) + Math.pow(endY-startY, 2))
                height: selectedLineIndex === index ? 4 : 1.5
                transformOrigin: Item.Left
                rotation: Math.atan2(endY - startY, endX - startX) * 180 / Math.PI
                z: 0

                // 横向色彩渐变，平滑融合源节点与目标节点的视觉属性
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

                // 呼吸灯光效，表达数据流转状态
                SequentialAnimation on opacity {
                    running: selectedLineIndex !== index
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 3000 + Math.random() * 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 3000 + Math.random() * 4000; easing.type: Easing.InOutSine }
                }
            }
        }

        // 6.2 极简美学视觉锚点：深渊级全息中枢
        Item {
            id: empireCore
            anchors.centerIn: parent
            width: 80; height: 80
            z: 0

            // 吸积盘辉光演算 (多层 Alpha 叠加与潮汐形变)
            Repeater {
                model: 5
                delegate: Rectangle {
                    anchors.centerIn: parent
                    width: 30 + (index * 12)
                    height: width; radius: width / 2
                    color: "#bae6fd"
                    opacity: 0.12 - (index * 0.02)

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.1 + (index * 0.02); duration: 4000 + index * 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 4000 + index * 800; easing.type: Easing.InOutSine }
                    }
                }
            }

            // 事件视界 (中心几何切割)
            Rectangle {
                anchors.centerIn: parent
                width: 28; height: 28; radius: width / 2
                color: "#000000"
            }
        }

        // 6.3 宇宙创世算法：基于概率池与三角函数的图网络生成逻辑
        function generateUniverse() {
            var pool = [];
            // 初始化概率池分布结构
            for (var p1 = 0; p1 < 10; p1++) pool.push({level: 1, color: "#22c55e", name: "一级星"});
            for (var p2 = 0; p2 < 7; p2++) pool.push({level: 2, color: "#eab308", name: "二级星"});
            // Fisher-Yates 乱序算法洗牌
            for (var s = pool.length - 1; s > 0; s--) {
                var rIndex = Math.floor(Math.random() * (s + 1));
                var temp = pool[s]; pool[s] = pool[rIndex]; pool[rIndex] = temp;
            }

            // 定义多环轨道的拓扑参数
            var ringConfigs = [ {total: 3, r: 120}, {total: 7, r: 240}, {total: 10, r: 380} ];
            var centerX = width / 2; var centerY = height / 2;
            var allVisualStars = []; var tempVisualItems = [];

            // 遍历渲染星系节点
            for (var j = 0; j < ringConfigs.length; j++) {
                var ring = ringConfigs[j];
                // 强制将三级星分配至初始集合
                var currentRingStars = [{level: 3, color: "#ef4444", name: "三级星"}];
                for (var k = 0; k < ring.total - 1; k++) currentRingStars.push(pool.pop());

                for (var i = 0; i < ring.total; i++) {
                    var starData = currentRingStars[i];
                    var angle = (i / ring.total) * Math.PI * 2;
                    // 极坐标到笛卡尔坐标转换
                    var posX = centerX + ring.r * Math.cos(angle);
                    var posY = centerY + ring.r * Math.sin(angle);

                    // 实例化 C++ 逻辑底层映射
                    var starLogic = Qt.createQmlObject('import GameLogic 1.0; Star {}', universeMap);
                    starObjects.push(starLogic);
                    starLevels.push(starData.level);

                    var currentIdx = allVisualStars.length;

                    // 动态注入 QML 前端渲染模板
                    var circle = Qt.createQmlObject(`
                        import QtQuick

                        Item {
                            id: nodeRoot
                            width: 46; height: 46
                            property var logic; property string baseColor: "${starData.color}"; property string starName: "${starData.name}";
                            property int myId: ${currentIdx};

                            // 利用属性绑定实现状态驱动的动态变色 (K 值提升导致 RGB 通道衰减)
                            property color coreColor: logic.p_K === 0 ? baseColor : Qt.rgba(1, 1 - (logic.p_K/100), 1 - (logic.p_K/100), 1)

                            // 疫情灾害场实体化
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

                            // 战术聚焦雷达组件
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

                            // 行星本体 3D 渲染光影
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                clip: true

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.lighter(nodeRoot.coreColor, 1.4) }
                                    GradientStop { position: 0.8; color: nodeRoot.coreColor }
                                    GradientStop { position: 1.0; color: Qt.darker(nodeRoot.coreColor, 2.5) }
                                }
                                border.color: "#1e293b"; border.width: 1
                            }

                            // 节点数据元信息
                            Text {
                                text: logic.p_K > 0 ? "K:" + logic.p_K : starName;
                                anchors.centerIn: parent;
                                color: "white"; font.pixelSize: 12; font.bold: true;
                                style: Text.Outline; styleColor: "black"
                            }

                            // 交互捕获区与事件分发处理器
                            MouseArea {
                                anchors.fill: parent; propagateComposedEvents: false;
                                onClicked: (mouse) => {
                                    if (isAiming) {
                                        // 处理航线重定向逻辑
                                        let cId = myId; let oldBId = globalTradeLinks[selectedLineIndex].toId;
                                        if (cId === aimingSourceId || cId === oldBId) return;
                                        let links = [...globalTradeLinks];
                                        let oldBLvl = starLevels[oldBId]; let newCLvl = starLevels[cId];
                                        // 扣除旧连接收益，添加新连接收益
                                        starObjects[oldBId].addM(-(oldBLvl * 10));
                                        starObjects[cId].addM(newCLvl * 10);
                                        // 将旧连接载入历史存档
                                        let severed = [...severedTradeLinks];
                                        severed.push({fromId: aimingSourceId, toId: oldBId});
                                        severedTradeLinks = severed;
                                        // 刷新活跃数据总线
                                        links[selectedLineIndex].toId = cId;
                                        globalTradeLinks = links;
                                        isAiming = false; selectedLineIndex = -1;
                                    } else {
                                        // 选中焦点节点
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

            // 依据星系等级生成动态连接矩阵
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

            // 初始化经济引擎加成数据
            for (var l = 0; l < finalLinks.length; l++) {
                var fId = finalLinks[l].fromId;
                var tId = finalLinks[l].toId;
                starObjects[fId].addM(starLevels[fId] * 10);
                starObjects[tId].addM(starLevels[tId] * 10);
            }

            // 病毒原型注入 (初始化零号病人)
            if (starObjects.length > 0) {
                var luckyIdx = Math.floor(Math.random() * starObjects.length);
                starObjects[luckyIdx].infect();
                patientZeroId = luckyIdx;
                console.log("零号病人降临在星系：" + luckyIdx);
            }
        }
    }

    // 生命周期挂载点：组件加载完成即触发创世
    Component.onCompleted: {
        universeMap.generateUniverse();
    }

    // ========================================================================
    // [07] 战术指令与信息面板 (Tactical UI Panels)
    // 采用声明式动画平滑处理面板的进入/退出逻辑
    // ========================================================================

    // 7.1 恒星级主权限控制面板
    Rectangle {
        id: infoPanel
        z: 100; width: 270; height: 680
        // 数据驱动的坐标变换：选中目标时平滑滑入
        x: (selectedStar !== null) ? 20 : -width - 20; y: 80
        color: Qt.rgba(0.12, 0.16, 0.22, 0.95); border.color: "#334155"; border.width: 2; radius: 6
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 15
            clip: true // 限制子组件渲染边界

            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                width: 245
                spacing: 12

                Text { text: "📡 " + selectedStarName; color: "white"; font.bold: true; font.pixelSize: 20 }
                Rectangle { width: parent.width; height: 1; color: "#475569" }
                // 核心状态数据解析
                Text { text: "☣️ 疫情指数 (K):  " + (selectedStar ? selectedStar.p_K : ""); color: selectedStar && selectedStar.p_K > 0 ? "#ef4444" : "#22c55e"; font.bold: true }
                Text { text: "🛡️ 稳定度 (P):  " + (selectedStar ? selectedStar.p_P : ""); color: "white" }
                Text { text: "🧱 独立度 (Q):  " + (selectedStar ? selectedStar.p_Q : ""); color: "white" }
                Text { text: "⚙️ 生产度 (N):  " + (selectedStar ? selectedStar.p_N : ""); color: "#fbbf24" }
                Text { text: "🤝 贸易度 (M):  " + (selectedStar ? selectedStar.p_M : ""); color: "#fbbf24" }

                // 辖下拓扑图管理系统
                Rectangle { width: parent.width; height: 1; color: "#475569" }
                Text { text: "🌌 辖下航线管理 (主权)"; color: "#94a3b8"; font.pixelSize: 12 }

                Column {
                    width: parent.width; spacing: 5

                    // 当前活跃边渲染
                    Repeater {
                        model: globalTradeLinks.length
                        delegate: Button {
                            width: parent.width
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

                    // 历史断交边恢复调度
                    Repeater {
                        model: severedTradeLinks.length
                        delegate: Button {
                            width: parent.width
                            visible: selectedStarId !== -1 && severedTradeLinks[index].fromId === selectedStarId
                            height: visible ? 30 : 0
                            text: "🔧 恢复航线 -> 星系 " + (visible ? severedTradeLinks[index].toId + " (A-5)": "")
                            palette.buttonText: "#cbd5e1"
                            enabled: globalA >= 5
                            background: Rectangle {
                                color: "#475569"; border.color: "#64748b"; radius: 4
                            }
                            onClicked: {
                                globalA -= 5;
                                // 历史图谱恢复与重映射
                                let active = [...globalTradeLinks];
                                let restored = severedTradeLinks[index];
                                active.push(restored);
                                globalTradeLinks = active;

                                let sLinks = [...severedTradeLinks];
                                sLinks.splice(index, 1);
                                severedTradeLinks = sLinks;

                                // 经济产值二次回归
                                let fLvl = starLevels[restored.fromId];
                                let tLvl = starLevels[restored.toId];
                                starObjects[restored.fromId].addM(fLvl * 10);
                                starObjects[restored.toId].addM(tLvl * 10);
                            }
                        }
                    }
                }

                // 双轨制宏观干预矩阵
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

                // 终极协议：改变底层逻辑的极端指令
                Rectangle { width: parent.width; height: 1; color: "#475569" }
                Text { text: "💀 终极协议 (高风险/高收益)"; color: "#f87171"; font.pixelSize: 12; font.bold: true }

                Button {
                    text: "💰 设立星际黑市 (A-50)\n[贸易度狂飙, 独立度永久极高]"
                    width: parent.width; height: 50
                    background: Rectangle { color: "#854d0e"; radius: 4 }
                    palette.buttonText: "white"
                    enabled: globalA >= 50 && selectedStar !== null
                    onClicked: {
                        globalA -= 50;
                        selectedStar.addM(80);
                        selectedStar.modifyAttribute("Q", 100); // 解除约束力
                    }
                }

                Button {
                    text: "💥 轨道焦土指令 (B-15)\n[物理毁灭：强制全网断交并镇压]"
                    width: parent.width; height: 50
                    background: Rectangle { color: "#7f1d1d"; radius: 4 }
                    palette.buttonText: "white"
                    enabled: globalB >= 15 && selectedStar !== null
                    onClicked: {
                        globalB -= 15;
                        // 基础产能清零
                        selectedStar.modifyAttribute("N", -100);
                        selectedStar.modifyAttribute("P", -100);
                        // 三级深层封锁
                        selectedStar.enforceLockdown();
                        selectedStar.enforceLockdown();
                        selectedStar.enforceLockdown();

                        // 拓扑隔离逻辑：提取所有涉及该节点的边结构
                        let links = [...globalTradeLinks];
                        let newLinks = [];
                        let severed = [...severedTradeLinks];

                        for(let i = 0; i < links.length; i++) {
                            if(links[i].fromId === selectedStarId || links[i].toId === selectedStarId) {
                                severed.push(links[i]);
                                // 强制回滚经济变量
                                let fLvl = starLevels[links[i].fromId];
                                let tLvl = starLevels[links[i].toId];
                                starObjects[links[i].fromId].addM(-(fLvl * 10));
                                starObjects[links[i].toId].addM(-(tLvl * 10));
                            } else {
                                newLinks.push(links[i]);
                            }
                        }
                        // 提交拓扑更改
                        globalTradeLinks = newLinks;
                        severedTradeLinks = severed;
                    }
                }
            }
        }
    }

    // 7.2 航线级二级关联面板
    Rectangle {
        id: linePanel
        z: 99; width: 230; height: 260
        // 级联定位：跟随在 infoPanel 右侧展开
        x: (selectedLineIndex !== -1 && !isAiming && selectedStar !== null) ? (infoPanel.x + infoPanel.width + 10) : -width - 50
        y: 80
        color: Qt.rgba(0.2, 0.1, 0.15, 0.95); border.color: "#3b82f6"; border.width: 2; radius: 6
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Column {
            anchors.fill: parent; anchors.margins: 15; spacing: 15
            Text { text: "🔗 航线档案 " + selectedLineIndex; color: "white"; font.bold: true }
            Text { text: "输入方: 星系 " + (selectedLineIndex !== -1 ? globalTradeLinks[selectedLineIndex].toId : ""); color: "#94a3b8" }

            // 动态关联值解析
            Text {
                text: selectedLineIndex !== -1 ?
                      "经济贡献: 源 +" + (starLevels[globalTradeLinks[selectedLineIndex].fromId] * 10) +
                      " M, 目标 +" + (starLevels[globalTradeLinks[selectedLineIndex].toId] * 10) + " M" : ""
                color: "#fbbf24"
            }

            Rectangle { width: parent.width; height: 1; color: "#475569" }

            // 越界安全保护机制与溯源隔离判断
            Button {
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

                    // 取消 UI 挂载焦点后方可修改底层数组，避免渲染越界
                    let cacheIndex = selectedLineIndex;
                    selectedLineIndex = -1;
                    links.splice(cacheIndex, 1);
                    globalTradeLinks = links;
                }
            }

            Button {
                property var currentLink: (selectedLineIndex >= 0 && selectedLineIndex < globalTradeLinks.length) ? globalTradeLinks[selectedLineIndex] : null
                property bool isFatal: currentLink ? (currentLink.fromId === patientZeroId || currentLink.toId === patientZeroId) : false

                text: isFatal ? "⚠️ 疫源地锁定 (无法改签)" : "🎯 重新部署 (A-15)"
                width: parent.width
                background: Rectangle { color: isFatal ? "#334155" : "#eab308" }
                enabled: globalA >= 15 && currentLink !== null && !isFatal

                onClicked: {
                    globalA -= 15;
                    aimingSourceId = globalTradeLinks[selectedLineIndex].fromId;
                    isAiming = true; // 状态机切换为重映射瞄准状态
                }
            }
        }
    }

    // ========================================================================
    // [08] 时间推进与逻辑演算枢纽 (Turn Resolver & Computation)
    // ========================================================================
    Button {
        id: nextTurnBtn
        text: "推进至下一回合 >>"
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 30
        width: 180; height: 50
        font.pixelSize: 16; font.bold: true
        palette.buttonText: "white"
        background: Rectangle {
            color: parent.down ? "#2563eb" : "#3b82f6"
            radius: 8; border.color: "#60a5fa"; border.width: 2
        }

        onClicked: {
            var turnA = 0; var sumK = 0; var sumQ = 0;
            var links = globalTradeLinks;

            // 8.1 病毒扩散算法 (图论遍历传染)
            for (var l = 0; l < links.length; l++) {
                var sA = starObjects[links[l].fromId]; var sB = starObjects[links[l].toId];
                // 阈值判定：跨越安全线即产生跨星系感染
                if (sA.p_K > 15) sB.receiveInfection(sA.p_K);
                if (sB.p_K > 15) sA.receiveInfection(sB.p_K);
            }

            // 8.2 内部演算与资源结算
            for (var i = 0; i < starObjects.length; i++) {
                var star = starObjects[i]; star.nextTurn();
                sumK += star.p_K; sumQ += star.p_Q;
                turnA += Math.floor((star.p_N + star.p_M) * (100 - star.p_K) / 13500);
            }
            globalA += turnA; globalB += (1 + Math.floor(sumK / 200));
            currentTurn += 1;

            // 8.3 毁灭条件触发 (全局灾难状态拦截)
            var currentGlobalK = Math.round(sumK / starObjects.length);

            if (currentGlobalK >= 90) {
                gameOverOverlay.visible = true;
                gameOverOverlay.y = 0;
                gameOverOverlay.opacity = 1;

                // 阻断交互权限
                nextTurnBtn.enabled = false;
                isAiming = false;
                infoPanel.x = -infoPanel.width - 20;
                linePanel.x = -linePanel.width - 50;
            }
        }
    }

    // ========================================================================
    // [09] 游戏全屏应用流转状态机 (App Flow Overlay UIs)
    // ========================================================================

    // 9.1 启动协议层 (Terminal Login UI)
    Rectangle {
        id: startMenu
        anchors.fill: parent
        z: 9998 // 覆盖应用工作区

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#000000" }
            GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.1, 0.15, 0.98) }
        }

        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -50
            spacing: 50

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 15
                Text { text: "银 河 帝 国"; color: "#e2e8f0"; font.pixelSize: 64; font.bold: true; font.letterSpacing: 25; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "疫 情 管 理 协 议 "; color: "#64748b"; font.pixelSize: 18; font.letterSpacing: 10; anchors.horizontalCenter: parent.horizontalCenter }
            }

            Rectangle { width: 400; height: 1; color: "#1e293b"; anchors.horizontalCenter: parent.horizontalCenter }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                // 悬停交互控制按钮
                Rectangle {
                    width: 220; height: 50
                    color: startMouseArea.containsMouse ? "#ffffff" : "transparent"
                    border.color: startMouseArea.containsMouse ? "#ffffff" : "#475569"; border.width: 1; radius: 2
                    Text { text: "启 动 协 议"; color: startMouseArea.containsMouse ? "#000000" : "#cbd5e1"; font.pixelSize: 16; font.bold: true; font.letterSpacing: 6; anchors.centerIn: parent }
                    MouseArea {
                        id: startMouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: startMenu.opacity = 0 // 触发退场过渡动画
                    }
                }

                Rectangle {
                    width: 220; height: 50
                    color: exitMouseArea.containsMouse ? "#ef4444" : "transparent"
                    border.color: exitMouseArea.containsMouse ? "#ef4444" : "#334155"; border.width: 1; radius: 2
                    Text { text: "切 断 连 接"; color: exitMouseArea.containsMouse ? "#ffffff" : "#64748b"; font.pixelSize: 16; font.bold: true; font.letterSpacing: 6; anchors.centerIn: parent }
                    MouseArea {
                        id: exitMouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: Qt.quit()
                    }
                }
            }
        }

        Behavior on opacity { NumberAnimation { duration: 1500; easing.type: Easing.InOutCubic } }
        onOpacityChanged: { if (opacity === 0) visible = false; }
    }

    // 9.2 末日清算层 (Game Over & Statistics UI)
    Rectangle {
        id: gameOverOverlay
        width: parent.width; height: parent.height
        color: Qt.rgba(0.05, 0.05, 0.08, 0.95)
        z: 9999

        onOpacityChanged: { if (opacity === 0) visible = false; }

        y: -height
        opacity: 0
        visible: false

        // 物理坠落缓冲动画
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBounce } }
        Behavior on opacity { NumberAnimation { duration: 1000 } }

        Column {
            anchors.centerIn: parent
            spacing: 30

            Text { text: "GAME OVER"; color: "#7f1d1d"; font.pixelSize: 60; font.bold: true; font.letterSpacing: 10; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: "中央政权已解体 · 帝国全面沦陷"; color: "#9ca3af"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }

            Rectangle { width: 400; height: 1; color: "#475569"; anchors.horizontalCenter: parent.horizontalCenter }

            // 最终指标结算面板
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

            // 终端裁决选项
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 30
                Rectangle {
                    width: 200; height: 50
                    color: restartMouseArea.containsMouse ? "#ffffff" : "transparent"
                    border.color: restartMouseArea.containsMouse ? "#ffffff" : "#475569"; border.width: 1; radius: 2
                    Text { text: "重 建 帝 国"; color: restartMouseArea.containsMouse ? "#000000" : "#cbd5e1"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 6; anchors.centerIn: parent }
                    MouseArea {
                        id: restartMouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: rebootUniverse() // 唤醒内存重载程序
                    }
                }
                Rectangle {
                    width: 200; height: 50
                    color: quitMouseArea.containsMouse ? "#ef4444" : "transparent"
                    border.color: quitMouseArea.containsMouse ? "#ef4444" : "#334155"; border.width: 1; radius: 2
                    Text { text: "放 弃 抵 抗"; color: quitMouseArea.containsMouse ? "#ffffff" : "#ef4444"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 6; anchors.centerIn: parent }
                    MouseArea {
                        id: quitMouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }
}