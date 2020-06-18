import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/API.js" as Logic
import "./components/"


Page {
    id: mainPage

    property bool isFirstPage: true
    property bool isTablet: true //Screen.sizeCategory >= Screen.Large

    allowedOrientations: Orientation.All

    DockedPanel {
        id: infoPanel
        open: true
        width: mainPage.isPortrait ? parent.width : Theme.itemSizeLarge
        height: mainPage.isPortrait ? Theme.itemSizeLarge : parent.height
        dock: mainPage.isPortrait ? Dock.Bottom : Dock.Right

        Navigation {
            id: navigation
            isPortrait: !mainPage.isPortrait
            onSlideshowShow: {
                console.log(vIndex)
                slideshow.positionViewAtIndex(vIndex, ListView.SnapToItem)
            }
        }
    }

    VisualItemModel {
        id: visualModel

        MyList{
            id: tlHome
            title: qsTr("Home")
            type: "timelines/home"
            mdl: Logic.modelTLhome
            width: parent.itemWidth
            height: parent.itemHeight
            onOpenDrawer:  infoPanel.open = setDrawer
        }

        MyList{
            id: tlNotifications
            title: qsTr("Notifications")
            type: "notifications"
            notifier: true
            mdl: Logic.modelTLnotifications
            width: parent.itemWidth
            height: parent.itemHeight
            onOpenDrawer: infoPanel.open = setDrawer
        }

        MyList{
            id: tlLocal
            title: qsTr("Local")
            type: "timelines/public?local=true"
            //params: ["local", true]
            mdl: Logic.modelTLlocal
            width: parent.itemWidth
            height: parent.itemHeight
            onOpenDrawer: infoPanel.open = setDrawer
        }

        MyList{
            id: tlPublic
            title: qsTr("Federated")
            type: "timelines/public"
            mdl: Logic.modelTLpublic
            width: parent.itemWidth
            height: parent.itemHeight
            onOpenDrawer: infoPanel.open = setDrawer
        }

        Item {
            id: tlSearch

            property ListModel mdl: ListModel {}
            property string search

            width: parent.itemWidth
            height: parent.itemHeight
            onSearchChanged: {
                console.log(search)
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
                        console.log(text)
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
                        view.type = "timelines/tag/"+tlSearch.search.substring(1)
                        view.loadData("append")
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
                        view3.loadData("append")
                    }
                }
            }
        }
    }

    SlideshowView {
        id: slideshow
        width: parent.width
        height: parent.height
        itemWidth: isTablet ? Math.round(parent.width) : parent.width
        itemHeight: height
        clip: true
        onCurrentIndexChanged: {
            navigation.slideshowIndexChanged(currentIndex)
        }
        anchors {
            fill: parent
            top: parent.top
            rightMargin: mainPage.isPortrait ? 0 : infoPanel.visibleSize
            bottomMargin: mainPage.isPortrait ? infoPanel.visibleSize : 0
        }
        model: visualModel
        Component.onCompleted: {
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
            rightMargin: Theme.paddingLarge
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
        var test = href.split("/")
        console.log(href)
        console.log(JSON.stringify(test))
        console.log(JSON.stringify(test.length))
        if (test.length === 5 && (test[3] === "tags" || test[3] === "tag") ) {
            tlSearch.search = "#"+decodeURIComponent(test[4])
            slideshow.positionViewAtIndex(4, ListView.SnapToItem)
            navigation.navigateTo('search')

        } else if (test.length === 4 && test[3][0] === "@" ) {
            tlSearch.search = decodeURIComponent("@"+test[3].substring(1)+"@"+test[2])
            slideshow.positionViewAtIndex(4, ListView.SnapToItem)
            navigation.navigateTo('search')

        } else {
            Qt.openUrlExternally(href)
        }
    }

    Component.onCompleted: {
        console.log("aaa")
    }
}
