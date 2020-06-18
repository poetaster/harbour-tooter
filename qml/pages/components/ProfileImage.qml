import QtQuick 2.0
import Sailfish.Silica 1.0

FullscreenContentPage {
    id: profileImage

    property string image: ""

    allowedOrientations: Orientation.All

    Image {
        source: image
        fillMode: Image.PreserveAspectFit
        anchors.fill: parent
    }

    IconButton {
        icon.source: "image://theme/icon-m-dismiss"
        anchors {
            top: profileImage.top
            topMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        onClicked: pageStack.pop()
    }
}
