import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/API.js" as Logic


Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    SilicaFlickable {
        contentHeight: column.height + Theme.paddingLarge
        contentWidth: parent.width
        anchors.fill: parent

        RemorsePopup { id: remorsePopup }

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingMedium
            width: parent.width

            PageHeader {
                title: qsTr("Settings")
            }

            SectionHeader { text: "Options"}

            IconTextSwitch {
                text: qsTr("Load Images in Toots")
                description: qsTr("Disable this option if you want to preserve your data connection")
                icon.source: "image://theme/icon-m-image"
                enabled: true
                checked: typeof Logic.conf['loadImages'] !== "undefined" && Logic.conf['loadImages']
                onClicked: {
                    Logic.conf['loadImages'] = checked
                }
            }

            IconTextSwitch {
                text: qsTr("Use smaller Font Size in Toots")
                description: qsTr("Enable this option if you prefer to use a smaller font size in displayed Toots")
                icon.source: "image://theme/icon-m-font-size"
                enabled: false
                //checked: typeof Logic.conf['loadImages'] !== "undefined" && Logic.conf['loadImages']
                //onClicked: {
                //    Logic.conf['loadImages'] = checked
                //}
            }

            SectionHeader { text: "Account"}

            Item {
                id: removeAccount
                width: parent.width
                height: txtRemoveAccount.height + btnRemoveAccount.height + Theme.paddingLarge
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }

                Icon {
                    id: icnRemoveAccount
                    color: Theme.secondaryColor
                    width: Theme.iconSizeMedium
                    fillMode: Image.PreserveAspectFit
                    source: Logic.conf['login'] ? "image://theme/icon-m-contact" : "image://theme/icon-m-add"
                    anchors.right: parent.right
                }

                Column {
                    id: clnRemoveAccount
                    spacing: Theme.paddingMedium
                    anchors {
                        left: parent.left
                        right: icnRemoveAccount.left
                    }

                    Button {
                        id: btnRemoveAccount
                        text: Logic.conf['login'] ? qsTr("Remove Account") : qsTr("Add Account")
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: {
                            remorsePopup.execute(btnRemoveAccount.text, function() {
                                if (Logic.conf['login']) {
                                    Logic.conf['login'] = false
                                    Logic.conf['instance'] = null;
                                    Logic.conf['api_user_token'] = null;
                                }
                                pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                            })
                        }

                        Timer {
                            id: timer1
                            interval: 4700
                            onTriggered: parent.busy = false
                        }
                    }

                    Label {
                        id: txtRemoveAccount
                        text: Logic.conf['login'] ? qsTr("Deauthorize this app from using your account and remove account data from phone") : qsTr("Authorize this app to access your Mastodon account")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        wrapMode: Text.Wrap
                        color: Theme.secondaryColor
                        anchors {
                            left: parent.left
                            leftMargin: Theme.paddingLarge * 1.9
                            right: parent.right
                            rightMargin: Theme.paddingLarge * 1.2
                        }
                    }
                }
            }

            /* SectionHeader { text: "Support"}

            IconTextSwitch {
                text: qsTr("Translate")
                description: qsTr("Use Transifex to help with app translation to your language")
                icon.source: "image://theme/icon-m-font-size"
                onCheckedChanged: {
                    busy = true;
                    checked = false;
                    Qt.openUrlExternally("https://www.transifex.com/dysko/tooter/");
                    timer2.start()
                }
                Timer {
                    id: timer2
                    interval: 4700
                    onTriggered: parent.busy = false
                }
            } */

            SectionHeader {
                text:  qsTr("Credits")
            }

            Column {
                width: parent.width
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }

                Repeater {
                    model: ListModel {

                        ListElement {
                            name: "Duško Angirević"
                            desc: qsTr("UI/UX design and development")
                            mastodon: "dysko@mastodon.social"
                            mail: ""
                        }

                        ListElement {
                            name: "Miodrag Nikolić"
                            desc: qsTr("Visual identity")
                            mastodon: ""
                            mail: "micotakis@gmail.com"
                        }

                        ListElement {
                            name: "Molan"
                            desc: qsTr("Development and translations")
                            mastodon: "molan@fosstodon.org"
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
                            name: "Mohamed-Touhami MAHDI"
                            desc: qsTr("Added README file")
                            mastodon: "dragnucs@touha.me"
                            mail: "touhami@touha.me"
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.itemSizeMedium

                        IconButton {
                            id: btn
                            icon.source: "image://theme/" + (model.mastodon !== "" ? "icon-m-outline-chat" : "icon-m-mail") + "?" + (pressed
                                                                                                                                     ? Theme.highlightColor                                                                                                                                : Theme.primaryColor)
                            anchors {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                            }
                            onClicked: {
                                if (model.mastodon !== ""){
                                    var m = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
                                    pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                                                       headerTitle: "Mention",
                                                       description: '@'+model.mastodon,
                                                       type: "new"
                                                   })
                                } else {
                                    Qt.openUrlExternally("mailto:"+model.mail);
                                }
                            }
                        }

                        Column {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
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
                    }
                }
            }
        }
    }

}
