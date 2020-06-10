import QtQuick 2.0
import Sailfish.Silica 1.0


Item {
    id: miniHeader
    height: lblName.height
    width: parent.width

    Label {
        id: lblName
        text:
            if (account_display_name === "") {
                account_username.split('@')[0]
            }
            else account_display_name
        font.weight: Font.Bold
        font.pixelSize: Theme.fontSizeSmall
        color: if (myList.type === "notifications" && ( model.type === "favourite" || model.type === "reblog" )) {
                   (pressed ? Theme.secondaryHighlightColor : (!highlight ? Theme.secondaryColor : Theme.secondaryHighlightColor))
               } else (pressed ? Theme.highlightColor : (!highlight ? Theme.primaryColor : Theme.secondaryColor))
        truncationMode: TruncationMode.Fade
        width: contentWidth > parent.width /2 ? parent.width /2 : contentWidth
        anchors {
            left: parent.left
            leftMargin: Theme.paddingMedium
        }
    }

    Image {
        id: icnLocked
        visible: account_locked
        opacity: 0.8
        source: "image://theme/icon-s-secure?" + (pressed ? Theme.highlightColor : Theme.primaryColor)
        width: account_locked ? Theme.iconSizeExtraSmall*0.8 : 0
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
        text: '@'+account_username
        font.pixelSize: Theme.fontSizeExtraSmall
        color: (pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor)
        truncationMode: TruncationMode.Fade
        anchors {
            left: icnLocked.right
            right: lblDate.left
            leftMargin: Theme.paddingMedium
            baseline: lblName.baseline
        }
    }

    Label {
        id: lblDate
        text: Format.formatDate(created_at, new Date() - created_at < 60*60*1000 ? Formatter.DurationElapsedShort : Formatter.TimeValueTwentyFourHours)
        font.pixelSize: Theme.fontSizeExtraSmall
        color: (pressed ? Theme.highlightColor : Theme.primaryColor)
        horizontalAlignment: Text.AlignRight
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            baseline: lblName.baseline
        }
    }

}
