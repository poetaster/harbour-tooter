import QtQuick 2.0
import Sailfish.Silica 1.0


Item {
    id: miniHeader
    height: lblName.height
    width: parent.width

    Label {
        id: lblName
        text: account_display_name ? account_display_name : (typeof account_username !== "undefined" && account_username ? account_username.split('@')[0] : "")
        font.weight: Font.Bold
        font.pixelSize: Theme.fontSizeSmall
        color: if ( model && myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
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
        visible: model && model.type !== "follow"
        text: '@' + (appWindow.fullUsernames && typeof account_acct !== "undefined" ? account_acct : (typeof account_username !== "undefined" ? account_username : ""))
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
        visible: model && model.type === "follow"
        text: '@' + (appWindow.fullUsernames && typeof account_acct !== "undefined" ? account_acct : (typeof account_username !== "undefined" ? account_username : ""))
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
