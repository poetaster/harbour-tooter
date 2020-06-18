import QtQuick 2.0
import Sailfish.Silica 1.0


DockedPanel {
    id: root
    dock: Dock.Top
    width: parent.width
    height: content.height

    Rectangle {
        id: content
        color: Theme.highlightBackgroundColor
        width: root.width
        height: infoLabel.height + 2 * Theme.paddingMedium

        Label {
            id: infoLabel
            text : ""
            font.family: Theme.fontFamilyHeading
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primaryColor
            wrapMode: Text.WrapAnywhere
            width: parent.width
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin*2
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.hide()
                autoClose.stop()
            }
        }
    }

    function showText(text) {
        infoLabel.text = text
        root.show()
        autoClose.start()
    }

    Timer {
        id: autoClose
        interval: 4500
        running: false
        onTriggered: {
            root.hide()
            stop()
        }
    }
}
