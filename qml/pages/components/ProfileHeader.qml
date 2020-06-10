import QtQuick 2.0
import Sailfish.Silica 1.0


Item {
    id: profileHeader

    property int value: 0
    property string title: ""
    property string description: ""
    property string image: ""
    property string bg: ""

    width: parent.width
    height: avatarImage.height + Theme.paddingLarge*2

    Rectangle {
        id: bgImage
        opacity: 0.2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.highlightBackgroundColor }
            GradientStop { position: 1.0; color: Theme.highlightBackgroundColor }
        }
        anchors.fill: parent

        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: bg
            opacity: 0.8
            anchors.fill: parent
        }
    }

    Image {
        id: avatarImage
        asynchronous: true
        source:
            if (avatarImage.status === Image.Error)
                source = "../../images/icon-l-profile.svg?" + (pressed
                                                               ? Theme.highlightColor
                                                               : Theme.primaryColor)
            else image
        width: description === "" ? Theme.iconSizeMedium : Theme.iconSizeLarge
        height: width
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            top: parent.top
            topMargin: Theme.paddingLarge
        }

        Button {
            id: imageButton
            opacity: 0
            width: Theme.iconSizeExtraLarge * 1.2
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            onClicked: {
                pageStack.push(Qt.resolvedUrl("ProfileImage.qml"), {
                                   "image": image
                               })
            }
        }
    }

    Column {
        anchors {
            left: avatarImage.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: ttl
            text:
                if (title === "") {
                    description.split('@')[0]
                }
                else title
            font.pixelSize: Theme.fontSizeLarge
            font.family: Theme.fontFamilyHeading
            color: Theme.highlightColor
            truncationMode: TruncationMode.Fade
            width: parent.width
            height: contentHeight
            horizontalAlignment: Text.AlignRight
        }

        Label {
            text: "@"+description
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamilyHeading
            color: Theme.secondaryHighlightColor
            truncationMode: TruncationMode.Fade
            width: parent.width
            height: description === "" ? 0 : contentHeight
            horizontalAlignment: Text.AlignRight
        }
    }

}
