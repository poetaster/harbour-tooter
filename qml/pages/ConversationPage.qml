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
    property int tootMaxChar: appWindow.instanceMaxChars
    property bool bot: false //otherwise ReferenceError ProfileHeader.qml
    property bool followed_by: false //otherwise ReferenceError ProfileHeader.qml
    property bool locked: false //otherwise ReferenceError ProfileHeader.qml
    property bool group: false //otherwise ReferenceError ProfileHeader.qml
    property string type: ""
    property string username: ""
    property string headerTitle: ""
    property string suggestedUser: ""
    property string status_id: ""
    property bool editMode: false
    property string editSpoilerText: ""
    property string status_url: ""
    property string status_uri: ""
    property string quoted_status_id: ""
    property string quoted_account_acct: ""
    property string quoted_account_avatar: ""
    property string quoted_account_display_name: ""
    property string quoted_content: ""
    property bool openReplyPanel: false  // Set to true to auto-open reply panel
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
        imageUploader.setUploadUrl(Logic.getActiveAccount().instance + "/api/v1/media")
        imageUploader.setFile(file)
        imageUploader.setMime(mime)
        imageUploader.setAuthorizationHeader(Logic.getActiveAccount().api_user_token)
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
            btnAddMedia.enabled = mediaModel.count < 4
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
        property string type: "conversation"
        property string mainStatusId: status_id  // The clicked toot that should not be truncated

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
            // Scroll to the clicked status after a brief delay to ensure layout is complete
            scrollTimer.restart()
        }

        Timer {
            id: scrollTimer
            interval: 50
            repeat: false
            onTriggered: {
                if (mdl) {
                    for (var i = 0; i < mdl.count; i++) {
                        if (mdl.get(i).status_id === status_id) {
                            console.log("Scrolling to status_id: " + status_id + " at index " + i)
                            myList.positionViewAtIndex(i, ListView.Center)
                            break
                        }
                    }
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

    // Quote preview when composing a quote post - styled like timeline quoted posts
    Rectangle {
        id: quotePreview
        visible: quoted_status_id.length > 0
        width: parent.width - Theme.horizontalPageMargin * 2
        height: visible ? quotePreviewColumn.implicitHeight + Theme.paddingMedium * 2 : 0
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        border.color: Theme.rgba(Theme.highlightColor, 0.4)
        border.width: 1
        radius: Theme.paddingSmall
        anchors {
            bottom: panel.open ? panel.top : hiddenPanel.top
            bottomMargin: Theme.paddingSmall
            horizontalCenter: parent.horizontalCenter
        }

        Column {
            id: quotePreviewColumn
            anchors {
                left: parent.left
                right: closeQuoteBtn.left
                top: parent.top
                margins: Theme.paddingMedium
            }
            spacing: Theme.paddingSmall

            // Quoted author row with avatar, display name and username
            Row {
                width: parent.width
                spacing: Theme.paddingSmall

                Image {
                    id: quotePreviewAvatar
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    source: quoted_account_avatar.length > 0 ? quoted_account_avatar : ""
                    visible: quoted_account_avatar.length > 0
                    asynchronous: true
                    smooth: true
                }

                Column {
                    width: parent.width - (quotePreviewAvatar.visible ? quotePreviewAvatar.width + Theme.paddingSmall : 0)
                    spacing: 0

                    Label {
                        text: quoted_account_display_name.length > 0 ? quoted_account_display_name : quoted_account_acct.split('@')[0]
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.bold: true
                        color: Theme.highlightColor
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }

                    Label {
                        text: {
                            var acct = quoted_account_acct
                            if (!appWindow.fullUsernames && acct.indexOf('@') > 0) {
                                acct = acct.split('@')[0]
                            }
                            return "@" + acct
                        }
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                }
            }

            // Quoted content
            Label {
                text: {
                    var content = quoted_content || ""
                    content = content.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
                    return content
                }
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                wrapMode: Text.Wrap
                maximumLineCount: 6
                truncationMode: TruncationMode.Elide
                width: parent.width
            }
        }

        IconButton {
            id: closeQuoteBtn
            icon.source: "image://theme/icon-s-clear-opaque-cross?" + Theme.highlightColor
            anchors {
                right: parent.right
                rightMargin: Theme.paddingSmall
                top: parent.top
                topMargin: Theme.paddingSmall
            }
            onClicked: {
                quoted_status_id = ""
                quoted_account_acct = ""
                quoted_account_avatar = ""
                quoted_account_display_name = ""
                quoted_content = ""
            }
        }
    }

    DockedPanel {
        id: panel
        width: parent.width
        height: progressBar.height + toot.height + (mediaModel.count ? uploadedImages.height : 0) + btnContentWarning.height + Theme.paddingMedium + (warningContent.visible ? warningContent.height : 0)
        dock: Dock.Bottom
        open: type === "new" || editMode || quoted_status_id.length > 0 || openReplyPanel  // Auto-open for new toots, edits, quotes, and replies

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
            color: Theme.primaryColor
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
            visible: mediaModel.count > 0
            width: parent.width
            anchors.top: btnContentWarning.bottom
            anchors.topMargin: mediaModel.count > 0 ? Theme.paddingSmall : 0
            height: mediaModel.count > 0 ? Theme.itemSizeExtraLarge : 0
            model: mediaModel
            cellWidth: uploadedImages.width / 4
            cellHeight: isPortrait ? cellWidth : Theme.itemSizeExtraLarge
            delegate: ListItem {
                id: myDelegate
                width: uploadedImages.cellWidth
                height: uploadedImages.cellHeight
                contentHeight: height

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: model.preview_url
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Image load error for: " + model.preview_url)
                        }
                    }
                }

                // ALT badge indicator
                Rectangle {
                    property bool hasAlt: model.description && model.description.length > 0
                    visible: true
                    color: hasAlt ? Theme.rgba(Theme.highlightBackgroundColor, 0.9) : Theme.rgba(Theme.errorColor, 0.8)
                    radius: Theme.paddingSmall / 2
                    width: altLabel.width + Theme.paddingSmall
                    height: altLabel.height + Theme.paddingSmall / 2
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: Theme.paddingSmall / 2
                    }
                    Label {
                        id: altLabel
                        text: parent.hasAlt ? "ALT" : "NO ALT"
                        font.pixelSize: Theme.fontSizeTiny
                        font.bold: true
                        color: parent.hasAlt ? Theme.primaryColor : Theme.lightPrimaryColor
                        anchors.centerIn: parent
                    }
                }

                onClicked: {
                    // Open full-size image viewer
                    pageStack.push(Qt.resolvedUrl("./components/MediaFullScreen.qml"), {
                        "previewURL": model.preview_url,
                        "mediaURL": model.url,
                        "type": model.type || "image",
                        "description": model.description || ''
                    })
                }

                menu: Component {
                    ContextMenu {
                        MenuItem {
                            text: qsTr("Edit Alt Text")
                            onClicked: {
                                var idx = index
                                var currentDesc = mediaModel.get(idx).description || ''
                                pageStack.push(altTextDialog, {
                                    altText: currentDesc,
                                    mediaIndex: idx
                                })
                            }
                        }
                        MenuItem {
                            text: qsTr("Remove")
                            onClicked: {
                                mediaModel.remove(index)
                            }
                        }
                    }
                }
            }
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1.0
                    duration: 200
                }
            }
            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0
                    duration: 150
                }
            }
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 200
                    easing.type: Easing.OutQuad
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
            id: btnAddMedia
            enabled: mediaModel.count < 4
            icon.source: "image://theme/icon-m-attach?" + ( pressed ? Theme.highlightColor : Theme.primaryColor )
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnContentWarning.right
                leftMargin: Theme.paddingSmall
            }
            onClicked: pageStack.push(mediaTypeDialog)
        }
        Component {
            id: musicPickerPage
            MusicPickerPage {
                onSelectedContentPropertiesChanged: {
                    var imagePath = selectedContentProperties.url
                    var mimeType = selectedContentProperties.mimeType
                    fileUpload(imagePath,mimeType)
                    /*
                    imageUploader.setUploadUrl(Logic.getActiveAccount().instance + "/api/v1/media")
                    imageUploader.setFile(imagePath)
                    imageUploader.setMime(mimeType)
                    imageUploader.setAuthorizationHeader(Logic.getActiveAccount().api_user_token)
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
                btnAddMedia.enabled = mediaModel.count < 4
            }
            onFailure: {
                uploadProgress.width = 0
                btnAddMedia.enabled = mediaModel.count < 4
                //console.log(status)
                //console.log(statusText)
            }
        }

        IconButton {
            id: btnPrivacy
            property int currentIndex: 0
            icon.source: {
                var icons = [
                    "image://theme/icon-m-region",     // public (globe)
                    "image://theme/icon-m-home",       // unlisted
                    "image://theme/icon-m-people",     // followers-only
                    "image://theme/icon-m-mail"        // direct
                ]
                return icons[currentIndex] + "?" + (pressed ? Theme.highlightColor : Theme.primaryColor)
            }
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnAddMedia.right
                leftMargin: Theme.paddingSmall
            }
            onClicked: pageStack.push(visibilityDialog)
        }

        // Language selector - just the language code as a clickable button
        BackgroundItem {
            id: btnLanguage
            property string selectedLanguage: Qt.locale().name.substring(0, 2)  // System language as default
            width: languageText.width + Theme.paddingMedium * 2
            height: btnPrivacy.height
            anchors {
                top: toot.bottom
                topMargin: -Theme.paddingSmall * 1.5
                left: btnPrivacy.right
                leftMargin: Theme.paddingSmall
            }
            onClicked: pageStack.push(languageDialog)

            Label {
                id: languageText
                text: btnLanguage.selectedLanguage.toUpperCase()
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors.centerIn: parent
            }
        }

        IconButton {
            id: btnSend
            icon.source: "image://theme/icon-m-send?" + (pressed ? Theme.highlightColor : Theme.primaryColor)
            enabled: (toot.text !== "" || mediaModel.count > 0) && toot.text.length < tootMaxChar && uploadProgress.width == 0 && ((Logic.getActiveAccount().type === 1 && type !== "reply") ? (mediaModel.count > 0) : true)
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

                var msg
                if (editMode) {
                    // Build media_attributes array with descriptions (alt-text)
                    var media_attributes = []
                    for (var j = 0; j < mediaModel.count; j++) {
                        var mediaItem = mediaModel.get(j)
                        media_attributes.push({
                            "id": mediaItem.id,
                            "description": mediaItem.description || ''
                        })
                    }

                    // Edit existing status with PUT
                    msg = {
                        "action": 'statuses/' + status_id,
                        "method": 'PUT',
                        "params": {
                            "status": toot.text,
                            "visibility": visibility[btnPrivacy.currentIndex],
                            "media_ids": media_ids,
                            "media_attributes": media_attributes
                        },
                        "conf": Logic.conf
                    }
                } else {
                    // Create new status with POST
                    msg = {
                        "action": 'statuses',
                        "method": 'POST',
                        "model": mdl,
                        "mode": "append",
                        "params": {
                            "status": toot.text,
                            "visibility": visibility[btnPrivacy.currentIndex],
                            "media_ids": media_ids
                        },
                        "conf": Logic.conf
                    }
                    if (status_id)
                        msg.params['in_reply_to_id'] = (status_id) + ""
                    if (quoted_status_id)
                        msg.params['quoted_status_id'] = quoted_status_id
                }

                if (warningContent.visible && warningContent.text.length > 0) {
                    msg.params['sensitive'] = 1
                    msg.params['spoiler_text'] = warningContent.text
                }

                // Add language if selected
                if (btnLanguage.selectedLanguage !== "") {
                    msg.params['language'] = btnLanguage.selectedLanguage
                }

                worker.sendMessage(msg)
                warningContent.text = ""
                toot.text = ""
                mediaModel.clear()
                btnLanguage.selectedLanguage = Qt.locale().name.substring(0, 2)
                sentBanner.showText(editMode ? qsTr("Toot edited!") : qsTr("Toot sent!"))
                if (editMode) {
                    pageStack.pop()
                }
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

        if (editMode && status_id) {
            // Fetch source text for editing
            Logic.api.get('statuses/' + status_id + '/source', [], function(data) {
                if (data && data.text) {
                    toot.text = data.text
                    toot.cursorPosition = toot.text.length
                }
                if (data && data.spoiler_text && data.spoiler_text.length > 0) {
                    warningContent.visible = true
                    warningContent.text = data.spoiler_text
                }
            })
            // Also fetch full status to get media attachments, visibility, and quote
            Logic.api.get('statuses/' + status_id, [], function(data) {
                console.log("Edit mode: fetched status data")
                if (data) {
                    // Set visibility
                    var visibilityMap = {"public": 0, "unlisted": 1, "private": 2, "direct": 3}
                    if (data.visibility && visibilityMap[data.visibility] !== undefined) {
                        btnPrivacy.currentIndex = visibilityMap[data.visibility]
                    }
                    // Load existing media attachments
                    if (data.media_attachments && data.media_attachments.length > 0) {
                        console.log("Edit mode: found " + data.media_attachments.length + " attachments")
                        for (var i = 0; i < data.media_attachments.length; i++) {
                            var attachment = data.media_attachments[i]
                            console.log("Attachment " + i + ": id=" + attachment.id + ", preview_url=" + attachment.preview_url)
                            mediaModel.append({
                                id: attachment.id,
                                type: attachment.type,
                                url: attachment.url,
                                preview_url: attachment.preview_url || attachment.url,
                                description: attachment.description || ''
                            })
                        }
                        console.log("Edit mode: mediaModel.count = " + mediaModel.count)
                    }
                    // Load quote post data if present (Mastodon 4.4+)
                    var validQuoteStates = ["accepted", "blocked_account", "blocked_domain", "muted_account"]
                    if (data.quote && data.quote.quoted_status && validQuoteStates.indexOf(data.quote.state) !== -1) {
                        var quoteData = data.quote.quoted_status
                        console.log("Edit mode: found quoted post " + quoteData.id)
                        quoted_status_id = quoteData.id
                        quoted_content = quoteData.content || ""
                        quoted_account_acct = quoteData.account ? quoteData.account.acct : ""
                        quoted_account_avatar = quoteData.account ? quoteData.account.avatar : ""
                        quoted_account_display_name = quoteData.account ? quoteData.account.display_name : ""
                    }
                }
            })
            return
        }

        if (mdl && mdl.count > 0) {
            var setIndex = 0
            switch (mdl.get(0).status_visibility) {
            case "unlisted":
                setIndex = 1
                break
            case "private":
                setIndex = 2
                break
            case "direct":
                btnPrivacy.enabled = false
                setIndex = 3
                break
            default:
                btnPrivacy.enabled = true
                setIndex = 0
            }
            btnPrivacy.currentIndex = setIndex

            // Set reply language to match the original toot's language
            if (mdl.get(0).status_language && mdl.get(0).status_language.length > 0) {
                btnLanguage.selectedLanguage = mdl.get(0).status_language
            }

            // console.log(JSON.stringify())

            worker.sendMessage({
                                   "action": 'statuses/' + mdl.get(0).status_id + '/context',
                                   "method": 'GET',
                                   "model": mdl,
                                   "params": { },
                                   "conf": Logic.conf
                               })
            // Fetch remote replies in background (Mastodon 4.5+, silently ignored if unsupported)
            worker.sendMessage({
                                   "action": 'statuses/' + mdl.get(0).status_id + '/fetch_remote_replies',
                                   "method": 'POST',
                                   "model": mdl,
                                   "params": {},
                                   "conf": Logic.conf
                               })
        } else if (status_id && status_id.length > 0) {
            // Model is empty but we have a status_id - fetch the status first
            console.log("Fetching status: " + status_id)
            worker.sendMessage({
                                   "action": 'statuses/' + status_id,
                                   "method": 'GET',
                                   "model": mdl,
                                   "mode": "append",
                                   "params": { },
                                   "conf": Logic.conf
                               })
            // Then fetch context
            worker.sendMessage({
                                   "action": 'statuses/' + status_id + '/context',
                                   "method": 'GET',
                                   "model": mdl,
                                   "params": { },
                                   "conf": Logic.conf
                               })
            // Fetch remote replies in background (Mastodon 4.5+, silently ignored if unsupported)
            worker.sendMessage({
                                   "action": 'statuses/' + status_id + '/fetch_remote_replies',
                                   "method": 'POST',
                                   "model": mdl,
                                   "params": {},
                                   "conf": Logic.conf
                               })
        }
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

    Component {
        id: altTextDialog
        Dialog {
            id: altDialog
            property string altText: ""
            property int mediaIndex: -1

            canAccept: true
            acceptDestination: conversationPage
            acceptDestinationAction: PageStackAction.Pop

            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                DialogHeader {
                    title: qsTr("Edit Alt Text")
                    acceptText: qsTr("Save")
                }

                TextArea {
                    id: altTextArea
                    width: parent.width
                    placeholderText: qsTr("Describe this media for visually impaired users")
                    text: altText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Alt text helps make content accessible to people who are blind or have low vision.")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                    wrapMode: Text.Wrap
                }
            }

            onAccepted: {
                if (mediaIndex >= 0 && mediaIndex < mediaModel.count) {
                    mediaModel.setProperty(mediaIndex, "description", altTextArea.text)
                }
            }
        }
    }

    Component {
        id: mediaTypeDialog
        Page {
            SilicaListView {
                anchors.fill: parent
                header: PageHeader {
                    title: qsTr("Add Media")
                }
                model: ListModel {
                    ListElement { name: "Image"; icon: "image://theme/icon-m-file-image"; mediaType: "image" }
                    ListElement { name: "Audio"; icon: "image://theme/icon-m-file-audio"; mediaType: "audio" }
                    ListElement { name: "Video"; icon: "image://theme/icon-m-file-video"; mediaType: "video" }
                }
                delegate: ListItem {
                    visible: model.mediaType !== "audio" || Logic.getActiveAccount().type !== 1
                    contentHeight: visible ? Theme.itemSizeMedium : 0
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        spacing: Theme.paddingMedium

                        Icon {
                            source: model.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: qsTr(model.name)
                            color: highlighted ? Theme.highlightColor : Theme.primaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    onClicked: {
                        btnAddMedia.enabled = false
                        if (model.mediaType === "image") {
                            pageStack.replace(imagePickerPage)
                        } else if (model.mediaType === "audio") {
                            pageStack.replace(musicPickerPage)
                        } else if (model.mediaType === "video") {
                            pageStack.replace(videoPickerPage)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: visibilityDialog
        Page {
            SilicaListView {
                anchors.fill: parent
                header: PageHeader {
                    title: qsTr("Post Visibility")
                }
                model: ListModel {
                    ListElement { name: "Public"; value: 0; icon: "image://theme/icon-m-region"; desc: "Visible to everyone" }
                    ListElement { name: "Unlisted"; value: 1; icon: "image://theme/icon-m-home"; desc: "Visible to everyone, but not in public timelines" }
                    ListElement { name: "Followers-only"; value: 2; icon: "image://theme/icon-m-people"; desc: "Only visible to followers" }
                    ListElement { name: "Direct"; value: 3; icon: "image://theme/icon-m-mail"; desc: "Only visible to mentioned users" }
                }
                delegate: ListItem {
                    contentHeight: Theme.itemSizeMedium
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        spacing: Theme.paddingMedium

                        Icon {
                            source: model.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.iconSizeMedium - Theme.paddingMedium - checkIcon.width

                            Label {
                                text: qsTr(model.name)
                                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            Label {
                                text: model.desc
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                                truncationMode: TruncationMode.Fade
                                width: parent.width
                            }
                        }

                        Icon {
                            id: checkIcon
                            source: "image://theme/icon-m-acknowledge"
                            visible: btnPrivacy.currentIndex === model.value
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    onClicked: {
                        btnPrivacy.currentIndex = model.value
                        pageStack.pop()
                    }
                }
            }
        }
    }

    Component {
        id: languageDialog
        Page {
            SilicaListView {
                anchors.fill: parent
                header: PageHeader {
                    title: qsTr("Post Language")
                }
                model: ListModel {
                    // Alphabetically sorted by native name
                    ListElement { name: "Bahasa Indonesia"; code: "id" }
                    ListElement { name: "Bahasa Melayu"; code: "ms" }
                    ListElement { name: "Bosanski"; code: "bs" }
                    ListElement { name: "Brezhoneg"; code: "br" }
                    ListElement { name: "Català"; code: "ca" }
                    ListElement { name: "Cymraeg"; code: "cy" }
                    ListElement { name: "Čeština"; code: "cs" }
                    ListElement { name: "Dansk"; code: "da" }
                    ListElement { name: "Deutsch"; code: "de" }
                    ListElement { name: "Eesti"; code: "et" }
                    ListElement { name: "English"; code: "en" }
                    ListElement { name: "Español"; code: "es" }
                    ListElement { name: "Euskara"; code: "eu" }
                    ListElement { name: "Français"; code: "fr" }
                    ListElement { name: "Gaeilge"; code: "ga" }
                    ListElement { name: "Galego"; code: "gl" }
                    ListElement { name: "Hrvatski"; code: "hr" }
                    ListElement { name: "Íslenska"; code: "is" }
                    ListElement { name: "Italiano"; code: "it" }
                    ListElement { name: "Latviešu"; code: "lv" }
                    ListElement { name: "Lietuvių"; code: "lt" }
                    ListElement { name: "Magyar"; code: "hu" }
                    ListElement { name: "Malti"; code: "mt" }
                    ListElement { name: "Nederlands"; code: "nl" }
                    ListElement { name: "Norsk bokmål"; code: "nb" }
                    ListElement { name: "Norsk nynorsk"; code: "nn" }
                    ListElement { name: "Occitan"; code: "oc" }
                    ListElement { name: "Polski"; code: "pl" }
                    ListElement { name: "Português"; code: "pt" }
                    ListElement { name: "Română"; code: "ro" }
                    ListElement { name: "Shqip"; code: "sq" }
                    ListElement { name: "Slovenčina"; code: "sk" }
                    ListElement { name: "Slovenščina"; code: "sl" }
                    ListElement { name: "Srpski"; code: "sr" }
                    ListElement { name: "Suomi"; code: "fi" }
                    ListElement { name: "Svenska"; code: "sv" }
                    ListElement { name: "Tiếng Việt"; code: "vi" }
                    ListElement { name: "Türkçe"; code: "tr" }
                    ListElement { name: "Ελληνικά"; code: "el" }
                    ListElement { name: "Беларуская"; code: "be" }
                    ListElement { name: "Български"; code: "bg" }
                    ListElement { name: "Македонски"; code: "mk" }
                    ListElement { name: "Русский"; code: "ru" }
                    ListElement { name: "Українська"; code: "uk" }
                    ListElement { name: "עברית"; code: "he" }
                    ListElement { name: "العربية"; code: "ar" }
                    ListElement { name: "فارسی"; code: "fa" }
                    ListElement { name: "हिन्दी"; code: "hi" }
                    ListElement { name: "ไทย"; code: "th" }
                    ListElement { name: "中文"; code: "zh" }
                    ListElement { name: "日本語"; code: "ja" }
                    ListElement { name: "한국어"; code: "ko" }
                }
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        spacing: Theme.paddingMedium

                        Label {
                            text: model.code.toUpperCase()
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.secondaryColor
                            width: Theme.itemSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: model.name
                            color: highlighted ? Theme.highlightColor : Theme.primaryColor
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.itemSizeSmall - checkIcon.width - Theme.paddingMedium * 2
                        }

                        Icon {
                            id: checkIcon
                            source: "image://theme/icon-m-acknowledge"
                            visible: btnLanguage.selectedLanguage === model.code
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    onClicked: {
                        btnLanguage.selectedLanguage = model.code
                        pageStack.pop()
                    }
                }
            }
        }
    }
}
