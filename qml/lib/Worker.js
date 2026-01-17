Qt.include("Mastodon.js")

var debug = false;
var loadImages = true;
// used to dedupe on append/insert - using object for O(1) lookup
var knownIdsSet = {};
var knownIdsCount = 0;
var max_id ;
var since_id;

WorkerScript.onMessage = function(msg) {

    if (debug) console.log("Action > " + msg.action)
    if (debug) console.log("Mode > " + msg.mode)

    msg.params = msg.params || []

    // Reset dedupe state per request to avoid stale IDs
    knownIdsSet = {}
    knownIdsCount = 0

    // this is not elegant. it's max_id and ids from MyList
    // we should always get max_id on append
    if (msg.mode === "append" && msg.params[0]) {
        if ( msg.params[0]["name"] === "max_id" ) {
            max_id = msg.params[0]["data"]
        }
    } else if ( msg.mode === "prepend" && msg.params[0]) {

       // prepend could be min_id or since_id
       since_id = msg.params[0]["data"]

    }
    // Find ids param and convert array to object for O(1) lookup
    var idsIndex = -1
    for (var p = 0; p < msg.params.length; p++) {
        if (msg.params[p] && msg.params[p]["name"] === "ids") {
            idsIndex = p
            break
        }
    }
    if (idsIndex !== -1) {
        var idsArray = msg.params[idsIndex]["data"] || []
        for (var k = 0; k < idsArray.length; k++) {
            knownIdsSet[idsArray[k]] = true
        }
        knownIdsCount = idsArray.length
        msg.params.splice(idsIndex, 1)
    }


    /** order notifications in ASC order */
    function orderNotifications(items){
        for (var i = items.length-1; i > 0; i--) {
            if (items[i].id > 0 ) //msg.conf.notificationLastID)
                WorkerScript.sendMessage({ 'fireNotification': true, "data": items[i]})
        }
    }

    var account = msg.conf && msg.conf.accounts ? msg.conf.accounts[msg.conf.activeAccount] : undefined

    /** Logged-in status */
    if (!account || !account.login) {
        //console.log("Not loggedin")
        return;
    }

    /** Load images */
    if (typeof msg.conf['loadImages'] !== "undefined")
        loadImages = msg.conf['loadImages']


    /* init API statuses */

    var API = mastodonAPI({ instance: account.instance, api_user_token: account.api_user_token});

    /*
    * HEAD call for some actions
    * we have to retrieve the Link  header
    * this falls through and continues for GET
    */

    if (msg.action === "bookmarks" ||
            //( msg.action === "timelines/home" && msg.mode === "append") ||
            ( msg.action.indexOf("timelines/tag/") !== -1 ) ){
        API.getLink(msg.action, msg.params, function(data) {
            if (debug) console.log(JSON.stringify(data))
            WorkerScript.sendMessage({ 'LinkHeader': data })
        });
    }

    /** DELETE statuses */

    if (msg.method === "DELETE"){
        API.delete(msg.action, function(data, status) {
            WorkerScript.sendMessage({
                'action': msg.action,
                'method': 'DELETE',
                'success': status === 200,
                'data': data
            });
        });
        return;
    }

    /** PUT statuses (edit) */

    if (msg.method === "PUT"){
        API.put(msg.action, msg.params, function(data, status) {
            WorkerScript.sendMessage({
                'action': msg.action,
                'method': 'PUT',
                'success': status === 200,
                'data': data
            });
        });
        return;
    }

    /** POST statuses */

    if (msg.method === "POST"){
        API.post(msg.action, msg.params, function(data) {
            if (msg.bgAction){
                //console.log(JSON.stringify(data))
            } else if (msg.action === "statuses") {
                // status posted
                if(msg.model){
                    var item = parseToot(data);
                    msg.model.append(item)
                    msg.model.sync();
                }

            } else if (msg.action.indexOf('fetch_remote_replies') > -1) {
                // Fetch remote replies completed - re-fetch context to get new replies
                var match = msg.action.match(/statuses\/([^\/]+)\/fetch_remote_replies/)
                if (match && match[1] && msg.model) {
                    if (debug) console.log("fetch_remote_replies completed, re-fetching context for: " + match[1])
                    API.get('statuses/' + match[1] + '/context', [], function(contextData) {
                        // Build knownIdsSet from existing model to avoid duplicates
                        buildKnownIdsFromModel(msg.model)
                        // Process descendants only (new replies) - append to model
                        if (contextData && contextData["descendants"] && contextData["descendants"].length > 0) {
                            var items = []
                            var item
                            for (var j = 0; j < contextData["descendants"].length; j++) {
                                if (contextData["descendants"][j]) {
                                    item = parseToot(contextData["descendants"][j]);
                                    item['id'] = item['status_id'];
                                    if (typeof item['attachments'] === "undefined")
                                        item['attachments'] = [];
                                    items.push(item);
                                }
                            }
                            if (items.length > 0) {
                                addDataToModel(msg.model, "append", items);
                                if (debug) console.log("Added " + items.length + " replies from remote fetch")
                            }
                        }
                    });
                }

            } else {
                for (var i in data) {
                    if (data.hasOwnProperty(i)) {
                        //console.log(JSON.stringify(data[i]))
                        WorkerScript.sendMessage({ 'action': msg.action, 'success': true,  key: i, "data": data[i]})
                    }
                }
            }
        });
        return;
    }

    API.get(msg.action, msg.params, function(data) {

        if (msg.action === "accounts/verify_credentials") {
            WorkerScript.sendMessage({action: msg.action, success: true, data: parseAccounts({}, '', data)})
            return
        }

        // Handle single status fetch (statuses/:id without /context, /source, etc.)
        var singleStatusMatch = msg.action.match(/^statuses\/(\d+)$/)
        if (singleStatusMatch && data && data.id) {
            if (debug) console.log("Single status fetch: " + data.id)
            var item = parseToot(data)
            item['id'] = item['status_id']
            if (typeof item['attachments'] === "undefined")
                item['attachments'] = []
            if (msg.model) {
                addDataToModel(msg.model, msg.mode || "append", [item])
            }
            WorkerScript.sendMessage({ 'updatedAll': true, 'itemsCount': 1, 'mode': msg.mode })
            return
        }

        // Handle v2/search for URL resolution
        if (msg.action === "v2/search" && msg.mode === "resolveUrl") {
            if (debug) console.log("URL resolution search result")
            var statuses = []
            if (data && data.statuses && data.statuses.length > 0) {
                for (var si = 0; si < data.statuses.length; si++) {
                    var statusItem = parseToot(data.statuses[si])
                    statusItem['id'] = statusItem['status_id']
                    statuses.push(statusItem)
                }
            }
            WorkerScript.sendMessage({
                'action': msg.action,
                'mode': msg.mode,
                'statuses': statuses,
                'originalUrl': msg.originalUrl
            })
            return
        }

        var items = [];
        // Debug: log API response size
        if (debug) console.log("API response for " + msg.action + ": " + (Array.isArray(data) ? data.length + " items" : typeof data))

        for (var i in data) {
            var item;
            if (data.hasOwnProperty(i)) {
                if(msg.action === "accounts/search") {
                    item = parseAccounts({}, "", data[i]);
                    //console.log(JSON.stringify(data[i]))
                    if (debug) console.log("has own data")

                    items.push(item)

                } else if(msg.action === "v2/notifications" && i === "notification_groups") {
                    // v2 grouped notifications
                    if (debug) console.log("Parsing v2 grouped notifications: " + data[i].length + " groups")
                    var accountsMap = {}
                    var statusesMap = {}

                    // Build lookup maps from the accounts and statuses arrays
                    if (data["accounts"]) {
                        for (var a = 0; a < data["accounts"].length; a++) {
                            accountsMap[data["accounts"][a].id] = data["accounts"][a]
                        }
                    }
                    if (data["statuses"]) {
                        for (var s = 0; s < data["statuses"].length; s++) {
                            statusesMap[data["statuses"][s].id] = data["statuses"][s]
                        }
                    }

                    // Parse each notification group
                    for (var g = 0; g < data[i].length; g++) {
                        var group = data[i][g]
                        item = parseGroupedNotification(group, accountsMap, statusesMap)
                        if (item) {
                            items.push(item)
                        }
                    }

                } else if(msg.action === "notifications") {
                    // v1 notification (fallback)
                    //console.log("Get notification list")
                    //console.log(JSON.stringify(data[i]))
                    item = parseNotification(data[i]);
                    items.push(item);

                } else if(msg.action.indexOf("statuses") >-1 && msg.action.indexOf("context") >-1 && i === "ancestors") {
                    // status ancestors toots - conversation
                    // Build knownIdsSet from existing model to avoid duplicates
                    buildKnownIdsFromModel(msg.model)
                    if (debug) console.log("ancestors: " + (data[i] ? data[i].length : 0))
                    if (data[i] && data[i].length > 0) {
                        for (var j = 0; j < data[i].length; j++) {
                            if (data[i][j]) {
                                item = parseToot(data[i][j]);
                                item['id'] = item['status_id'];
                                if (typeof item['attachments'] === "undefined")
                                    item['attachments'] = [];
                                items.push(item);
                            }
                        }
                        addDataToModel(msg.model, "prepend", items);
                        // Update knownIdsSet with newly added ancestors
                        for (var k = 0; k < items.length; k++) {
                            knownIdsSet[items[k]['id']] = true
                            knownIdsCount++
                        }
                        items = [];
                    }
                } else if(msg.action.indexOf("statuses") >-1 && msg.action.indexOf("context") >-1 && i === "descendants") {
                    // status descendants toots - conversation
                    // Build knownIdsSet if not already built (in case there were no ancestors)
                    if (knownIdsCount < 1) {
                        buildKnownIdsFromModel(msg.model)
                    }
                    if (debug) console.log("descendants: " + (data[i] ? data[i].length : 0))
                    if (data[i] && data[i].length > 0) {
                        for (var j = 0; j < data[i].length; j++) {
                            if (data[i][j]) {
                                item = parseToot(data[i][j]);
                                item['id'] = item['status_id'];
                                if (typeof item['attachments'] === "undefined")
                                    item['attachments'] = [];
                                items.push(item);
                            }
                        }
                        addDataToModel(msg.model, "append", items);
                        items = [];
                    }

                } else if (data[i] && typeof data[i] === 'object' && data[i].hasOwnProperty("content")){
                    //console.log("Get Toot")
                    item = parseToot(data[i]);
                    // Use timeline_id for pagination (preserves correct ID for reblogs)
                    item['id'] = item['timeline_id']
                    items.push(item);
                    if (debug && items.length <= 3) console.log("Parsed toot id: " + item['id'])


                } else {
                    WorkerScript.sendMessage({ 'action': msg.action, 'success': true,  key: i, "data": data[i] })
                }
            }
        }

        if(msg.model && items.length) {
            // Apply self-thread reordering for timeline views
            // This makes threads read in chronological order (oldest to newest)
            var isTimeline = msg.action.indexOf("timelines/") === 0 ||
                             msg.action === "bookmarks"
            if (isTimeline) {
                items = reorderSelfThreads(items)
            }

            // Pass gapIndex for fillgap mode
            var insertIdx = (msg.mode === "fillgap" && typeof msg.gapIndex === "number") ? msg.gapIndex : undefined
            addDataToModel(msg.model, msg.mode, items, insertIdx)
        } else {
	   // for some reason, home chokes.
	   if (debug) console.log( "items.length = " + items.length)
        }

        /*if(msg.action === "notifications")
            orderNotifications(items)*/

        if (debug) console.log("Get em all?")

        // Include gapIndex in response for fillgap mode
        var responseMsg = { 'updatedAll': true, 'itemsCount': items.length, 'mode': msg.mode }
        if (msg.mode === "fillgap") {
            responseMsg.gapIndex = msg.gapIndex
            // Send oldest item ID so MyList can update or remove the gap
            if (items.length > 0) {
                responseMsg.oldestItemId = items[items.length - 1]['id']
            }
        }
        WorkerScript.sendMessage(responseMsg)
    });
}

