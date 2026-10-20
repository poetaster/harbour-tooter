import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic


BackgroundItem {
    id: delegate

    property bool debug: true
    property bool conversationPage:false
    property bool expanded: false
    property int charLimit: 700

    // Cache processed content to avoid regex on every press state change
    // Compute base content (truncated if needed) once, then derive styled versions
    property string baseDisplayContent: {
        var displayContent = content
        // Truncate if long post and not expanded (not for notifications)
        // In conversation view, don't truncate the main clicked toot
        var isMainConversationToot = (typeof myList.type !== "undefined"
                                      && myList.type === "conversation" &&
                                      typeof myList.mainStatusId !== "undefined"
                                      && model.status_id === myList.mainStatusId)
        if (isLongPost && !expanded &&
                !isMainConversationToot &&
                !(myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog"))) {
            displayContent = truncateContent(content, charLimit) + "..."
        }
        return displayContent
    }

    // Pre-compute both color variants - regex only runs when content changes, not on press
    property bool isNotificationCompact: myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")
    property string processedContent: isNotificationCompact ? baseDisplayContent :
        baseDisplayContent.replace(/<a /g, '<a style="text-decoration: none; color:' + Theme.highlightColor + ';" ')
    property string processedContentPressed: isNotificationCompact ? baseDisplayContent :
        baseDisplayContent.replace(/<a /g, '<a style="text-decoration: none; color:' + Theme.secondaryColor + ';" ')
    /*
     * A number of elements are only loaded if the tootdata contains the type
     * Speed up loading of any given toot and reduce memory footprint
      */

    Component.onCompleted: {
        logModelItems(model)
        if ( Logic.conf['conMen']  ) {
            tootMenu.source = "TootActionMenu.qml"
        } else {
            tootMenu.source = "TootActionRow.qml"

        }
        if ( checkForQuotes() ) quotedPost.source = "QuotedPost.qml"
        if ( checkForLinkPreviews() ) linkPreview.source = "LinkPreviewCard.qml"
        if ( checkForPolls() ) pollContainer.source = "PollContainer.qml"

    }

    function checkForPolls() {
        // Parse all poll data from JSON string
        return typeof model.poll_json !== "undefined" && model.poll_json ? model.poll_json : ''

    }

    function checkForLinkPreviews() {
        var hasLinkPreview = typeof model.card_url !== "undefined" && model.card_url.length > 0
        var hastPreviewTitle = typeof model.card_title !== "undefined" && model.card_title.length > 0
        return hasLinkPreview && hastPreviewTitle
    }

    function checkForQuotes() {
            var hasQuoteId = typeof model.quote_id !== "undefined" && model.quote_id.length > 0
            if (!hasQuoteId) return false
            var hasContent = typeof model.quote_content !== "undefined" && model.quote_content.length > 0
            var hasAuthor = typeof model.quote_account_acct !== "undefined" && model.quote_account_acct.length > 0
            return hasContent || hasAuthor
        }


    function logModelItems(model) {
            for (var i = 0; i < model.count; i++) {
                var item = model.get(i);
                if  (debug) console.log("Item at index " + i + ": ", item);
            }
    }
    // Helper function to strip HTML and get text length
    function getTextLength(html) {
        if (!html) return 0
        return html.replace(/<[^>]*>/g, '').length
    }

    function favourite(){
        var status = typeof model.status_favourited !== "undefined" && model.status_favourited
        worker.sendMessage({
                               "conf"   : Logic.conf,
                               "params" : [],
                               "method" : "POST",
                               "bgAction": true,
                               "action" : "statuses/"+model.status_id+"/" + (status ? "unfavourite" : "favourite")
                           })
        model.status_favourites_count = !status ? model.status_favourites_count+1 : (model.status_favourites_count > 0 ? model.status_favourites_count-1 : model.status_favourites_count);
        model.status_favourited = !model.status_favourited
    }

    function boost(){
        var status = typeof model.status_reblogged !== "undefined" && model.status_reblogged
        worker.sendMessage({
                               "conf"   : Logic.conf,
                               "params" : [],
                               "method" : "POST",
                               "bgAction": true,
                               "action" : "statuses/"+model.status_id+"/" + (status ? "unreblog" : "reblog")
                           })
        model.status_reblogs_count = !status ? model.status_reblogs_count+1 : (model.status_reblogs_count > 0 ? model.status_reblogs_count-1 : model.status_reblogs_count);
        model.status_reblogged = !model.status_reblogged
    }

    function reply() {
        var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject');
        if (typeof mdl !== "undefined")
            m.append(mdl.get(index))

        // Build mentions string: author + all mentioned users, excluding self
        var activeAccount = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
        var myUsername = activeAccount && activeAccount.userInfo ? activeAccount.userInfo.account_username : ""
        var mentions = []
        var seen = {}

        // Add the author first (unless it's us)
        if (model.account_acct && model.account_acct !== myUsername) {
            mentions.push("@" + model.account_acct)
            seen[model.account_acct.toLowerCase()] = true
        }

        // Add all mentioned users from the toot
        if (typeof model.status_mentions !== "undefined" && model.status_mentions.length > 0) {
            var mentionList = model.status_mentions.split(',')
            for (var i = 0; i < mentionList.length; i++) {
                var acct = mentionList[i].trim()
                if (acct && acct !== myUsername && !seen[acct.toLowerCase()]) {
                    mentions.push("@" + acct)
                    seen[acct.toLowerCase()] = true
                }
            }
        }

        if (debug) console.log("convesation from mnureply")
        pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
            headerTitle: qsTr("Reply"),
            "status_id": model.status_id,
            "status_url": model.status_url,
            "username": mentions.join(' '),
            mdl: m,
            type: "reply",
            openReplyPanel: true
        })
    }

    function quote(){
        if (debug) console.log("link from mnuQuote")
        pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                           headerTitle: qsTr("Quote"),
                           quoted_status_id: model.status_id,
                           quoted_account_acct: model.account_acct,
                           quoted_account_avatar: model.account_avatar,
                           quoted_account_display_name: model.account_display_name,
                           quoted_content: model.content,
                           type: "new"
                       })

    }
    function bookmark(){
        var status = typeof model.status_bookmarked !== "undefined" && model.status_bookmarked
        worker.sendMessage({
                               "conf"   : Logic.conf,
                               "params" : [],
                               "method" : "POST",
                               "bgAction": true,
                               "action" : "statuses/"+model.status_id+"/" + (status ? "unbookmark" : "bookmark")
                           })
        model.status_bookmarked = !model.status_bookmarked

    }
    function tootdelete(){
        remorseDelete.execute(delegate, qsTr("Deleting"), function() {
            worker.sendMessage({
                                   "conf": Logic.conf,
                                   "method": "DELETE",
                                   "action": "statuses/" + model.status_id
                               })
            mdl.remove(index)
        })

    }

    // Helper function to truncate HTML content
    function truncateContent(html, limit) {
        if (!html) return ''
        var text = html.replace(/<[^>]*>/g, '')
        if (text.length <= limit) return html

        // Find truncation point
        var truncateAt = limit
        var lastSpace = text.lastIndexOf(' ', limit)
        if (lastSpace > limit - 100) truncateAt = lastSpace

        // Count characters while preserving HTML
        var charCount = 0
        var inTag = false
        var result = ''
        for (var i = 0; i < html.length && charCount < truncateAt; i++) {
            var c = html.charAt(i)
            if (c === '<') inTag = true
            if (!inTag) charCount++
            result += c
            if (c === '>') inTag = false
        }
        // Close any open tags roughly (simplified)
        return result
    }

    property bool isLongPost: getTextLength(content) > charLimit

    // Shared empty model to avoid creating new ListModel objects for toots without attachments
    property ListModel emptyAttachmentsModel: ListModel {}

    signal send (string notice)
    signal navigateTo(string link)

    RemorseItem { id: remorseDelete }

    // Gap item UI - "Load more" button for timeline gaps
    // I think we can retire this?
    Item {
        id: gapLoader
        visible: model.type === "gap"
        width: parent.width
        height: visible ? Theme.itemSizeLarge : 0

        Rectangle {
            anchors.fill: parent
            color: Theme.highlightDimmerColor
            opacity: 0.3
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.paddingMedium

            BusyIndicator {
                id: gapBusy
                size: BusyIndicatorSize.Small
                running: model.gap_loading === true
                visible: running
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: model.gap_loading === true ? qsTr("Loading...") : qsTr("Load more")
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
            }

            Image {
                visible: model.gap_loading !== true
                source: "image://theme/icon-m-down"
                width: Theme.iconSizeSmall
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: model.gap_loading !== true
            onClicked: {
                if  (debug) console.log("Gap clicked at index " + index)
                myList.loadGap(index)
            }
        }
    }
    // This is a hack which will go away when all the loaders are finished?
    height:  {
        var commonheight =  tootMenu.height + miniHeader.height
        commonheight += (typeof attachments !== "undefined" && attachments.count ? media.height + Theme.paddingLarge + Theme.paddingMedium: Theme.paddingLarge)
        commonheight += lblContent.height + (isLongPost ? showMoreLabel.height : 0)
        commonheight += (pollContainer.visible ? pollContainer.childrenRect.height + Theme.paddingMedium : 0)
        commonheight += (linkPreview.visible ? linkPreview.height + Theme.paddingMedium : 0)
        commonheight += (quotedPost.visible ? quotedPost.height + Theme.paddingMedium : 0)
        commonheight += Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0)
        commonheight += (iconDirectMsg.visible ? iconDirectMsg.height : 0)
        return commonheight
    }
        /*
        if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                mnu.height + miniHeader.height + Theme.paddingLarge + lblContent.height + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0)
            } else {
                 mnu.height + miniHeader.height + (typeof attachments !== "undefined" && attachments.count ? media.height + Theme.paddingLarge + Theme.paddingMedium: Theme.paddingLarge) + lblContent.height + (isLongPost ? showMoreLabel.height : 0) + (pollContainer.visible ? pollContainer.childrenRect.height + Theme.paddingMedium : 0) + (linkPreview.visible ? linkPreview.height + Theme.paddingMedium : 0) + (quotedPost.visible ? quotedPost.height + Theme.paddingMedium : 0) + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0) + (iconDirectMsg.visible ? iconDirectMsg.height : 0)
             }
             */

    // Background for Direct Messages in Notification View
    Rectangle {
        id: bgDirect
        x: 0
        y: 0
        visible: model.type !== "gap" && model.status_visibility === "direct"
        width: parent.width
        height: parent.height
        opacity: 0.3
        gradient: Gradient {
            GradientStop { position: -1.5; color: "transparent" }
            GradientStop { position: 0.6; color: Theme.highlightBackgroundColor }
        }
    }
   // Element showing reblog, favourite, follow status on top of Toot
    MiniStatus {
        id: miniStatus
        anchors {
            top: parent.top
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            topMargin: Theme.paddingMedium

        }
    }
    // Stacked avatars for grouped notifications (v2 API)
    // I don't like them, so there not in the mix at the moment
