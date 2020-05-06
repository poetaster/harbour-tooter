# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-tooterb

CONFIG += sailfishapp

QT += network dbus sql
CONFIG += link_pkgconfig
PKGCONFIG += sailfishapp
PKGCONFIG += \
    nemonotifications-qt5

DEFINES += "APPVERSION=\\\"$${SPECVERSION}\\\""
DEFINES += "APPNAME=\\\"$${TARGET}\\\""

!exists( src/dbusAdaptor.h ) {
    system(qdbusxml2cpp config/ba.dysko.harbour.tooterb.xml -i dbus.h -a src/dbusAdaptor)
}

config.path = /usr/share/$${TARGET}/config/
config.files = config/icon-lock-harbour-tooterb.png

notification_categories.path = /usr/share/lipstick/notificationcategories
notification_categories.files = config/x-harbour.tooterb.activity.*

dbus_services.path = /usr/share/dbus-1/services/
dbus_services.files = config/ba.dysko.harbour.tooterb.service

interfaces.path = /usr/share/dbus-1/interfaces/
interfaces.files = config/ba.dysko.harbour.tooterb.xml

SOURCES += \
    src/harbour-tooterb.cpp
SOURCES += src/imageuploader.cpp
SOURCES += src/filedownloader.cpp
SOURCES += src/notifications.cpp
SOURCES += src/dbusAdaptor.cpp
SOURCES += src/dbus.cpp

HEADERS += src/imageuploader.h
HEADERS += src/filedownloader.h
HEADERS += src/notifications.h
HEADERS += src/dbusAdaptor.h
HEADERS += src/dbus.h

DISTFILES += qml/harbour-tooterb.qml \
    config/icon-lock-harbour-tooterb.png \
    qml/images/tooterb.svg \
    qml/pages/components/VisualContainer.qml \
    qml/pages/components/MiniStatus.qml \
    qml/pages/components/MiniHeader.qml \
    qml/pages/components/ItemUser.qml \
    qml/pages/components/MyList.qml \
    qml/pages/components/Navigation.qml \
    qml/pages/components/ProfileHeader.qml \
    qml/pages/components/MediaBlock.qml \
    qml/pages/components/MyImage.qml \
    qml/pages/components/ImageFullScreen.qml \
    qml/cover/CoverPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/Conversation.qml \
    qml/pages/components/Toot.qml \
    qml/pages/Browser.qml \
    qml/pages/Profile.qml \
    qml/pages/Settings.qml \
    qml/lib/API.js \
    qml/images/notification.svg \
    qml/images/verified.svg \
    qml/images/boosted.svg \
    qml/images/emojiselect.svg \
    qml/images/icon-m-profile.svg \
    qml/images/icon-l-profile.svg \
    qml/lib/Mastodon.js \
    qml/lib/Worker.js \
    config/x-harbour.tooterb.activity.conf \
    rpm/harbour-tooterb.changes \
    rpm/harbour-tooterb.changes.run.in \
    rpm/harbour-tooterb.spec \
    rpm/harbour-tooterb.yaml \
    translations/*.ts \
    harbour-tooterb.desktop 

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-tooterb-de.ts
TRANSLATIONS += translations/harbour-tooterb-el.ts
TRANSLATIONS += translations/harbour-tooterb-es.ts
TRANSLATIONS += translations/harbour-tooterb-fi.ts
TRANSLATIONS += translations/harbour-tooterb-fr.ts
TRANSLATIONS += translations/harbour-tooterb-nl.ts
TRANSLATIONS += translations/harbour-tooterb-nl_BE.ts
TRANSLATIONS += translations/harbour-tooterb-oc.ts
TRANSLATIONS += translations/harbour-tooterb-pl.ts
TRANSLATIONS += translations/harbour-tooterb-ru.ts
TRANSLATIONS += translations/harbour-tooterb-sr.ts
TRANSLATIONS += translations/harbour-tooterb-sv.ts
TRANSLATIONS += translations/harbour-tooterb-zh_CN.ts
TRANSLATIONS += translations/harbour-tooterb-it.ts
