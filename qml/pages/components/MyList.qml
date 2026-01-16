import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic
import "."


SilicaListView {
    id: myList

    clip: true

    property bool debug: false
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
    // should consider better names or
    // using min_ & max_id
    property string linkprev: ""
    property string linknext: ""
    property variant vars
    property variant conf
    property bool notifier: false
    property bool deduping: false
    property bool reachedEnd: false  // Flag to stop loading when timeline ends
    property bool hasLoadedOnce: false  // Lazy loading: track if initial load done
    property bool isCurrentTab: false   // Lazy loading: is this tab currently visible

    // Gap detection: track state before prepend to detect gaps
    property int prePrependCount: 0
    property string prePrependTopId: ""

    // Model generation counter - incremented on any structural model change
    // Used to detect and discard stale async operation results
    property int modelGeneration: 0

    // Operation mutex - prevents concurrent model modifications
    property bool gapFillInProgress: false

    // Lazy loading: load data when tab becomes visible for the first time
    onIsCurrentTabChanged: {
        if (isCurrentTab && !hasLoadedOnce) {
            if (debug) console.log("Lazy loading: " + title)
            loadData("prepend")
            hasLoadedOnce = true
        }
    }

    model:  mdl

    signal notify (string what, int num)
    onNotify: {
        if(debug) console.log(what + " - " + num)
    }
    signal openDrawer (bool setDrawer)
    onOpenDrawer: {
        //console.log("Open drawer: " + setDrawer)
    }
    signal send (string notice)
    onSend: {
        if (debug) console.log("LIST send signal emitted with notice: " + notice)
    }

    header: PageHeader {
        title: myList.title
        description: myList.description
    }

    BusyLabel {
        id: myListBusyLabel
        running: model.count === 0 && timeoutTimer.running && !remove.running
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        Timer {
            id: timeoutTimer
            interval: 5000
            running: true
        }
    }

    ViewPlaceholder {
        id: loadStatusPlaceholder
        enabled: model.count === 0 && !myListBusyLabel.running && !remove.running
        text: hasLoadedOnce ? qsTr("Nothing found") : qsTr("Loading...")
    }

    PullDownMenu {
        id: mainPulleyMenu
        MenuItem {
            text: qsTr("Settings")
            visible: ! parent.profilePage
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../SettingsPage.qml"), {})
            }
        }
        MenuItem {
            text: qsTr("My Profile")
            visible: ! parent.profilePage
            onClicked: {
                var activeAccount = Logic.conf.accounts && Logic.conf.accounts[Logic.conf.activeAccount]
                if (activeAccount && activeAccount.userInfo) {
                    var user = activeAccount.userInfo
                    pageStack.push(Qt.resolvedUrl("../ProfilePage.qml"), {
                        "display_name": user.account_display_name,
                        "username": user.account_acct || user.account_username,
                        "user_id": user.account_id,
                        "profileImage": user.account_avatar,
                        "profileBackground": user.account_header,
                        "note": user.account_note,
                        "url": user.account_url,
                        "followers_count": user.account_followers_count,
                        "following_count": user.account_following_count,
                        "statuses_count": user.account_statuses_count,
                        "locked": user.account_locked,
                        "bot": user.account_bot,
                        "group": user.account_group
                    })
                }
            }
        }
        MenuItem {
            text: qsTr("New Toot")
            visible: ! parent.profilePage
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../ConversationPage.qml"), {
                                   headerTitle: qsTr("New Toot"),
                                   type: "new"
                               })
            }
        }

        MenuItem {
            text: qsTr("Open in Browser")
            visible: typeof mainPage === 'undefined'
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
        if (debug) console.log("count changed on: " + title)
        //deDouble()
        //loadStarted = false

        /*contentY = scrollOffset
        console.log("CountChanged!")*/
        if (count === 0) {
            loadData("prepend")
            timeoutTimer.start()
        }
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
                if (!loadStarted && !deduping) loadData("append")
            }
        }

        BusyIndicator {
            running: loadStarted
            visible: myListBusyLabel.running ? false : true
            size: BusyIndicatorSize.Small
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    onContentYChanged: {
        if (Math.abs(contentY - scrollOffset) > Theme.itemSizeMedium) {
            openDrawer(contentY - scrollOffset  > 0 ? false : true )
            scrollOffset = contentY
        }
        // Check all mutexes before triggering append
        if(footerItem && contentY+height > footerItem.y && !deduping && !loadStarted && !gapFillInProgress && autoLoadMore && !reachedEnd) {
                loadStarted = true
                console.log("Loading more: " + title + " (append)")
                loadData("append")
        }
    }

    VerticalScrollDecorator {}

    WorkerScript {
        id: worker
        source: "../../lib/Worker.js"
        onMessage: {
            if (messageObject.error){
                if (debug) console.log(JSON.stringify(messageObject))
            } else {
                if (debug) console.log(JSON.stringify(messageObject))
                // loadStarted = false
            }

            if (messageObject.fireNotification && notifier){
                Logic.notifier(messageObject.data)
            }

            // temporary debugging measure
            if (messageObject.updatedAll){
                console.log(title + ": Got all, count=" + model.count + ", itemsCount=" + messageObject.itemsCount + ", resetting loadStarted")
                // Only dedupe when no gap fill in progress to avoid invalidating indices
                if (model.count > 20 && !gapFillInProgress) deDouble()

                // Gap detection: check if there might be a gap after prepend
                // Do this BEFORE setting loadStarted=false to prevent immediate re-trigger
                if (messageObject.mode === "prepend" && messageObject.itemsCount > 0 && prePrependCount > 0) {
                    checkForGap(messageObject.itemsCount)
                }
                // Reset gap tracking state
                prePrependCount = 0
                prePrependTopId = ""

                loadStarted = false

                // Detect end of timeline: API returned 0 items in append mode
                if (messageObject.mode === "append" && messageObject.itemsCount === 0) {
                    console.log(title + ": Reached end of timeline")
                    reachedEnd = true
                }
                // Reset reachedEnd on successful prepend (user refreshed)
                if (messageObject.mode === "prepend" && messageObject.itemsCount > 0) {
                    reachedEnd = false
                }

                // Handle gap fill completion
                if (messageObject.mode === "fillgap") {
                    handleGapFillComplete(messageObject)
                }
            }

            // the api  is stupid
            if (messageObject.LinkHeader) {
                // <https://mastodon.gamedev.place/api/v1/bookmarks?max_id=11041>; rel=\"next\",
                // <https://mastodon.gamedev.place/api/v1/bookmarks?min_id=14158>; rel=\"prev\""

                var matches = /max_id=([0-9]+)/.exec(messageObject.LinkHeader);
                var maxlink = matches[0].split("=")[1];
                var matches = /min_id=([0-9]+)/.exec(messageObject.LinkHeader);
                var minlink = matches[0].split("=")[1];
                if (debug) console.log("maxlink: " + maxlink)
                if (debug) console.log("minlink: " + minlink)
                linkprev = maxlink
                linknext = minlink
            }
        }
    }

    Component.onCompleted: {
        // Lazy loading: don't load data here, wait for isCurrentTab to be set
        if (debug) console.log("MyList completed: " + title)
    }

    Timer {
        triggeredOnStart: false;
        interval: {
            // Varied intervals so server isn't hit simultaneously
            var listInterval = Math.floor(Math.random() * 60)*10*1000
            if( title === "Home" ) listInterval = 20*60*1000
            if( title === "Local" ) listInterval = 10*60*1000
            if( title === "Federated" ) listInterval = 30*60*1000
            if( title === "Bookmarks" ) listInterval = 40*60*1000
            if( title === "Notifications" ) listInterval = 12*60*1000

            if(debug) console.log(title + ' interval: ' + listInterval)

            return listInterval
        }
        // Only run timer for current tab, but always run for notifications (badge updates)
        running: isCurrentTab || notifier
        repeat: true
        onTriggered: {
            if(debug) console.log(title + ' ' + Date().toString())
            // Avoid concurrent operations - check all mutexes
            if ( ! loadStarted && ! deduping && ! gapFillInProgress ) loadData("prepend")
        }
    }

    /*
    * Deduplication utility - O(n) implementation using hash lookup
    * Called on updates to model to remove duplicates
    */
    function deDouble(){
        deduping = true

        try {
            if (debug) console.log("deDouble: model count = " + model.count)

            var seen = {}
            var toRemove = []

            // Single pass: find duplicates using hash for O(1) lookup
            for (var i = 0; i < model.count; i++) {
                var item = model.get(i)
                if (!item) continue
                var id = item.id
                if (!id) continue
                if (seen[id]) {
                    toRemove.push(i)
                    if (debug) console.log("Duplicate found at index " + i + ": " + id)
                } else {
                    seen[id] = true
                }
            }

            // Remove duplicates in reverse order to preserve indices
            for (var j = toRemove.length - 1; j >= 0; j--) {
                model.remove(toRemove[j], 1)
            }

            if (toRemove.length > 0) {
                modelGeneration++  // Increment generation on structural change
                if (debug) console.log("Removed " + toRemove.length + " duplicates (gen=" + modelGeneration + ")")
            }
        } catch (e) {
            console.log("deDouble error: " + e)
        }

        deduping = false
    }

    /* Principle load function, uses websocket's worker.js
    *
    */

    function loadData(mode) {

        if (debug) console.log('loadData called: ' + mode + " in " + title)

        // Prevent loading during gap fill to avoid index confusion
        if (gapFillInProgress && mode !== "fillgap") {
            console.log(title + ": Skipping " + mode + " - gap fill in progress")
            return
        }

        // Save state before prepend for gap detection
        if (mode === "prepend" && model.count > 0) {
            prePrependCount = model.count
            var topItem = model.get(0)
            prePrependTopId = (topItem && topItem.id) ? topItem.id : ""
            if (debug) console.log("Gap tracking: saved top id " + prePrependTopId + " with count " + prePrependCount)
        }

        // Collect current model IDs using object for O(1) operations
        // This replaces the old approach that kept growing an array and deduping
        var idsSet = {}
        for(var i = 0 ; i < model.count ; i++) {
            idsSet[model.get(i).id] = true
        }
        // Convert to array only when needed for passing to worker
        var currentIds = Object.keys(idsSet)

        var p = []
        if (params.length) {
            for(var i = 0; i<params.length; i++)
                p.push(params[i])
        }

        /*
        * for some types, min_id, max_id
        * is obtained from link header
        */

        if (mode === "append" && model.count) {
            if ( linkprev === "" ) {
                p.push({name: 'max_id', data: model.get(model.count-1).id})
            } else {
                p.push({name: 'max_id', data: linkprev})
            }
        }
        if (mode === "prepend" && model.count) {
            if ( linknext === "" ) {
                p.push({name:'since_id', data: model.get(0).id})
            } else {
                p.push({name: 'since_id', data: linknext})
            }
            //p.push({name:'since_id', data: model.get(0).id})
        }

        // to keep the number of params the same for all requests
        // always set local

        if(title === "Local") {
            type = "timelines/public"
            p.push({name:'local', data: "true"})
        } else {
            p.push({name:'local', data: "false"})
        }

        // we push the ids via params which we remove in the WorkerScript
        if (model.count) {
            p.push({name:'ids', data: currentIds})
        }

        var msg = {
            'action'    : type,
            'params'    : p,
            'model'     : model,
            'mode'      : mode,
            'conf'      : Logic.conf
        }

        //if (debug) console.log(JSON.stringify(msg))
        if (type !== "")
            worker.sendMessage(msg)
    }

    /*
     * Gap detection: Check if there's likely a gap between new and old items
     * Called after prepend completes
     */
    function checkForGap(newItemsCount) {
        // Mastodon API typically returns max 20 items per request
        // If we got 15+ items, there might be more we didn't fetch
        var gapThreshold = 15

        if (newItemsCount < gapThreshold) {
            console.log(title + ": No gap detected (only " + newItemsCount + " new items)")
            return
        }

        // Validate prePrependTopId exists
        if (!prePrependTopId || prePrependTopId.length === 0) {
            console.log(title + ": No prePrependTopId saved, skipping gap check")
            return
        }

        // Find where the old top item is now (should be at index = newItemsCount)
        var oldTopIndex = -1
        for (var i = 0; i < model.count; i++) {
            var item = model.get(i)
            if (item && item.id === prePrependTopId) {
                oldTopIndex = i
                break
            }
        }

        if (oldTopIndex < 0) {
            console.log(title + ": Could not find old top item, skipping gap check")
            return
        }

        // Guard: Need at least one new item before oldTopIndex to insert gap between
        if (oldTopIndex <= 0) {
            console.log(title + ": No room for gap marker (oldTopIndex=" + oldTopIndex + ")")
            return
        }

        // Check if there's already a gap item at this position
        var itemBeforeOld = model.get(oldTopIndex - 1)
        if (itemBeforeOld && itemBeforeOld.type === "gap") {
            console.log(title + ": Gap item already exists at position " + (oldTopIndex - 1))
            return
        }

        // Get the item just before the old content (newest of the old batch)
        var oldestNewItem = itemBeforeOld
        var newestOldItem = model.get(oldTopIndex)

        if (!oldestNewItem || !newestOldItem) {
            console.log(title + ": Missing items for gap check (oldestNew=" + !!oldestNewItem + ", newestOld=" + !!newestOldItem + ")")
            return
        }

        // Validate IDs exist
        if (!oldestNewItem.id || !newestOldItem.id) {
            console.log(title + ": Items missing IDs for gap check")
            return
        }

        console.log(title + ": Potential gap detected! Inserting gap marker between " +
                    oldestNewItem.id + " and " + newestOldItem.id)

        // Insert a gap placeholder item
        var gapItem = {
            type: "gap",
            id: "gap_" + oldestNewItem.id + "_" + newestOldItem.id,
            gap_max_id: oldestNewItem.id,  // Fetch items older than this
            gap_since_id: newestOldItem.id, // Fetch items newer than this
            created_at: newestOldItem.created_at,
            section: newestOldItem.section,
            content: "",
            attachments: []
        }

        model.insert(oldTopIndex, gapItem)
        modelGeneration++  // Increment generation on structural change
        console.log(title + ": Gap item inserted at index " + oldTopIndex + " (gen=" + modelGeneration + ")")
    }

    /*
     * Load items to fill a gap
     * Called when user taps "Load more" button
     */
    function loadGap(gapIndex) {
        // Prevent concurrent gap fill operations
        if (gapFillInProgress) {
            console.log(title + ": Gap fill already in progress, ignoring request")
            return
        }

        if (gapIndex < 0 || gapIndex >= model.count) {
            console.log(title + ": Invalid gap index: " + gapIndex)
            return
        }

        var gapItem = model.get(gapIndex)
        if (!gapItem || gapItem.type !== "gap") {
            console.log(title + ": Item at index " + gapIndex + " is not a gap")
            return
        }

        // Validate gap item has required properties
        if (!gapItem.gap_max_id || !gapItem.gap_since_id) {
            console.log(title + ": Gap item missing required IDs")
            return
        }

        console.log(title + ": Loading gap between " + gapItem.gap_max_id + " and " + gapItem.gap_since_id)

        // Set mutex and track generation
        gapFillInProgress = true

        // Mark as loading
        model.setProperty(gapIndex, "gap_loading", true)

        // Build params for gap fill request
        var p = []
        if (params.length) {
            for (var i = 0; i < params.length; i++)
                p.push(params[i])
        }

        // max_id: get items older than the newest new item (exclusive)
        p.push({name: 'max_id', data: gapItem.gap_max_id})
        // since_id: but newer than the oldest old item
        p.push({name: 'since_id', data: gapItem.gap_since_id})

        if (title === "Local") {
            p.push({name: 'local', data: "true"})
        } else {
            p.push({name: 'local', data: "false"})
        }

        // Store gap info for the worker response handler
        myList.gapFillIndex = gapIndex
        myList.gapFillMaxId = gapItem.gap_max_id
        myList.gapFillSinceId = gapItem.gap_since_id
        myList.gapFillGeneration = modelGeneration  // Track generation at request time

        var msg = {
            'action': type,
            'params': p,
            'model': model,
            'mode': 'fillgap',
            'conf': Logic.conf,
            'gapIndex': gapIndex
        }

        worker.sendMessage(msg)
    }

    // Gap fill state
    property int gapFillIndex: -1
    property string gapFillMaxId: ""
    property string gapFillSinceId: ""
    property int gapFillGeneration: -1  // Generation when gap fill started

    /*
     * Handle gap fill completion
     * Remove gap if fully filled, or update it for another load
     */
    function handleGapFillComplete(msg) {
        var gapIndex = msg.gapIndex
        var itemsCount = msg.itemsCount
        var oldestItemId = msg.oldestItemId

        console.log(title + ": Gap fill complete. Index=" + gapIndex + ", items=" + itemsCount + ", gen=" + modelGeneration + " (started at " + gapFillGeneration + ")")

        // Check if model was modified since gap fill started (stale operation)
        if (gapFillGeneration !== -1 && gapFillGeneration !== modelGeneration) {
            console.log(title + ": Model changed during gap fill (gen " + gapFillGeneration + " -> " + modelGeneration + "), finding gap by ID")
            // Model changed, can't trust calculated index - must find by ID
        }

        // Find the gap item - it may have shifted due to insertions
        // The gap was at gapIndex before insertion, now it's at gapIndex + itemsCount
        var actualGapIndex = gapIndex + itemsCount
        var gapItem = null

        // Validate calculated index first
        if (actualGapIndex >= 0 && actualGapIndex < model.count) {
            gapItem = model.get(actualGapIndex)
            if (!gapItem || gapItem.type !== "gap" || gapItem.gap_since_id !== gapFillSinceId) {
                gapItem = null  // Not the right gap, need to search
            }
        }

        // If calculated index didn't work, search by gap_since_id
        if (!gapItem) {
            console.log(title + ": Calculated index invalid, searching for gap by ID")
            for (var i = 0; i < model.count; i++) {
                var item = model.get(i)
                if (item && item.type === "gap" && item.gap_since_id === gapFillSinceId) {
                    actualGapIndex = i
                    gapItem = item
                    console.log(title + ": Found gap at index " + i)
                    break
                }
            }
        }

        if (!gapItem || gapItem.type !== "gap") {
            console.log(title + ": Could not find gap item after fill - it may have been removed")
            resetGapFillState()
            return
        }

        // Final bounds check before modification
        if (actualGapIndex < 0 || actualGapIndex >= model.count) {
            console.log(title + ": Gap index " + actualGapIndex + " out of bounds (count=" + model.count + ")")
            resetGapFillState()
            return
        }

        // If we got less than threshold items, gap is fully filled - remove it
        var gapThreshold = 15
        if (itemsCount < gapThreshold || itemsCount === 0) {
            console.log(title + ": Gap fully filled, removing gap item at " + actualGapIndex)
            model.remove(actualGapIndex)
            modelGeneration++  // Increment generation on structural change
        } else {
            // Gap might still have more items - update max_id for next load
            console.log(title + ": Gap may have more items, updating max_id to " + oldestItemId)
            model.setProperty(actualGapIndex, "gap_max_id", oldestItemId)
            model.setProperty(actualGapIndex, "gap_loading", false)
        }

        resetGapFillState()
    }

    /*
     * Reset gap fill state - called after completion or on error
     */
    function resetGapFillState() {
        gapFillIndex = -1
        gapFillMaxId = ""
        gapFillSinceId = ""
        gapFillGeneration = -1
        gapFillInProgress = false
    }
}