/*
    Row {
        id: stackedAvatars
        visible: model.type !== "gap" && typeof model.notifications_count !== "undefined" && model.notifications_count > 1 && typeof model.grouped_account_count !== "undefined" && model.grouped_account_count > 1
        spacing: -Theme.paddingSmall * 1.5  // Negative spacing for overlap
        anchors {
            top: miniStatus.visible ? miniStatus.bottom : parent.top
            topMargin: miniStatus.visible ? Theme.paddingMedium : Theme.paddingLarge
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
        }

        Image {
            visible: typeof model.grouped_account_avatar_0 !== "undefined"
            width: Theme.iconSizeSmall
            height: width
            source: typeof model.grouped_account_avatar_0 !== "undefined" ? model.grouped_account_avatar_0 : ""
            asynchronous: true
            smooth: true
            cache: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            z: 3
        }
        Image {
            visible: typeof model.grouped_account_avatar_1 !== "undefined" && model.grouped_account_count >= 2
            width: Theme.iconSizeSmall
            height: width
            source: typeof model.grouped_account_avatar_1 !== "undefined" ? model.grouped_account_avatar_1 : ""
            asynchronous: true
            smooth: true
            cache: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            z: 2
        }
        Image {
            visible: typeof model.grouped_account_avatar_2 !== "undefined" && model.grouped_account_count >= 3
            width: Theme.iconSizeSmall
            height: width
            source: typeof model.grouped_account_avatar_2 !== "undefined" ? model.grouped_account_avatar_2 : ""
            asynchronous: true
            smooth: true
            cache: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            z: 1
        }
    }
*/

    // Account avatar (hidden when showing stacked avatars or for gap items)
    Image {
        id: avatar
        visible: model.type !== "gap" //&& !stackedAvatars.visible
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        asynchronous: true
        smooth: true
        cache: true
        source: account_avatar
        width: Theme.iconSizeMedium
        height: width
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        anchors {
            top: miniStatus.visible ? miniStatus.bottom : parent.top
            topMargin: miniStatus.visible ? Theme.paddingMedium : Theme.paddingLarge
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
        }
        onStatusChanged: {
            if (avatar.status === Image.Error)
                source = "../../images/icon-m-profile.svg?" + Theme.primaryColor
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../ProfilePage.qml"), {
                                   "display_name": model.account_display_name,
                                   "username": model.account_acct,
                                   "user_id": model.account_id,
                                   "profileImage": model.account_avatar,
                                   "profileBackground": model.account_header,
                                   "note": model.account_note,
                                   "url": model.account_url,
                                   "followers_count": model.account_followers_count,
                                   "following_count": model.account_following_count,
                                   "statuses_count": model.account_statuses_count,
                                   "locked": model.account_locked,
                                   "bot": model.account_bot,
                                   "group": model.account_group
                               } )
            }
        }

        // Avatar dimmer for facourite and reblog notifications
        Rectangle {
            visible: myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )
            opacity: 0.4
            color: Theme.highlightDimmerColor
            anchors.fill: avatar
        }

        Icon {
            id: iconDirectMsg
            visible: status_visibility === "direct"
            width: Theme.iconSizeMedium
            height: width
            source: "image://theme/icon-m-mail?" + Theme.primaryColor
            color: Theme.primaryColor
            anchors {
                horizontalCenter: avatar.horizontalCenter
                top: avatar.bottom
                topMargin: Theme.paddingMedium
                left: avatar.left
            }
        }

        Rectangle {
            id: bgReblogAvatar
            color: Theme.secondaryColor
            width: Theme.iconSizeSmall
            height: width
            visible: typeof status_reblog !== "undefined" && status_reblog
            anchors {
                bottom: parent.bottom
                bottomMargin: -width/3
                left: parent.left
                leftMargin: -width/3
            }

            Image {
                id: reblogAvatar
                asynchronous: true
                smooth: true
                cache: true
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }
                source: typeof reblog_account_avatar !== "undefined" ? reblog_account_avatar : ''
                visible: typeof status_reblog !== "undefined" && status_reblog
                width: Theme.iconSizeSmall
                height: width
                sourceSize.width: width * 2
                sourceSize.height: height * 2
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../ProfilePage.qml"), {
                                       "display_name": model.reblog_account_display_name,
                                       "username": model.reblog_account_acct,
                                       "user_id": model.reblog_account_id,
                                       "profileImage": model.reblog_account_avatar,
                                       "profileBackground": model.account_header,
                                       "note": model.reblog_account_note,
                                       "url": model.reblog_account_url,
                                       "followers_count": model.reblog_account_followers_count,
                                       "following_count": model.reblog_account_following_count,
                                       "statuses_count": model.reblog_account_statuses_count,
                                       "locked": model.reblog_account_locked,
                                       "bot": model.reblog_account_bot,
                                       "group": model.reblog_account_group
                                   } )
                }
            }
        }
    }

    // Display name, username, date of Toot
    MiniHeader {
        id: miniHeader
        visible: model.type !== "gap"
        anchors {
            top:  avatar.top//stackedAvatars.visible ? stackedAvatars.top : avatar.top
            left: avatar.right// stackedAvatars.visible ? stackedAvatars.right : avatar.right
            right: parent.right
            bottomMargin: Theme.paddingLarge
        }
    }

    // Toot content
    Label  {
        id: lblContent
        visible: model.type !== "gap" && model.type !== "follow"
        text: pressed ? processedContentPressed : processedContent
        textFormat: myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" ) ? Text.StyledText : Text.RichText
        font.pixelSize: Theme.fontSizeSmall * appWindow.fontScale
        wrapMode: Text.Wrap
        truncationMode: TruncationMode.Elide
        color: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                   (pressed ? Theme.secondaryHighlightColor : (!highlight ? Theme.secondaryColor : Theme.secondaryHighlightColor))
               } else (pressed ? Theme.highlightColor : (!highlight ? Theme.primaryColor : Theme.secondaryColor))
        linkColor: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                       Theme.secondaryHighlightColor
                   } else (pressed ? Theme.secondaryColor : Theme.highlightColor)
        height: if (model.type === "follow") {
                    Theme.paddingLarge
                } else if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                    Math.min( implicitHeight, Theme.itemSizeExtraLarge * 1.5 )
                } else content.length ? ( contentWarningLabel.paintedHeight > paintedHeight ? contentWarningLabel.paintedHeight : paintedHeight ) : 0
        anchors {
            left: miniHeader.left
            leftMargin: Theme.paddingMedium
            right: miniHeader.right
            rightMargin: Theme.horizontalPageMargin + Theme.paddingMedium
            top: miniHeader.bottom
            topMargin: Theme.paddingLarge
            bottomMargin: Theme.paddingLarge
        }
        onLinkActivated: {
            if (debug) console.log("VisualContainer link activated: " + link)

            // Use the URL parser to detect Mastodon resource types
            var parsed = Logic.parseMastodonUrl(link)
            if (debug) console.log(parsed.statusId)
            if (debug) console.log(conversationPage.status_id)
            // For recognized Mastodon URLs (tag, profile, status), delegate to MainPage
            if (parsed.type === "status"){
                if (conversationPage.status_id === parsed.statusId) return
                var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject');
                if (typeof mdl !== "undefined")
                m.append(mdl.get(index))
                pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                               headerTitle: qsTr("Conversation"),
                               "status_id": status_id,
                               "status_url": status_url,
                               "status_uri": status_uri,
                               "username": '@'+account_acct,
                               mdl: m,
                               type: "reply"
                           })
            } else if (parsed.type !== "unknown") {
                pageStack.pop(pageStack.find(function(page) {
                    var check = page.isFirstPage === true
                    if (check)
                        page.onLinkActivated(link)
                    return check
                }))
            } else {
                // Unknown URL - open externally
                Qt.openUrlExternally(link)
            }
        }

        // Content warning cover for Toots
        Rectangle {
            id: contentWarningBg
            color: Theme.highlightDimmerColor
            visible: {
                if (status_spoiler_text !== undefined && status_spoiler_text.length > 0) {
                    return true
                }
                return false
            }
            anchors.fill: parent

            Label {
                id: contentWarningLabel
                text: status_spoiler_text !== undefined ? status_spoiler_text : ""
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                truncationMode: TruncationMode.Fade
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                anchors {
                    topMargin: Theme.paddingSmall
                    left: parent.left
                    leftMargin: Theme.paddingMedium
                    centerIn: parent
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                    bottomMargin: Theme.paddingSmall
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: parent.visible = false
            }
        }
    }

    // Show more / Show less label for long posts (not for main toot in conversation view)
    Label {
        id: showMoreLabel
        visible: {
            if (model.type === "gap") return false
            if (!isLongPost) return false
            if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) return false
            // Hide for main toot in conversation view
            if (myList.type === "conversation" && typeof myList.mainStatusId !== "undefined" && model.status_id === myList.mainStatusId) return false
            return true
        }
        text: expanded ? qsTr("Show less") : qsTr("Show more")
        font.pixelSize: Theme.fontSizeSmall * appWindow.fontScale
        color: Theme.highlightColor
        anchors {
            left: lblContent.left
            top: lblContent.bottom
            topMargin: Theme.paddingSmall
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                expanded = !expanded
            }
        }
    }

    // Poll display
    Loader {
        id:pollContainer
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom
            topMargin: Theme.paddingMedium
        }
    }

    // Displays media in Toots
    MediaBlock {
        id: media
        visible: typeof attachments !== "undefined"
        model: typeof attachments !== "undefined" ? attachments : emptyAttachmentsModel
        height: Theme.itemSizeExtraLarge
        anchors {
            left: lblContent.left
            leftMargin: isPortrait ? 0 : Theme.itemSizeSmall
            right: lblContent.right
            rightMargin: isPortrait ? 0 : Theme.itemSizeLarge * 1.2
            top: pollContainer.visible ? pollContainer.bottom : (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom)
            topMargin: Theme.paddingMedium
            bottomMargin: Theme.paddingLarge
        }
    }

    // Link Preview Card
    Loader {
        id: linkPreview
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: {
                // refactor this
                (typeof attachments !== "undefined" && attachments.count) ? media.bottom : (pollContainer.visible ? pollContainer.bottom : (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom))
            }
            topMargin: Theme.paddingMedium
        }

    }

    // Quoted Post Display - styled like a mini-toot
    Loader {
        id: quotedPost
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: {
                // refactor this
                linkPreview.visible ? linkPreview.bottom : ((typeof attachments !== "undefined" && attachments.count) ? media.bottom : (pollContainer.visible ? pollContainer.bottom : (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom)))
            }
            topMargin: Theme.paddingMedium
        }
    }

    // Context menu for Toots (hidden for gap items)
    Loader {
        id: tootMenu
        width: miniHeader.width
        anchors {
            left:  ! Logic.conf['conMen'] ? miniHeader.left : parent.left
            leftMargin: ! Logic.conf['conMen'] ? Theme.paddingMedium : 0
            right:   ! Logic.conf['conMen'] ? miniHeader.right : parent.right
            rightMargin: ! Logic.conf['conMen'] ? Theme.paddingMedium : 0
            topMargin: ! Logic.conf['conMen'] ? Theme.paddingLarge : 0
            top: {
                // in revserse order return the closest visible container
                if ( quotedPost.visible ) return quotedPost.bottom
                if ( linkPreview.visible ) return linkPreview.bottom
                if (typeof attachments !== "undefined" && attachments.count) return media.bottom
                if ( pollContainer.visible ) return pollContainer.bottom
                if (showMoreLabel.visible ) return showMoreLabel.bottom
                return lblContent.bottom
            }
        }
    }

    ContextMenu {
        id:ctxmnu
        visible: {
            if (model.type === "follow") return false
            var activeAccount = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
            if (!activeAccount || !activeAccount.userInfo) return false
            var myUsername = activeAccount.userInfo.account_username
            return model.account_acct === myUsername || model.account_username === myUsername
        }
        MenuItem {
            id: mnuDelete
            // Only show for user's own posts
            width: parent.width
            text: qsTr("Delete")
            onClicked: { tootdelete() }
            Icon {
                id: icDel
                source: "image://theme/icon-s-clear-opaque-cross?" + Theme.highlightColor
                width: Theme.iconSizeSmall
                height: width
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
            }
        }
        MenuItem {
            width: parent.width
            id: mnuEdit
            // Only show for user's own posts
            text: qsTr("Edit")
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                                   headerTitle: qsTr("Edit"),
                                   status_id: model.status_id,
                                   editMode: true,
                                   type: "edit"
                               })
            }

            Icon {
                id: icEdit
                source: "image://theme/icon-s-edit?" + Theme.highlightColor
                width: Theme.iconSizeSmall
                height: width
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }


    onPressAndHold: {
        var activeAccount = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
        if (!activeAccount || !activeAccount.userInfo) return false
        if ( Logic.conf['conMen'] ) tootMenu.item.open(delegate)
    }
    // Context menu for own Toots edit and delete
        // Open ConversationPage and show other Toots in thread (if available) or ProfilePage if new Follower
    onClicked: {
        // Don't navigate for gap items - they have their own click handler
        if (model.type === "gap") return

        var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject');
        if (typeof mdl !== "undefined")
            m.append(mdl.get(index))

        if (model.type !== "follow") {
            if (conversationPage) return
            pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                               headerTitle: qsTr("Conversation"),
                               "status_id": status_id,
                               "status_url": status_url,
                               "status_uri": status_uri,
                               "username": '@'+account_acct,
                               mdl: m,
                               type: "reply"
                           })
        } else pageStack.push(Qt.resolvedUrl("../ProfilePage.qml"), {
                                  "display_name": model.account_display_name,
                                  "username": model.account_acct,
                                  "user_id": model.account_id,
                                  "profileImage": model.account_avatar,
                                  "profileBackground": model.account_header,
                                  "note": model.account_note,
                                  "url": model.account_url,
                                  "followers_count": model.account_followers_count,
                                  "following_count": model.account_following_count,
                                  "statuses_count": model.account_statuses_count,
                                  "locked": model.account_locked,
                                  "bot": model.account_bot,
                                  "group": model.account_group
                              } )
    }

}
