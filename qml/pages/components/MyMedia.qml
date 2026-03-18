import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6


Item {
    id: myMedia

    property string type : ""
    property string previewURL: ""
    property string mediaURL: ""
    property string url: ""
    property string description: ""

    // Gallery support: pass full media list and index
    property var mediaModel: null
    property int mediaIndex: 0

    Rectangle {
        opacity: 0.4
        color: Theme.highlightDimmerColor
        anchors.fill: parent
    }

    Image {
        visible: type == 'image'
        opacity: img.status === Image.Ready ? 0.0 : 1.0
        Behavior on opacity { FadeAnimator {} }
        source: "image://theme/icon-m-image?"
        anchors.centerIn: parent
    }

    Image {
        visible: type == 'video' || type == "gifv"
        opacity: img.status === Image.Ready ? 0.0 : 1.0
        Behavior on opacity { FadeAnimator {} }
        source: "image://theme/icon-m-file-video?"
        anchors.centerIn: parent
    }

    /*Text {
        anchors{
            topMargin: 10
        }
        id: audioUrl
        visible: type == 'audio'
        text: "<a href='" + url + "'>" + 'Audio file' + '</a>'
        font.pixelSize: Theme.fontSizeLarge
    }*/


    MediaItem {
        id: audioContent
        visible: type == 'audio'
        opacity: img.status === Image.Ready ? 0.0 : 1.0
        Behavior on opacity { FadeAnimator {} }
        mimeType: 'audio/mp3'
        url: mediaURL
        mediaUrl: mediaURL
        //source: "image://theme/icon-m-file-audio?"
        anchors.centerIn: parent
        /*MouseArea {
            anchors.fill: parent
            onClicked: {
                pageStack.push(Qt.resolvedUrl("./MediaItem.qml"), {
                                   "url": url,
                                   "type": type,
                                   "mimeType": type
                               })
            }
        } */
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
        visible: type != 'audio'
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
            visible: type != 'audio'
            onClicked: {
                pageStack.push(Qt.resolvedUrl("./MediaFullScreen.qml"), {
                                   "previewURL": previewURL,
                                   "mediaURL": mediaURL,
                                   "type": type,
                                   "description": description,
                                   "mediaModel": mediaModel,
                                   "startIndex": mediaIndex
                               })
            }
        }

        // ALT text badge
        Rectangle {
            id: altBadge
            visible: description.length > 0
            color: Theme.highlightDimmerColor
            opacity: 0.9
            width: altLabel.width + Theme.paddingSmall * 2
            height: altLabel.height + Theme.paddingSmall
            radius: Theme.paddingSmall / 2
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: Theme.paddingSmall
            }

            Label {
                id: altLabel
                text: "ALT"
                font.pixelSize: Theme.fontSizeTiny
                font.bold: true
                color: Theme.highlightColor
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    altTooltip.visible = !altTooltip.visible
                }
            }
        }

        // ALT text tooltip
        Rectangle {
            id: altTooltip
            visible: false
            color: Theme.highlightDimmerColor
            opacity: 0.95
            width: parent.width - Theme.paddingMedium * 2
            height: altTooltipText.paintedHeight + Theme.paddingMedium * 2
            radius: Theme.paddingSmall
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: altBadge.top
                bottomMargin: Theme.paddingSmall
            }

            Label {
                id: altTooltipText
                text: description
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.paddingMedium * 2
                anchors {
                    centerIn: parent
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    altTooltip.visible = false
                }
            }
        }

        Image {
            id: videoIcon
            visible: type === "video" || type === "gifv"
            source: "image://theme/icon-l-play?"
            anchors.centerIn: parent
        }

        BusyIndicator {
            id: mediaLoader
            visible: type != 'audio'
            size: BusyIndicatorSize.Large
            running: img.status !== Image.Ready
            opacity: img.status === Image.Ready ? 0.0 : 1.0
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
        }

        Rectangle {
            id: mediaWarning
            color: Theme.highlightDimmerColor
            visible: typeof status_sensitive != "undefined" && status_sensitive ? true : false
            Image {
                source: "image://theme/icon-l-attention?"+Theme.highlightColor
                anchors.centerIn: parent
            }
            anchors.fill: parent
            MouseArea {
                anchors.fill: parent
                onClicked: parent.visible = false
            }
        }
        /*IconButton {
            id: mediaDlBtn
            icon.source: "image://theme/icon-m-cloud-download"
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: parent.bottom
                bottomMargin: Theme.horizontalPageMargin
            }
            onClicked: {
                var filename = url.split("/")
                FileDownloader.downloadFile(url, filename[filename.length-1])
            }
        }*/
    }
}
