import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import "../lib/API.js" as Logic
import "./components/"


Page {
    id: profilePage

    property ListModel tweets
    property string display_name: ""
    property string username: ""
    property string profileImage: ""
    property string profileBackground: ""
    property string note: ""
    property string url: ""
    property string user_id: ""
    property int statuses_count
    property int following_count
    property int followers_count
    property bool locked: false
    property bool bot: false
    property bool group: false
    property bool following: false
    property bool followed_by: false
    property bool requested: false
    property bool blocking: false
    property bool muting: false
    property bool domain_blocking: false
    property date created_at
    property bool debug: false

    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {
            if (debug) console.log(JSON.stringify(messageObject))
            if(messageObject.action.indexOf("accounts/search") > -1 ){
                user_id = messageObject.data.id
                followers_count = messageObject.data.followers_count
                following_count = messageObject.data.following_count
                username = messageObject.data.acct
                display_name = messageObject.data.display_name
                profileImage = messageObject.data.avatar_static
                profileBackground = messageObject.data.header_static

                var msg = {
                    'action'    : "accounts/relationships/",
                    'params'    : [ {name: "id[]", data: user_id}],
                    'conf'      : Logic.conf
                };
                worker.sendMessage(msg);
                list.loadData("prepend")
            }

            if(messageObject.action === "accounts/relationships/"){
                if (debug) console.log(JSON.stringify(messageObject))
                following = messageObject.data.following
                requested = messageObject.data.requested
                followed_by = messageObject.data.followed_by
                blocking = messageObject.data.blocking
                muting = messageObject.data.muting
                domain_blocking = messageObject.data.domain_blocking
            }
            switch (messageObject.key) {
            case 'followers_count':
                followers_count = messageObject.data
                break;
            case 'following_count':
                following_count = messageObject.data
                break;
            /* case 'acct':
                username = messageObject.data
                break; */
            case 'created_at':
                created_at = messageObject.data
                break;
            case 'statuses_count':
                statuses_count = messageObject.data
                break;
            case 'note':
                note = messageObject.data
                break;
            case 'url':
                url = messageObject.data
                break;
            case 'following':
                following = messageObject.data
                followers_count = followers_count + (following ? 1 : - 1)
                break;
            case 'muting':
                muting = messageObject.data
                break;
            case 'blocking':
                blocking = messageObject.data
                // followers_count = followers_count + (blocking ? -1 : 0)
                break;
            }
        }
    }

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All
    Component.onCompleted: {
        if (user_id) {
            worker.sendMessage({
                'action'    : "accounts/relationships/",
                'params'    : [ {name: "id[]", data: user_id} ],
                'conf'      : Logic.conf
            })

        } else {
            var user = username
            if (user.indexOf('@') == 0)
                user = user.slice(1)
            user = user.replace('@'+Logic.getActiveAccount().instance.split('//')[1], "")
            var resolve = user.indexOf('@') > -1

            if (resolve && Logic.getActiveAccount().type === 1)
                // With Pixelfed and "@" in q parameter, it returns 404 and crashes, so we disable this for now
                return

            worker.sendMessage({
                'action'    : "accounts/search?limit=1&q=" + user + '&resolve=' + resolve,
                'conf'      : Logic.conf
            })
        }
    }

    MyList {
        id: list
        header: ProfileHeader {
            id: profileHeader
            title: display_name
            description: username
            image: profileImage
            bg: profileBackground
        }
        clip: true
        mdl: ListModel {}
        type: "accounts/"+user_id+"/statuses"
        vars: {}
        conf: Logic.conf
        anchors {
            top: parent.top
            bottom: profileExpander.top
            left: parent.left
            right: parent.right
        }
    }

    // ProfilePage ExpandingSection
    ExpandingSectionGroup {
        id: profileExpander
        anchors.bottom: parent.bottom

        ExpandingSection {
            id: expandingSection1
            title:
                //: If there's no good translation for "About", use "Details" (in details about profile).
                qsTr("About")
            content.sourceComponent: Column {
                spacing: Theme.paddingLarge

                Item {
                    id: txtContainer
                    width: parent.width
                    height: profilePage.isPortrait ? Math.min( txtNote.height, parent.height * 0.5 ) :  Math.min( txtNote.height, parent.height * 0.2 )
                    /*visible: {
                        if ((note.text === "") || ( note.text === "<p></p>" )) {
                            false
                        } else {
                            true
                        }
                    }*/

                    SilicaFlickable {
                        id: txtFlickable
                        contentWidth: parent.width
                        contentHeight: txtNote.height
                        anchors.fill: parent
                        clip: true

                        VerticalScrollDecorator {}

                        Label {
                            id: txtNote
                            text: note
                            textFormat: Text.StyledText
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            linkColor: Theme.secondaryColor
                            wrapMode: Text.Wrap
                            width: parent.width - ( 2 * Theme.horizontalPageMargin )
                            anchors.horizontalCenter: parent.horizontalCenter
                            onLinkActivated: {
                                if (debug) console.log("ProfilePage link activated: " + link)

                                // Use the URL parser to detect Mastodon resource types
                                var parsed = Logic.parseMastodonUrl(link)

                                // For recognized Mastodon URLs, delegate to MainPage
                                if (parsed.type !== "unknown") {
                                    pageStack.pop(pageStack.find(function(page) {
                                        var check = page.isFirstPage === true
                                        if (check)
                                            page.onLinkActivated(link)
                                        return check
                                    }))
                                } else {
                                    // Unknown URL - open externally
                                    Qt.openUrlExternally(link)
                                }
                            }
                        }
                    }
                }

                Item {  // dummy item for spacing
                    height: Theme.paddingSmall
                }

                Row {
                    id: statsRow
                    spacing: Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.rightMargin: Theme.paddingLarge

                    Label {
                        id: txtFollowers
                        visible: true //followers_count ? true : false
                        text: followers_count+" "+
                              //: Will show as: "35 Followers"
                              qsTr("Followers")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                    }

                    Label {
                        id: txtFollowing
                        visible: true //following_count ? true : false
                        text: following_count+" "+
                              //: Will show as: "23 Following"
                              qsTr("Following")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                    }

                   Label {
                        id: txtStatuses
                        visible: true //statuses_count ? true : false
                        text: statuses_count+" "+
                              //: Will show as: "115 Statuses"
                              qsTr("Statuses")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: pressed ?  Theme.highlightColor : Theme.primaryColor
                        wrapMode: Text.Wrap

                        MouseArea {
                            anchors.fill: parent
                            onClicked: expandingSection1.expanded = false
                        }

                    }
                }

                Item {  // dummy item for spacing
                    height: Theme.paddingSmall
                }

                ButtonLayout {
                    id: btnLayout
                    Button {
                        id: btnMention
                        preferredWidth: Theme.buttonWidthSmall
                        text: qsTr("Mention")
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                                               headerTitle: qsTr("Mention"),
                                               username: "@"+username,
                                               type: "new"
                                           })
                        }
                    }

                    Button {
                        id: btnFollow
                        preferredWidth: Theme.buttonWidthSmall
                        text: (following ?
                                   //: Is a button. Keep it as short as possible.
                                   qsTr("Unfollow") : (requested ?
                                                           //: Is a button. Keep it as short as possible.
                                                           qsTr("Requested") :
                                                           //: Is a button. Keep it as short as possible.
                                                           qsTr("Follow")))
                        color: (following ? highlightColor : (requested ? palette.errorColor : palette.primaryColor))
                        onClicked: {
                            var msg = {
                                'method'    : 'POST',
                                'params'    : [],
                                'action'    : "accounts/" + user_id + (following ? '/unfollow':'/follow'),
                                'conf'      : Logic.conf
                            };
                            worker.sendMessage(msg);
                        }
                    }

                    Button {
                        id: btnMute
                        preferredWidth: Theme.buttonWidthSmall
                        text: (muting ?
                                   //: Is a button. Keep it as short as possible.
                                   qsTr("Unmute") :
                                   //: Is a button. Keep it as short as possible.
                                   qsTr("Mute"))
                        color: (muting ? palette.errorColor : palette.primaryColor)
                        onClicked: {
                            var msg = {
                                'method'    : 'POST',
                                'params'    : [],
                                'action'    : "accounts/" + user_id + (muting ? '/unmute':'/mute'),
                                'conf'      : Logic.conf
                            };
                            worker.sendMessage(msg);
                        }
                    }

                    Button {
                        id: btnBlock
                        preferredWidth: Theme.buttonWidthSmall
                        text: (blocking ?
                                   //: Is a button. Keep it as short as possible.
                                   qsTr("Unblock") :
                                   //: Is a button. Keep it as short as possible.
                                   qsTr("Block") )
                        color: (blocking ? palette.errorColor : palette.primaryColor)
                        onClicked: {
                            var msg = {
                                'method'    : 'POST',
                                'params'    : [],
                                'action'    : "accounts/" + user_id + (blocking ? '/unblock':'/block'),
                                'conf'      : Logic.conf
                            }
                            worker.sendMessage(msg)
                        }
                    }
                }

                Rectangle { // dummy item for spacing
                    height: Theme.paddingSmall
                    width: parent.width
                    opacity: 0
                }
            }
        }
    }
}
