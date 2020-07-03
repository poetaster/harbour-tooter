import QtQuick 2.0
import Sailfish.Silica 1.0


BackgroundItem {
    id: delegate

    signal openUser (string notice)

    width: parent.width
    height: Theme.itemSizeMedium

    Item {
        id: avatar
        width: Theme.itemSizeExtraSmall
        height: width
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin

        Image {
            id: img
            opacity: status === Image.Ready ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }
            anchors.fill: parent
            source: model.account_avatar
        }

        BusyIndicator {
            size: BusyIndicatorSize.Small
            opacity: img.status === Image.Ready ? 0.0 : 1.0
            Behavior on opacity { FadeAnimator {} }
            running: avatar.status !== Image.Ready
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pageStack.push(Qt.resolvedUrl("./../ProfilePage.qml"), {
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
                                      })
        }
    }

    Item {
        id: userDescription
        height: account_acct.height + display_name.height
        anchors.left: avatar.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter

        Label {
            id: display_name
            text: account_display_name ? account_display_name : account_username.split('@')[0]
            color: !pressed ? Theme.primaryColor : Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            truncationMode: TruncationMode.Fade
            width: parent.width - Theme.paddingMedium
            anchors.top: parent.top
        }

        Label {
            id: account_acct
            text: "@"+model.account_acct
            color: !pressed ?  Theme.secondaryColor : Theme.secondaryHighlightColor
            anchors.leftMargin: Theme.paddingMedium
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            width: parent.width - Theme.paddingMedium
            anchors.top: display_name.bottom
        }
    }

    onClicked: openUser( {
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
