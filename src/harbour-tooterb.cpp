#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QQuickView>
#include <QtQml>
#include <QScopedPointer>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QQmlContext>
#include <QCoreApplication>
#include <QtNetwork>
#include <QDBusConnection>
//#include <QtSystemInfo/QDeviceInfo>
#include "filedownloader.h"
#include "imageuploader.h"
#include "notifications.h"

#include "dbusAdaptor.h"

#include "requires_defines.h"


int main(int argc, char *argv[]) {
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    app->setOrganizationName("de.poetaster");
    app->setApplicationName("tooterb");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    QQmlEngine* engine = view->engine();

    view->rootContext()->setContextProperty("APP_VERSION", QString(APP_VERSION));
    view->rootContext()->setContextProperty("APP_RELEASE", QString(APP_RELEASE));

    FileDownloader *fd = new FileDownloader(engine);
    view->rootContext()->setContextProperty("FileDownloader", fd);
    qmlRegisterType<ImageUploader>("harbour.tooterb.Uploader", 1, 0, "ImageUploader");

    Notifications *no = new Notifications();
    view->rootContext()->setContextProperty("Notifications", no);
    QObject::connect(engine, SIGNAL(quit()), app.data(), SLOT(quit()));

    //Dbus *dbus = new Dbus();
    //view->rootContext()->setContextProperty("Dbus", dbus);

    /*new DBusAdaptor(view.data());

    if (!QDBusConnection::sessionBus().registerObject("/de/poetaster/tooterb", view.data()))
        qWarning() << "Could not register /de/poetaster/tooter D-Bus object.";

    if (!QDBusConnection::sessionBus().registerService("de.poetaster.tooterb"))
        qWarning() << "Could not register de.poetaster.tooterb D-Bus service.";
    */
    view->setSource(SailfishApp::pathTo("qml/harbour-tooterb.qml"));
    view->show();
    return app->exec();
}
