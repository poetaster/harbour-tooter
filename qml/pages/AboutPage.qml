import QtQuick 2.0
import Sailfish.Silica 1.0
import '../modules/Opal/About'

AboutPageBase {
    id: root
    allowedOrientations: Orientation.All
    appName: "Tooter β"
    appIcon: Qt.resolvedUrl('../images/harbour-tooterb.svg')
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    description: qsTr("Tooter is Mastodon client for Sailfish OS.")

    // Fix icon scaling
    _iconItem.sourceSize.width: _iconItem.width
    _iconItem.sourceSize.height: _iconItem.height

    authors: 'poetaster'
    licenses: License { spdxId: 'GPL-3.0-or-later' }
    sourcesUrl: 'https://github.com/poetaster/harbour-tooter'
    translationsUrl: 'https://www.transifex.com/molan-git/tooter-b'
    homepageUrl: 'https://forum.sailfishos.org/t/tooter-feedback-thread/13508'
    donations.services: [
        DonationService {
            name: qsTr("SFOS Community Liberapay")
            url: "https://liberapay.com/SailfishOScommunityTeam"
        },
        DonationService {
            name: "Liberapay"
            url: "https://liberapay.com/poetaster"
        }
    ]

    function openMastodonUrl(mastodon) {
        pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                           headerTitle: qsTr("Mention"),
                           username: '@'+mastodon,
                           type: 'new'
                       })
    }

    // for now, we use a custom contributors list, as the one Opal provides doesn't work well with links
    extraSections: [
        InfoSection {
            title: qsTr("Credits")
            Column {
                width: parent.width
                Repeater {
                    model: ListModel {
                        ListElement {
                            name: "Duško Angirević"
                            desc: qsTr("UI/UX design and development")
                            mastodon: "dysko@mastodon.social"
                            mail: ""
                        }

                        ListElement {
                            name: "molan"
                            desc: qsTr("Development and translations")
                            mastodon: "molan@fosstodon.org"
                            mail: "mol_an@sunrise.ch"
                        }

                        ListElement {
                            name: "poetaster"
                            desc: qsTr("Development")
                            mastodon: "postaster@mastodon.gamedev.place"
                            mail: "blueprint@poetaster.de"
                        }
                        ListElement {
                            name: "Miodrag Nikolić"
                            desc: qsTr("Visual identity")
                            mastodon: ""
                            mail: "micotakis@gmail.com"
                        }
                        ListElement {
                            name: "Jozef Mlich"
                            desc: qsTr("Documentation")
                            mastodon: "@jmlich@fosstodon.org"
                            mail: ""
                        }

                        ListElement {
                            name: "Quentin PAGÈS / Quenti ♏"
                            desc: qsTr("Occitan & French translation")
                            mastodon: "Quenti@framapiaf.org"
                            mail: ""
                        }

                        ListElement {
                            name: "Luchy Kon / dashinfantry"
                            desc: qsTr("Chinese translation")
                            mastodon: ""
                            mail: "dashinfantry@gmail.com"
                        }

                        ListElement {
                            name: "André Koot"
                            desc: qsTr("Dutch translation")
                            mastodon: "meneer@mastodon.social"
                            mail: "https://twitter.com/meneer"
                        }

                        ListElement {
                            name: "CarmenFdez"
                            desc: qsTr("Spanish translation")
                            mastodon: ""
                            mail: ""
                        }

                        ListElement {
                            name: "roundedrectangle"
                            desc: qsTr("Development, Russian translation")
                            mastodon: "roundedrectangle@techhub.social"
                            mail: ""
                        }
                        ListElement {
                            name: "Frank Paul Silye"
                            desc: qsTr("Norwegian Translation")
                            mastodon: "frankps@babb.no"
                            mail: ""
                        }
                        ListElement {
                            name: "Lari Lohikoski"
                            desc: qsTr("Development")
                            mastodon: "lari@suomi.social"
                            mail: ""
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.itemSizeMedium

                        Column {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: btn.left
                                rightMargin: Theme.paddingMedium
                            }

                            Label {
                                id: lblName
                                text: model.name
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Label {
                                text: model.desc
                                color: Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }

                        IconButton {
                            id: btn
                            icon.source: "image://theme/" + (model.mastodon !== "" ? "icon-m-outline-chat" : "icon-m-mail") + "?" + (pressed
                                                                                                                                     ? Theme.highlightColor                                                                                                                                : Theme.primaryColor)
                            anchors {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                            }
                            onClicked: {
                                if (model.mastodon) {
                                    pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                                                       headerTitle: qsTr("Mention"),
                                                       username: '@'+model.mastodon,
                                                       type: 'new'
                                                   })
                                } else
                                    Qt.openUrlExternally('mailto:' + model.mail)
                            }
                        }
                    }
                }
            }
        }

    ]
}
