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
import "../lib/API.js" as Logic


CoverBackground {
    id: coverPage

    // App active state for timer frequency
    property bool appActive: Qt.application.state === Qt.ApplicationActive

    onStatusChanged: {
        switch (status ){
        case PageStatus.Activating:
            console.log("Cover: App minimized")
            checkNotifications()
            break;
        case PageStatus.Inactive:
            console.log("Cover: App active")
            break;
        }
    }

    Image {
        id: bg
        source: "../images/tooter-cover.svg"
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignBottom
        fillMode: Image.PreserveAspectFit
        anchors {
            bottom : parent.bottom
            left: parent.left
            right: parent.right
            top: parent.top
        }
    }

    Timer {
        id: timer
        // Same interval as notifications polling in MyList (12 minutes)
        interval: 12*60*1000
        triggeredOnStart: true
        running: true
        repeat: true
        onTriggered: checkNotifications()
    }

    Image {
        id: iconNot
        source: "image://theme/icon-s-alarm?" + Theme.highlightColor
        visible: notificationsLbl.text !== ""
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Theme.paddingLarge
            topMargin: Theme.paddingLarge
        }
    }

    Label {
        id: notificationsLbl
        text: ""
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.highlightColor
        anchors {
            left: iconNot.right
            leftMargin: Theme.paddingMedium
            verticalCenter: iconNot.verticalCenter
        }
    }

    // Update notification count when model changes
    Connections {
        target: Logic.modelTLnotifications || null
        onCountChanged: if (coverPage.status !== PageStatus.Inactive) checkNotifications()
    }

    // Clear notification count when user views notifications tab
    Connections {
        target: appWindow
        onNotificationsViewed: markNotificationsRead()
    }

    Label {
        text: "Tooter β"
        color: Theme.secondaryColor
        anchors {
            right: parent.right
            rightMargin: Theme.paddingLarge
            verticalCenter: iconNot.verticalCenter
        }
    }

    signal activateapp(string person, string notice)
    CoverActionList {
        id: coverAction
        /*CoverAction {
            iconSource: "image://theme/icon-cover-next"
             onTriggered: {
                 Logic.conf.notificationLastID = 0;
             }
        }*/

        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                pageStack.push(Qt.resolvedUrl("./../pages/ConversationPage.qml"), {
                                   headerTitle: qsTr("New Toot"),
                                   type: "new"
                               })
                appWindow.activate()
            }
        }
    }
    function checkNotifications(){
        console.log("checkNotifications")
        // Guard against access when model is not ready
        if (!Logic.modelTLnotifications) return

        var notificationsNum = 0
        var lastSeenTimestamp = Logic.conf.notificationLastTimestamp || 0

        for(var i = 0; i < Logic.modelTLnotifications.count; i++) {
            var item = Logic.modelTLnotifications.get(i)
            // Use created_at timestamp for comparison (works with both v1 and v2 API)
            var itemTimestamp = item.created_at ? new Date(item.created_at).getTime() : 0

            if (itemTimestamp > lastSeenTimestamp) {
                notificationsNum++
            }
        }

        notificationsLbl.text = notificationsNum > 0 ? notificationsNum : ""

        // Update last seen timestamp to the newest notification
        if (Logic.modelTLnotifications.count > 0) {
            var newestItem = Logic.modelTLnotifications.get(0)
            var newestTimestamp = newestItem.created_at ? new Date(newestItem.created_at).getTime() : 0
            if (newestTimestamp > lastSeenTimestamp) {
                // Only update when user views notifications tab (not here)
                // This keeps showing the count until user acknowledges
            }
        }
    }

    // Clear notification count when user views notifications
    function markNotificationsRead() {
        if (Logic.modelTLnotifications && Logic.modelTLnotifications.count > 0) {
            var newestItem = Logic.modelTLnotifications.get(0)
            Logic.conf.notificationLastTimestamp = newestItem.created_at ? new Date(newestItem.created_at).getTime() : 0
        }
        notificationsLbl.text = ""
    }

}
