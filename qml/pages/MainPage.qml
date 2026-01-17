import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/API.js" as Logic
import "./components/"


Page {
    id: mainPage
    property bool debug: false
    property bool isFirstPage: true
    property bool isTablet: true //Screen.sizeCategory >= Screen.Large

    allowedOrientations: Orientation.All

    // Docked Navigation panel
    DockedPanel {
        id: infoPanel
        open: true
        width: isPortrait ? parent.width : Theme.itemSizeLarge
        height: isPortrait ? (Theme.itemSizeLarge + navigation.menuHeight) : parent.height
        dock: isPortrait ? Dock.Bottom : Dock.Right

        NavigationPanel {
            id: navigation
            isPortrait: mainPage.isPortrait
            dockedPanelMouseArea: parent
            onSlideshowShow: {
                if (debug) console.log(vIndex)

                slideshow.positionViewAtIndex(vIndex, ListView.SnapToItem)
            }
            onScrollToTop: {
                // Scroll the corresponding list to top
                var lists = [tlHome, tlNotifications, tlLocal, tlPublic, tlBookmarks, null, tlTrending]
                if (lists[vIndex]) {
                    lists[vIndex].positionViewAtBeginning()
                }
            }
        }
    }

    InteractionHintLabel {
        z: 1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: infoPanel.visibleSize
        text: qsTr("Press and hold the home tab to switch account")
        opacity: navigation.showInteractionHintLabel && infoPanel.visible ? 1 : 0
        Behavior on opacity { FadeAnimator {} }
    }

    VisualItemModel {
        id: visualModel

        MyList {
            id: tlHome
            title: qsTr("Home")
            type: "timelines/home"
            mdl: Logic.modelTLhome
            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
            onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true

            onCountChanged: if (count == 0) worker.verifyCredentials()
        }

        MyList {
            id: tlNotifications
            title: qsTr("Notifications")
            type: "v2/notifications"
            notifier: true
            mdl: Logic.modelTLnotifications
            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
            onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true
        }

        MyList {
            id: tlLocal
            title: qsTr("Local")
            type: "timelines/public?local=true"
            //params: ["local", true]
            mdl: Logic.modelTLlocal
            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
            onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true
        }

        MyList {
            id: tlPublic
            title: qsTr("Federated")
            type: "timelines/public"
            mdl: Logic.modelTLpublic
            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
            onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true
        }
        MyList {
            id: tlBookmarks
            title: qsTr("Bookmarks")
            type: "bookmarks"
            mdl: Logic.modelTLbookmarks
            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
            onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true
        }

        Item {
            id: tlSearch

            property ListModel mdl: ListModel {}
            property string search

            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
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
                    onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true
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
                    onOpenDrawer:  infoPanel.open = setDrawer
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
                    onOpenDrawer:  infoPanel.open = setDrawer
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

        MyList {
            id: tlTrending
            title: qsTr("Trending")
            type: "trends/statuses"
            mdl: Logic.modelTLtrending
            width: isPortrait ? slideshow.itemWidth : slideshow.itemWidth - Theme.itemSizeLarge
            height: slideshow.itemHeight
            onOpenDrawer: isPortrait ? infoPanel.open = setDrawer : infoPanel.open = true
        }
    }

    // Update which tab is currently visible for lazy loading
    function updateCurrentTab(index) {
        tlHome.isCurrentTab = (index === 0)
        tlNotifications.isCurrentTab = (index === 1)
        tlLocal.isCurrentTab = (index === 2)
        tlPublic.isCurrentTab = (index === 3)
        tlBookmarks.isCurrentTab = (index === 4)
        // index 5 is Search (not a MyList)
        tlTrending.isCurrentTab = (index === 6)

        // Clear cover notification badge when viewing notifications tab
        if (index === 1) {
            appWindow.notificationsViewed()
        }
    }

    SlideshowView {
        id: slideshow
        width: parent.width
        height: parent.height
        itemWidth: isTablet ? Math.round(parent.width) : parent.width
        itemHeight: height
        clip: true
        model: visualModel
        onCurrentIndexChanged: {
            navigation.slideshowIndexChanged(currentIndex)
            updateCurrentTab(currentIndex)
        }
        anchors {
            fill: parent
            top: parent.top
            rightMargin: isPortrait ? 0 : infoPanel.visibleSize
            bottomMargin: isPortrait ? infoPanel.visibleSize : 0
        }
        Component.onCompleted: {
            // Initialize Home tab as current for lazy loading
            updateCurrentTab(0)
            // Also load Notifications at startup for badge count
            tlNotifications.loadData("prepend")
            tlNotifications.hasLoadedOnce = true
        }
    }

    IconButton {
        id: newToot
        width: Theme.iconSizeLarge
        height: width
        visible: !isPortrait ? true : !infoPanel.open
        icon.source: "image://theme/icon-l-add"
        anchors {
            right: (mainPage.isPortrait ? parent.right : infoPanel.left)
            rightMargin: isPortrait ? Theme.paddingLarge : Theme.paddingLarge * 0.8
            bottom: (mainPage.isPortrait ? infoPanel.top : parent.bottom)
            bottomMargin: Theme.paddingLarge
        }
        onClicked: {
            pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                               headerTitle: qsTr("New Toot"),
                               type: "new"
                           })
        }
    }

    function onLinkActivated(href) {
        if (debug) console.log("onLinkActivated: " + href)

        // Use the URL parser to detect Mastodon resource types
        var parsed = Logic.parseMastodonUrl(href)
        if (debug) console.log("Parsed URL: " + JSON.stringify(parsed))

        switch (parsed.type) {
        case "tag":
            // Navigate to tag timeline
            tlSearch.search = "#" + parsed.tag
            slideshow.positionViewAtIndex(5, ListView.SnapToItem)
            navigation.navigateTo('search')
            break

        case "profile":
            // Search for profile with full acct
            tlSearch.search = "@" + parsed.acct
            slideshow.positionViewAtIndex(5, ListView.SnapToItem)
            navigation.navigateTo('search')
            break

        case "status":
            // Resolve status URL via search API and open in ConversationPage
            resolveStatusUrl(href)
            break

        default:
            // Unknown URL - open externally
            Qt.openUrlExternally(href)
        }
    }

    // Resolve a status URL and open it in ConversationPage
    function resolveStatusUrl(url) {
        if (debug) console.log("Resolving status URL: " + url)
        worker.sendMessage({
            action: "v2/search",
            mode: "resolveUrl",
            params: [
                { name: "q", data: encodeURIComponent(url) },
                { name: "resolve", data: "true" },
                { name: "type", data: "statuses" },
                { name: "limit", data: "1" }
            ],
            conf: Logic.conf,
            originalUrl: url
        })
    }

    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {
            if (debug) console.log(JSON.stringify(messageObject))
            if (messageObject.action === "accounts/verify_credentials") {
                Logic.getActiveAccount().userInfo = messageObject.data
                Logic.getActiveAccount().userInfo.account_acct += "@" + (Logic.getActiveAccount()['instance'].split("//")[1])
                delete Logic.getActiveAccount().userInfo.account_id
            }
            // Handle URL resolution results
            else if (messageObject.action === "v2/search" && messageObject.mode === "resolveUrl") {
                if (messageObject.statuses && messageObject.statuses.length > 0) {
                    var status = messageObject.statuses[0]
                    if (debug) console.log("Resolved status: " + status.status_id)
                    // Open in ConversationPage
                    var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject')
                    pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                        headerTitle: qsTr("Conversation"),
                        "status_id": status.status_id,
                        "status_url": status.status_url,
                        "status_uri": status.status_uri,
                        mdl: m,
                        type: "reply"
                    })
                } else {
                    // Status not found - open URL externally
                    if (debug) console.log("Status not found, opening externally: " + messageObject.originalUrl)
                    Qt.openUrlExternally(messageObject.originalUrl)
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
