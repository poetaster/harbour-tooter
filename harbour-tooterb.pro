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

TARGET = harbour-tooterb

CONFIG += sailfishapp

QT += network dbus sql
QT += multimedia
CONFIG += link_pkgconfig
PKGCONFIG += sailfishapp \
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
interfaces.files = config/ba.dysko.harbourb.tooterb.xml

# Explicit install rules for new QML pages
newpages.path = /usr/share/$${TARGET}/qml/pages
newpages.files = qml/pages/LinkOptionsDialog.qml \
    qml/pages/ReaderPage.qml \
    qml/pages/TestPage.qml

INSTALLS += newpages

SOURCES += src/harbour-tooterb.cpp \
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

DISTFILES += qml/harbour-tooterb.qml \
    qml/images/tooterb-cover.svg \
    qml/pages/ConversationPage.qml \
    qml/pages/ProfilePage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/LinkOptionsDialog.qml \
    qml/pages/ReaderPage.qml \
    qml/pages/components/HoldInteractionHint.qml \
    qml/pages/components/InfoBanner.qml \
    qml/pages/components/MediaFullScreen.qml \
    qml/pages/components/MyMedia.qml \
    qml/pages/components/NavigationPanel.qml \
    qml/pages/components/ProfileImage.qml \
    qml/pages/components/VisualContainer.qml \
    qml/pages/components/MiniStatus.qml \
    qml/pages/components/MiniHeader.qml \
    qml/pages/components/ItemUser.qml \
    qml/pages/components/MyList.qml \
    qml/pages/components/ProfileHeader.qml \
    qml/pages/components/MediaBlock.qml \
    qml/pages/components/MediaItem.qml \
    qml/cover/CoverPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/Browser.qml \
    qml/lib/API.js \
    qml/images/icon-s-following \
    qml/images/icon-s-bookmark \
    qml/images/icon-m-bookmark \
    qml/images/icon-m-emoji.svg \
    qml/images/icon-m-profile.svg \
    qml/images/icon-l-profile.svg \
    qml/lib/Mastodon.js \
    qml/lib/Worker.js \
    config/icon-lock-harbour-tooterb.png \
    config/x-harbour.tooterb.activity.conf \
    rpm/harbour-tooterb.changes.run \
    rpm/harbour-tooterb.changes \
    rpm/harbour-tooterb.spec \
    translations/*.ts \
    harbour-tooterb.desktop \
    translations/harbour-tooter-no.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-tooterb.ts \
    translations/harbour-tooterb-de.ts \
    translations/harbour-tooterb-el.ts \
    translations/harbour-tooterb-es.ts \
    translations/harbour-tooterb-fi.ts \
    translations/harbour-tooterb-fr.ts \
    translations/harbour-tooterb-it.ts \
    translations/harbour-tooterb-nl.ts \
    translations/harbour-tooterb-nl_BE.ts \
    translations/harbour-tooterb-oc.ts \
    translations/harbour-tooterb-pl.ts \
    translations/harbour-tooterb-ru.ts \
    translations/harbour-tooterb-sr.ts \
    translations/harbour-tooterb-sv.ts \
    #translations/harbour-tooterb-no.ts \
    translations/harbour-tooterb-nb.ts
    #translations/harbour-tooterb-nb_NO.ts
    translations/harbour-tooterb-zh_CN.ts