//WorkerScript.sendMessage({ 'notifyNewItems': length - i })

function addDataToModel (model, mode, items, insertIndex) {

    var length = items.length;
    var i
    var addedCount = 0

    if (debug) console.log("addDataToModel: " + length + " items, mode=" + mode + ", knownIds=" + knownIdsCount)

    if (knownIdsCount < 1) {
        if (mode === "append") {
            // Append items one by one to ensure dynamic properties are properly registered
            for (i = 0; i < length; i++) {
                model.append(items[i])
            }
        } else if (mode === "prepend") {
            for (i = length - 1; i >= 0; i--) {
                model.insert(0, items[i])
            }
        } else if (mode === "fillgap" && typeof insertIndex === "number") {
            // Insert items after the gap position (newest first)
            for (i = length - 1; i >= 0; i--) {
                model.insert(insertIndex, items[i])
            }
        }
        model.sync()
        return
    }

    if (mode === "append") {
        for(i = 0; i <= length-1; i++) {
           // O(1) lookup using object instead of O(n) indexOf
           if (!knownIdsSet[items[i]["id"]]) {
                model.append(items[i])
                addedCount++
           } else {
               if (debug) console.log("Skipped (known): " + items[i]["id"] )
          }
       }
       if (debug) console.log("Added " + addedCount + " of " + length + " items")

    } else if (mode === "prepend") {
        for(i = length-1; i >= 0 ; i--) {
            // O(1) lookup using object instead of O(n) indexOf
            if (!knownIdsSet[items[i]["id"]]) {
                model.insert(0,items[i])
            }
        }
    } else if (mode === "fillgap" && typeof insertIndex === "number") {
        // Insert items at gap position, skipping duplicates
        for (i = length - 1; i >= 0; i--) {
            if (!knownIdsSet[items[i]["id"]]) {
                model.insert(insertIndex, items[i])
                addedCount++
            } else {
                if (debug) console.log("Skipped (known): " + items[i]["id"])
            }
        }
        if (debug) console.log("Gap fill: Added " + addedCount + " of " + length + " items at index " + insertIndex)
    }
    model.sync()
}

