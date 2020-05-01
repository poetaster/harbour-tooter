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
TARGET = harbour-tooter-beta

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

SOURCES += \
    src/harbour-tooter-beta.cpp
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

DISTFILES += qml/harbour-tooter-beta.qml \
    config/icon-lock-harbour-tooter-beta.png \
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
    qml/images/tooter.svg \
    qml/images/emojiselect.svg \
    qml/images/icon-m-profile.svg \
    qml/images/icon-l-profile.svg \
    qml/lib/Mastodon.js \
    qml/lib/Worker.js \
    config/x-harbour.tooter.activity.conf \
    rpm/harbour-tooter-beta.changes \
    rpm/harbour-tooter-beta.changes.run.in \
    rpm/harbour-tooter-beta.spec \
    rpm/harbour-tooter-beta.yaml \
    translations/*.ts \
    harbour-tooter-beta.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-tooter-beta-de.ts
TRANSLATIONS += translations/harbour-tooter-beta-el.ts
TRANSLATIONS += translations/harbour-tooter-beta-es.ts
TRANSLATIONS += translations/harbour-tooter-beta-fi.ts
TRANSLATIONS += translations/harbour-tooter-beta-fr.ts
TRANSLATIONS += translations/harbour-tooter-beta-nl.ts
TRANSLATIONS += translations/harbour-tooter-beta-nl_BE.ts
TRANSLATIONS += translations/harbour-tooter-beta-oc.ts
TRANSLATIONS += translations/harbour-tooter-beta-pl.ts
TRANSLATIONS += translations/harbour-tooter-beta-ru.ts
TRANSLATIONS += translations/harbour-tooter-beta-sr.ts
TRANSLATIONS += translations/harbour-tooter-beta-sv.ts
TRANSLATIONS += translations/harbour-tooter-beta-zh_CN.ts
TRANSLATIONS += translations/harbour-tooter-beta-it.ts
