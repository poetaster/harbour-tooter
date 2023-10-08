import QtQuick 2.0
import Sailfish.Silica 1.0
import Amber.Web.Authorization 1.0
import "../lib/API.js" as Logic




Page {
     property bool debug: false

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

            OAuth2Ac {
                id: mastodonOAuth
                authorizationEndpoint: instance.text + "/oauth/authorize"
                tokenEndpoint: instance.text + "/oauth/token"
                scopes: ["read", "write", "follow"]
                redirectListener.port: 7538

                onErrorOccurred: console.log("Mastodon OAuth2 Error: " + error.code + " = " + error.message + " : " + error.httpCode)

                onReceivedAuthorizationCode: {
                    console.log("Got auth code, about to request token.")
                }

                onReceivedAccessToken: {
                    console.log("Got access token: " + token.access_token)
                    Logic.conf["api_user_token"] = token.access_token
                                Logic.conf["login"] = true;
                                Logic.api.setConfig("api_user_token", Logic.conf["api_user_token"])
                                pageStack.replace(Qt.resolvedUrl("MainPage.qml"), {})
                            }
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
                                                  "http://127.0.0.1:7538", 
                                                  ["read", "write", "follow"], //scopes
                                                  "https://github.com/poetaster/harbour-tooter#readme", //website on the login screen
                                                  function(data) {

                                                      if (debug) console.log(data)
                                                      var conf = JSON.parse(data)
                                                      conf.instance = instance.text;
                                                      conf.login = false;

                                                      Logic.conf = conf;
                                                      if(debug) console.log(JSON.stringify(conf))
                                                      if(debug) console.log(JSON.stringify(Logic.conf))
                                                      // we got our application

                                                      mastodonOAuth.clientId = conf["client_id"]
                                                      mastodonOAuth.clientSecret = conf["client_secret"];

                                                      mastodonOAuth.authorizeInBrowser()
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
}
