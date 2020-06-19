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

            SectionHeader { text: qsTr("Options")}

            IconTextSwitch {
                text: qsTr("Load Images in Toots")
                description: qsTr("Disable this option if you want to preserve your data connection")
                icon.source: "image://theme/icon-m-image"
                checked: typeof Logic.conf['loadImages'] !== "undefined" && Logic.conf['loadImages']
                onClicked: {
                    Logic.conf['loadImages'] = checked
                }
            }

            SectionHeader { text: qsTr("Account") }

            Item {
                id: removeAccount
                width: parent.width
                height: txtRemoveAccount.height + btnRemoveAccount.height + Theme.paddingLarge
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }

                Icon {
                    id: icnRemoveAccount
                    color: Theme.highlightColor
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
                        preferredWidth: Theme.buttonWidthMedium
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
                        color: Theme.highlightColor
                        width: parent.width - Theme.paddingMedium
                        anchors.left: parent.left
                    }
                }
            }

            SectionHeader {
                text:  qsTr("Translate")
            }

            LinkedLabel {
                id: translateLbl
                //: Full sentence for translation: "Use Transifex to help with app translation to your language." - The word Transifex is a link and doesn't need translation.
                text: qsTr("Use")+" "+"<a href='https://www.transifex.com/dysko/tooter/'>Transifex</a>"+" "+qsTr("to help with app translation to your language.")
                textFormat: Text.StyledText
                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.family: Theme.fontFamilyHeading
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }
            }

            SectionHeader {
                //: Translation alternative: "Development"
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
                            name: "Molan"
                            desc: qsTr("Development and translations")
                            mastodon: "molan@fosstodon.org"
                            mail: ""
                        }

                        ListElement {
                            name: "Miodrag Nikolić"
                            desc: qsTr("Visual identity")
                            mastodon: ""
                            mail: "micotakis@gmail.com"
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
                                    var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { }', Qt.application, 'InternalQmlObject');
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
