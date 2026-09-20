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
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    QQmlEngine* engine = view->engine();

    view->rootContext()->setContextProperty("APP_VERSION", QString(APP_VERSION));
    view->rootContext()->setContextProperty("APP_RELEASE", QString(APP_RELEASE));

    qmlRegisterType<FileDownloader>("harbour.tooterb.Downloader", 1, 0, "FileDownloader");
    qmlRegisterType<ImageUploader>("harbour.tooterb.Uploader", 1, 0, "ImageUploader");

    Notifications *no = new Notifications();
    view->rootContext()->setContextProperty("Notifications", no);
    QObject::connect(engine, SIGNAL(quit()), app.data(), SLOT(quit()));

    QTranslator *appTranslator = new QTranslator;
    appTranslator->load("harbour-tooterb-" + QLocale::system().name(), SailfishApp::pathTo("translations").path());
    app->installTranslator(appTranslator);

    //Dbus *dbus = new Dbus();
    //view->rootContext()->setContextProperty("Dbus", dbus);

    app->setOrganizationName("de.poetaster");
    app->setApplicationName("tooterb");

    view->setSource(SailfishApp::pathTo("qml/harbour-tooterb.qml"));
/* from s-office */
    new DBusAdaptor(view.data());
    if (!QDBusConnection::sessionBus().registerObject("/de/poetaster/tooterb", view.data()))
        qWarning() << "Could not register de/poetaster/tooterb D-Bus object.";
    if (!QDBusConnection::sessionBus().registerService("de.poetaster.tooterb"))
        qWarning() << "Could not register de.poetaster.tooterb D-Bus service.";

    bool preStart = false;
    QString fileName;

    for (int i = 1; i < argc; ++i) {
        QString parameter(argv[i]);
        if (parameter == QStringLiteral("-prestart")) {
            preStart = true;
        } else if (fileName.isEmpty()) {
            fileName = parameter;
        }
    }
/* end from s-office    */

    view->show();
    return app->exec();
}
