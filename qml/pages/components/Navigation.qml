import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0


SilicaGridView {
    id: gridView

    property bool isPortrait: false
    signal slideshowShow(int vIndex)
    signal slideshowIndexChanged(int vIndex)

    onSlideshowIndexChanged: {
        navigateTo(vIndex)
    }

    ListModel {
        id: listModel
        ListElement {
            icon: "image://theme/icon-m-home"
            slug: "home"
            name: "Home"
            active: true
            unread: false
        }

        ListElement {
            icon: "image://theme/icon-m-alarm"
            slug: "notifications"
            name: "Notifications"
            active: false
        }

        ListElement {
            icon: "image://theme/icon-m-whereami"
            slug: "local"
            name: "Local"
            active: false
            unread: false
        }

        ListElement {
            icon: "image://theme/icon-m-website"
            slug: "federated"
            name: "Federated"
            active: false
            unread: false
        }

        ListElement {
            icon: "image://theme/icon-m-search"
            slug: "search"
            name: "Search"
            active: false
            unread: false
        }
    }
    model: listModel
    currentIndex: -1
    cellWidth: isPortrait ? gridView.width : gridView.width / model.count
    cellHeight: isPortrait ? gridView.height/model.count : gridView.height
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
            visible: !isPortrait && unread
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
            visible: isPortrait && unread
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

        OpacityRampEffect {
            sourceItem: label
            offset: 0.5
        }

        ColorOverlay {
            source: image
            color: (highlighted ? Theme.highlightColor : (model.active ? Theme.primaryColor : Theme.secondaryHighlightColor))
            anchors.fill: image
        }

        Image {
            id: image
            visible: false
            source: model.icon // +'?'+ (highlighted ? Theme.highlightColor : (model.active ? Theme.primaryColor : Theme.secondaryHighlightColor))
            sourceSize.width: Theme.iconSizeMedium
            sourceSize.height: Theme.iconSizeMedium
            anchors.centerIn: parent
        }

        Text {
            visible: false
            text: model.name
            font.pixelSize: Theme.fontSizeExtraSmall/2
            color: (highlighted
                    ? Theme.highlightColor
                    : (model.active ? Theme.primaryColor : Theme.secondaryHighlightColor))
            horizontalAlignment: Text.AlignHCenter
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
            }
        }

        Label {
            id: label
            visible: false
            color: (highlighted ? Theme.highlightColor : Theme.secondaryHighlightColor)
            text: {
                return model.name.toUpperCase();
            }
            font.pixelSize: Theme.fontSizeExtraSmall
            font.family: Theme.fontFamilyHeading
            width: parent.width
            horizontalAlignment : Text.AlignHCenter
            anchors.bottom: parent.bottom
        }

        onClicked: {
            slideshowShow(index)
            console.log(index)
            navigateTo(model.slug)
            effect.state = "right"
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
}
