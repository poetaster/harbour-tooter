import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import io.thp.pyotherside 1.5
import "../lib/API.js" as Logic


Page {
     property bool debug: false

    // Python connections and signals, callable from QML side
    // This is not ideal but keeps the page from erroring out on redirect
    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../lib/'));
            importModule('server', function () {});

              setHandler('finished', function(newvalue) {
                  if(debug) console.debug(newvalue)
              });
            startDownload();
        }
        function startDownload() {
            call('server.downloader.serve', function() {});
            if (debug) console.debug("called")

        }
   }

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
                                                  'http://localhost:8000/index.html', // redirect uri, we will need this later on
                                                  ["read", "write", "follow"], //scopes
                                                  "https://github.com/poetaster/harbour-tooter#readme", //website on the login screen
                                                  function(data) {

                                                      if (debug) console.log(data)
                                                      var conf = JSON.parse(data)
                                                      conf.instance = instance.text;
                                                      conf.login = false;

                                                      /*conf['login'] = false;
                                                        conf['mastodon_client_id'] = data['mastodon_client_id'];
                                                        conf['mastodon_client_secret'] = data['mastodon_client_secret'];
                                                        conf['mastodon_client_redirect_uri'] = data['mastodon_client_redirect_uri'];
                                                        delete Logic.conf;*/
                                                      Logic.conf = conf;
                                                      if(debug) console.log(JSON.stringify(conf))
                                                      if(debug) console.log(JSON.stringify(Logic.conf))
                                                      // we got our application

                                                      // our user to it!
                                                      var url = Logic.api.generateAuthLink(Logic.conf["client_id"],
                                                                                           Logic.conf["redirect_uri"],
                                                                                           "code", // oauth method
                                                                                           ["read", "write", "follow"] //scopes
                                                                                           );
                                                      if(debug) console.log(url)
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
    WebView {
        id: webView

        /* This will probably be required from 4.4 on. */
        Component.onCompleted: {
            WebEngineSettings.setPreference("security.disable_cors_checks", true, WebEngineSettings.BoolPref)
            WebEngineSettings.setPreference("security.fileuri.strict_origin_policy", false, WebEngineSettings.BoolPref)
        }
        onViewInitialized: {
            //webview.loadFrameScript(Qt.resolvedUrl("../html/framescript.js"));
            //webview.addMessageListener("webview:action");
            //webview.runJavaScript("return latlon('" + lat + "','" + lon + "')");
        }

        onRecvAsyncMessage: {
            if(debug) console.log('async changed: ' + url)
            if(debug) console.debug(message)
            switch (message) {
            case "embed:contentOrientationChanged":
                break
            case "webview:action":
                if ( data.topic != lon ) {
                    //webview.runJavaScript("return latlon('" + lat + "','" + lon + "')");
                    //if (debug) console.debug(data.topic)
                    //if (debug) console.debug(data.also)
                    //if (debug) console.debug(data.src)
                }
                break
            }
        }
        visible: false
        //opacity: 0
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        onLoadingChanged: {
            if(debug) console.log('loading changed: ' + url)
            if (
                    (url+"").substr(0, 38) === 'http://localhost:8000/index.html?code=' ||
                    (url+"").substr(0, 39) === 'https://localhost:8000/index.html?code='
                    ) {
                visible = false;

                var vars = {};
                (url+"").replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) { vars[key] = value;}); /* found on https://html-online.com/articles/get-url-parameters-javascript/ */

                var authCode = vars["code"];

                if(debug) console.log(authCode)

                Logic.api.getAccessTokenFromAuthCode(
                            Logic.conf["client_id"],
                            Logic.conf["client_secret"],
                            Logic.conf["redirect_uri"],
                            authCode,
                            function(data) {
                                // AAAND DATA CONTAINS OUR TOKEN!
                                if(debug) console.log(data)
                                data = JSON.parse(data)
                                if(debug) console.log(JSON.stringify(data))
                                if(debug) console.log(JSON.stringify(data.access_token))
                                Logic.conf["api_user_token"] = data.access_token
                                Logic.conf["login"] = true;
                                Logic.api.setConfig("api_user_token", Logic.conf["api_user_token"])
                                pageStack.replace(Qt.resolvedUrl("MainPage.qml"), {})
                            }
                            )
            }


            /*switch (loadRequest.status)
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
            }*/
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
