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
    height: if (following === true || bot === true) {
                avatarImage.height + Theme.paddingLarge*2 + infoLbl.height + Theme.paddingLarge
            } else avatarImage.height + Theme.paddingLarge*2

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
            top: parent.top
            topMargin: Theme.paddingLarge
            left: avatarImage.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: profileTitle
            text: if (title === "") {
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
            id: profileDescription
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

    Row {
        id: infoLbl
        spacing: Theme.paddingLarge
        layoutDirection: Qt.RightToLeft
        height: Theme.iconSizeSmall + Theme.paddingSmall
        anchors {
            top: avatarImage.bottom
            topMargin: Theme.paddingLarge
            left: parent.left
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingLarge
        }

        Rectangle {
            id: followingBg
            visible: (following ? true : false)
            radius: Theme.paddingSmall
            color: Theme.secondaryHighlightColor
            width: followingLbl.width + 2*Theme.paddingLarge
            height: parent.height

            Label {
                id: followingLbl
                text: qsTr("Follows you")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: botBg
            visible: (bot ? true : false)
            radius: Theme.paddingSmall
            color: Theme.secondaryHighlightColor
            width: botLbl.width + 2*Theme.paddingLarge
            height: parent.height

            Label {
                id: botLbl
                text: qsTr("Bot")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
