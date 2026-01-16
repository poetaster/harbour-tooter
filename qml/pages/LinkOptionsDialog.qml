import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: linkOptionsPage
    property string linkUrl: ""

    Component.onCompleted: {
        console.log("LinkOptionsDialog: loaded with url = " + linkUrl)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: "Open Link"
            }

            Label {
                text: linkUrl
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
            }

            Button {
                text: "Reader Mode"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("Reader mode clicked")
                    pageStack.push(Qt.resolvedUrl("ReaderPage.qml"), {
                        articleUrl: linkUrl
                    })
                }
            }

            Button {
                text: "Open in Browser"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Qt.openUrlExternally(linkUrl)
                    pageStack.pop()
                }
            }

            Button {
                text: "Copy Link"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Clipboard.text = linkUrl
                    pageStack.pop()
                }
            }
        }
    }
}
