import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic


BackgroundItem {
    id: delegate

    signal send (string notice)
    signal navigateTo(string link)

    width: parent.width
    height: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                mnu.height + miniHeader.height + Theme.paddingLarge + lblContent.height + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0)
            } else mnu.height + miniHeader.height + (typeof attachments !== "undefined" && attachments.count ? media.height + Theme.paddingLarge + Theme.paddingMedium: Theme.paddingLarge) + lblContent.height + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0) + (iconDirectMsg.visible ? iconDirectMsg.height : 0)

    Rectangle {
        id: bgDirect
        x: 0
        y: 0
        visible: status_visibility === "direct"
        width: parent.width
        height: parent.height
        opacity: 0.3
        gradient: Gradient {
            GradientStop { position: -1.5; color: "transparent" }
            GradientStop { position: 0.6; color: Theme.highlightBackgroundColor }
        }
    }

    Rectangle {
        id: bgNotifications
        x: 0
        y: 0
        visible: myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )
        width: parent.width
        height: parent.height
        opacity: 0.5
        gradient: Gradient {
            GradientStop { position: -0.5; color: "transparent" }
            GradientStop { position: 0.4; color: Theme.highlightDimmerColor }
        }
    }

    MiniStatus {
        id: miniStatus
        anchors {
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            top: parent.top
            topMargin: Theme.paddingMedium
        }
    }

    Image {
        id: avatar
        visible: true
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
                source = "../../images/icon-m-profile.svg?" + (pressed
                                                               ? Theme.highlightColor
                                                               : Theme.primaryColor)
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
                                   "bot": model.account_bot
                               } )
            }
        }

        Rectangle {
            visible: myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )
            opacity: 0.5
            color: Theme.highlightDimmerColor
            anchors.fill: avatar
        }

        Image {
            id: iconTR
            visible: typeof status_reblogged !== "undefined" && status_reblogged
            width: Theme.iconSizeExtraSmall
            height: width
            source: "image://theme/icon-s-retweet"
            anchors {
                top: avatar.bottom
                topMargin: Theme.paddingMedium
                left: avatar.left
            }
        }

        Image {
            id: iconDirectMsg
            visible: status_visibility === "direct"
            width: Theme.iconSizeMedium
            height: width
            source: "image://theme/icon-m-mail"
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
                                       "bot": model.reblog_account_bot
                                   } )
                }
            }
        }
    }

    MiniHeader {
        id: miniHeader
        anchors {
            top: avatar.top
            left: avatar.right
            right: parent.right
        }
    }

    Text  {
        id: lblContent
        visible: model.type !== "follow"
        text: content.replace(new RegExp("<a ", 'g'), '<a style="text-decoration: none; color:'+(pressed ?  Theme.secondaryColor : Theme.highlightColor)+'" ')
        textFormat: Text.RichText
        font.pixelSize: Theme.fontSizeSmall
        linkColor: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                       Theme.secondaryHighlightColor
                   } else Theme.highlightColor
        wrapMode: Text.Wrap
        color: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                   (pressed ? Theme.secondaryHighlightColor : (!highlight ? Theme.secondaryColor : Theme.secondaryHighlightColor))
               } else (pressed ? Theme.highlightColor : (!highlight ? Theme.primaryColor : Theme.secondaryColor))
        height: if (model.type === "follow") {
                    Theme.paddingLarge
                } else content.length ? (contentWarningLabel.paintedHeight > paintedHeight ? contentWarningLabel.paintedHeight : paintedHeight) : 0
        anchors {
            left: miniHeader.left
            leftMargin: Theme.paddingMedium
            right: miniHeader.right
            rightMargin: Theme.horizontalPageMargin
            top: miniHeader.bottom
            topMargin: Theme.paddingSmall
            bottomMargin: Theme.paddingLarge
        }
        onLinkActivated: {
            var test = link.split("/")
            console.log(link)
            console.log(JSON.stringify(test))
            console.log(JSON.stringify(test.length))

            if (test.length === 5 && (test[3] === "tags" || test[3] === "tag") ) {
                pageStack.pop(pageStack.find(function(page) {
                    var check = page.isFirstPage === true;
                    if (check)
                        page.onLinkActivated(link)
                    return check;
                }));
                send(link)
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

        Rectangle {
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

    MediaBlock {
        id: media
        visible: if (myList.type === "notifications" && ( type === "favourite" || type === "reblog" )) {
                     false
                 } else true
        model: typeof attachments !== "undefined" ? attachments : Qt.createQmlObject('import QtQuick 2.0; ListModel { }', Qt.application, 'InternalQmlObject');
        height: Theme.iconSizeExtraLarge * 2
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: lblContent.bottom
            topMargin: Theme.paddingMedium
            bottomMargin: Theme.paddingLarge
        }
    }

    ContextMenu {
        id: mnu

        MenuItem {
            id: mnuBoost
            visible: model.type !== "follow"
            enabled: status_visibility !== "direct"
            text: typeof model.reblogged !== "undefined" && model.reblogged ? qsTr("Unboost") : qsTr("Boost")
            onClicked: {
                var status = typeof model.reblogged !== "undefined" && model.reblogged
                worker.sendMessage({
                                       "conf"   : Logic.conf,
                                       "params" : [],
                                       "method" : "POST",
                                       "bgAction": true,
                                       "action" : "statuses/"+model.status_id+"/" + (status ? "unreblog" : "reblog")
                                   })
                model.status_reblogs_count = !status ? model.status_reblogs_count+1 : (model.status_reblogs_count > 0 ? model.status_reblogs_count-1 : model.status_reblogs_count);
                model.reblogged = !model.reblogged
            }

            Image {
                id: icRT
                source: "image://theme/icon-s-retweet?" + (!model.reblogged ? Theme.highlightColor : Theme.primaryColor)
                width: Theme.iconSizeExtraSmall
                height: width
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Label {
                text: status_reblogs_count // from API.js
                font.pixelSize: Theme.fontSizeExtraSmall
                color: !model.reblogged ? Theme.highlightColor : Theme.primaryColor
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
            text: typeof model.favourited !== "undefined" && model.favourited ? qsTr("Unfavorite") : qsTr("Favorite")
            onClicked: {
                var status = typeof model.favourited !== "undefined" && model.favourited
                worker.sendMessage({
                                       "conf"   : Logic.conf,
                                       "params" : [],
                                       "method" : "POST",
                                       "bgAction": true,
                                       "action" : "statuses/"+model.status_id+"/" + (status ? "unfavourite" : "favourite")
                                   })
                model.status_favourites_count = !status ? model.status_favourites_count+1 : (model.status_favourites_count > 0 ? model.status_favourites_count-1 : model.status_favourites_count);
                model.favourited = !model.favourited
            }

            Image {
                id: icFA
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: Theme.iconSizeExtraSmall
                height: width
                source: "image://theme/icon-s-favorite?" + (!model.favourited ? Theme.highlightColor : Theme.primaryColor)
            }

            Label {
                text: status_favourites_count // from API.js
                font.pixelSize: Theme.fontSizeExtraSmall
                color: !model.favourited ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    left: icFA.right
                    leftMargin: Theme.paddingMedium
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
                                   headerTitle: "Mention",
                                   description: "@"+reblog_account_acct,
                                   type: "new"
                               })
            }

            Image {
                id: icMT
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: Theme.iconSizeExtraSmall
                height: width
                source: "image://theme/icon-s-chat?" + (!model.favourited ? Theme.highlightColor : Theme.primaryColor)
            }
        }
    }

    onClicked: {
        var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { }', Qt.application, 'InternalQmlObject');
        if (typeof mdl !== "undefined")
            m.append(mdl.get(index))
        pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                           headerTitle: qsTr("Conversation"),
                           "toot_id": status_id,
                           "toot_url": status_url,
                           "toot_uri": status_uri,
                           "description": '@'+account_acct,
                           mdl: m,
                           type: "reply"
                       })
    }
    onPressAndHold: {
        console.log(JSON.stringify(mdl.get(index)))
        mnu.open(delegate)
    }

    onDoubleClicked: {
        console.log("double click")
    }

}
