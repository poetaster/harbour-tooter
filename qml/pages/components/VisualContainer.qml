import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic


BackgroundItem {
    id: delegate

    property bool debug:false
    property bool expanded: false
    property int charLimit: 500

    // Helper function to strip HTML and get text length
    function getTextLength(html) {
        if (!html) return 0
        return html.replace(/<[^>]*>/g, '').length
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

    // Function to fetch fresh status stats from the server
    function refreshStatusStats() {
        if (!model.status_id || model.type === "follow" || model.type === "gap") return

        var account = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
        if (!account || !account.instance || !account.api_user_token) return

        var url = account.instance + "/api/v1/statuses/" + model.status_id
        var http = new XMLHttpRequest()
        http.open("GET", url, true)
        http.setRequestHeader("Authorization", "Bearer " + account.api_user_token)
        http.setRequestHeader("Content-Type", "application/json")

        http.onreadystatechange = function() {
            if (http.readyState === 4 && http.status === 200) {
                try {
                    var data = JSON.parse(http.responseText)
                    // Update model with fresh counts
                    if (typeof data.replies_count !== "undefined")
                        model.status_replies_count = data.replies_count
                    if (typeof data.reblogs_count !== "undefined")
                        model.status_reblogs_count = data.reblogs_count
                    if (typeof data.favourites_count !== "undefined")
                        model.status_favourites_count = data.favourites_count
                    // Also update interaction states in case they changed
                    if (typeof data.favourited !== "undefined")
                        model.status_favourited = data.favourited
                    if (typeof data.reblogged !== "undefined")
                        model.status_reblogged = data.reblogged
                    if (typeof data.bookmarked !== "undefined")
                        model.status_bookmarked = data.bookmarked
                    if (debug) console.log("Refreshed stats: replies=" + data.replies_count +
                        " reblogs=" + data.reblogs_count + " favs=" + data.favourites_count)
                } catch (e) {
                    console.log("Error parsing status response: " + e)
                }
            }
        }
        http.send()
    }

    signal send (string notice)
    signal navigateTo(string link)

    RemorseItem { id: remorseDelete }

    // Gap item UI - "Load more" button for timeline gaps
    Item {
        id: gapLoader
        visible: model && model.type === "gap"
        width: parent.width
        height: visible ? Theme.itemSizeLarge : 0

        // Safe property access for gap_loading
        property bool isGapLoading: model && typeof model.gap_loading !== "undefined" && model.gap_loading === true

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
                running: gapLoader.isGapLoading
                visible: running
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: gapLoader.isGapLoading ? qsTr("Loading...") : qsTr("Load more")
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
            }

            Image {
                visible: !gapLoader.isGapLoading
                source: "image://theme/icon-m-down"
                width: Theme.iconSizeSmall
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !gapLoader.isGapLoading
            onClicked: {
                console.log("Gap clicked at index " + index)
                if (typeof myList !== "undefined" && myList && typeof myList.loadGap === "function") {
                    myList.loadGap(index)
                } else {
                    console.log("Error: myList.loadGap not available")
                }
            }
        }
    }

    height: if (!model) {
                0
            } else if (model.type === "gap") {
                gapLoader.height
            } else if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                mnu.height + miniHeader.height + Theme.paddingLarge + lblContent.height + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0)
            } else mnu.height + miniHeader.height + (replyIndicator.visible ? replyIndicator.height + Theme.paddingSmall : 0) + (typeof attachments !== "undefined" && attachments.count ? media.height + Theme.paddingLarge + Theme.paddingMedium: Theme.paddingLarge) + lblContent.height + (isLongPost ? showMoreLabel.height : 0) + (pollContainer.visible ? pollContainer.childrenRect.height + Theme.paddingMedium : 0) + (linkPreview.visible ? linkPreview.height + Theme.paddingMedium : 0) + (quotedPost.visible ? quotedPost.height + Theme.paddingMedium : 0) + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0) + (iconDirectMsg.visible ? iconDirectMsg.height : 0)

    // Background for Direct Messages in Notification View
    Rectangle {
        id: bgDirect
        x: 0
        y: 0
        visible: model && model.type !== "gap" && model.status_visibility === "direct"
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
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            top: parent.top
            topMargin: Theme.paddingMedium
        }
    }

    // Stacked avatars for grouped notifications (v2 API)
    Row {
        id: stackedAvatars
        visible: model && model.type !== "gap" && typeof model.notifications_count !== "undefined" && model.notifications_count > 1 && typeof model.grouped_account_count !== "undefined" && model.grouped_account_count > 1
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

    // Account avatar (hidden when showing stacked avatars or for gap items)
    Image {
        id: avatar
        visible: model && model.type !== "gap" && !stackedAvatars.visible
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        asynchronous: true
        smooth: true
        cache: true
        source: typeof account_avatar !== "undefined" ? account_avatar : ""
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
            visible: model && myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )
            opacity: 0.5
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
        visible: model && model.type !== "gap"
        anchors {
            top: stackedAvatars.visible ? stackedAvatars.top : avatar.top
            left: stackedAvatars.visible ? stackedAvatars.right : avatar.right
            right: parent.right
        }
    }

    // Reply indicator - shows when toot is a reply to another toot
    Row {
        id: replyIndicator
        visible: model && model.type !== "gap" && model.type !== "follow" && typeof model.status_in_reply_to_id !== "undefined" && model.status_in_reply_to_id && String(model.status_in_reply_to_id).length > 0
        spacing: Theme.paddingSmall
        anchors {
            left: miniHeader.left
            leftMargin: Theme.paddingMedium
            top: miniHeader.bottom
            topMargin: Theme.paddingSmall / 2
        }

        Icon {
            id: replyIcon
            source: "image://theme/icon-s-repost"  // Reply/thread icon
            width: Theme.iconSizeExtraSmall
            height: width
            color: Theme.secondaryColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            text: {
                // Get the first mention as the reply target
                if (typeof model.status_mentions !== "undefined" && model.status_mentions && model.status_mentions.length > 0) {
                    var firstMention = model.status_mentions.split(',')[0]
                    if (appWindow.fullUsernames) {
                        return qsTr("replying to @%1").arg(firstMention)
                    } else {
                        // Show short username
                        var shortName = firstMention.indexOf('@') > 0 ? firstMention.split('@')[0] : firstMention
                        return qsTr("replying to @%1").arg(shortName)
                    }
                }
                return qsTr("replying to thread")
            }
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.secondaryColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Cache processed content to avoid regex on every press state change
    // Compute base content (truncated if needed) once, then derive styled versions
    property string baseDisplayContent: {
        if (!model) return ""
        var displayContent = typeof content !== "undefined" ? content : ""
        // Truncate if long post and not expanded (not for notifications)
        // In conversation view, don't truncate the main clicked toot
        var isMainConversationToot = (typeof myList.type !== "undefined" && myList.type === "conversation" &&
                                      typeof myList.mainStatusId !== "undefined" && model.status_id === myList.mainStatusId)
        if (isLongPost && !expanded && !isMainConversationToot && !(myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog"))) {
            displayContent = truncateContent(content, charLimit) + "..."
        }
        return displayContent
    }

    // Pre-compute both color variants - regex only runs when content changes, not on press
    property bool isNotificationCompact: model && myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")
    property string processedContent: isNotificationCompact ? baseDisplayContent :
        baseDisplayContent.replace(/<a /g, '<a style="text-decoration: none; color:' + Theme.highlightColor + ';" ')
    property string processedContentPressed: isNotificationCompact ? baseDisplayContent :
        baseDisplayContent.replace(/<a /g, '<a style="text-decoration: none; color:' + Theme.secondaryColor + ';" ')

    // Toot content
    Label  {
        id: lblContent
        visible: model && model.type !== "gap" && model.type !== "follow"
        text: pressed ? processedContentPressed : processedContent
        textFormat: model && myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" ) ? Text.StyledText : Text.RichText
        font.pixelSize: Theme.fontSizeSmall * appWindow.fontScale
        wrapMode: Text.Wrap
        truncationMode: TruncationMode.Elide
        color: if (model && myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                   (pressed ? Theme.secondaryHighlightColor : (!highlight ? Theme.secondaryColor : Theme.secondaryHighlightColor))
               } else (pressed ? Theme.highlightColor : (!highlight ? Theme.primaryColor : Theme.secondaryColor))
        linkColor: if (model && myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                       Theme.secondaryHighlightColor
                   } else (pressed ? Theme.secondaryColor : Theme.highlightColor)
        height: if (!model || model.type === "follow") {
                    Theme.paddingLarge
                } else if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                    Math.min( implicitHeight, Theme.itemSizeExtraLarge * 1.5 )
                } else (typeof content !== "undefined" && content.length) ? ( contentWarningLabel.paintedHeight > paintedHeight ? contentWarningLabel.paintedHeight : paintedHeight ) : 0
        anchors {
            left: miniHeader.left
            leftMargin: Theme.paddingMedium
            right: miniHeader.right
            rightMargin: Theme.horizontalPageMargin + Theme.paddingMedium
            top: replyIndicator.visible ? replyIndicator.bottom : miniHeader.bottom
            topMargin: Theme.paddingSmall
            bottomMargin: Theme.paddingLarge
        }
        onLinkActivated: {
            if (debug) console.log("VisualContainer link activated: " + link)

            // Use the URL parser to detect Mastodon resource types
            var parsed = Logic.parseMastodonUrl(link)

            // For recognized Mastodon URLs (tag, profile, status), delegate to MainPage
            if (parsed.type !== "unknown") {
                pageStack.pop(pageStack.find(function(page) {
                    var check = page.isFirstPage === true
                    if (check)
                        page.onLinkActivated(link)
                    return check
                }))
            } else {
                // Unknown URL - open in reader mode or browser based on setting
                if (appWindow.openLinksInReader) {
                    console.log("VisualContainer: Opening in reader mode: " + link)
                    pageStack.push(Qt.resolvedUrl("../ReaderPage.qml"), {
                        articleUrl: link
                    })
                } else {
                    console.log("VisualContainer: Opening in browser: " + link)
                    Qt.openUrlExternally(link)
                }
            }
        }

        // Content warning cover for Toots
        Rectangle {
            id: contentWarningBg
            color: Theme.highlightDimmerColor
            visible: typeof status_spoiler_text !== "undefined" && status_spoiler_text.length > 0
            anchors.fill: parent

            Label {
                id: contentWarningLabel
                text: typeof model.status_spoiler_text !== "undefined" ? model.status_spoiler_text : ""
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
    Column {
        id: pollContainer
        visible: {
            if (model.type === "gap") return false
            if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) return false
            return pollData.id && pollData.id.length > 0
        }
        width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
        spacing: Theme.paddingSmall
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom
            topMargin: Theme.paddingMedium
        }

        // Parse all poll data from JSON string
        property var pollData: {
            try {
                var json = typeof model.poll_json !== "undefined" && model.poll_json ? model.poll_json : ''
                if (json.length === 0) return { id: '', options: [], votes_count: 0, voted: false, expired: false, multiple: false, own_votes: [] }
                return JSON.parse(json)
            } catch (e) {
                return { id: '', options: [], votes_count: 0, voted: false, expired: false, multiple: false, own_votes: [] }
            }
        }

        // Track selected options for voting
        property var selectedOptions: []
        property bool hasVoted: pollData.voted || false
        property bool isExpired: pollData.expired || false
        property bool canVote: !hasVoted && !isExpired
        property bool isMultiple: pollData.multiple || false

        // Helper to check if option is selected
        function isOptionSelected(idx) {
            return selectedOptions.indexOf(idx) !== -1
        }

        // Helper to check if user voted for this option
        function userVotedFor(idx) {
            var ownVotes = pollData.own_votes || []
            return ownVotes.indexOf(idx) !== -1
        }

        // Helper to get vote percentage
        function getVotePercentage(optionVotes) {
            var total = pollData.votes_count || 0
            if (total === 0) return 0
            return Math.round((optionVotes / total) * 100)
        }

        // Poll options using Repeater
        Repeater {
            model: pollContainer.pollData.options || []

            Rectangle {
                width: pollContainer.width
                height: Math.max(Theme.itemSizeSmall, optionText.implicitHeight + Theme.paddingMedium * 2)
                color: pollContainer.canVote && pollContainer.isOptionSelected(index) ? Theme.rgba(Theme.highlightColor, 0.3) : Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                radius: Theme.paddingSmall
                border.color: pollContainer.userVotedFor(index) ? Theme.highlightColor : "transparent"
                border.width: pollContainer.userVotedFor(index) ? 2 : 0

                // Vote percentage bar (shown after voting or when expired)
                Rectangle {
                    visible: !pollContainer.canVote
                    width: parent.width * pollContainer.getVotePercentage(modelData.votes) / 100
                    height: parent.height
                    color: Theme.rgba(Theme.highlightColor, 0.2)
                    radius: Theme.paddingSmall
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.paddingMedium
                    spacing: Theme.paddingSmall

                    // Checkbox/Radio indicator for voting
                    Rectangle {
                        visible: pollContainer.canVote
                        width: Theme.iconSizeSmall * 0.7
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        radius: pollContainer.isMultiple ? Theme.paddingSmall / 2 : width / 2
                        color: pollContainer.isOptionSelected(index) ? Theme.highlightColor : "transparent"
                        border.color: Theme.highlightColor
                        border.width: 2
                    }

                    // Checkmark for voted option
                    Icon {
                        visible: !pollContainer.canVote && pollContainer.userVotedFor(index)
                        width: Theme.iconSizeSmall
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/icon-s-installed"
                        color: Theme.highlightColor
                    }

                    Label {
                        id: optionText
                        text: modelData.title
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                        width: parent.width - (pollContainer.canVote || pollContainer.userVotedFor(index) ? Theme.iconSizeSmall + Theme.paddingSmall : 0) - optionPercent.width - Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        id: optionPercent
                        visible: !pollContainer.canVote
                        text: pollContainer.getVotePercentage(modelData.votes) + "%"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: pollContainer.canVote
                    onClicked: {
                        if (pollContainer.isMultiple) {
                            var idx = pollContainer.selectedOptions.indexOf(index)
                            if (idx === -1) {
                                pollContainer.selectedOptions.push(index)
                            } else {
                                pollContainer.selectedOptions.splice(idx, 1)
                            }
                            pollContainer.selectedOptions = pollContainer.selectedOptions.slice()
                        } else {
                            pollContainer.selectedOptions = [index]
                        }
                    }
                }
            }
        }

        // Vote button and poll info
        Row {
            width: parent.width
            height: Math.max(Theme.itemSizeSmall, implicitHeight)
            spacing: Theme.paddingMedium

            Button {
                id: voteButton
                visible: pollContainer.canVote
                enabled: pollContainer.selectedOptions.length > 0
                text: qsTr("Vote")
                preferredWidth: Theme.buttonWidthSmall
                onClicked: {
                    // Build vote params - API expects {"choices": [0, 1, ...]}
                    var choices = []
                    for (var i = 0; i < pollContainer.selectedOptions.length; i++) {
                        choices.push(pollContainer.selectedOptions[i])
                    }
                    worker.sendMessage({
                        "conf": Logic.conf,
                        "params": { "choices": choices },
                        "method": "POST",
                        "bgAction": true,
                        "action": "polls/" + pollContainer.pollData.id + "/votes"
                    })
                    // Update local state optimistically by rebuilding poll_json
                    var newPollData = JSON.parse(JSON.stringify(pollContainer.pollData))
                    newPollData.voted = true
                    newPollData.own_votes = pollContainer.selectedOptions.slice()
                    newPollData.votes_count = (newPollData.votes_count || 0) + 1
                    model.poll_json = JSON.stringify(newPollData)
                }
            }

            Label {
                text: {
                    var parts = []
                    var total = pollContainer.pollData.votes_count || 0
                    parts.push(total + " " + qsTr("votes"))

                    if (pollContainer.isExpired) {
                        parts.push(qsTr("Closed"))
                    } else if (pollContainer.pollData.expires_at) {
                        var now = new Date()
                        var expires = new Date(pollContainer.pollData.expires_at)
                        var diff = expires - now
                        if (diff > 0) {
                            var hours = Math.floor(diff / (1000 * 60 * 60))
                            var minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
                            if (hours > 24) {
                                var days = Math.floor(hours / 24)
                                parts.push(days + " " + qsTr("days left"))
                            } else if (hours > 0) {
                                parts.push(hours + " " + qsTr("hours left"))
                            } else {
                                parts.push(minutes + " " + qsTr("minutes left"))
                            }
                        }
                    }
                    return parts.join(" · ")
                }
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                anchors.verticalCenter: voteButton.visible ? voteButton.verticalCenter : undefined
                wrapMode: Text.Wrap
                width: parent.width - (voteButton.visible ? voteButton.width + Theme.paddingMedium : 0)
            }
        }
    }

    // Displays media in Toots
    MediaBlock {
        id: media
        visible: model && model.type !== "gap" && ((myList.type === "notifications" && ( type === "favourite" || type === "reblog" )) ? false : true)
        model: typeof attachments !== "undefined" ? attachments : emptyAttachmentsModel
        height: Theme.iconSizeExtraLarge * 2
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
    Rectangle {
        id: linkPreview
        visible: {
            if (!model || model.type === "gap") return false
            if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) return false
            // Require both URL and title to avoid showing empty card boxes
            return typeof model.card_url !== "undefined" && model.card_url.length > 0
                   && typeof model.card_title !== "undefined" && model.card_title.length > 0
        }
        width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
        // Dynamic height: max of image height or text content height
        height: visible ? Math.max(Theme.itemSizeLarge, linkPreviewText.implicitHeight) + Theme.paddingMedium * 2 : 0
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        radius: Theme.paddingSmall
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: (typeof attachments !== "undefined" && attachments.count) ? media.bottom : (pollContainer.visible ? pollContainer.bottom : (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom))
            topMargin: Theme.paddingMedium
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (appWindow.openLinksInReader) {
                    console.log("VisualContainer: Opening link preview in reader mode: " + model.card_url)
                    pageStack.push(Qt.resolvedUrl("../ReaderPage.qml"), {
                        articleUrl: model.card_url
                    })
                } else {
                    Qt.openUrlExternally(model.card_url)
                }
            }
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

    // Quoted Post Display - styled like a mini-toot
    Rectangle {
        id: quotedPost
        visible: {
            if (model.type === "gap") return false
            if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) return false
            // Require both quote_id AND some meaningful content (either text content or author info)
            var hasQuoteId = typeof model.quote_id !== "undefined" && model.quote_id.length > 0
            if (!hasQuoteId) return false
            var hasContent = typeof model.quote_content !== "undefined" && model.quote_content.length > 0
            var hasAuthor = typeof model.quote_account_acct !== "undefined" && model.quote_account_acct.length > 0
            return hasContent || hasAuthor
        }
        width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
        height: visible ? quotedPostContent.implicitHeight + Theme.paddingMedium * 2 : 0
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        border.color: Theme.rgba(Theme.highlightColor, 0.4)
        border.width: 1
        radius: Theme.paddingSmall
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: linkPreview.visible ? linkPreview.bottom : ((typeof attachments !== "undefined" && attachments.count) ? media.bottom : (pollContainer.visible ? pollContainer.bottom : (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom)))
            topMargin: Theme.paddingMedium
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                // Open the quoted post in conversation view
                var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject');
                pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                    headerTitle: qsTr("Conversation"),
                    "status_id": model.quote_id,
                    "status_url": model.quote_url,
                    mdl: m,
                    type: "reply"
                })
            }
        }

        Column {
            id: quotedPostContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.paddingMedium
            }
            spacing: Theme.paddingSmall

            // Quoted author row with avatar, display name and username
            Row {
                width: parent.width
                spacing: Theme.paddingSmall

                Image {
                    id: quotedAvatar
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    source: typeof model.quote_account_avatar !== "undefined" ? model.quote_account_avatar : ""
                    asynchronous: true
                    smooth: true
                    cache: true
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Open quoted user's profile
                            pageStack.push(Qt.resolvedUrl("../ProfilePage.qml"), {
                                "display_name": model.quote_account_display_name,
                                "username": model.quote_account_acct,
                                "user_id": model.quote_account_id,
                                "profileImage": model.quote_account_avatar
                            })
                        }
                    }
                }

                Column {
                    width: parent.width - quotedAvatar.width - Theme.paddingSmall
                    spacing: 0

                    Label {
                        text: typeof model.quote_account_display_name !== "undefined" ? model.quote_account_display_name : ""
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.bold: true
                        color: Theme.highlightColor
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }

                    Label {
                        text: {
                            if (typeof model.quote_account_acct === "undefined") return ""
                            var acct = model.quote_account_acct
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

            // Quoted content - smaller than main toot
            Label {
                text: {
                    var content = typeof model.quote_content !== "undefined" ? model.quote_content : ""
                    // Strip HTML tags for cleaner display
                    content = content.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
                    return content
                }
                font.pixelSize: Theme.fontSizeExtraSmall * appWindow.fontScale
                color: Theme.primaryColor
                wrapMode: Text.Wrap
                maximumLineCount: 6
                truncationMode: TruncationMode.Elide
                width: parent.width
            }
        }
    }

    // Context menu for Toots (hidden for gap items)
    ContextMenu {
        id: mnu
        visible: model && model.type !== "gap"

        // Fetch fresh stats when menu opens
        onActiveChanged: if (active) refreshStatusStats()

        MenuItem {
            id: mnuFavourite
            visible: model && model.type !== "follow"
            text: typeof model.status_favourited !== "undefined" && model.status_favourited ? qsTr("Unfavorite") : qsTr("Favorite")
            onClicked: {
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

            Icon {
                id: icFA
                source: "image://theme/icon-s-favorite?" + (!model.status_favourited ? Theme.highlightColor : Theme.primaryColor)
                width: Theme.iconSizeSmall
                height: width
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
            }

            Label {
                text: typeof status_favourites_count !== "undefined" ? status_favourites_count : 0
                font.pixelSize: Theme.fontSizeSmall
                color: !model.status_favourited ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    left: icFA.right
                    leftMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        MenuItem {
            id: mnuBoost
            visible: model && model.type !== "follow"
            enabled: model && model.status_visibility !== "direct"
            text: typeof model.status_reblogged !== "undefined" && model.status_reblogged ? qsTr("Unboost") : qsTr("Boost")
            onClicked: {
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

            Icon {
                id: icRT
                source: "image://theme/icon-s-retweet?" + (!model.status_reblogged ? Theme.highlightColor : Theme.primaryColor)
                width: Theme.iconSizeSmall
                height: width
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Label {
                text: typeof status_reblogs_count !== "undefined" ? status_reblogs_count : 0
                font.pixelSize: Theme.fontSizeSmall
                color: !model.status_reblogged ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    left: icRT.right
                    leftMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        MenuItem {
            id: mnuReply
            visible: model && model.type !== "follow"
            text: qsTr("Reply")
            onClicked: {
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

            Icon {
                id: icReply
                source: "image://theme/icon-s-message?" + Theme.highlightColor
                width: Theme.iconSizeSmall
                height: width
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Label {
                text: typeof status_replies_count !== "undefined" ? status_replies_count : 0
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                anchors {
                    left: icReply.right
                    leftMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        MenuItem {
            id: mnuQuote
            visible: model && model.type !== "follow"
            enabled: model && model.status_visibility !== "direct"
            text: qsTr("Quote")
            onClicked: {
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

            Icon {
                id: icQuote
                source: "image://theme/icon-s-edit?" + Theme.highlightColor
                width: Theme.iconSizeSmall
                height: width
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        MenuItem {
            id: mnuBookmark
            visible: model && model.type !== "follow"
            text: typeof model.status_bookmarked !== "undefined" && model.status_bookmarked ? qsTr("Remove Bookmark") : qsTr("Bookmark")
            onClicked: {
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

            Icon {
                id: icBM
                source: "../../images/icon-s-bookmark.svg?"
                color: !model.status_bookmarked ? Theme.highlightColor : Theme.primaryColor
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
            id: mnuDelete
            // Only show for user's own posts
            visible: {
                if (!model || model.type === "follow") return false
                var activeAccount = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
                if (!activeAccount || !activeAccount.userInfo) return false
                var myUsername = activeAccount.userInfo.account_username
                return model.account_acct === myUsername || model.account_username === myUsername
            }
            text: qsTr("Delete")
            onClicked: {
                remorseDelete.execute(delegate, qsTr("Deleting"), function() {
                    worker.sendMessage({
                        "conf": Logic.conf,
                        "method": "DELETE",
                        "action": "statuses/" + model.status_id
                    })
                    mdl.remove(index)
                })
            }

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
            id: mnuEdit
            // Only show for user's own posts
            visible: {
                if (!model || model.type === "follow") return false
                var activeAccount = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
                if (!activeAccount || !activeAccount.userInfo) return false
                var myUsername = activeAccount.userInfo.account_username
                return model.account_acct === myUsername || model.account_username === myUsername
            }
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

        MenuItem {
            id: mnuMention
            visible: model && model.type === "follow"
            text: qsTr("Mention")
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                                   headerTitle: qsTr("Mention"),
                                   username: "@"+reblog_account_acct,
                                   type: "new"
                               })
            }

            Icon {
                id: icMT
                source: "image://theme/icon-s-chat?" + (!model.status_favourited ? Theme.highlightColor : Theme.primaryColor)
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

    // Open ConversationPage and show other Toots in thread (if available) or ProfilePage if new Follower
    onClicked: {
        // Don't navigate for gap items - they have their own click handler
        if (model.type === "gap") return

        var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject');
        if (typeof mdl !== "undefined")
            m.append(mdl.get(index))

        if (model.type !== "follow") {
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

    onPressAndHold: {
        if (model.type === "gap") return
        if (debug) console.log(JSON.stringify(mdl.get(index)))
        mnu.open(delegate)
    }

    onDoubleClicked: {
        if (debug) console.log("double click")
    }
}
