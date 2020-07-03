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
    height: isPortrait ? (avatarImage.height + Theme.paddingLarge*3 + infoLbl.height) : (avatarImage.height + Theme.paddingLarge*2.5 + infoLbl.height)

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
            anchors.fill: parent
        }
    }

    Image {
        id: avatarImage
        asynchronous: true
        source: if (avatarImage.status === Image.Error)
                    source = "../../images/icon-l-profile.svg?" + Theme.primaryColor
                else image
        width: isPortrait ? Theme.iconSizeLarge : Theme.iconSizeExtraLarge
        height: width
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            top: parent.top
            topMargin: Theme.paddingLarge * 1.5
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
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: profileTitle
            text: title ? title : description.split('@')[0]
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
            height: contentHeight
            horizontalAlignment: Text.AlignRight
        }
    }

    Row {
        id: infoLbl
        spacing: Theme.paddingLarge
        layoutDirection: Qt.RightToLeft
        height: followed_by || locked || bot || group ? Theme.iconSizeSmall + Theme.paddingSmall : 0
        anchors {
            top: avatarImage.bottom
            topMargin: isPortrait ? Theme.paddingMedium : 0
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }

        Rectangle {
            id: groupBg
            visible: (group ? true : false)
            radius: Theme.paddingSmall
            color: Theme.secondaryHighlightColor
            width: groupLbl.width + 2*Theme.paddingLarge
            height: parent.height

            Label {
                id: groupLbl
                text: qsTr("Group")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: followingBg
            visible: (followed_by ? true : false)
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
            id: lockedBg
            visible: (locked ? true : false)
            radius: Theme.paddingSmall
            color: Theme.secondaryHighlightColor
            width: lockedImg.width + 2*Theme.paddingLarge
            height: parent.height

            HighlightImage {
                id: lockedImg
                source: "image://theme/icon-s-secure?"
                width: Theme.fontSizeExtraSmall
                height: width
                color: Theme.primaryColor
                anchors.horizontalCenter: lockedBg.horizontalCenter
                anchors.verticalCenter: lockedBg.verticalCenter
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
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
