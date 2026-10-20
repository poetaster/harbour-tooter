import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic

Item {
    id: mnu
    visible: model.type !== "gap"
    height: Theme.itemSizeMedium
    width:delegate.width
    Row {
        spacing: 20

        Item {
            id: mnuFavourite
            visible: model.type !== "follow"
            width: mnu.width / 6
            height: icFA.height
            //text: typeof model.status_favourited !== "undefined" && model.status_favourited ? qsTr("Unfavorite") : qsTr("Favorite")
            MouseArea {
                anchors.fill: parent
                onClicked:  favourite()
            }
            Row {
                opacity: 0.5
                spacing: Theme.paddingSmall
                Icon {
                    id: icFA
                    source: "image://theme/icon-s-favorite?" + (!model.status_favourited ? Theme.highlightColor : Theme.primaryColor)
                    width: Theme.iconSizeSmallPlus
                    height: width
                }

                Label {
                    text: (status_favourites_count !== undefined) ? status_favourites_count : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: !model.status_favourited ? Theme.highlightColor : Theme.primaryColor
                }
            }
        }

        Item {
            id: mnuBoost
            width: mnu.width / 6
            height: icRT.height
            visible: model.type !== "follow"
            enabled: model.status_visibility !== "direct"
            //text: typeof model.status_reblogged !== "undefined" && model.status_reblogged ? qsTr("Unboost") : qsTr("Boost")
            MouseArea {
                anchors.fill: parent
                onClicked: boost()
            }
            Row {
                spacing: Theme.paddingSmall
                opacity: 0.5
                Icon {
                    id: icRT
                    source: "image://theme/icon-s-retweet?" + (!model.status_reblogged ? Theme.highlightColor : Theme.primaryColor)
                    width: Theme.iconSizeSmallPlus
                    height: width
                }

                Label {
                    text: (status_reblogs_count !== undefined) ? status_reblogs_count : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: !model.status_reblogged ? Theme.highlightColor : Theme.primaryColor
                }
            }
        }

        Item {
            id: mnuReply
            visible: model.type !== "follow"
            width: mnu.width / 6
            height: icReply.height
            //text: qsTr("Reply")
            MouseArea {
                anchors.fill: parent
                onClicked: reply()
            }
            Icon {
                opacity: 0.5
                id: icReply
                source: "image://theme/icon-s-message?" + Theme.highlightColor
                width: Theme.iconSizeSmallPlus
                height: width
            }
        }

        Item {
            id: mnuQuote
            width: mnu.width / 6
            height: icQuote.height
            visible: model.type !== "follow"
            enabled: model.status_visibility !== "direct"
            //text: qsTr("Quote")
            MouseArea {
                anchors.fill: parent
                onClicked: quote()
            }
            Label {
                opacity: 0.5
                id:icQuoteT
                visible: false
                text: "«»"
                font.pixelSize: Theme.fontSizeLarge
                color: !model.status_reblogged ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Icon {
                opacity: 0.5
                id: icQuote
                source: "image://theme/icon-s-clipboard?" + Theme.highlightColor
                width: Theme.iconSizeSmallPlus
                height: width
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

        }

        Item {
            id: mnuBookmark
            width: mnu.width / 6
            height: icBM.height
            visible: model.type !== "follow"
            //text: typeof model.status_bookmarked !== "undefined" && model.status_bookmarked ? qsTr("Remove Bookmark") : qsTr("Bookmark")
            MouseArea {
                anchors.fill: parent
                onClicked:  bookmark()
            }

            Icon {
                opacity: 0.5
                id: icBM
                source: "../../images/icon-s-bookmark.svg?"
                color: !model.status_bookmarked ? Theme.highlightColor : Theme.primaryColor
                width: Theme.iconSizeSmallPlus
                height: width
            }
        }

        Item {
            width: mnu.width / 6
            id: mnuMention
            height: icMT.height
            visible: model.type === "follow"
            //text: qsTr("Mention")
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (debug) console.log("link from mnuMention")
                    pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                                       headerTitle: qsTr("Mention"),
                                       username: "@"+reblog_account_acct,
                                       type: "new"
                                   })
                }
            }

            Icon {
                opacity: 0.5
                id: icMT
                source: "image://theme/icon-s-chat?" + (!model.status_favourited ? Theme.highlightColor : Theme.primaryColor)
                width: Theme.iconSizeSmallPlus
                height: width
            }
        }

    }
}