function findDuplicate(arr,val) {
        for(var i=0; i < arr.length; i++){
            if( arr.indexOf(val) === -1 )  {
               return true;
            }
        }
        return false;
}

/**
 * Reorder self-thread chains so they read in chronological order.
 * Self-threads are posts where the author replies to themselves.
 * API returns newest first, but threads should read oldest first.
 */
function reorderSelfThreads(items) {
    if (!items || items.length < 2) return items

    // Build lookup map: status_id -> item
    var idToItem = {}
    for (var i = 0; i < items.length; i++) {
        idToItem[items[i]['status_id']] = items[i]
    }

    var result = []
    var processed = {}

    for (var i = 0; i < items.length; i++) {
        var item = items[i]

        if (processed[item['status_id']]) continue

        // Is this part of a self-thread with parent in this batch?
        if (item['is_self_thread'] && idToItem[item['status_in_reply_to_id']]) {
            // Collect the chain by walking up the reply chain
            var chain = []
            var current = item

            while (current && current['is_self_thread'] && idToItem[current['status_in_reply_to_id']]) {
                chain.push(current)
                processed[current['status_id']] = true
                current = idToItem[current['status_in_reply_to_id']]
            }

            // Add root post (first in thread - not a self-reply or parent not in feed)
            if (current && !processed[current['status_id']]) {
                chain.push(current)
                processed[current['status_id']] = true
            }

            // chain = [newest, ..., oldest] - reverse for reading order
            chain.reverse()

            // Add position metadata for UI
            for (var j = 0; j < chain.length; j++) {
                chain[j]['thread_position'] = j + 1
                chain[j]['thread_total'] = chain.length
                chain[j]['is_thread_start'] = (j === 0)
                chain[j]['is_thread_end'] = (j === chain.length - 1)
            }

            // Add reordered chain to result
            for (var k = 0; k < chain.length; k++) {
                result.push(chain[k])
            }
        } else {
            // Regular post - add as-is with no thread metadata
            processed[item['status_id']] = true
            item['thread_position'] = 0
            item['thread_total'] = 0
            item['is_thread_start'] = false
            item['is_thread_end'] = false
            result.push(item)
        }
    }

    if (debug) console.log("reorderSelfThreads: " + items.length + " items -> " + result.length + " after reordering")
    return result
}

