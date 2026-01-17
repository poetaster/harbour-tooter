import QtQuick 2.0
import Sailfish.Silica 1.0


Item {
    id: miniStatus
    visible: true
    width: parent.width
    height: icon.height+Theme.paddingMedium

    Icon {
        id: icon
        visible: type.length
        color: Theme.highlightColor
        width: Theme.iconSizeExtraSmall
        height: width
        source: typeof typeIcon !== "undefined" ? typeIcon : ""
        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium
            left: parent.left
            leftMargin: Theme.horizontalPageMargin + Theme.iconSizeMedium - width
            bottomMargin: Theme.paddingMedium
        }
    }

    Label {
        id: lblRtByName
        visible: type.length
        text: {
            var action = "";
            switch(type){
            case "reblog":
                action =  qsTr('boosted');
                break;
            case "favourite":
                action =  qsTr('favourited');
                break;
            case "follow":
                action =  qsTr('followed you');
                break;
            default:
                miniStatus.visible = false
                action = type;
            }
            if (typeof reblog_account_username === "undefined") {
                return " "
            }
            var username = appWindow.fullUsernames && typeof reblog_account_acct !== "undefined"
                ? reblog_account_acct : reblog_account_username
            // Handle grouped notifications (v2 API)
            if (typeof notifications_count !== "undefined" && notifications_count > 1) {
                var others = notifications_count - 1
                return '@' + username + " " + qsTr('and %n other(s)', '', others) + " " + action
            }
            return '@' + username + " " + action
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        anchors {
            left: icon.right
            leftMargin: Theme.paddingMedium
            verticalCenter: icon.verticalCenter
        }
    }
}
