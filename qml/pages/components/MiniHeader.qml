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
        width: contentWidth > parent.width /2 ? parent.width /2 : contentWidth
        anchors.left: parent.left
    }

    Icon {
        id: icnBot
        visible: account_bot
        source: "../../images/icon-s-bot.svg?" + ( pressed ? Theme.highlightColor : Theme.primaryColor )
        color: Theme.primaryColor
        width: account_bot ? Theme.iconSizeExtraSmall * 1.3 : 0
        height: width
        y: Theme.paddingLarge
        anchors {
            left: lblName.right
            leftMargin: Theme.paddingSmall
            verticalCenter: lblName.verticalCenter
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
            left: icnBot ? icnBot.right : icnLocked.right
            leftMargin: Theme.paddingSmall
            right: lblDate.left
            rightMargin: Theme.paddingMedium
            verticalCenter: lblName.verticalCenter
        }
    }

    Label {
        id: lblScreenNameFollow
        visible: model.type === "follow" && myList.type === "notifications"
        text: '@'+account_username
        font.pixelSize: Theme.fontSizeExtraSmall
        color: ( pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor )
        truncationMode: TruncationMode.Fade
        anchors {
            left: parent.left
            top: lblName.bottom
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
            verticalCenter: lblName.verticalCenter
        }
    }
}
