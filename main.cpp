#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "star.h" // [步骤1] 引入你的类

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // [步骤2] 注册类型。
    // 参数含义：命名空间、主版本、次版本、QML中使用的名称
    qmlRegisterType<Star>("GameLogic", 1, 0, "Star");

    QQmlApplicationEngine engine;
   const QUrl url("qrc:/qt/qml/greatestgame/Main.qml");
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
