import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import "../../lib/API.js" as Logic


SilicaGridView {
    id: gridView

    property bool isPortrait: true
    signal slideshowShow(int vIndex)
    signal slideshowIndexChanged(int vIndex)

    property var dockedPanelMouseArea
    readonly property real menuHeight: headerItem.implicitHeight
    property bool showInteractionHintLabel

    onSlideshowIndexChanged: {
        navigateTo(vIndex)
    }

    header: Component {
        ListItem {
            width: parent.width
            contentHeight: 0
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
    }

    ListModel {
        id: listModel
        ListElement {
            icon: "image://theme/icon-m-home?"
            slug: "home"
            name: "Home"
            active: true
            unread: false
            showMenuOnPressAndHold: true
        }

        ListElement {
            icon: "image://theme/icon-m-alarm?"
            slug: "notifications"
            name: "Notifications"
            active: false
        }

        ListElement {
            icon: "image://theme/icon-m-whereami?"
            slug: "local"
            name: "Local"
            active: false
            unread: false
        }
        ListElement {
            icon: "image://theme/icon-m-website?"
            slug: "federated"
            name: "Federated"
            active: false
            unread: false
        }

        ListElement {
            icon: "../../images/icon-m-bookmark.svg?"
            //icon: "image://theme/icon-m-bookmark"
            slug: "bookmarks"
            name: "Bookmarks"
            active: false
            unread: false
        }
        ListElement {
            icon: "image://theme/icon-m-search?"
            slug: "search"
            name: "Search"
            active: false
            unread: false
        }
    }
    model: listModel
    currentIndex: -1
    cellWidth: isPortrait ? gridView.width / model.count : gridView.width
    cellHeight: (gridView.height - headerItem.implicitHeight) / (isPortrait ? 1 : model.count)
    anchors.fill: parent
    delegate: BackgroundItem {
        id: rectangle
        clip: true
        width: gridView.cellWidth
        height: gridView.cellHeight
        GridView.onAdd: AddAnimation {
            target: rectangle
        }
        GridView.onRemove: RemoveAnimation {
            target: rectangle
        }

        GlassItem {
            id: effect
            visible: isPortrait && unread
            dimmed: true
            color: Theme.highlightColor
            width: Theme.itemSizeMedium
            height: Theme.itemSizeMedium
            anchors {
                bottom: parent.bottom
                bottomMargin: -height/2
                horizontalCenter: parent.horizontalCenter
            }
        }

        GlassItem {
            id: effect2
            visible: !isPortrait && unread
            dimmed: false
            color: Theme.highlightColor
            width: Theme.itemSizeMedium
            height: Theme.itemSizeMedium
            anchors {
                right: parent.right
                rightMargin: -height/2
                verticalCenter: parent.verticalCenter
            }
        }

        Image {
            id: image
            visible: false
            source: model.icon
            sourceSize.width: Theme.iconSizeMedium
            sourceSize.height: Theme.iconSizeMedium
            anchors.centerIn: parent
        }

        ColorOverlay {
            source: image
            color: (highlighted ? Theme.highlightColor : (model.active ? Theme.secondaryHighlightColor : Theme.primaryColor))
            anchors.fill: image
        }

        onClicked: {
            slideshowShow(index)
            console.log(index)
            navigateTo(model.slug)
            effect.state = "right"
        }

        onPressAndHold: if (isPortrait && showMenuOnPressAndHold) headerItem.openMenu()

        HoldInteractionHint {
            id: hint
            anchors.centerIn: parent

            running: false
            function updateRunning() {
                if (!showMenuOnPressAndHold || Logic.conf.multipleAccountsHintCompleted || !isPortrait) {
                    running = false
                    return
                }


                headerItem.openMenu()
                running = headerItem._menuItem.hasContent
                headerItem.closeMenu()

                if (running)
                    rectangle.pressAndHold.connect(function() {
                        Logic.conf.multipleAccountsHintCompleted = true
                        updateRunning()
                    })
            }

            Component.onCompleted: updateRunning()
            Connections {
                ignoreUnknownSignals: true
                target: !showMenuOnPressAndHold || Logic.conf.multipleAccountsHintCompleted
                        ? undefined : gridView
                onIsPortraitChanged: hint.updateRunning()
            }

            Binding {
                when: showMenuOnPressAndHold && !Logic.conf.multipleAccountsHintCompleted
                target: gridView
                property: 'showInteractionHintLabel'
                value: hint.running
            }
        }
    }

    function navigateTo(slug){
        for(var i = 0; i < listModel.count; i++){
            if (listModel.get(i).slug === slug || i===slug)
                listModel.setProperty(i, 'active', true);
            else
                listModel.setProperty(i, 'active', false);
        }
        console.log(slug)
    }

    VerticalScrollDecorator {}

    Connections {
        // Forward events from docked panel to context menu
        target: dockedPanelMouseArea
        onPositionChanged: if (headerItem._menuItem)
            headerItem._menuItem._updatePosition(headerItem._menuItem._contentColumn.mapFromItem(dockedPanelMouseArea, dockedPanelMouseArea.mouseX, dockedPanelMouseArea.mouseY).y)
        onReleased: if (headerItem._menuItem) headerItem._menuItem.released(mouse)
    }

    Binding {
        target: dockedPanelMouseArea
        property: 'enabled'
        value: !headerItem.menuOpen
    }
}
