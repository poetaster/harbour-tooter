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

    signal send (string notice)
    signal navigateTo(string link)

    RemorseItem { id: remorseDelete }

    height: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                mnu.height + miniHeader.height + Theme.paddingLarge + lblContent.height + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0)
            } else mnu.height + miniHeader.height + (typeof attachments !== "undefined" && attachments.count ? media.height + Theme.paddingLarge + Theme.paddingMedium: Theme.paddingLarge) + lblContent.height + (isLongPost ? showMoreLabel.height : 0) + (linkPreview.visible ? linkPreview.height + Theme.paddingMedium : 0) + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0) + (iconDirectMsg.visible ? iconDirectMsg.height : 0)

    // Background for Direct Messages in Notification View
    Rectangle {
        id: bgDirect
        x: 0
        y: 0
        visible: model.status_visibility === "direct"
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

    // Account avatar
    Image {
        id: avatar
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        asynchronous: true
        smooth: true
        source: account_avatar
        width: Theme.iconSizeMedium
        height: width
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
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }
                source: typeof reblog_account_avatar !== "undefined" ? reblog_account_avatar : ''
                visible: typeof status_reblog !== "undefined" && status_reblog
                width: Theme.iconSizeSmall
                height: width
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
        anchors {
            top: avatar.top
            left: avatar.right
            right: parent.right
        }
    }

    // Toot content
    Label  {
        id: lblContent
        visible: model.type !== "follow"
        text: {
            var displayContent = content
            // Truncate if long post and not expanded (not for notifications)
            if (isLongPost && !expanded && !(myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog"))) {
                displayContent = truncateContent(content, charLimit) + "..."
            }
            // Apply link styling for non-notification views
            if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) {
                return displayContent
            } else {
                return displayContent.replace(new RegExp("<a ", 'g'), '<a style="text-decoration: none; color:'+(pressed ? Theme.secondaryColor : Theme.highlightColor)+'" ')
            }
        }
        textFormat: myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" ) ? Text.StyledText : Text.RichText
        font.pixelSize: Theme.fontSizeSmall * appWindow.fontScale
        wrapMode: Text.Wrap
        truncationMode: TruncationMode.Elide
        color: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                   (pressed ? Theme.secondaryHighlightColor : (!highlight ? Theme.secondaryColor : Theme.secondaryHighlightColor))
               } else (pressed ? Theme.highlightColor : (!highlight ? Theme.primaryColor : Theme.secondaryColor))
        linkColor: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                       Theme.secondaryHighlightColor
                   } else Theme.highlightColor
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
            topMargin: Theme.paddingSmall
            bottomMargin: Theme.paddingLarge
        }
        onLinkActivated: {
            var test = link.split("/")
            if (debug) {
                console.log(link)
                console.log(JSON.stringify(test))
                console.log(JSON.stringify(test.length))
            }
            if (test.length === 5 && (test[3] === "tags" || test[3] === "tag") ) {
                pageStack.pop(pageStack.find(function(page) {
                    var check = page.isFirstPage === true;
                    if (check)
                        page.onLinkActivated(link)
                    return check;
                }));
                send(link)
              // temporary solution for access to user profiles via toots
            } else if (test.length === 4 && test[3][0] === "@" ) {
                pageStack.pop(pageStack.find(function(page) {
                    var check = page.isFirstPage === true;
                    if (check)
                        page.onLinkActivated(link)
                    return check;
                }));
            } else {
                Qt.openUrlExternally(link);
            }
        }

        // Content warning cover for Toots
        Rectangle {
            id: contentWarningBg
            color: Theme.highlightDimmerColor
            visible: status_spoiler_text.length > 0
            anchors.fill: parent

            Label {
                id: contentWarningLabel
                text: model.status_spoiler_text
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

    // Show more / Show less label for long posts
    Label {
        id: showMoreLabel
        visible: isLongPost && !(myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog"))
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

    // Displays media in Toots
    MediaBlock {
        id: media
        visible: (myList.type === "notifications" && ( type === "favourite" || type === "reblog" )) ? false : true
        model: typeof attachments !== "undefined" ? attachments : Qt.createQmlObject('import QtQuick 2.0; ListModel { }', Qt.application, 'InternalQmlObject')
        height: Theme.iconSizeExtraLarge * 2
        anchors {
            left: lblContent.left
            leftMargin: isPortrait ? 0 : Theme.itemSizeSmall
            right: lblContent.right
            rightMargin: isPortrait ? 0 : Theme.itemSizeLarge * 1.2
            top: showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom
            topMargin: Theme.paddingMedium
            bottomMargin: Theme.paddingLarge
        }
    }

    // Link Preview Card
    Rectangle {
        id: linkPreview
        visible: {
            if (myList.type === "notifications" && (model.type === "favourite" || model.type === "reblog")) return false
            return typeof model.card_url !== "undefined" && model.card_url.length > 0
        }
        width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
        // Dynamic height: max of image height or text content height
        height: visible ? Math.max(Theme.itemSizeLarge, linkPreviewText.implicitHeight) + Theme.paddingMedium * 2 : 0
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        radius: Theme.paddingSmall
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: (typeof attachments !== "undefined" && attachments.count) ? media.bottom : (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom)
            topMargin: Theme.paddingMedium
        }

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

    // Context menu for Toots
    ContextMenu {
        id: mnu

        MenuItem {
            id: mnuBoost
            visible: model.type !== "follow"
            enabled: model.status_visibility !== "direct"
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
                text: status_reblogs_count
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
            id: mnuFavourite
            visible: model.type !== "follow"
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
                text: status_favourites_count
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
            id: mnuBookmark
            visible: model.type !== "follow"
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
                if (model.type === "follow") return false
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
                if (model.type === "follow") return false
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
            visible: model.type === "follow"
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
        if (debug) console.log(JSON.stringify(mdl.get(index)))
        mnu.open(delegate)
    }

    onDoubleClicked: {
        if (debug) console.log("double click")
    }
}
