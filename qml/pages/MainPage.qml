import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/API.js" as Logic
import "./components/"
import '../modules/Opal/Tabs'


Page {
    id: mainPage
    allowedOrientations: Orientation.All

    property bool debug: false
    property bool isFirstPage: true

    property bool quickAccountSwitchHintActive: !Logic.conf.multipleAccountsHintCompleted && Logic.conf.accounts.length > 1

    TabView {
        id: tabView
        width: parent.width
        height: parent.height - accountsMenuHelper.height
        tabBarPosition: Qt.AlignBottom
        defaultTabIconSourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)

        property var homeButton: tabView.tabBarItem.children[0].children[0].children[0].children[0] // this is kind of a hack, so can be improved

        // prevent stealing focus from the context menu
        interactive: !accountsMenuHelper.menuOpen

        Tab {
            icon: 'image://theme/icon-m-home'
            Component {
                TabItem {
                    MyList {
                        title: qsTr("Home")
                        type: 'timelines/home'
                        mdl: Logic.modelTLhome
                        width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                        height: parent.height

                        onCountChanged: if (count == 0) worker.verifyCredentials()
                    }
                }
            }
        }

        Tab {
            icon: 'image://theme/icon-m-alarm'
            Component {
                TabItem {
                    MyList {
                        title: qsTr("Notifications")
                        type: "notifications"
                        notifier: true
                        mdl: Logic.modelTLnotifications
                        width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                        height: parent.height
                    }
                }
            }
        }

        Tab {
            icon: 'image://theme/icon-m-whereami'
            Component {
                MyList {
                    title: qsTr("Local")
                    type: "timelines/public?local=true"
                    mdl: Logic.modelTLlocal
                    width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                    height: parent.height
                }
            }
        }

        Tab {
            icon: 'image://theme/icon-m-website'
            Component {
                MyList {
                    title: qsTr("Federated")
                    type: "timelines/public"
                    mdl: Logic.modelTLpublic
                    width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                    height: parent.height
                }
            }
        }

        Tab {
            icon: Qt.resolvedUrl('../images/icon-m-bookmark.svg')
            Component {
                MyList {
                    title: qsTr("Bookmarks")
                    type: "bookmarks"
                    mdl: Logic.modelTLbookmarks
                    width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                    height: parent.height
                }
            }
        }

        Tab {
            icon: 'image://theme/icon-m-search'
            Component {
                Item {
                    id: tlSearch

                    property ListModel mdl: ListModel {}
                    property string search

                    width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                    height: parent.height
                    onSearchChanged: {
                        if (debug) console.log(search)
                        loader.sourceComponent = loading
                        if (search.charAt(0) === "@") {
                            loader.sourceComponent = userListComponent
                        } else if (search.charAt(0) === "#") {
                            loader.sourceComponent = tagListComponent
                        } else loader.sourceComponent = wordListComponent
                    }

                    Loader {
                        id: loader
                        anchors.fill: parent
                    }

                    Column {
                        id: headerContainer
                        width: tlSearch.width
                        PageHeader {
                            title: qsTr("Search")
                        }

                        SearchField {
                            id: searchField
                            width: parent.width
                            placeholderText: qsTr("@user or #term")
                            text: tlSearch.search
                            EnterKey.iconSource: "image://theme/icon-m-enter-close"
                            EnterKey.onClicked: {
                                tlSearch.search = text.toLowerCase().trim()
                                focus = false
                                if (debug) console.log(text)
                            }
                        }
                    }

                    Component {
                        id: loading
                        BusyIndicator {
                            size: BusyIndicatorSize.Large
                            anchors.centerIn: parent
                            running: true
                        }
                    }

                    Component {
                        id: tagListComponent
                        MyList {
                            id: view
                            mdl: ListModel {}
                            width: parent.width
                            height: parent.height
                            anchors.fill: parent
                            currentIndex: -1 // otherwise currentItem will steal focus
                            header:  Item {
                                id: header
                                width: headerContainer.width
                                height: headerContainer.height
                                Component.onCompleted: headerContainer.parent = header
                            }

                            delegate: VisualContainer
                            Component.onCompleted: {
                                view.type = "timelines/tag/"+tlSearch.search.substring(1)
                                if (mdl.count) {
                                    view.loadData("append")
                                } else {
                                    view.loadData("prepend")
                                }
                            }
                        }
                    }

                    Component {
                        id: userListComponent
                        MyList {
                            id: view2
                            mdl: ListModel {}
                            autoLoadMore: false
                            width: parent.width
                            height: parent.height
                            anchors.fill: parent
                            currentIndex: -1 // otherwise currentItem will steal focus
                            header:  Item {
                                id: header
                                width: headerContainer.width
                                height: headerContainer.height
                                Component.onCompleted: headerContainer.parent = header
                            }

                            delegate: ItemUser {
                                onClicked: {
                                    pageStack.push(Qt.resolvedUrl("ProfilePage.qml"), {
                                                       "display_name": model.account_display_name,
                                                       "username": model.account_acct,
                                                       "user_id": model.account_id,
                                                       "profileImage": model.account_avatar,
                                                       "profileBackground": model.account_header,
                                                       "note": model.account_note,
                                                       "url": model.account_url,
                                                       "followers_count": model.account_followers_count,
                                                       "following_count": model.account_following_count,
                                                       "statuses_count": model.account_statuses_count,
                                                       "locked": model.account_locked,
                                                       "bot": model.account_bot,
                                                       "group": model.account_group
                                                   })
                                }
                            }

                            Component.onCompleted: {
                                view2.type = "accounts/search"
                                view2.params = []
                                view2.params.push({name: 'q', data: tlSearch.search.substring(1)});
                                view2.loadData("append")
                            }
                        }
                    }

                    Component {
                        id: wordListComponent
                        MyList {
                            id: view3
                            mdl: ListModel {}
                            width: parent.width
                            height: parent.height
                            anchors.fill: parent
                            currentIndex: -1 // otherwise currentItem will steal focus
                            header:  Item {
                                id: header
                                width: headerContainer.width
                                height: headerContainer.height
                                Component.onCompleted: headerContainer.parent = header
                            }

                            delegate: VisualContainer
                            Component.onCompleted: {
                                view3.type = "timelines/tag/"+tlSearch.search
                                if (mdl.count) {
                                    view3.loadData("append")
                                } else {
                                    view3.loadData("prepend")
                                }
                            }
                        }
                    }
                }
            }
        }

        Tab {
            icon: 'image://theme/icon-camera-flash-on'
            Component {
                MyList {
                    id: tlTrending
                    title: qsTr("Trending")
                    type: "trends/statuses"
                    mdl: Logic.modelTLtrending
                    width: isPortrait ? parent.width : parent.width - Theme.itemSizeLarge
                    height: parent.height
                }
            }
        }
    }

    ListItem {
        id: accountsMenuHelper
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: 0
        onMenuOpenChanged:
            if (menuOpen) {
                Logic.conf.multipleAccountsHintCompleted = true
                quickAccountSwitchHintActive = false
            }
        menu: Component {
            ContextMenu {
                hasContent: Logic.conf.accounts.length > 1
                Repeater {
                    model: Logic.conf.accounts
                    MenuItem {
                        enabled: index !== Logic.conf.activeAccount
                        text: modelData.userInfo.account_acct
                        onClicked: Logic.setActiveAccount(index)
                    }
                }
            }
        }
    }

    Connections {
        // Forward events from the home button to context menu
        target: tabView.homeButton
        onPositionChanged:
            if (accountsMenuHelper._menuItem)
                accountsMenuHelper._menuItem._updatePosition(accountsMenuHelper._menuItem._contentColumn.mapFromItem(target, target.mouseX, target.mouseY).y)
        onReleased:
            if (accountsMenuHelper._menuItem)
                accountsMenuHelper._menuItem.released(mouse)
    }

    Connections {
        target: tabView.homeButton
        onPressAndHold:
            accountsMenuHelper.openMenu()
    }

    HoldInteractionHint {
        id: quickAccountSwitchHint
        parent: tabView.homeButton
        anchors.centerIn: parent.contentItem
        running: quickAccountSwitchHintActive
    }

    InteractionHintLabel {
        z: 1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: tabView.tabBarHeight + accountsMenuHelper.height
        text: qsTr("Press and hold the home tab to switch account")
        opacity: quickAccountSwitchHintActive ? 1 : 0
        Behavior on opacity { FadeAnimator {} }
    }

    IconButton {
        id: newToot
        width: Theme.iconSizeLarge
        height: width
        icon.source: "image://theme/icon-l-add"
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            bottom: parent.bottom
            bottomMargin: tabView.tabBarHeight + Theme.paddingLarge + accountsMenuHelper.height
        }
        onClicked: {
            pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                               headerTitle: qsTr("New Toot"),
                               type: "new"
                           })
        }
    }

    function onLinkActivated(href) {
        var test = href.split("/")
        debug = true
        if (debug) {
                console.log(href)
                console.log(JSON.stringify(test))
                console.log(JSON.stringify(test.length))
        }
        if (test.length === 5 && (test[3] === "tags" || test[3] === "tag") ) {
            tlSearch.search = "#"+decodeURIComponent(test[4])
            tabView.currentIndex = 5
            if (debug) console.log("search tag")

        } else if (test.length === 4 && test[3][0] === "@" ) {
            tlSearch.search = decodeURIComponent("@"+test[3].substring(1)+"@"+test[2])
            tabView.currentIndex = 5

        } else {
            Qt.openUrlExternally(href)
        }
    }

    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {
            if (debug) console.log(JSON.stringify(messageObject))
            if (messageObject.action === "accounts/verify_credentials") {
                if (messageObject.success) {
                    Logic.getActiveAccount().userInfo = messageObject.data
                    Logic.getActiveAccount().userInfo.account_acct += "@" + (Logic.getActiveAccount()['instance'].split("//")[1])
                    delete Logic.getActiveAccount().userInfo.account_id
                } else
                    if (Logic.removeActiveAccount()) {
                        pageStack.clear()
                        pageStack.push(Qt.resolvedUrl('LoginPage.qml'))
                    }
            }
        }

        function verifyCredentials() {
            sendMessage({action: "accounts/verify_credentials", conf: Logic.conf})
        }

        Component.onCompleted: verifyCredentials()
    }

    Component.onCompleted: {
        //console.log("aaa")
    }
}
