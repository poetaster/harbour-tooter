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

TARGET = harbour-tooter

CONFIG += sailfishapp

QT += network dbus sql
CONFIG += link_pkgconfig
PKGCONFIG += sailfishapp
PKGCONFIG += \
    nemonotifications-qt5

DEFINES += "APPVERSION=\\\"$${SPECVERSION}\\\""
DEFINES += "APPNAME=\\\"$${TARGET}\\\""

!exists( src/dbusAdaptor.h ) {
    system(qdbusxml2cpp config/ba.dysko.harbour.tooter.xml -i dbus.h -a src/dbusAdaptor)
}

config.path = /usr/share/$${TARGET}/config/
config.files = config/icon-lock-harbour-tooter.png

notification_categories.path = /usr/share/lipstick/notificationcategories
notification_categories.files = config/x-harbour.tooter.activity.*

dbus_services.path = /usr/share/dbus-1/services/
dbus_services.files = config/ba.dysko.harbour.tooter.service

interfaces.path = /usr/share/dbus-1/interfaces/
interfaces.files = config/ba.dysko.harbour.tooter.xml

SOURCES += src/harbour-tooter.cpp \
    src/imageuploader.cpp \
    src/filedownloader.cpp \
    src/notifications.cpp \
    src/dbusAdaptor.cpp \
    src/dbus.cpp

HEADERS += src/imageuploader.h \
    src/filedownloader.h \
    src/notifications.h \
    src/dbusAdaptor.h \
    src/dbus.h

DISTFILES += qml/harbour-tooter.qml \
    qml/images/tooter-cover.svg \
    qml/pages/ConversationPage.qml \
    qml/pages/ProfilePage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/components/InfoBanner.qml \
    qml/pages/components/MediaFullScreen.qml \
    qml/pages/components/ProfileImage.qml \
    qml/pages/components/VisualContainer.qml \
    qml/pages/components/MiniStatus.qml \
    qml/pages/components/MiniHeader.qml \
    qml/pages/components/ItemUser.qml \
    qml/pages/components/MyList.qml \
    qml/pages/components/Navigation.qml \
    qml/pages/components/ProfileHeader.qml \
    qml/pages/components/MediaBlock.qml \
    qml/pages/components/MyImage.qml \
    qml/cover/CoverPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/Browser.qml \
    qml/lib/API.js \
    qml/images/icon-s-following \
    qml/images/icon-s-bookmark \
    qml/images/icon-m-emoji.svg \
    qml/images/icon-m-profile.svg \
    qml/images/icon-l-profile.svg \
    qml/lib/Mastodon.js \
    qml/lib/Worker.js \
    config/icon-lock-harbour-tooter.png \
    config/x-harbour.tooter.activity.conf \
    rpm/harbour-tooter.changes \
    rpm/harbour-tooter.changes.run.in \
    rpm/harbour-tooter.spec \
    rpm/harbour-tooter.yaml \
    translations/*.ts \
    harbour-tooter.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-tooter.ts \
    translations/harbour-tooter-de.ts \
    translations/harbour-tooter-el.ts \
    translations/harbour-tooter-es.ts \
    translations/harbour-tooter-fr.ts \
    translations/harbour-tooter-it.ts \
    translations/harbour-tooter-nl.ts \
    translations/harbour-tooter-nl_BE.ts \
    translations/harbour-tooter-oc.ts \
    translations/harbour-tooter-pl.ts \
    translations/harbour-tooter-ru.ts \
    translations/harbour-tooter-sr.ts \
    translations/harbour-tooter-sv.ts \
    translations/harbour-tooter-zh_CN.ts
