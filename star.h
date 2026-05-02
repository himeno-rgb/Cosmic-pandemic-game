#ifndef STAR_H
#define STAR_H

#include <QObject>
#include <QString> // 【修复】：必须加上这个，因为 modifyAttribute 用到了 QString

class Star : public QObject
{
    Q_OBJECT
    // 把核心数值暴露给 QML，并绑定 dataChanged 信号
    Q_PROPERTY(int p_K READ kValue NOTIFY dataChanged)
    Q_PROPERTY(int p_N READ nValue NOTIFY dataChanged)
    Q_PROPERTY(int p_M READ mValue NOTIFY dataChanged)
    Q_PROPERTY(int p_P READ pValue NOTIFY dataChanged)
    Q_PROPERTY(int p_Q READ qValue NOTIFY dataChanged)

public:
    explicit Star(QObject *parent = nullptr);

    // 核心指标
    int P = 80; // 稳定度
    int Q = 10; // 独立度
    int N = 90; // 生产度
    int M = 90; // 贸易度
    int K = 0;  // 疫情指数

    // 提供给 QML 的读取接口
    int kValue() const { return K; }
    int nValue() const { return N; }
    int mValue() const { return M; }
    int pValue() const { return P; }
    int qValue() const { return Q; }

    // --- 提供给 QML 调用的核心交互机制 ---

    Q_INVOKABLE void nextTurn(); // 下一回合演化
    Q_INVOKABLE void infect();   // 模拟突发感染

    // 外交：增加经济贸易度
    Q_INVOKABLE void addM(int bonus);

    // 外交：接收外部贸易网络的感染输入
    Q_INVOKABLE void receiveInfection(int neighborK);

    // 内政：万能属性修改接口 (用于发补给升P，或行政托管降Q)
    Q_INVOKABLE void modifyAttribute(QString attrName, int delta);

    // 【新增核心机制】：实施内部高压封锁 (强压疫情，牺牲稳定度)
    Q_INVOKABLE void enforceLockdown();

signals:
    // 神经冲动：只要数据一变，就发射这个信号刷新界面
    void dataChanged();
};

#endif // STAR_H