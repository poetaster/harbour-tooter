import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6


FullscreenContentPage {
    id: mediaPage

    // Single item properties (backward compatibility)
    property string type: ""
    property string previewURL: ""
    property string mediaURL: ""
    property string url: ""
    property string description: ""

    // Gallery properties
    property var mediaModel: null
    property int startIndex: 0

    property bool debug: false
    property bool isGalleryMode: mediaModel !== null && mediaModel.count > 1
    property bool isImageType: type !== 'gifv' && type !== 'video' && type !== 'audio'

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        if (debug) {
            console.log("MediaFullScreen type: " + type)
            console.log("Gallery mode: " + isGalleryMode)
            if (mediaModel) console.log("Media count: " + mediaModel.count)
        }

        if (isGalleryMode && isImageType) {
            // Gallery mode for multiple images
            galleryView.currentIndex = startIndex
            galleryView.visible = true
        } else if (isImageType) {
            // Single image mode
            imagePreview.source = mediaURL
            imageFlickable.visible = true
        } else if (type === 'audio') {
            video.source = url
            videoFlickable.visible = true
            playerIcon.visible = true
            playerProgress.visible = true
            video.play()
            hideTimer.start()
        } else {
            // Video/gifv
            video.source = mediaURL
            video.fillMode = VideoOutput.PreserveAspectFit
            videoFlickable.visible = true
            playerIcon.visible = true
            playerProgress.visible = true
            video.play()
            hideTimer.start()
        }
    }

    // Gallery view for multiple images
    SlideshowView {
        id: galleryView
        visible: false
        anchors.fill: parent
        itemWidth: width
        itemHeight: height
        clip: true

        model: mediaModel

        onCurrentIndexChanged: {
            // Hide description panel when switching images
            descriptionPanel.visible = false
        }

        delegate: SilicaFlickable {
            id: galleryFlickable
            width: galleryView.itemWidth
            height: galleryView.itemHeight
            contentWidth: galleryImageContainer.width
            contentHeight: galleryImageContainer.height

            onHeightChanged: if (galleryImage.status === Image.Ready) {
                galleryImage.fitToScreen()
            }

            Item {
                id: galleryImageContainer
                width: Math.max(galleryImage.width * galleryImage.scale, galleryFlickable.width)
                height: Math.max(galleryImage.height * galleryImage.scale, galleryFlickable.height)

                Image {
                    id: galleryImage

                    property real prevScale: 1.0

                    function fitToScreen() {
                        scale = Math.min(galleryFlickable.width / width, galleryFlickable.height / height, galleryFlickable.width, galleryFlickable.height)
                        galleryPinchArea.minScale = scale
                        prevScale = scale
                    }

                    fillMode: Image.PreserveAspectFit
                    cache: true
                    asynchronous: true
                    sourceSize.width: mediaPage.width
                    smooth: true
                    anchors.centerIn: parent
                    source: model.url

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            fitToScreen()
                            galleryLoadedAnimation.start()
                        }
                    }

                    NumberAnimation {
                        id: galleryLoadedAnimation
                        target: galleryImage
                        property: "opacity"
                        duration: 250
                        from: 0; to: 1
                        easing.type: Easing.InOutQuad
                    }

                    onScaleChanged: {
                        if ((width * scale) > galleryFlickable.width) {
                            var xoff = (galleryFlickable.width / 2 + galleryFlickable.contentX) * scale / prevScale;
                            galleryFlickable.contentX = xoff - galleryFlickable.width / 2
                        }
                        if ((height * scale) > galleryFlickable.height) {
                            var yoff = (galleryFlickable.height / 2 + galleryFlickable.contentY) * scale / prevScale;
                            galleryFlickable.contentY = yoff - galleryFlickable.height / 2
                        }
                        prevScale = scale
                    }
                }

                // Loading indicator for gallery image
                BusyIndicator {
                    running: galleryImage.status === Image.Loading
                    size: BusyIndicatorSize.Large
                    anchors.centerIn: parent
                }

                // Error text for gallery image
                Text {
                    visible: galleryImage.status === Image.Error
                    text: qsTr("Error loading")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                    anchors.centerIn: parent
                }
            }

            PinchArea {
                id: galleryPinchArea

                property real minScale: 1.0
                property real maxScale: 3.0

                anchors.fill: parent
                enabled: galleryImage.status === Image.Ready
                pinch.target: galleryImage
                pinch.minimumScale: minScale * 0.5
                pinch.maximumScale: maxScale * 1.5

                onPinchFinished: {
                    galleryFlickable.returnToBounds()
                    if (galleryImage.scale < galleryPinchArea.minScale) {
                        galleryBounceBackAnimation.to = galleryPinchArea.minScale
                        galleryBounceBackAnimation.start()
                    }
                    else if (galleryImage.scale > galleryPinchArea.maxScale) {
                        galleryBounceBackAnimation.to = galleryPinchArea.maxScale
                        galleryBounceBackAnimation.start()
                    }
                }

                NumberAnimation {
                    id: galleryBounceBackAnimation
                    target: galleryImage
                    duration: 250
                    property: "scale"
                    from: galleryImage.scale
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: overlayIcons.active = !overlayIcons.active
                }
            }

            VerticalScrollDecorator { flickable: galleryFlickable }
        }
    }

    // Page indicator for gallery
    Row {
        id: pageIndicator
        visible: galleryView.visible && mediaModel && mediaModel.count > 1
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Theme.paddingLarge + Theme.iconSizeMedium
        }
        spacing: Theme.paddingSmall

        Repeater {
            model: mediaModel ? mediaModel.count : 0
            Rectangle {
                width: Theme.paddingSmall
                height: Theme.paddingSmall
                radius: width / 2
                color: index === galleryView.currentIndex ? Theme.highlightColor : Theme.primaryColor
                opacity: index === galleryView.currentIndex ? 1.0 : 0.4
            }
        }
    }

    SilicaFlickable {
        id: videoFlickable
        visible: false
        contentWidth: imageContainer.width
        contentHeight: imageContainer.height
        anchors.fill: parent

        Image {
            id: videoPreview
            fillMode: Image.PreserveAspectFit
            anchors.fill: parent
            source: previewURL
        }

        Video {
            id: video
            anchors.fill: parent
            onErrorStringChanged: function() {
                videoError.visible = true
            }
            onStatusChanged: {
                if(debug) console.log(status)
                switch (status) {
                case MediaPlayer.Loading:
                    if(debug) console.log("loading")
                    return;
                case MediaPlayer.EndOfMedia:
                    if (debug) console.log("EndOfMedia")
                    return;
                }
            }
            onPlaybackStateChanged: {
               if (debug) console.log(playbackState)
                switch (playbackState) {
                case MediaPlayer.PlayingState:
                    playerIcon.icon.source = "image://theme/icon-m-pause"
                    return;
                case MediaPlayer.PausedState:
                    playerIcon.icon.source = "image://theme/icon-m-play"
                    return;
                case MediaPlayer.StoppedState:
                    playerIcon.icon.source = "image://theme/icon-m-reload"
                    return;
                }
            }
            onPositionChanged: function() {
                //console.log(duration)
                //console.log(bufferProgress)
                //console.log(position)
                if (status !== MediaPlayer.Loading){
                    playerProgress.indeterminate = false
                    playerProgress.maximumValue = duration
                    playerProgress.minimumValue = 0
                    playerProgress.value = position
                }
            }
            onStopped: function() {
                if (type == 'gifv') {
                    video.play()
                } else {
                    video.stop()
                    overlayIcons.active = true
                    hideTimer.stop()
                }
            }


            MouseArea {
                anchors.fill: parent
                onClicked: function() {
                    if (video.playbackState === MediaPlayer.PlayingState) {
                        video.pause()
                        overlayIcons.active = true
                        hideTimer.stop()
                    } else {
                        video.play()
                        hideTimer.start()
                    }
                }
            }

            Rectangle {
                visible: videoError.text != ""
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: Theme.highlightDimmerColor
                height: videoError.height + 2*Theme.paddingMedium
                width: parent.width

                Label {
                    id: videoError
                    visible: false
                    text: video.errorString
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                    wrapMode: Text.Wrap
                    width: parent.width - 2*Theme.paddingMedium
                    height: contentHeight
                    anchors.centerIn: parent
                }
            }
        }
    }


    SilicaFlickable {
        id: imageFlickable
        visible: false
        contentWidth: imageContainer.width
        contentHeight: imageContainer.height
        anchors.fill: parent
        onHeightChanged: if (imagePreview.status === Image.Ready) {
                             imagePreview.fitToScreen()
                         }

        Item {
            id: imageContainer
            width: Math.max(imagePreview.width * imagePreview.scale, imageFlickable.width)
            height: Math.max(imagePreview.height * imagePreview.scale, imageFlickable.height)

            Image {
                id: imagePreview

                property real prevScale

                function fitToScreen() {
                    scale = Math.min(imageFlickable.width / width, imageFlickable.height / height, imageFlickable.width, imageFlickable.height)
                    pinchArea.minScale = scale
                    prevScale = scale
                }

                fillMode: Image.PreserveAspectFit
                cache: true
                asynchronous: true
                sourceSize.width: mediaPage.width
                smooth: true
                anchors.centerIn: parent
                onStatusChanged: {
                    if (status == Image.Ready) {
                        fitToScreen()
                        loadedAnimation.start()
                    }
                }

                NumberAnimation {
                    id: loadedAnimation
                    target: imagePreview
                    property: "opacity"
                    duration: 250
                    from: 0; to: 1
                    easing.type: Easing.InOutQuad
                }

                onScaleChanged: {
                    if ((width * scale) > imageFlickable.width) {
                        var xoff = (imageFlickable.width / 2 + imageFlickable.contentX) * scale / prevScale;
                        imageFlickable.contentX = xoff - imageFlickable.width / 2
                    }
                    if ((height * scale) > imageFlickable.height) {
                        var yoff = (imageFlickable.height / 2 + imageFlickable.contentY) * scale / prevScale;
                        imageFlickable.contentY = yoff - imageFlickable.height / 2
                    }
                    prevScale = scale
                }
            }
        }

        PinchArea {
            id: pinchArea

            property real minScale: 1.0
            property real maxScale: 3.0

            anchors.fill: parent
            enabled: imagePreview.status === Image.Ready
            pinch.target: imagePreview
            pinch.minimumScale: minScale * 0.5 // This is to create "bounce back effect"
            pinch.maximumScale: maxScale * 1.5 // when over zoomed}

            onPinchFinished: {
                imageFlickable.returnToBounds()
                if (imagePreview.scale < pinchArea.minScale) {
                    bounceBackAnimation.to = pinchArea.minScale
                    bounceBackAnimation.start()
                }
                else if (imagePreview.scale > pinchArea.maxScale) {
                    bounceBackAnimation.to = pinchArea.maxScale
                    bounceBackAnimation.start()
                }
            }

            NumberAnimation {
                id: bounceBackAnimation
                target: imagePreview
                duration: 250
                property: "scale"
                from: imagePreview.scale
            }

            MouseArea {
                anchors.fill: parent
                onClicked: overlayIcons.active = !overlayIcons.active
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        sourceComponent: {
            switch (imagePreview.status) {
            case Image.Loading:
                return loadingIndicator
            case Image.Error:
                return failedLoading
            default:
                return undefined
            }
        }

        Component {
            id: loadingIndicator
            Item {
                width: mediaPage.width
                height: childrenRect.height

                ProgressCircle {
                    id: imageLoadingIndicator
                    progressValue: imagePreview.progress
                    progressColor: inAlternateCycle ? Theme.highlightColor : Theme.highlightDimmerColor
                    backgroundColor: inAlternateCycle ? Theme.highlightDimmerColor : Theme.highlightColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component {
        id: failedLoading
        Text {
            text: qsTr("Error loading")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
        }
    }

    Item {
        id: overlayIcons

        property bool active: true

        // Get current media info based on mode
        property string currentMediaURL: {
            if (galleryView.visible && mediaModel && mediaModel.count > galleryView.currentIndex) {
                return mediaModel.get(galleryView.currentIndex).url || ""
            }
            return mediaURL
        }
        property string currentDescription: {
            if (galleryView.visible && mediaModel && mediaModel.count > galleryView.currentIndex) {
                return mediaModel.get(galleryView.currentIndex).description || ""
            }
            return description
        }

        enabled: active
        anchors.fill: parent
        opacity: active ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}

        IconButton {
            y: Theme.paddingLarge
            icon.source: "image://theme/icon-m-dismiss"
            onClicked: pageStack.pop()
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
        }

        IconButton {
            id: mediaDlBtn
            icon.source: "image://theme/icon-m-cloud-download"
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: parent.bottom
                bottomMargin: Theme.horizontalPageMargin
            }
            onClicked: {
                var urlToDownload = overlayIcons.currentMediaURL
                var filename = urlToDownload.split("/")
                FileDownloader.downloadFile(urlToDownload, filename[filename.length-1])
            }
        }

        // ALT button to show/hide description
        Rectangle {
            id: altButton
            visible: overlayIcons.currentDescription.length > 0
            color: descriptionPanel.visible ? Theme.highlightColor : Theme.highlightDimmerColor
            opacity: 0.9
            width: altButtonLabel.width + Theme.paddingMedium * 2
            height: altButtonLabel.height + Theme.paddingSmall * 2
            radius: Theme.paddingSmall / 2
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                bottom: parent.bottom
                bottomMargin: Theme.horizontalPageMargin
            }

            Label {
                id: altButtonLabel
                text: "ALT"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: descriptionPanel.visible ? Theme.highlightDimmerColor : Theme.highlightColor
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: descriptionPanel.visible = !descriptionPanel.visible
            }
        }

        // Alt-text description panel (hidden by default)
        Rectangle {
            id: descriptionPanel
            visible: false
            color: Theme.highlightDimmerColor
            opacity: 0.9
            height: Math.min(descriptionText.paintedHeight + Theme.paddingMedium * 2, parent.height * 0.4)
            anchors {
                left: parent.left
                right: parent.right
                bottom: altButton.top
                bottomMargin: Theme.paddingMedium
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }
            radius: Theme.paddingSmall

            Flickable {
                anchors.fill: parent
                anchors.margins: Theme.paddingMedium
                contentHeight: descriptionText.paintedHeight
                clip: true

                Label {
                    id: descriptionText
                    text: overlayIcons.currentDescription
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }

        IconButton {
            id: playerIcon
            visible: false
            icon.source: "image://theme/icon-m-play"
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: Theme.horizontalPageMargin
                bottomMargin: Theme.horizontalPageMargin
            }
            onClicked: function() {
                if (video.playbackState === MediaPlayer.PlayingState) {
                    video.pause()
                    hideTimer.stop()
                } else {
                    video.play()
                    hideTimer.start()
                }
            }
        }

        ProgressBar {
            id: playerProgress
            visible: false
            indeterminate: true
            width: 400
            anchors {
                verticalCenter: playerIcon.verticalCenter
                left: playerIcon.right
                right: parent.right
                rightMargin: Theme.horizontalPageMargin + Theme.iconSizeMedium
                bottomMargin: Theme.horizontalPageMargin
            }
        }

        Timer {
            id: hideTimer
            running: false
            interval: 2000
            onTriggered: {
                overlayIcons.active = !overlayIcons.active
            }
        }
    }

    VerticalScrollDecorator { flickable: imageFlickable }
}
