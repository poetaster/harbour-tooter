import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0


SilicaGridView {
    id: gridView

    property bool isPortrait: true
    signal slideshowShow(int vIndex)
    signal slideshowIndexChanged(int vIndex)

    property var dockedPanelMouseArea
    readonly property real menuHeight: headerItem.implicitHeight
    readonly property var menuItem: headerItem._menuItem

    property Component menu

    onSlideshowIndexChanged: {
        navigateTo(vIndex)
    }

    header: Component { ListItem {
        width: parent.width
        contentHeight: 0
        menu: gridView.menu
    } }

    ListModel {
        id: listModel
        ListElement {
            icon: "image://theme/icon-m-home?"
            slug: "home"
            name: "Home"
            active: true
            unread: false
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

        onPressAndHold: if (isPortrait) headerItem.openMenu()
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
        target: dockedPanelMouseArea
        onPositionChanged: if (menuItem)
            menuItem._updatePosition(menuItem._contentColumn.mapFromItem(dockedPanelMouseArea, dockedPanelMouseArea.mouseX, dockedPanelMouseArea.mouseY).y)
        onReleased: if (menuItem) menuItem.released(mouse)
    }

    Binding {
        target: dockedPanelMouseArea
        property: 'enabled'
        value: !headerItem.menuOpen
    }
}
