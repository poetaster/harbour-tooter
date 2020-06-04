import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic


BackgroundItem {
    id: delegate

    signal send (string notice)
    signal navigateTo(string link)

    width: parent.width
    height: mnu.height +  miniHeader.height + (typeof attachments !== "undefined" && attachments.count ? media.height + Theme.paddingLarge + Theme.paddingMedium: Theme.paddingLarge) + lblContent.height + Theme.paddingLarge + (miniStatus.visible ? miniStatus.height : 0)

    Rectangle {
        id: bgDirect
        x: 0
        y: 0
        visible: status_visibility == 'direct'
        width: parent.width
        height: parent.height
        opacity: 0.3
        color: Theme.highlightBackgroundColor
    }

    /* Rectangle {
        id: bgDelegate
        x: 0
        y: 0
        visible: status_visibility !== 'direct'
        width: parent.width
        height: parent.height
        opacity: 0.15
        gradient: Gradient {
                GradientStop { position: 0.7; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.highlightDimmerColor }
        }
    } */

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
                                   "profileBackground": model.account_header
                               })
            }
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

        Rectangle {
            color: Theme.highlightDimmerColor
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
                asynchronous: true
                smooth: true
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }
                source: typeof reblog_account_avatar !== "undefined" ? reblog_account_avatar : ''
                visible: typeof status_reblog !== "undefined" && status_reblog
                width: Theme.iconSizeSmall
                height: width
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
        linkColor: Theme.highlightColor
        wrapMode: Text.Wrap
        color: (pressed ? Theme.highlightColor : (!highlight ? Theme.primaryColor : Theme.secondaryColor))
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
            radius: 2
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
        model: typeof attachments !== "undefined" ? attachments : Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
        height: Theme.iconSizeExtraLarge * 2
        anchors {
            left: lblContent.left
            right: lblContent.right
            top: lblContent.bottom
            topMargin: Theme.paddingSmall
            bottomMargin: Theme.paddingLarge
        }
    }

    ContextMenu {
        id: mnu

        MenuItem {
            visible: model.type !== "follow"
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
                model.reblogs_count = !status ? model.reblogs_count+1 : (model.reblogs_count > 0 ? model.reblogs_count-1 : model.reblogs_count);
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
                text: reblogs_count
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
                model.favourites_count = !status ? model.favourites_count+1 : (model.favourites_count > 0 ? model.favourites_count-1 : model.favourites_count);
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
                text: favourites_count
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
        var m = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
        if (typeof mdl !== "undefined")
            m.append(mdl.get(index))
        pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                           headerTitle: "Conversation",
                           toot_id: status_id,
                           toot_url: status_url,
                           title: account_display_name,
                           description: '@'+account_acct,
                           avatar: account_avatar,
                           mdl: m,
                           type: "reply"
                       })
    }
    onPressAndHold: {
        console.log(JSON.stringify(mdl.get(index)))
        mnu.show(delegate)
    }
    onDoubleClicked: {
        console.log("double click")
    }

}
