import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic

ContextMenu {
    id: altMnu
    visible:  model.type !== "gap"

    MenuItem {
        id: altFavourite
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
            id: altFa
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
            text: (status_favourites_count !== undefined) ? status_favourites_count : ""
            font.pixelSize: Theme.fontSizeSmall
            color: !model.status_favourited ? Theme.highlightColor : Theme.primaryColor
            anchors {
                left: altFa.right
                leftMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
        }
    }

    MenuItem {
        id: altBoost
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
            id: altBst
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
            text: (status_reblogs_count !== undefined) ? status_reblogs_count : ""
            font.pixelSize: Theme.fontSizeSmall
            color: !model.status_reblogged ? Theme.highlightColor : Theme.primaryColor
            anchors {
                left: altBst.right
                leftMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
        }
    }

    MenuItem {
        id: altReply
        visible: model.type !== "follow"
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

        Icon {
            id: altRepl
            source: "image://theme/icon-s-message?" + Theme.highlightColor
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
        id: altQuote
        visible: model.type !== "follow"
        enabled: model.status_visibility !== "direct"
        text: qsTr("Quote")
        onClicked: {
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

        Icon {
            id: altQt
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
        id: altBookmark
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
            id: altBM
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
        id: altDelete
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
            id: altDel
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
        id: altEdit
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
            id: altEd
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
        id: altMention
        visible: model.type === "follow"
        text: qsTr("Mention")
        onClicked: {
            if (debug) console.log("link from mnuMention")
            pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                               headerTitle: qsTr("Mention"),
                               username: "@"+reblog_account_acct,
                               type: "new"
                           })
        }

        Icon {
            id: altMT
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
