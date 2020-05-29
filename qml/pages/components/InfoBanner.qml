import QtQuick 2.0
import Sailfish.Silica 1.0


DockedPanel {
    id: root
    z: 100
    width: parent.width
    height: content.height
    dock: Dock.Top

    Rectangle {
        id: content
        width: root.width
        height: infoLabel.height + 5*Theme.paddingMedium
        //anchors.topMargin: 20
        color: Theme.highlightBackgroundColor
        opacity: 1.0

        Label {
            id: infoLabel
            text : ""
            color: Theme.primaryColor
            font.family: Theme.fontFamilyHeading
            font.pixelSize: Theme.fontSizeMedium
            //font.weight: Font.Bold
            width: parent.width
            wrapMode: Text.WrapAnywhere
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
