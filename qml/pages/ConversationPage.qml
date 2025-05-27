import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import harbour.tooterb.Uploader 1.0
import "../lib/API.js" as Logic
import "./components/"


Page {
    id: conversationPage

    property bool debug: false
    property ListModel suggestedModel
    property ListModel mdl
    property int tootMaxChar: 500
    property bool bot: false //otherwise ReferenceError ProfileHeader.qml
    property bool followed_by: false //otherwise ReferenceError ProfileHeader.qml
    property bool locked: false //otherwise ReferenceError ProfileHeader.qml
    property bool group: false //otherwise ReferenceError ProfileHeader.qml
    property string type
    property string username: ""
    property string headerTitle: ""
    property string suggestedUser: ""
    property string status_id: ""
    property string status_url: ""
    property string status_uri: ""
    property string status_link:
        if (status_url === "") {
            var test = status_uri.split("/")
            if (debug) {
                console.log(status_uri)
                console.log(JSON.stringify(test))
                console.log(JSON.stringify(test.length))
            }
            if (test.length === 8 && (test[7] === "activity")) {
                var urialt = status_uri.replace("activity", "")
                status_link = urialt
            }
            else status_link = status_uri
        } else status_link = status_url



    // This function is used by the upload Pickers
    function fileUpload(file,mime) {
        imageUploader.setUploadUrl(Logic.conf.instance + "/api/v1/media")
        imageUploader.setFile(file)
        imageUploader.setMime(mime)
        imageUploader.setAuthorizationHeader(Logic.conf.api_user_token)
        imageUploader.upload()
    }

    allowedOrientations: Orientation.All
    onSuggestedUserChanged: {
        //console.log(suggestedUser)
        suggestedModel = Qt.createQmlObject( 'import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject' )
        predictionList.visible = false
        if (suggestedUser.length > 0) {
            var msg = {
                "action": 'accounts/search',
                "method": 'GET',
                "model": suggestedModel,
                "mode": "append",
                "params": [{
                        "name": "q",
                        "data": suggestedUser
                    }],
                "conf": Logic.conf
            }
            worker.sendMessage(msg)
            predictionList.visible = true
        }
    }

    ListModel {
        id: mediaModel
        onCountChanged: {
            btnAddImage.enabled = mediaModel.count < 4
        }
    }

    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {
            //console.log(JSON.stringify(messageObject))
        }
    }

    SilicaListView {
        id: myList

        header: PageHeader {
            title: headerTitle // pageTitle pushed from MainPage.qml or VisualContainer.qml
        }
        clip: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: if (panel.open == true) {
                            panel.top
                        } else {
                            hiddenPanel.top
                        }
        model: mdl
        section {
            property: 'section'
            delegate: SectionHeader {
                height: Theme.itemSizeExtraSmall
                text: Format.formatDate(section, Formatter.DateMedium)
            }
        }
        delegate: VisualContainer {}
        onCountChanged: {
            if (mdl)
                for (var i = 0; i < mdl.count; i++) {
                    if (mdl.get(i).status_id === status_id) {
                        //console.log(mdl.get(i).status_id)
                        positionViewAtIndex(i, ListView.Center)
                    }
                }
        }

        PullDownMenu {
            id: pulleyConversation
            visible: type === "reply"

            MenuItem {
                text: qsTr("Open in Browser")
                onClicked: {
                    Qt.openUrlExternally(status_link)
                }
            }

            MenuItem {
                //: Use the translation of "Copy Link" for a shorter PullDownMenu label
                text: qsTr("Copy Link to Clipboard")
                onClicked: Clipboard.text = status_link
            }

            MenuItem {
                //: "Reply" will show the Toot text entry Panel. "Hide Reply" closes it. Alternative: Use "Close Reply"
                text: !panel.open ? qsTr("Reply") : qsTr("Hide Reply")
                visible: type == "reply"
                onClicked: !panel.open ? panel.open = true : panel.open = false
            }
        }
    }

    Rectangle {
        id: predictionList
        visible: false
        color: Theme.highlightDimmerColor
        height: parent.height - panel.height - (Theme.paddingLarge * 4.5)
        anchors {
            left: panel.left
            right: panel.right
            bottom: panel.open == true ? panel.top : hiddenPanel.top
        }

        SilicaListView {
            id: predictionResults
            rotation: 180 // shows best matching result on the bottom
            anchors.fill: parent
            model: suggestedModel
            clip: true
            quickScroll: false
            delegate: ItemUser {
                rotation: 180
                onClicked: {
                    var start = toot.cursorPosition
                    while (toot.text[start] !== "@" && start > 0) {
                        start--
                    }
                    textOperations.text = toot.text
                    textOperations.cursorPosition = toot.cursorPosition
                    textOperations.moveCursorSelection(start - 1, TextInput.SelectWords)
                    toot.text = textOperations.text.substring(0, textOperations.selectionStart)
                            + ' @'
                            + model.account_acct
                            + ' '
                            + textOperations.text.substring(textOperations.selectionEnd).trim()
                    toot.cursorPosition = toot.text.indexOf('@' + model.account_acct)
                }
            }
            onCountChanged: {
                if (count > 0) {
                    positionViewAtBeginning(suggestedModel.count - 1, ListView.Beginning)
                }
            }

            VerticalScrollDecorator {}
        }
    }

    DockedPanel {
        id: panel
        width: parent.width
        height: progressBar.height + toot.height + (mediaModel.count ? uploadedImages.height : 0) + btnContentWarning.height + Theme.paddingMedium + (warningContent.visible ? warningContent.height : 0)
        dock: Dock.Bottom
        open: true

        Rectangle {
            id: progressBarBg
            width: parent.width
            height: progressBar.height
            color: Theme.highlightBackgroundColor
            opacity: 0.2
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }

        Rectangle {
            id: progressBar
            width: toot.text.length ? panel.width * (toot.text.length / tootMaxChar) : 0
            height: Theme.itemSizeSmall * 0.05
            color: Theme.highlightBackgroundColor
            opacity: 0.7
            anchors {
                left: parent.left
                top: parent.top
            }
        }

        TextField {
            id: warningContent
            visible: false
            height: visible ? implicitHeight : 0
            autoScrollEnabled: true
            labelVisible: false
            font.pixelSize: Theme.fontSizeSmall
            //: placeholderText in Toot content warning panel
            placeholderText: qsTr("Write your warning here")
            placeholderColor: palette.highlightColor
            color: palette.highlightColor
            horizontalAlignment: Text.AlignLeft
            EnterKey.onClicked: {}
            anchors {
                top: parent.top
                topMargin: Theme.paddingMedium
                left: parent.left
                right: parent.right
            }
        }

        TextInput {
            id: textOperations
            visible: false
        }

        TextArea {
            id: toot
            autoScrollEnabled: true
            labelVisible: false
            //: placeholderText in Toot text panel
            placeholderText: qsTr("What's on your mind?")
            font.pixelSize: Theme.fontSizeSmall
            text: username !== "" && (username.charAt(0) === '@'
                                         || username.charAt(
                                             0) === '#') ? username + ' ' : ''
            height: if (type !== "reply") {
                        isPortrait ? Math.max(conversationPage.height / 3, Math.min(conversationPage.height * 0.65, implicitHeight)) : Math.max(conversationPage.height / 2, Math.min(conversationPage.height * 0.65, implicitHeight))
                    }
                    else {
                        isPortrait ? Math.max(conversationPage.height / 4, Math.min(conversationPage.height * 0.65, implicitHeight)) : Math.max(conversationPage.height / 2.5, Math.min(conversationPage.height * 0.65, implicitHeight))
                    }
            horizontalAlignment: Text.AlignLeft
            anchors {
                top: warningContent.bottom
                topMargin: Theme.paddingMedium
                left: parent.left
                right: parent.right
                rightMargin: Theme.paddingLarge * 2
            }
            EnterKey.onClicked: {}
            onTextChanged: {
                textOperations.text = toot.text
                textOperations.cursorPosition = toot.cursorPosition
                textOperations.selectWord()
                textOperations.select(
                            textOperations.selectionStart ? textOperations.selectionStart - 1 : 0,
                            textOperations.selectionEnd)
                //console.log(toot.text.length)
                suggestedUser = ""
                if (textOperations.selectedText.charAt(0) === "@") {
                    suggestedUser = textOperations.selectedText.trim().substring(1)
                }
            }
        }

        IconButton {
            id: btnSmileys

            property string selection

            opacity: 0.7
            icon {
                source: "../../qml/images/icon-m-emoji.svg?"
                color: Theme.secondaryColor
                width: Theme.iconSizeSmallPlus
                fillMode: Image.PreserveAspectFit
            }
            anchors {
                top: warningContent.bottom
                bottom: bottom.top
                right: parent.right
                rightMargin: Theme.paddingSmall
            }
            onSelectionChanged: {
                //console.log(selection)
            }
            onClicked: pageStack.push(emojiDialog)
        }

        SilicaGridView {
            id: uploadedImages
            width: parent.width
            anchors.top: bottom.toot
            anchors.bottom: parent.bottom
            height: mediaModel.count ? Theme.itemSizeExtraLarge : 0
            model: mediaModel
            cellWidth: uploadedImages.width / 4
            cellHeight: isPortrait ? cellWidth : Theme.itemSizeExtraLarge
            delegate: BackgroundItem {
                id: myDelegate
                width: uploadedImages.cellWidth
                height: uploadedImages.cellHeight
                RemorseItem {
                    id: remorse
                    cancelText: ""
                }

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: model.preview_url
                }
                onClicked: {
                    var idx = index
                    //console.log(idx)
                    //mediaModel.remove(idx)
                    remorse.execute(myDelegate, "", function () {
                        mediaModel.remove(idx)
                    })
                }
            }
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1.0
                    duration: 800
                }
            }
            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0
                    duration: 800
                }
            }
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 800
                    easing.type: Easing.InOutBack
                }
            }
        }

        IconButton {
            id: btnContentWarning
            icon.source: "image://theme/icon-s-warning?" + ( pressed ? Theme.highlightColor : (warningContent.visible ? Theme.secondaryHighlightColor : Theme.primaryColor) )
            onClicked: warningContent.visible = !warningContent.visible
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: parent.left
                leftMargin: Theme.paddingMedium
            }
        }

        IconButton {
            id: btnAddImage
            enabled: mediaModel.count < 4
            icon.source: "image://theme/icon-m-file-image?" + ( pressed ? Theme.highlightColor : (warningContent.visible ? Theme.secondaryHighlightColor : Theme.primaryColor) )
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnContentWarning.right
                leftMargin: Theme.paddingSmall
            }
            onClicked: {
                btnAddImage.enabled = false
                var once = true
                pageStack.push(imagePickerPage)
            }
        }

        IconButton {
            id: btnAddMusic
            enabled: mediaModel.count < 4
            icon.source: "image://theme/icon-m-file-audio?" + ( pressed ? Theme.highlightColor : (warningContent.visible ? Theme.secondaryHighlightColor : Theme.primaryColor) )
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnAddImage.right
                leftMargin: Theme.paddingSmall
            }
            onClicked: {
                btnAddMusic.enabled = false
                var once = true
                pageStack.push(musicPickerPage)
            }
        }
        IconButton {
            id: btnAddVideo
            enabled: mediaModel.count < 4
            icon.source: "image://theme/icon-m-file-video?" + ( pressed ? Theme.highlightColor : (warningContent.visible ? Theme.secondaryHighlightColor : Theme.primaryColor) )
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnAddMusic.right
                leftMargin: Theme.paddingSmall
            }
            onClicked: {
                btnAddVideo.enabled = false
                var once = true
                pageStack.push(videoPickerPage)
            }
        }
        Component {
            id: musicPickerPage
            MusicPickerPage {
                onSelectedContentPropertiesChanged: {
                    var imagePath = selectedContentProperties.url
                    var mimeType = selectedContentProperties.mimeType
                    fileUpload(imagePath,mimeType)
                    /*
                    imageUploader.setUploadUrl(Logic.conf.instance + "/api/v1/media")
                    imageUploader.setFile(imagePath)
                    imageUploader.setMime(mimeType)
                    imageUploader.setAuthorizationHeader(Logic.conf.api_user_token)
                    imageUploader.upload()
                    */
                }
            }
        }
        Component {
            id: imagePickerPage
            ImagePickerPage {
                onSelectedContentPropertiesChanged: {
                    var imagePath = selectedContentProperties.url
                    var mimeType = selectedContentProperties.mimeType
                    fileUpload(imagePath,mimeType)
                }
            }
        }
        Component {
            id: videoPickerPage
            VideoPickerPage {
                onSelectedContentPropertiesChanged: {
                    var imagePath = selectedContentProperties.url
                    var mimeType = selectedContentProperties.mimeType
                    fileUpload(imagePath,mimeType)
                }
            }
        }
        ImageUploader {
            id: imageUploader
            onProgressChanged: {
                // console.log("progress " + progress)
                uploadProgress.width = parent.width * progress
            }
            onSuccess: {
                uploadProgress.width = 0
                //console.log(replyData)
                mediaModel.append(JSON.parse(replyData))
            }
            onFailure: {
                uploadProgress.width = 0
                btnAddImage.enabled = true
                btnAddMusic.enabled = true
                btnAddVideo.enabled = true
                //console.log(status)
                //console.log(statusText)
            }
        }

        ComboBox {
            id: privacy
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Public")
                }
                MenuItem {
                    text: qsTr("Unlisted")
                }
                MenuItem {
                    text: qsTr("Followers-only")
                }
                MenuItem {
                    text: qsTr("Direct")
                }
            }
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnAddVideo.right
                right: btnSend.left
            }
        }

        IconButton {
            id: btnSend
            icon.source: "image://theme/icon-m-send?" + (pressed ? Theme.highlightColor : Theme.primaryColor)
            enabled: (toot.text !== "" || mediaModel.count > 0) && toot.text.length < tootMaxChar && uploadProgress.width == 0 && (Logic.conf.type === 1 ? (mediaModel.count > 0) : true)
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                right: parent.right
                rightMargin: Theme.paddingSmall
            }
            onClicked: {
                var visibility = ["public", "unlisted", "private", "direct"]
                var media_ids = []
                for (var k = 0; k < mediaModel.count; k++) {
                    // console.log(mediaModel.get(k).id)
                    media_ids.push(mediaModel.get(k).id)
                }
                var msg = {
                    "action": 'statuses',
                    "method": 'POST',
                    "model": mdl,
                    "mode": "append",
                    "params": {
                        "status": toot.text,
                        "visibility": visibility[privacy.currentIndex],
                        "media_ids": media_ids
                    },
                    "conf": Logic.conf
                }
                if (status_id)
                    msg.params['in_reply_to_id'] = (status_id) + ""

                if (warningContent.visible && warningContent.text.length > 0) {
                    msg.params['sensitive'] = 1
                    msg.params['spoiler_text'] = warningContent.text
                }

                worker.sendMessage(msg)
                warningContent.text = ""
                toot.text = ""
                mediaModel.clear()
                sentBanner.showText(qsTr("Toot sent!"))
            }
        }

        Rectangle {
            id: uploadProgress
            color: Theme.highlightBackgroundColor
            height: Theme.itemSizeSmall * 0.05
            anchors {
                bottom: parent.bottom
                left: parent.left
            }
        }
    }

    Component.onCompleted: {
        toot.cursorPosition = toot.text.length
        if (mdl.count > 0) {
            var setIndex = 0
            switch (mdl.get(0).status_visibility) {
            case "unlisted":
                setIndex = 1
                break
            case "private":
                setIndex = 2
                break
            case "direct":
                privacy.enabled = false
                setIndex = 3
                break
            default:
                privacy.enabled = true
                setIndex = 0
            }
            privacy.currentIndex = setIndex
        }

        // console.log(JSON.stringify())

        worker.sendMessage({
                               "action": 'statuses/' + mdl.get(0).status_id + '/context',
                               "method": 'GET',
                               "model": mdl,
                               "params": { },
                               "conf": Logic.conf
                           })
    }

    BackgroundItem {
        id: hiddenPanel
        visible: !panel.open
        height: Theme.paddingLarge * 0.7
        width: parent.width
        opacity: enabled ? 0.6 : 0.0
        Behavior on opacity { FadeAnimator { duration: 400 } }
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
        }

        MouseArea {
            anchors.fill: parent
            onClicked: panel.open = !panel.open
        }

        Rectangle {
            id: hiddenPanelBackground
            width: parent.width
            height: parent.height
            color: Theme.highlightBackgroundColor
            opacity: 0.4
            anchors.fill: parent
        }

        Rectangle {
            id: progressBarBackground
            width: parent.width
            height: progressBarHiddenPanel.height
            color: Theme.highlightBackgroundColor
            opacity: 0.2
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
        }

        Rectangle {
            id: progressBarHiddenPanel
            width: toot.text.length ? panel.width * (toot.text.length / tootMaxChar) : 0
            height: Theme.itemSizeSmall * 0.05
            color: Theme.highlightBackgroundColor
            opacity: 0.7
            anchors {
                top: parent.top
                left: parent.left
            }
        }

    }

    EmojiSelect {
        id: emojiDialog
    }

    InfoBanner {
        id: sentBanner
    }
}
