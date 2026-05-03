#include "star.h"
#include <cmath>  // 为了使用 std::exp 和 std::round

Star::Star(QObject *parent) : QObject(parent)
{
    // 初始化数值
    P = 50; Q = 50; N = 90; M = 20; K = 0;
}

// 物理演化核心算法
void Star::nextTurn() {
    if (K > 0) {
        // 1. 疫情反噬社会与经济
        P = P - (K / 10);
        if (P < 0) P = 0;

        N = N - (K / 5);
        if (N < 0) N = 0;

        // 2. 逻辑斯谛动力学模型
        double r = 0.05;       // 基础增殖率
        double K_max = 100.0;  // 疫情上限
        double lambda = 0.06;  // 稳定度权重系数

        // 计算阻尼函数 phi (注意类型转换，避免整数除法丢失精度)
        double phi = std::exp(-lambda * static_cast<double>(P)) * static_cast<double>(Q);

        // 计算本回合的疫情增量 dK
        double dK = r * static_cast<double>(K) * (1.0 - static_cast<double>(K) / K_max) * phi;

        // 3. 将增量加到 K 上 (使用 std::round 四舍五入为整数)
        K = K + std::round(dK);

        if (K > 100) K = 100;
    }

    // 发射信号！
    emit dataChanged();
}

// 模拟病毒降临
void Star::infect() {
    K = 10;
    emit dataChanged();
}

// 增加 M 值
void Star::addM(int bonus) {
    M += bonus;
    emit dataChanged();
}

// 接收外部感染
void Star::receiveInfection(int neighborK) {
    // 只有当邻居的疫情成规模（>15），且自己没病入膏肓时，才会被传染
    if (neighborK > 25 && K < 100) {
        double beta = 0.03; // 贸易线传染系数
        int incoming = std::round(neighborK * beta);

        // 保证即使传得慢，只要触发了至少也会 +1，避免被 round(0) 吃掉
        if (incoming < 1) incoming = 1;

        K += incoming;
        if (K > 100) K = 100;
    }
}

// 万能属性修改接口：新增了对生产度 "N" 的支持
void Star::modifyAttribute(QString attrName, int delta) {
    if (attrName == "P") {
        P += delta;
        if (P > 100) P = 100;
        if (P < 0) P = 0;
    }
    else if (attrName == "Q") {
        Q += delta;
        if (Q > 100) Q = 100;
        if (Q < 0) Q = 0;
    }
    else if (attrName == "N") {  // 【新增的漏洞补丁】：允许政治点数拉升生产力
        N += delta;
        if (N > 100) N = 100;
        if (N < 0) N = 0;
    }

    // 至于贸易度 M，咱们之前已经有专门的 addM() 接口了，所以不需要写在这里

    emit dataChanged();
}
// ------ 【新增】内部高压封锁 ------
void Star::enforceLockdown() {
    // 1. 强力压制内部疫情：K 值直接削减 30%
    K = std::round(static_cast<double>(K) * 0.7);

    // 2. 惨痛代价：稳定度暴跌 25，生产力受损 20
    P -= 25;
    if (P < 0) P = 0;

    N -= 20;
    if (N < 0) N = 0;

    // 3. 独立度降低 15：高压之下，社会被强制统一管理
    Q -= 15;
    if (Q < 0) Q = 0;

    emit dataChanged();
}