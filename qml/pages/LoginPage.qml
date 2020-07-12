import QtQuick 2.0
import QtWebKit 3.0
import Sailfish.Silica 1.0
import "../lib/API.js" as Logic


Page {
    id: loginPage
    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width
            PageHeader {
                title: qsTr("Login")
            }

            SectionHeader {
                text: qsTr("Instance")
            }

            TextField {
                id: instance
                focus: true
                label: qsTr("Enter a valid Mastodon instance URL")
                text: "https://"
                width: parent.width
                validator: RegExpValidator { regExp: /^(ftp|http|https):\/\/[^ "]+$/ }
                EnterKey.enabled: instance.acceptableInput;
                EnterKey.highlighted: instance.acceptableInput;
                EnterKey.iconSource: "image://theme/icon-m-accept"
                EnterKey.onClicked: {
                    Logic.api = Logic.mastodonAPI({ instance: instance.text, api_user_token: "" });
                    Logic.api.registerApplication("Tooter",
                                                  'http://localhost/harbour-tooter', // redirect uri, we will need this later on
                                                  ["read", "write", "follow"], //scopes
                                                  "http://grave-design.com/harbour-tooter", //website on the login screen
                                                  function(data) {

                                                      console.log(data)
                                                      var conf = JSON.parse(data)
                                                      conf.instance = instance.text;
                                                      conf.login = false;

                                                      /*conf['login'] = false;
                                                        conf['mastodon_client_id'] = data['mastodon_client_id'];
                                                        conf['mastodon_client_secret'] = data['mastodon_client_secret'];
                                                        conf['mastodon_client_redirect_uri'] = data['mastodon_client_redirect_uri'];
                                                        delete Logic.conf;*/
                                                      Logic.conf = conf;
                                                      console.log(JSON.stringify(conf))
                                                      console.log(JSON.stringify(Logic.conf))
                                                      // we got our application

                                                      // our user to it!
                                                      var url = Logic.api.generateAuthLink(Logic.conf["client_id"],
                                                                                           Logic.conf["redirect_uri"],
                                                                                           "code", // oauth method
                                                                                           ["read", "write", "follow"] //scopes
                                                                                           );
                                                      console.log(url)
                                                      webView.url = url
                                                      webView.visible = true
                                                  }
                                                  );
                }
            }

            Label {
                id: serviceDescr
                text: qsTr("Mastodon is a free, open-source social network. A decentralized alternative to commercial platforms, it avoids the risks of a single company monopolizing your communication. Pick a server that you trust — whichever you choose, you can interact with everyone else. Anyone can run their own Mastodon instance and participate in the social network seamlessly.")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                wrapMode: Text.WordWrap
                width: parent.width
                anchors {
                    topMargin: Theme.paddingMedium
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
            }
        }
    }

    SilicaWebView {
        id: webView
        visible: false
        opacity: 0
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        onLoadingChanged: {
            console.log(url)
            if (
                    (url+"").substr(0, 37) === 'http://localhost/harbour-tooter?code=' ||
                    (url+"").substr(0, 38) === 'https://localhost/harbour-tooter?code='
                    ) {
                visible = false;

                var vars = {};
                (url+"").replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) { vars[key] = value;}); /* found on https://html-online.com/articles/get-url-parameters-javascript/ */

                var authCode = vars["code"];

                console.log(authCode)

                Logic.api.getAccessTokenFromAuthCode(
                            Logic.conf["client_id"],
                            Logic.conf["client_secret"],
                            Logic.conf["redirect_uri"],
                            authCode,
                            function(data) {
                                // AAAND DATA CONTAINS OUR TOKEN!
                                console.log(data)
                                data = JSON.parse(data)
                                console.log(JSON.stringify(data))
                                console.log(JSON.stringify(data.access_token))
                                Logic.conf["api_user_token"] = data.access_token
                                Logic.conf["login"] = true;
                                Logic.api.setConfig("api_user_token", Logic.conf["api_user_token"])
                                pageStack.replace(Qt.resolvedUrl("MainPage.qml"), {})
                            }
                            )
            }


            switch (loadRequest.status)
            {
            case WebView.LoadSucceededStatus:
                opacity = 1
                break
            case WebView.LoadFailedStatus:
                //opacity = 0
                break
            default:
                //opacity = 0
                break
            }
        }

        FadeAnimation on opacity {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload")
                onClicked: webView.reload()
            }
        }
    }
}
