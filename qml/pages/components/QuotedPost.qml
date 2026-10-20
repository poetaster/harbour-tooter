import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic

// Quoted Post Display - styled like a mini-toot
Rectangle {
    id: quotedPost
    width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
    height: visible ? quotedPostContent.implicitHeight + Theme.paddingMedium * 2 : 0
    color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
    border.color: Theme.rgba(Theme.highlightColor, 0.4)
    border.width: 1
    radius: Theme.paddingSmall

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Open the quoted post in conversation view
            if (debug) console.log("convesation from quoted")
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
                    text: typeof model.quote_account_acct !== "undefined" ? "@" + model.quote_account_acct : ""
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