/** Build knownIdsSet from existing model items for deduplication */
function buildKnownIdsFromModel(model) {
    knownIdsSet = {}
    knownIdsCount = 0
    if (model && model.count > 0) {
        for (var i = 0; i < model.count; i++) {
            var item = model.get(i)
            if (item && item.status_id) {
                knownIdsSet[item.status_id] = true
                knownIdsCount++
            }
        }
    }
    if (debug) console.log("Built knownIdsSet from model: " + knownIdsCount + " items")
}

/**
 * Check if a URL is a Mastodon/ActivityPub status URL
 * Used to suppress link previews for posts that should open in-app
 */
function isMastodonStatusUrl(url) {
    if (!url || typeof url !== "string") return false
    if (!url.match(/^https?:\/\//i)) return false

    // Normalize: remove trailing slashes
    var normalized = url.replace(/\/+$/, '')
    var parts = normalized.split("/")

    // Need at least: https: / "" / instance / path
    if (parts.length < 4) return false

    var pathPart1 = parts[3]
    var pathPart2 = parts.length > 4 ? parts[4] : null
    var pathPart3 = parts.length > 5 ? parts[5] : null
    var pathPart4 = parts.length > 6 ? parts[6] : null

    // Pattern: /@username/123456789 (length 5, starts with @, numeric ID)
    if (parts.length === 5 && pathPart1 && pathPart1[0] === "@" && /^\d+$/.test(pathPart2)) {
        return true
    }

    // Pattern: /users/username/statuses/123456789 (length 7)
    if (parts.length === 7 && pathPart1 === "users" && pathPart3 === "statuses" && /^\d+$/.test(pathPart4)) {
        return true
    }

    return false
}

/* Function: Get Account Data */
function parseAccounts(collection, prefix, data) {

    var res = collection;
    // Base attributes
    res[prefix + 'account_id'] = data["id"]
    res[prefix + 'account_username'] = data["username"]
    res[prefix + 'account_acct'] = data["acct"]
    res[prefix + 'account_url'] = data["url"]
    // Display attributes
    res[prefix + 'account_display_name'] = data["display_name"]
    res[prefix + 'account_note'] = data["note"]
    res[prefix + 'account_avatar'] = data["avatar"]
    res[prefix + 'account_header'] = data["header"]
    res[prefix + 'account_locked'] = data["locked"]
    //res[prefix + 'account_emojis'] = data["emojis"]
    res[prefix + 'account_discoverable'] = data["discoverable"]
    // Statistical attributes
    res[prefix + 'account_created_at'] = data["created_at"]
    res[prefix + 'account_statuses_count'] = data["statuses_count"]
    res[prefix + 'account_followers_count'] = data["followers_count"]
    res[prefix + 'account_following_count'] = data["following_count"]
    // Optional attributes
    //res[prefix + 'account_fields'] = data["fields"]
    res[prefix + 'account_bot'] = data["bot"]
    res[prefix + 'account_group'] = data["group"]

    //console.log(JSON.stringify(res))
    return (res);
}

/** Function: Get Notification Data */
function parseNotification(data){
    //console.log(JSON.stringify(data))
    var item = {
        id: data.id,
        type: data.type,
        attachments: []
    };
    switch (item['type']){

    case "mention":
        if (!data.status) {
            break;
        }
        item = parseToot(data.status)
        item['typeIcon'] = "image://theme/icon-s-alarm"
        item['type'] = "mention"
        break;

    case "reblog":
        if (!data.status) {
            break;
        }
        item = parseToot(data.status)
        item = parseAccounts(item, "reblog_", data["account"])
        item = parseAccounts(item, "", data["status"]["account"])
        item['status_reblog'] = true
        item['type'] = "reblog"
        item['typeIcon'] = "image://theme/icon-s-retweet"
        break;

    case "favourite":
        if (!data.status) {
            break;
        }
        item = parseToot(data.status)
        item = parseAccounts(item, "reblog_", data["account"])
        item = parseAccounts(item, "", data["status"]["account"])
        item['status_reblog'] = true
        item['type'] = "favourite"
        item['typeIcon'] = "image://theme/icon-s-favorite"
        break;

    case "follow":
        item['type'] = "follow";
        item = parseAccounts(item, "", data["account"])
        item = parseAccounts(item, "reblog_", data["account"])
        //item['content'] = data['account']['note']
        item['typeIcon'] = "../../images/icon-s-follow.svg"
        //item['attachments'] = []
        break;

    default:
        item['typeIcon'] = "image://theme/icon-s-sailfish"
    }

    item['id'] = data.id
    item['created_at'] =  new Date(data.created_at)
    item['section'] =  getDate(data["created_at"])
    return item;
}

/** Function: Parse v2 Grouped Notification */
function parseGroupedNotification(group, accountsMap, statusesMap) {
    var item = {
        id: group.group_key,
        type: group.type,
        attachments: [],
        notifications_count: group.notifications_count || 1
    };

    // Get sample accounts for stacked avatar display (stored as indexed properties for ListModel compatibility)
    var groupedData = {
        grouped_account_count: 0
    }
    if (group.sample_account_ids) {
        for (var i = 0; i < group.sample_account_ids.length && i < 3; i++) {
            var acc = accountsMap[group.sample_account_ids[i]]
            if (acc) {
                groupedData['grouped_account_avatar_' + i] = acc.avatar
                groupedData['grouped_account_acct_' + i] = acc.acct
                groupedData['grouped_account_display_name_' + i] = acc.display_name
                groupedData['grouped_account_id_' + i] = acc.id
                groupedData.grouped_account_count++
            }
        }
    }

    // Get the first account for reblog_account_* fields (for MiniStatus display)
    var firstAccount = groupedData.grouped_account_count > 0 ? accountsMap[group.sample_account_ids[0]] : null

    switch (group.type) {
    case "mention":
        if (!group.status_id || !statusesMap[group.status_id]) {
            return null
        }
        item = parseToot(statusesMap[group.status_id])
        item['typeIcon'] = "image://theme/icon-s-alarm"
        item['type'] = "mention"
        break;

    case "reblog":
        if (!group.status_id || !statusesMap[group.status_id]) {
            return null
        }
        var statusData = statusesMap[group.status_id]
        item = parseToot(statusData)
        if (firstAccount) {
            item = parseAccounts(item, "reblog_", firstAccount)
        }
        if (statusData.account) {
            item = parseAccounts(item, "", statusData.account)
        }
        item['status_reblog'] = true
        item['type'] = "reblog"
        item['typeIcon'] = "image://theme/icon-s-retweet"
        break;

    case "favourite":
        if (!group.status_id || !statusesMap[group.status_id]) {
            return null
        }
        var statusData2 = statusesMap[group.status_id]
        item = parseToot(statusData2)
        if (firstAccount) {
            item = parseAccounts(item, "reblog_", firstAccount)
        }
        if (statusData2.account) {
            item = parseAccounts(item, "", statusData2.account)
        }
        item['status_reblog'] = true
        item['type'] = "favourite"
        item['typeIcon'] = "image://theme/icon-s-favorite"
        break;

    case "follow":
        item['type'] = "follow"
        if (firstAccount) {
            item = parseAccounts(item, "", firstAccount)
            item = parseAccounts(item, "reblog_", firstAccount)
        }
        item['typeIcon'] = "../../images/icon-s-follow.svg"
        break;

    default:
        item['typeIcon'] = "image://theme/icon-s-sailfish"
    }

    // Apply common fields after switch (since parseToot replaces item)
    item['id'] = group.group_key
    item['created_at'] = new Date(group.latest_page_notification_at)
    item['section'] = getDate(group.latest_page_notification_at)
    item['notifications_count'] = group.notifications_count || 1

    // Apply grouped account data
    for (var key in groupedData) {
        item[key] = groupedData[key]
    }

    return item
}

/** Function: */
function collect() {
    var ret = {};
    var len = arguments.length;
    for (var i=0; i<len; i++) {
        for (p in arguments[i]) {
            if (arguments[i].hasOwnProperty(p)) {
                ret[p] = arguments[i][p];
            }
        }
    }
    return ret;
}

/** Function: Get Status date */
function getDate(dateStr) {
    var ts = new Date(dateStr);
    return new Date(ts.getFullYear(), ts.getMonth(), ts.getDate(), 0, 0, 0)
}

/** Function: Get Status data */
function parseToot (data) {
    var i = 0;
    var item = {};

    item['type'] = "toot"
    item['highlight'] = false
    item['status_id'] = data["id"]
    // timeline_id preserves the original entry ID for pagination (important for reblogs)
    item['timeline_id'] = data["id"]
    item['status_created_at'] = item['created_at'] = new Date(data["created_at"])
    item['status_sensitive'] = data["sensitive"]
    item['status_spoiler_text'] = data["spoiler_text"]
    item['status_visibility'] = data["visibility"]
    item['status_language'] = data["language"]
    item['status_uri'] = data["uri"]
    item['status_url'] = data["url"]
    item['status_replies_count'] = data["replies_count"]
    item['status_reblogs_count'] = data["reblogs_count"]
    item['status_favourites_count'] = data["favourites_count"]
    item['status_favourited'] = data["favourited"]
    item['status_reblogged'] = data["reblogged"]
    item['status_bookmarked'] = data["bookmarked"]
    item['content'] = data["content"]
    item['attachments'] = data['media_attachments']
    item['status_in_reply_to_id'] = data["in_reply_to_id"]
    item['status_in_reply_to_account_id'] = data["in_reply_to_account_id"]
    item['status_reblog'] = data["reblog"] ? true : false

    // Self-thread detection: author replying to their own post
    item['is_self_thread'] = data["in_reply_to_account_id"] &&
                             data["account"] &&
                             data["in_reply_to_account_id"] === data["account"]["id"]

    // Default thread metadata (may be updated by reorderSelfThreads)
    item['thread_position'] = 0
    item['thread_total'] = 0
    item['is_thread_start'] = false
    item['is_thread_end'] = false

    item['section'] = getDate(data["created_at"])

    /** If Toot is a Reblog */
    if(item['status_reblog']) {
        item['type'] = "reblog";
        item['typeIcon'] = "image://theme/icon-s-retweet"
        item['status_id'] = data["reblog"]["id"]
        // Use the original toot's timestamp, not the boost timestamp
        item['created_at'] = item['status_created_at'] = new Date(data["reblog"]["created_at"])
        item['status_sensitive'] = data["reblog"]["sensitive"]
        item['status_spoiler_text'] = data["reblog"]["spoiler_text"]
        item['status_replies_count'] = data["reblog"]["replies_count"]
        item['status_reblogs_count'] = data["reblog"]["reblogs_count"]
        item['status_favourites_count'] = data["reblog"]["favourites_count"]
        item['status_in_reply_to_id'] = data["reblog"]["in_reply_to_id"]
        item['status_in_reply_to_account_id'] = data["reblog"]["in_reply_to_account_id"]
        // Self-thread detection for reblogged post
        item['is_self_thread'] = data["reblog"]["in_reply_to_account_id"] &&
                                 data["reblog"]["account"] &&
                                 data["reblog"]["in_reply_to_account_id"] === data["reblog"]["account"]["id"]
        item['content'] = data["reblog"]["content"]
        item = parseAccounts(item, "", data['reblog']["account"])
        item = parseAccounts(item, "reblog_", data["account"])
    } else {
        item = parseAccounts(item, "", data["account"])
    }

    /** Parse mentions for reply functionality */
    var mentionsData = item['status_reblog'] ? data["reblog"]["mentions"] : data["mentions"]
    if (mentionsData && mentionsData.length > 0) {
        var mentionAccts = []
        for (var m = 0; m < mentionsData.length; m++) {
            if (mentionsData[m]["acct"]) {
                mentionAccts.push(mentionsData[m]["acct"])
            }
        }
        item['status_mentions'] = mentionAccts.join(',')
    } else {
        item['status_mentions'] = ''
    }

    /** Link Preview Card */
    var cardData = item['status_reblog'] ? data["reblog"]["card"] : data["card"]
    if (cardData) {
        var cardUrl = cardData["url"] || ''
        // Don't show link preview for Mastodon post URLs - they should open in-app
        if (cardUrl && isMastodonStatusUrl(cardUrl)) {
            if (debug) console.log("Suppressing card for Mastodon URL: " + cardUrl)
            item['card_url'] = ''
        } else {
            item['card_url'] = cardUrl
            item['card_title'] = cardData["title"] || ''
            item['card_description'] = cardData["description"] || ''
            item['card_image'] = cardData["image"] || ''
            item['card_type'] = cardData["type"] || 'link'
            item['card_provider'] = cardData["provider_name"] || ''
        }
    } else {
        item['card_url'] = ''
    }

    /** Quote Post (Quote Boost) */
    // Mastodon 4.4+ uses quote.quoted_status structure
    var quoteWrapper = item['status_reblog'] ? data["reblog"]["quote"] : data["quote"]
    // States where quoted_status is available: accepted, blocked_account, blocked_domain, muted_account
    var validQuoteStates = ["accepted", "blocked_account", "blocked_domain", "muted_account"]
    if (quoteWrapper && quoteWrapper["quoted_status"] && validQuoteStates.indexOf(quoteWrapper["state"]) !== -1) {
        var quoteData = quoteWrapper["quoted_status"]
        item['quote_id'] = quoteData["id"] || ''
        item['quote_content'] = quoteData["content"] || ''
        item['quote_url'] = quoteData["url"] || ''
        item['quote_created_at'] = quoteData["created_at"] ? new Date(quoteData["created_at"]) : null
        item['quote_status_id'] = quoteData["id"] || ''
        // Always set account properties (even if empty) for consistent model structure
        if (quoteData["account"]) {
            item['quote_account_display_name'] = quoteData["account"]["display_name"] || ''
            item['quote_account_acct'] = quoteData["account"]["acct"] || ''
            item['quote_account_avatar'] = quoteData["account"]["avatar"] || ''
            item['quote_account_id'] = quoteData["account"]["id"] || ''
        } else {
            // Account may be null if quoted post author deleted their account
            item['quote_account_display_name'] = ''
            item['quote_account_acct'] = ''
            item['quote_account_avatar'] = ''
            item['quote_account_id'] = ''
        }
        if (debug) console.log("Quote found: " + item['quote_id'] + " state: " + quoteWrapper["state"] + " content length: " + item['quote_content'].length)
    } else {
        item['quote_id'] = ''
        item['quote_content'] = ''
        item['quote_url'] = ''
        item['quote_account_display_name'] = ''
        item['quote_account_acct'] = ''
        item['quote_account_avatar'] = ''
        item['quote_account_id'] = ''
        if (quoteWrapper) {
            if (debug) console.log("Quote wrapper exists but state is: " + quoteWrapper["state"])
        }
    }

    /** Replace HTML content in Toots - single regex pass for performance */
    item['content'] = item['content'].replace(
        /<\/span><span class="invisible">|<span class="invisible">|<\/span><span class="ellipsis">|class=""/g,
        ''
    );

    /** Remove "RE:" quote link prefix when we have a proper quote */
    if (item['quote_id'] && item['quote_id'].length > 0) {
        // Remove the "RE: <link>" that Mastodon adds as fallback
        // Note: <a> tags may contain <span> tags inside, so use .*? instead of [^<]*
        // Pattern 1: <p>RE: <a href="...">...</a></p> as standalone paragraph (with optional class like "quote-inline")
        item['content'] = item['content'].replace(/^<p[^>]*>\s*RE:\s*<a[^>]*>.*?<\/a>\s*<\/p>\s*/i, '');
        item['content'] = item['content'].replace(/\s*<p[^>]*>\s*RE:\s*<a[^>]*>.*?<\/a>\s*<\/p>$/i, '');
        // Pattern 2: RE: <a>...</a> without p tags (inline at start or end)
        item['content'] = item['content'].replace(/^RE:\s*<a[^>]*>.*?<\/a>\s*/i, '');
        item['content'] = item['content'].replace(/\s*RE:\s*<a[^>]*>.*?<\/a>$/i, '');
        // Pattern 3: <br>RE: ... or <br/>RE: ... (line break before RE:)
        item['content'] = item['content'].replace(/<br\s*\/?>\s*RE:\s*<a[^>]*>.*?<\/a>\s*/gi, '');
        // Pattern 4: RE: inside a paragraph with other content - remove just the RE: part
        item['content'] = item['content'].replace(/RE:\s*<a[^>]*>.*?<\/a>\s*/gi, '');

        // Also remove the quote URL link from content since we show the embedded quote
        if (item['quote_url'] && item['quote_url'].length > 0) {
            var escapedQuoteUrl = item['quote_url'].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            var quoteUrlPattern = new RegExp('<a[^>]*href="' + escapedQuoteUrl + '"[^>]*>[^<]*</a>', 'gi');
            item['content'] = item['content'].replace(quoteUrlPattern, '');
        }
    }

    /** Remove card URL from content when link preview is shown */
    if (item['card_url'] && item['card_url'].length > 0) {
        // Escape special regex characters in the URL
        var escapedUrl = item['card_url'].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        // Remove the <a> tag containing this URL
        var urlPattern = new RegExp('<a[^>]*href="' + escapedUrl + '"[^>]*>.*?</a>', 'gi');
        item['content'] = item['content'].replace(urlPattern, '');
    }

    /** Final cleanup: remove empty paragraphs and trim */
    item['content'] = item['content'].replace(/<p>\s*<\/p>/g, '').trim();

    /** Poll data - store all in JSON for reliable ListModel sync */
    var pollData = item['status_reblog'] ? data["reblog"]["poll"] : data["poll"]
    if (pollData) {
        var optionsArray = []
        if (pollData["options"]) {
            for (var p = 0; p < pollData["options"].length && p < 10; p++) {
                optionsArray.push({
                    title: pollData["options"][p]["title"] || '',
                    votes: pollData["options"][p]["votes_count"] || 0
                })
            }
        }
        // Store all poll data in single JSON string for reliable sync
        item['poll_json'] = JSON.stringify({
            id: pollData["id"] || '',
            expires_at: pollData["expires_at"] || null,
            expired: pollData["expired"] || false,
            multiple: pollData["multiple"] || false,
            votes_count: pollData["votes_count"] || 0,
            voters_count: pollData["voters_count"] || 0,
            voted: pollData["voted"] || false,
            own_votes: pollData["own_votes"] || [],
            options: optionsArray
        })
        if (debug) console.log("Poll found: " + pollData["id"] + " options: " + optionsArray.length + " voted: " + pollData["voted"])
    } else {
        item['poll_json'] = ''
    }

    /** Media attachements in Toots */
    
    item['attachments'] = [];
    for(i = 0; i < data['media_attachments'].length; i++) {
        var attachments = data['media_attachments'][i];
        if (attachments['text_url']) {
            item['content'] = item['content'].split(attachments['text_url']).join('')
        }
        var tmp = {
            id: attachments['id'],
            type: attachments['type'],
            url: attachments['remote_url'] && typeof attachments['remote_url'] == "string" ? attachments['remote_url'] : attachments['url'] ,
            preview_url: loadImages ? attachments['preview_url'] : '',
            description: attachments['description'] || ''
        }
        item['attachments'].push(tmp)
    }

    // Media attachements in Reblogs
    if(item['status_reblog']) {
        for(i = 0; i < data['reblog']['media_attachments'].length ; i++) {
            var attachments = data['reblog']['media_attachments'][i];
            if (attachments['text_url']) {
                item['content'] = item['content'].split(attachments['text_url']).join('')
            }
            var tmp = {
                id: attachments['id'],
                type: attachments['type'],
                url: attachments['remote_url'] && typeof attachments['remote_url'] == "string" ? attachments['remote_url'] : attachments['url'],
                preview_url: loadImages ? attachments['preview_url'] : '',
                description: attachments['description'] || ''
            }
            item['attachments'].push(tmp)
        }
    }

    return addEmojis(item, data);
}

/** Function: Display custom Emojis in Toots - batched for performance */
function addEmojis(item, data) {
    // Collect all emojis from both main and reblog data
    var allEmojis = data["emojis"] || [];
    if (data["reblog"] && data["reblog"]["emojis"]) {
        allEmojis = allEmojis.concat(data["reblog"]["emojis"]);
    }

    if (allEmojis.length === 0) {
        return item;
    }

    // Build emoji lookup map
    var emojiMap = {};
    for (var i = 0; i < allEmojis.length; i++) {
        var emoji = allEmojis[i];
        emojiMap[emoji.shortcode] = emoji.static_url;
    }

    // Build single regex matching all shortcodes
    var shortcodes = Object.keys(emojiMap);
    // Escape special regex characters in shortcodes
    var escapedShortcodes = shortcodes.map(function(sc) {
        return sc.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    });
    var pattern = new RegExp(':(' + escapedShortcodes.join('|') + '):', 'g');

    // Single pass replacement
    item['content'] = item['content'].replace(pattern, function(match, shortcode) {
        return '<img src="' + emojiMap[shortcode] + '" align="top" width="50" height="50">';
    });

    return item;
}
