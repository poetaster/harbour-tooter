import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0


Item {
    id: myImage

    property string type : ""
    property string previewURL: ""
    property string mediaURL: ""

    Rectangle {
        opacity: 0.2
        color: Theme.highlightDimmerColor
        anchors.fill: parent
    }

    Image {
        source: "image://theme/icon-m-image"
        anchors.centerIn: parent
    }

    Rectangle {
        id: progressRec
        width: 0
        height: Theme.paddingSmall
        color: Theme.highlightBackgroundColor
        anchors.bottom: parent.bottom
    }

    Image {
        id: img
        asynchronous: true
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        source: previewURL
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        onProgressChanged: {
            if (progress != 1)
                progressRec.width = parent.width * progress
            else {
                progressRec.width = 0;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pageStack.push(Qt.resolvedUrl("./MediaFullScreen.qml"), {
                                   "previewURL": previewURL,
                                   "mediaURL": mediaURL,
                                   "type": type
                               })
            }
        }

        Image {
            id: videoIcon
            visible: type === "video" || type === "gifv"
            source: "image://theme/icon-l-play"
            anchors.centerIn: parent
        }

        BusyIndicator {
            id: mediaLoader
            size: BusyIndicatorSize.Large
            running: img.status !== Image.Ready
            opacity: img.status === Image.Ready ? 0.0 : 1.0
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            id: mediaWarning
            color: Theme.highlightDimmerColor
            visible: typeof status_sensitive != 'undefined' && status_sensitive ? true : false
            anchors.fill: parent

            Image {
                source: "image://theme/icon-l-attention?"+Theme.highlightColor
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: parent.visible = false
            }
        }
    }
}
