import QtQuick 2.0
import Sailfish.Silica 1.0
import "components"
import "../lib/API.js" as Logic


Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        // Just so translations are not lost in case we will need them again
        qsTr("Remove Account")
        qsTr("Deauthorize this app from using your account and remove account data from phone")
    }

    SilicaFlickable {
        contentHeight: column.height + Theme.paddingLarge
        contentWidth: parent.width
        anchors.fill: parent

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

            signal activeAccountChanged
            function setActiveAccount(index, removing) {
                if (!removing && Logic.conf.activeAccount === index) return
                Logic.setActiveAccount(index)

                if (removing)
                    accountsList.model = Logic.conf.accounts
                else activeAccountChanged()
            }

            Repeater {
                id: accountsList
                model: Logic.conf.accounts
                ItemUser {
                    id: userItem
                    property var model: modelData.userInfo
                    textHighlighted: index === Logic.conf.activeAccount

                    Connections {
                        target: column
                        onActiveAccountChanged: textHighlighted = index === Logic.conf.activeAccount
                    }

                    onClicked: column.setActiveAccount(index)

                    function remove() {
                        remorseAction(qsTr("Account removed"), function() {
                            Logic.conf.accounts.splice(index, 1)
                            if (Logic.conf.accounts.length)
                                column.setActiveAccount(0, true) //Logic.conf.accounts.length - 1
                            else {
                                Logic.conf.activeAccount = null
                                pageStack.clear()
                                pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                            }
                        })
                    }

                    menu: Component {
                        ContextMenu {
                            MenuItem {
                                text: qsTr("Remove")
                                onClicked: remove()
                            }
                        }
                    }
                }
            }

            Item {
                id: addAccount
                width: parent.width
                height: clnAddAccount.height + Theme.paddingLarge
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }

                Icon {
                    id: icnAddAccount
                    color: Theme.highlightColor
                    width: Theme.iconSizeMedium
                    fillMode: Image.PreserveAspectFit
                    source: "image://theme/icon-m-add"
                    anchors.right: parent.right
                }

                Column {
                    id: clnAddAccount
                    spacing: Theme.paddingMedium
                    anchors {
                        left: parent.left
                        right: icnAddAccount.left
                    }

                    Button {
                        id: btnAddAccount
                        text: qsTr("Add Account")
                        preferredWidth: Theme.buttonWidthMedium
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                        }

                        Timer {
                            interval: 4700
                            onTriggered: parent.busy = false
                        }
                    }

                    Label {
                        id: txtAddAccount
                        text: qsTr("Authorize this app to access your Mastodon account")
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
                text: qsTr("Use")+" "+"<a href='https://www.transifex.com/molan-git/tooter-b'>Transifex</a>"+" "+qsTr("to help with app translation to your language.")
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
                            desc: qsTr("Development")
                            mastodon: "roundedrectangle@techhub.social"
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
                                                       headerTitle: qsTr("Mention"),
                                                       username: '@'+model.mastodon,
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
