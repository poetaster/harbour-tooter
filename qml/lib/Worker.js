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
    // ids are always the last param - convert array to object for O(1) lookup
    if (msg.params[2]) {
        if ( msg.params[2]["name"] === "ids" ) {
            var idsArray = msg.params[2]["data"]
            knownIdsSet = {}
            for (var k = 0; k < idsArray.length; k++) {
                knownIdsSet[idsArray[k]] = true
            }
            knownIdsCount = idsArray.length
            msg.params.pop()
        }
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
            console.log("Single status fetch: " + data.id)
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

        var items = [];
        // Debug: log API response size
        console.log("API response for " + msg.action + ": " + (Array.isArray(data) ? data.length + " items" : typeof data))

        for (var i in data) {
            var item;
            if (data.hasOwnProperty(i)) {
                if(msg.action === "accounts/search") {
                    item = parseAccounts({}, "", data[i]);
                    //console.log(JSON.stringify(data[i]))
                    console.log("has own data")

                    items.push(item)

                } else if(msg.action === "notifications") {
                    // notification
                    //console.log("Get notification list")
                    //console.log(JSON.stringify(data[i]))
                    item = parseNotification(data[i]);
                    items.push(item);

                } else if(msg.action.indexOf("statuses") >-1 && msg.action.indexOf("context") >-1 && i === "ancestors") {
                    // status ancestors toots - conversation
                    var ancestorCount = data[i] ? data[i].length : 0
                    var descendantCount = data["descendants"] ? data["descendants"].length : 0
                    var threadTotal = ancestorCount + 1 + descendantCount
                    console.log("ancestors: " + ancestorCount + ", total thread: " + threadTotal)
                    if (data[i] && data[i].length > 0) {
                        for (var j = 0; j < data[i].length; j++) {
                            if (data[i][j]) {
                                item = parseToot(data[i][j]);
                                item['id'] = item['status_id'];
                                if (typeof item['attachments'] === "undefined")
                                    item['attachments'] = [];
                                // Add thread position info
                                item['thread_position'] = j + 1;
                                item['thread_total'] = threadTotal;
                                items.push(item);
                            }
                        }
                        addDataToModel(msg.model, "prepend", items);
                        items = [];
                    }
                    // Update the main status with thread info
                    if (msg.model && msg.model.count > 0 && threadTotal > 1) {
                        // Find the main status (should be at position = ancestorCount after prepend)
                        var mainPos = ancestorCount;
                        if (mainPos < msg.model.count) {
                            msg.model.setProperty(mainPos, 'thread_position', ancestorCount + 1);
                            msg.model.setProperty(mainPos, 'thread_total', threadTotal);
                            msg.model.sync();  // Required for setProperty changes in WorkerScript
                        }
                    }
                } else if(msg.action.indexOf("statuses") >-1 && msg.action.indexOf("context") >-1 && i === "descendants") {
                    // status descendants toots - conversation
                    var ancestorCount2 = data["ancestors"] ? data["ancestors"].length : 0
                    var descendantCount2 = data[i] ? data[i].length : 0
                    var threadTotal2 = ancestorCount2 + 1 + descendantCount2
                    console.log("descendants: " + descendantCount2)
                    if (data[i] && data[i].length > 0) {
                        for (var j = 0; j < data[i].length; j++) {
                            if (data[i][j]) {
                                item = parseToot(data[i][j]);
                                item['id'] = item['status_id'];
                                if (typeof item['attachments'] === "undefined")
                                    item['attachments'] = [];
                                // Add thread position info
                                item['thread_position'] = ancestorCount2 + 1 + 1 + j;  // ancestors + main + position in descendants
                                item['thread_total'] = threadTotal2;
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
                    if (items.length <= 3) console.log("Parsed toot id: " + item['id'])


                } else {
                    WorkerScript.sendMessage({ 'action': msg.action, 'success': true,  key: i, "data": data[i] })
                }
            }
        }

        if(msg.model && items.length) {
            addDataToModel(msg.model, msg.mode, items)
        } else {
	   // for some reason, home chokes.
	   console.log( "items.length = " + items.length)
        }

        /*if(msg.action === "notifications")
            orderNotifications(items)*/

        console.log("Get em all?")

        WorkerScript.sendMessage({ 'updatedAll': true, 'itemsCount': items.length, 'mode': msg.mode})
    });
}

//WorkerScript.sendMessage({ 'notifyNewItems': length - i })

function addDataToModel (model, mode, items) {

    var length = items.length;
    var i
    var addedCount = 0

    console.log("addDataToModel: " + length + " items, mode=" + mode + ", knownIds=" + knownIdsCount)

    if (mode === "append") {
        for(i = 0; i <= length-1; i++) {
           // O(1) lookup using object instead of O(n) indexOf
           if (!knownIdsSet[items[i]["id"]]) {
                model.append(items[i])
                addedCount++
           } else {
               console.log("Skipped (known): " + items[i]["id"] )
          }
       }
       console.log("Added " + addedCount + " of " + length + " items")
       // search does not use ids
       if (knownIdsCount < 1) model.append(items)

    } else if (mode === "prepend") {
        for(i = length-1; i >= 0 ; i--) {
            // O(1) lookup using object instead of O(n) indexOf
            if (!knownIdsSet[items[i]["id"]]) {
                model.insert(0,items[i])
            }
        }
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
    // Thread position info (will be set properly when viewing conversation context)
    item['thread_position'] = 0
    item['thread_total'] = 0
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
    item['section'] = getDate(data["created_at"])

    /** If Toot is a Reblog */
    if(item['status_reblog']) {
        item['type'] = "reblog";
        item['typeIcon'] = "image://theme/icon-s-retweet"
        item['status_id'] = data["reblog"]["id"]
        item['status_sensitive'] = data["reblog"]["sensitive"]
        item['status_spoiler_text'] = data["reblog"]["spoiler_text"]
        item['status_replies_count'] = data["reblog"]["replies_count"]
        item['status_reblogs_count'] = data["reblog"]["reblogs_count"]
        item['status_favourites_count'] = data["reblog"]["favourites_count"]
        item['content'] = data["reblog"]["content"]
        item = parseAccounts(item, "", data['reblog']["account"])
        item = parseAccounts(item, "reblog_", data["account"])
    } else {
        item = parseAccounts(item, "", data["account"])
    }

    /** Link Preview Card */
    var cardData = item['status_reblog'] ? data["reblog"]["card"] : data["card"]
    if (cardData) {
        item['card_url'] = cardData["url"] || ''
        item['card_title'] = cardData["title"] || ''
        item['card_description'] = cardData["description"] || ''
        item['card_image'] = cardData["image"] || ''
        item['card_type'] = cardData["type"] || 'link'
        item['card_provider'] = cardData["provider_name"] || ''
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
        if (quoteData["account"]) {
            item['quote_account_display_name'] = quoteData["account"]["display_name"] || ''
            item['quote_account_acct'] = quoteData["account"]["acct"] || ''
            item['quote_account_avatar'] = quoteData["account"]["avatar"] || ''
            item['quote_account_id'] = quoteData["account"]["id"] || ''
        }
        console.log("Quote found: " + item['quote_id'] + " state: " + quoteWrapper["state"])
    } else {
        item['quote_id'] = ''
        if (quoteWrapper) {
            console.log("Quote wrapper exists but state is: " + quoteWrapper["state"])
        }
    }

    /** Replace HTML content in Toots - single regex pass for performance */
    item['content'] = item['content'].replace(
        /<\/span><span class="invisible">|<span class="invisible">|<\/span><span class="ellipsis">|class=""/g,
        ''
    );

    /** Remove "RE:" quote link prefix when we have a proper quote */
    if (item['quote_id'] && item['quote_id'].length > 0) {
        // Remove the "RE: <link>" paragraph that Mastodon adds as fallback
        // Pattern: <p>RE: <a href="...">...</a></p> at the start
        item['content'] = item['content'].replace(/^<p>RE:\s*<a[^>]*>.*?<\/a><\/p>\s*/i, '');
        // Also handle if it's at the end
        item['content'] = item['content'].replace(/\s*<p>RE:\s*<a[^>]*>.*?<\/a><\/p>$/i, '');

        // Also remove the quote URL link from content since we show the embedded quote
        if (item['quote_url'] && item['quote_url'].length > 0) {
            var escapedQuoteUrl = item['quote_url'].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            var quoteUrlPattern = new RegExp('<a[^>]*href="' + escapedQuoteUrl + '"[^>]*>.*?</a>', 'gi');
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

    /** Media attachements in Toots */
    
    item['attachments'] = [];
    for(i = 0; i < data['media_attachments'].length; i++) {
        var attachments = data['media_attachments'][i];
        item['content'] = item['content'].replaceAll(attachments['text_url'], '')
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
            item['content'] = item['content'].replaceAll(attachments['text_url'], '')
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
