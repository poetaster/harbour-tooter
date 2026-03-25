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

        PullDownMenu {
            MenuItem {
                text: qsTr("About", "About the app")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }

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

            IconTextSwitch {
                text: qsTr("Quick Scroll Arrows")
                description: qsTr("Show arrows to jump to top/bottom when scrolling fast")
                icon.source: "image://theme/icon-m-up"
                checked: typeof Logic.conf['quickScroll'] === "undefined" || Logic.conf['quickScroll']
                onClicked: {
                    Logic.conf['quickScroll'] = checked
                    appWindow.quickScrollEnabled = checked
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
        }
    }
}
