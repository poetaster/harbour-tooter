import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic

    // Link Preview Card
    Rectangle {
        id: linkPreview
        visible: {
            //if (model.type === "gap") return false
            //if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) return false
            // Require both URL and title to avoid showing empty card boxes
            return typeof model.card_url !== "undefined" && model.card_url.length > 0
                   && typeof model.card_title !== "undefined" && model.card_title.length > 0
        }
        width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
        // Dynamic height: max of image height or text content height
        height: visible ? Math.max(Theme.itemSizeLarge, linkPreviewText.implicitHeight) + Theme.paddingMedium * 2 : 0
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        radius: Theme.paddingSmall

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.openUrlExternally(model.card_url)
        }

        // Thumbnail (if available)
        Image {
            id: cardImage
            visible: typeof model.card_image !== "undefined" && model.card_image.length > 0
            width: visible ? Theme.itemSizeLarge : 0
            height: Theme.itemSizeLarge
            source: visible ? model.card_image : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            anchors {
                left: parent.left
                top: parent.top
                margins: Theme.paddingMedium
            }
            onStatusChanged: {
                if (status === Image.Error) visible = false
            }
        }

        Column {
            id: linkPreviewText
            anchors {
                left: cardImage.visible ? cardImage.right : parent.left
                right: parent.right
                top: parent.top
                leftMargin: cardImage.visible ? Theme.paddingMedium : Theme.paddingMedium
                rightMargin: Theme.paddingMedium
                topMargin: Theme.paddingMedium
            }
            spacing: Theme.paddingSmall / 2

            // Provider name
            Label {
                visible: typeof model.card_provider !== "undefined" && model.card_provider.length > 0
                text: model.card_provider || ""
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
                truncationMode: TruncationMode.Fade
                width: parent.width
            }

            // Title
            Label {
                text: typeof model.card_title !== "undefined" ? model.card_title : ""
                font.pixelSize: Theme.fontSizeExtraSmall
                font.bold: true
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                maximumLineCount: 2
                truncationMode: TruncationMode.Elide
                width: parent.width
            }

            // Description (truncated)
            Label {
                visible: typeof model.card_description !== "undefined" && model.card_description.length > 0
                text: model.card_description || ""
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
                maximumLineCount: 3
                truncationMode: TruncationMode.Elide
                width: parent.width
            }
        }
    }
