/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import "pages"
import "./lib/API.js" as Logic

ApplicationWindow {
    id: appWindow
    allowedOrientations: defaultAllowedOrientations
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    property bool debug: true
    // Global font scale property - reactive, updates UI immediately
    property real fontScale: 1.0
    // Global quick scroll setting - reactive
    property bool quickScrollEnabled: true
    // Global notify setting - reactive
    property bool notify: false
    // Global notificationIds
    property var notificationIds: []

    // Instance max characters - fetched from server, default to 500
    property int instanceMaxChars: 500

    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {

            if (debug) console.log(JSON.stringify(messageObject))

            if (messageObject.action === "v2/search" && messageObject.mode === "resolveUrl") {
                if (messageObject.statuses && messageObject.statuses.length > 0) {
                    var status = messageObject.statuses[0]
                    if (debug) console.log("Resolved status: " + status.status_id)
                    // Open in ConversationPage
                    var m = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles:true }', Qt.application, 'InternalQmlObject')
                    pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {
                                       headerTitle: qsTr("Conversation"),
                                       "status_id": status.status_id,
                                       "status_url": status.status_url,
                                       "status_uri": status.status_uri,
                                       mdl: m,
                                       type: "reply"
                                   })
                } else {
                    // Status not found - open URL externally
                    if (debug) console.log("Status not found, opening externally: " + messageObject.originalUrl)
                    Qt.openUrlExternally(messageObject.originalUrl)
                }
            }
        }
    }
    Component.onCompleted: {
        var obj = {}
        Logic.mediator.installTo(obj)
        obj.subscribe('confLoaded', function() {
            //console.log('confLoaded');
            //console.log(JSON.stringify(Logic.conf))
            if (!Logic.conf['notificationLastID'])
                Logic.conf['notificationLastID'] = 0
            if (!Logic.conf['accounts'])
                Logic.conf['accounts'] = []
            if (typeof Logic.conf['fontScale'] !== "undefined")
                appWindow.fontScale = Logic.conf['fontScale']
            if (typeof Logic.conf['quickScroll'] !== "undefined")
                appWindow.quickScrollEnabled = Logic.conf['quickScroll']
            if (typeof Logic.conf['notify'] !== "undefined")
                appWindow.notify = Logic.conf['notify']

            var oldAccountParameters = ['api_user_token', 'instance', 'login']
            if (oldAccountParameters.every(function(el) { return el in Logic.conf })) {
                if (!('type' in Logic.conf))
                    Logic.conf.type = 0
                oldAccountParameters.push('type')

                var account = {}
                oldAccountParameters.forEach(function(el) {
                    account[el] = Logic.conf[el]
                    Logic.conf[el] = null
                })
                Logic.conf.accounts.push(account)
                Logic.conf.activeAccount = Logic.conf.accounts.length - 1
            }

            var currentAccount = Logic.getActiveAccount()

            if (currentAccount.instance) {
                Logic.api = Logic.mastodonAPI({
                                                  "instance": currentAccount.instance,
                                                  "api_user_token": ""
                                              })
            }

            if (currentAccount.login) {
                //Logic.conf['notificationLastID'] = 0
                Logic.api.setConfig('api_user_token', currentAccount['api_user_token'])
                pageStack.push(Qt.resolvedUrl("./pages/MainPage.qml"))
            } else {
                pageStack.clear() // FIXME: is this really needed?
                pageStack.push(Qt.resolvedUrl("./pages/LoginPage.qml"))
            }
        })
        Logic.init()
    }

    // Resolve a status URL and open it in ConversationPage
    function resolveStatusUrl(url,encoded) {
        if ( ! encoded) url = encodeURIComponent(url)
        if (debug) console.log("Resolving status URL: " + url)
        worker.sendMessage({
            action: "v2/search",
            mode: "resolveUrl",
            params: [
                { name: "q", data: url },
                { name: "resolve", data: "true" },
                { name: "type", data: "statuses" },
                { name: "limit", data: "1" }
            ],
            conf: Logic.conf,
            originalUrl: url
        })
    }
    function openUrl(u) {
        console.log("openUrl called via DBus:" + u)
        // Use the URL parser to detect Mastodon resource types
        var url = u.toString()
        var username
        var searchUrl = url
        if (url.indexOf("?uri") !== -1) {
            url = url.split("?")[1]
            url = url.split("=")[1]
            searchUrl = Logic.seqDecode(url)
        }
        var parsed = Logic.parseMastodonUrl(searchUrl)
        username = parsed.username

        // For recognized Mastodon URLs (tag, profile, status), delegate to MainPage
        if (parsed.type === "status"){
            resolveStatusUrl(url,true)
            //loader.sourceComponent = loading
            //searchField.text = '@' + username
            //tlSearch.search = searchField.text
            // slideshow.positionViewAtIndex(5, ListView.SnapToItem)
        } else if (parsed.type !== "unknown") {
            pageStack.pop(pageStack.find(function(page) {
                var check = page.isFirstPage === true
                if (check)
                    page.onLinkActivated(u.toString())
                return check
            }))
        }
        //activate()
    }

    Component.onDestruction: {
        //Logic.conf.notificationLastID = 0;
        Logic.saveData()
    }

}
