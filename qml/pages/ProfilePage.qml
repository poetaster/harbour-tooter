import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/API.js" as Logic
import "./components/"
import QtGraphicalEffects 1.0


Page {
    id: profilePage
    property ListModel tweets
    property string display_name: ""
    property string username: ""
    property string profileImage: ""
    property int user_id
    property int statuses_count
    property int following_count
    property int followers_count
    property int favourites_count
    property int reblogs_count
    property int count_moments
    property string profileBackground: ""
    property string note: ""
    property string url: ""
    property bool locked: false
    property date created_at
    property bool following: false
    property bool requested: false
    property bool followed_by: false
    property bool blocking: false
    property bool muting: false
    property bool domain_blocking: false

    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {
            console.log(JSON.stringify(messageObject))
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
                    'params'    : [ {name: "id", data: user_id}],
                    'conf'      : Logic.conf
                };
                worker.sendMessage(msg);
                list.loadData("prepend")
            }

            if(messageObject.action === "accounts/relationships/"){
                console.log(JSON.stringify(messageObject))
                following= messageObject.data.following
                requested= messageObject.data.requested
                followed_by= messageObject.data.followed_by
                blocking= messageObject.data.blocking
                muting= messageObject.data.muting
                domain_blocking= messageObject.data.domain_blocking
            }
            switch (messageObject.key) {
            case 'followers_count':
                followers_count = messageObject.data
                break;
            case 'following_count':
                following_count = messageObject.data
                break;
            case 'acct':
                // line below was commented out, reason unknown
                // username = messageObject.data
                break;
            case 'locked':
                locked = messageObject.data
                break;
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
                followers_count = followers_count + (blocking ? -1 : 0)
                break;
            case 'followed_by':
                followed_by = messageObject.data
                break;
            }
        }
    }
    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All
    Component.onCompleted: {
        var msg

        if (user_id) {
            msg = {
                'action'    : "accounts/relationships/",
                'params'    : [ {name: "id", data: user_id}],
                'conf'      : Logic.conf
            }
            worker.sendMessage(msg)
            msg = {
                'action'    : "accounts/"+user_id,
                'conf'      : Logic.conf
            }
            worker.sendMessage(msg)
        } else {
            var instance = Logic.conf['instance'].split("//")
            msg = {
                'action'    : "accounts/search?limit=1&q="+username.replace("@"+instance[1], ""),
                'conf'      : Logic.conf
            }
            worker.sendMessage(msg)
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
        anchors {
            top: parent.top
            bottom: expander.top
            left: parent.left
            right: parent.right
        }
        clip: true
        mdl: ListModel {}
        type: "accounts/"+user_id+"/statuses"
        vars: {}
        conf: Logic.conf
    }

    // ProfilePage ExpandingSection
    ExpandingSectionGroup {
        id: expander
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        ExpandingSection {
            id: expandingSection1
            title: qsTr("About")
            content.sourceComponent: Column {
                height: Math.min(txtContainer, parent.height*0.7)
                spacing: Theme.paddingSmall
                anchors.bottomMargin: Theme.paddingLarge

                Rectangle {
                    id: txtContainer
                    width: expander.width
                    height: Math.min(txtNote.height, parent.height*0.488)
                    color: "transparent"
                    visible: {
                        if ((note.text === "") && (note.text === "<p></p>") ) {
                            false
                        } else {
                            true
                        }
                    }
                    SilicaListView {
                        id: txtFlickable
                        anchors.fill: txtContainer
                        clip: true
                        quickScroll: false
                        VerticalScrollDecorator { flickable: txtNote }

                        Text {
                            id: txtNote
                            text: note
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            linkColor: Theme.highlightColor
                            width: parent.width - ( 2 * Theme.horizontalPageMargin )
                            anchors.horizontalCenter: parent.horizontalCenter
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
                                    /*  Function still missing for user accounts */
                                    //  } else if (test.length === 4 && test[3][0] === "@" ) {
                                } else {
                                    Qt.openUrlExternally(link);
                                }
                            }
                        }
                    }
                }

                Row {
                    id: statsRow
                    spacing: Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.rightMargin: Theme.paddingLarge
                    Text {
                        id: txtFollowers
                        visible: followers_count ? true : false
                        text: followers_count+" "+qsTr("Followers")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                    }
                    Text {
                        id: txtFollowing
                        visible: following_count ? true : false
                        text: following_count+" "+qsTr("Following")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                    }
                    Text {
                        id: txtStatuses
                        visible: statuses_count ? true : false
                        text: statuses_count+" "+qsTr("Statuses")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                    }
                    /*Text {
                        id: txtFavourites
                        visible: favourites_count ? true : false
                        text: favourites_count+" "+qsTr("Favourites")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                    } */
                }

                Label {
                    id: separatorLabel1
                    x: Theme.horizontalPageMargin
                    width: parent.width  - ( 2 * Theme.horizontalPageMargin )
                    font.pixelSize: Theme.fontSizeExtraSmall
                    wrapMode: Text.Wrap
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                ButtonLayout {
                    id: btnLayout
                    Button {
                        id: btnMention
                        preferredWidth: Theme.buttonWidthSmall
                        text: "Mention"
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                                               headerTitle: "Mention",
                                               description: "@"+username,
                                               type: "new"
                                           })
                        }
                    }

                    Button {
                        id: btnFollow
                        preferredWidth: Theme.buttonWidthSmall
                        text: (following ? qsTr("Unfollow") : (requested ? qsTr("Requested") : qsTr("Follow")))
                        color: (following ? highlightColor : (requested ? palette.errorColor : palette.primaryColor))
                        onClicked: {
                            var msg = {
                                'method'    : 'POST',
                                'params'    : [],
                                'action'    : "accounts/" + user_id + (following ? '/unfollow':'/follow'),
                                'conf'      : Logic.conf
                            };
                            worker.sendMessage(msg);
                            // to-do: create notification banner "Follow request sent!"
                        }
                    }
                    Button {
                        id: btnMute
                        preferredWidth: Theme.buttonWidthSmall
                        text: (muting ?  qsTr("Unmute") : qsTr("Mute"))
                        color: (muting ? highlightColor : palette.primaryColor)
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
                        text: (blocking ? qsTr("Unblock") : qsTr("Block") )
                        color: (blocking ? palette.errorColor : palette.primaryColor)
                        onClicked: {
                            var msg = {
                                'method'    : 'POST',
                                'params'    : [],
                                'action'    : "accounts/" + user_id + (blocking ? '/unblock':'/block'),
                                'conf'      : Logic.conf
                            };
                            worker.sendMessage(msg);
                        }
                    }
                }

                Separator {
                    id: btnSeparator
                    width: parent.width
                    height: Theme.paddingMedium
                    color: Theme.primaryColor
                    opacity: 0.0
                    horizontalAlignment: Qt.AlignHCenter
                }

                Button {
                    id: btnBrowser
                    text: qsTr("Open in Browser")
                    preferredWidth: Theme.buttonWidthMedium
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                    onClicked: {
                        Qt.openUrlExternally(url);
                    }
                }

                Label {
                    id: separatorLabel2
                    x: Theme.horizontalPageMargin
                    width: parent.width  - ( 2 * Theme.horizontalPageMargin )
                    font.pixelSize: Theme.fontSizeExtraSmall
                    wrapMode: Text.Wrap
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

            }
        }
    }
}
