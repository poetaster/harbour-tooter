import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic
import "."


SilicaListView {
    id: myList

    property string type
    property string title
    property string description
    property ListModel mdl: []
    property variant params: []
    property var locale: Qt.locale()
    property bool autoLoadMore: true
    property bool loadStarted: false
    property int scrollOffset
    property string action: ""
    property variant vars
    property variant conf
    property bool notifier: false

    model:  mdl

    signal notify (string what, int num)
    onNotify: {
        console.log(what + " - " + num)
    }
    signal openDrawer (bool setDrawer)
    onOpenDrawer: {
        //console.log("Open drawer: " + setDrawer)
    }
    signal send (string notice)
    onSend: {
        console.log("LIST send signal emitted with notice: " + notice)
    }

    header: PageHeader {
        title: myList.title
        description: myList.description
    }

    BusyIndicator {
        size: BusyIndicatorSize.Large
        running: myList.model.count === 0 && !viewPlaceHolder.visible
        anchors.centerIn: parent
    }

    ViewPlaceholder {
        id: viewPlaceHolder
        enabled: model.count === 0
        text: qsTr("Loading")
        hintText: qsTr("please wait...")
        anchors.centerIn: parent
    }

    PullDownMenu {

        MenuItem {
            text: qsTr("Settings")
            visible: !profilePage
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../SettingsPage.qml"), {})
            }
        }

        MenuItem {
            text: qsTr("New Toot")
            visible: !profilePage
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                                   headerTitle: qsTr("New Toot"),
                                   type: "new"
                               })
            }
        }

        MenuItem {
            text: qsTr("Open in Browser")
            visible: !mainPage
            onClicked: {
                Qt.openUrlExternally(url)
            }
        }

        MenuItem {
            text: qsTr("Reload")
            onClicked: {
                loadData("prepend")
            }
        }
    }

    delegate: VisualContainer {}

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 800 }
        NumberAnimation { property: "x"; duration: 800; easing.type: Easing.InOutBack }
    }

    remove: Transition {
        NumberAnimation { properties: "x,y"; duration: 800; easing.type: Easing.InOutBack }
    }

    onCountChanged: {
        loadStarted = false
        /*contentY = scrollOffset
        console.log("CountChanged!")*/
    }

    footer: Item {
        visible: autoLoadMore
        width: parent.width
        height: Theme.itemSizeLarge
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.paddingSmall
            anchors.bottomMargin: Theme.paddingLarge
            visible: false
            onClicked: {
                loadData("append")
            }
        }

        BusyIndicator {
            size: BusyIndicatorSize.Small
            running: loadStarted;
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    onContentYChanged: {
        if (Math.abs(contentY - scrollOffset) > Theme.itemSizeMedium) {
            openDrawer(contentY - scrollOffset  > 0 ? false : true )
            scrollOffset = contentY
        }
        if(contentY+height > footerItem.y && !loadStarted && autoLoadMore) {
            loadData("append")
            loadStarted = true
        }
    }

    VerticalScrollDecorator {}

    WorkerScript {
        id: worker
        source: "../../lib/Worker.js"
        onMessage: {
            if (messageObject.error){
                console.log(JSON.stringify(messageObject))
            }
            if (messageObject.fireNotification && notifier){
                Logic.notifier(messageObject.data)
            }
        }
    }

    Component.onCompleted: {
        loadData("prepend")
    }

    Timer {
        triggeredOnStart: false; interval: 5*60*1000; running: true; repeat: true
        onTriggered: {
            console.log(title + ' ' +Date().toString())
            loadData("prepend")
        }
    }

    function loadData(mode) {
        var p = []
        if (params.length)
            for(var i = 0; i<params.length; i++)
                p.push(params[i])

        if (mode === "append" && model.count) {
            p.push({name: 'max_id', data: model.get(model.count-1).id})
        }
        if (mode === "prepend" && model.count) {
            p.push({name:'since_id', data: model.get(0).id})
        }

        var msg = {
            'action'    : type,
            'params'    : p,
            'model'     : model,
            'mode'      : mode,
            'conf'      : Logic.conf
        }

        console.log(JSON.stringify(msg))
        if (type !== "")
            worker.sendMessage(msg)
    }
}
