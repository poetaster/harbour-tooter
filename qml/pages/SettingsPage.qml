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

            SectionHeader { text: qsTr("Options") }

            IconTextSwitch {
                text: qsTr("Load Images in Toots")
                description: qsTr("Disable this option if you want to preserve your data connection")
                icon.source: "image://theme/icon-m-image"
                checked: typeof Logic.conf['loadImages'] !== "undefined" && Logic.conf['loadImages']
                onClicked: {
                    Logic.conf['loadImages'] = checked
                }
            }

            IconTextSwitch {
                text: qsTr("Show Full Usernames")
                description: qsTr("Display @user@domain instead of @user")
                icon.source: "image://theme/icon-m-contact"
                checked: typeof Logic.conf['fullUsernames'] !== "undefined" && Logic.conf['fullUsernames']
                onClicked: {
                    Logic.conf['fullUsernames'] = checked
                    appWindow.fullUsernames = checked
                }
            }

            IconTextSwitch {
                text: qsTr("Open Links in Reader Mode")
                description: qsTr("Display articles in a clean reading view")
                icon.source: "image://theme/icon-m-document"
                checked: typeof Logic.conf['openLinksInReader'] !== "undefined" && Logic.conf['openLinksInReader']
                onClicked: {
                    Logic.conf['openLinksInReader'] = checked
                    appWindow.openLinksInReader = checked
                }
            }

            Item {
                width: parent.width
                height: fontSizeColumn.height

                Column {
                    id: fontSizeColumn
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Row {
                        width: parent.width - Theme.horizontalPageMargin * 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.paddingMedium

                        Icon {
                            source: "image://theme/icon-m-font-size"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: qsTr("Font Size")
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.highlightColor
                        }

                        Label {
                            text: Math.round(appWindow.fontScale * 100) + "%"
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.secondaryHighlightColor
                        }
                    }

                    Slider {
                        id: fontSizeSlider
                        width: parent.width
                        minimumValue: 0.7
                        maximumValue: 1.5
                        value: appWindow.fontScale
                        stepSize: 0.1
                        onValueChanged: {
                            appWindow.fontScale = value
                            Logic.conf['fontScale'] = value
                        }

                        Label {
                            text: qsTr("Sample text")
                            font.pixelSize: Theme.fontSizeSmall * appWindow.fontScale
                            color: Theme.primaryColor
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: parent.bottom
                            }
                        }
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
                        ListElement {
                            name: "Frank Paul Silye"
                            desc: qsTr("Norwegian Translation")
                            mastodon: "frankps@babb.no"
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
