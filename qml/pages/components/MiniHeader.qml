import QtQuick 2.0
import Sailfish.Silica 1.0


Item {
    id: miniHeader
    height: lblName.height
    width: parent.width

    Label {
        id: lblName
        text: account_display_name ? account_display_name : account_username.split('@')[0]
        font.weight: Font.Bold
        font.pixelSize: Theme.fontSizeSmall
        color: if ( myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                   ( pressed ? Theme.secondaryHighlightColor : (!highlight ? Theme.secondaryColor : Theme.secondaryHighlightColor ))
               } else ( pressed ? Theme.highlightColor : ( !highlight ? Theme.primaryColor : Theme.secondaryColor ))
        truncationMode: TruncationMode.Fade
        width: myList.type !== "follow" ? ( contentWidth > parent.width /2 ? parent.width /2 : contentWidth ) : parent.width - Theme.paddingMedium
        anchors {
            left: parent.left
            leftMargin: Theme.paddingMedium
        }
    }

    Label {
        id: lblScreenName
        visible: model.type !== "follow"
        text: '@'+account_username
        font.pixelSize: Theme.fontSizeExtraSmall
        color: ( pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor )
        truncationMode: TruncationMode.Fade
        anchors {
            left: lblName.right
            leftMargin: Theme.paddingMedium
            right: lblDate.left
            rightMargin: Theme.paddingMedium
            verticalCenter: lblName.verticalCenter
        }
    }

    Label {
        id: lblScreenNameFollow
        visible: model.type === "follow"
        text: '@'+account_username
        font.pixelSize: Theme.fontSizeExtraSmall
        color: ( pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor )
        width: parent.width - Theme.paddingMedium
        truncationMode: TruncationMode.Fade
        anchors {
            top: lblName.bottom
            left: parent.left
            leftMargin: Theme.paddingMedium
        }
    }

    // Thread indicator - shows position in conversation (e.g., "2/5")
    Label {
        id: lblThread
        visible: model.thread_total > 1
        text: model.thread_position + "/" + model.thread_total
        font.pixelSize: Theme.fontSizeTiny
        color: Theme.highlightColor
        horizontalAlignment: Text.AlignRight
        anchors {
            right: lblDate.left
            rightMargin: Theme.paddingSmall
            verticalCenter: lblName.verticalCenter
        }
    }

    // Reply indicator for timeline (shows when post is a reply but no thread info)
    Icon {
        id: icReplyIndicator
        visible: model.thread_total < 2 &&
                 model.status_in_reply_to_id !== null &&
                 model.status_in_reply_to_id !== ""
        source: "image://theme/icon-s-repost?" + Theme.secondaryColor
        width: Theme.iconSizeExtraSmall
        height: width
        anchors {
            right: lblDate.left
            rightMargin: Theme.paddingSmall
            verticalCenter: lblName.verticalCenter
        }
    }

    Label {
        id: lblDate
        text: Format.formatDate(created_at, new Date() - created_at < 60*60*1000 ? Formatter.DurationElapsedShort : Formatter.TimeValueTwentyFourHours)
        font.pixelSize: Theme.fontSizeExtraSmall
        color: ( pressed ? Theme.highlightColor : Theme.secondaryColor )
        horizontalAlignment: Text.AlignRight
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: lblName.verticalCenter
        }
    }
}
