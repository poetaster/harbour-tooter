Qt.include("Mastodon.js")


var loadImages = true;

WorkerScript.onMessage = function(msg) {
    console.log("Action > " + msg.action)
    console.log("Model > " + msg.model)
    console.log("Mode > " + msg.mode)
    console.log("Conf > " + JSON.stringify(msg.conf))
    console.log("Params > " + JSON.stringify(msg.params))

    /** order notifications in ASC order */
    function orderNotifications(items){
        for (var i = items.length-1; i > 0; i--) {
            if (items[i].id > 0 ) //msg.conf.notificationLastID)
                WorkerScript.sendMessage({ 'fireNotification': true, "data": items[i]})
        }
    }

    /** Logged-in status */
    if (!msg.conf || !msg.conf.login) {
        console.log("Not loggedin")
        return;
    }

    /** Load images */
    if (typeof msg.conf['loadImages'] !== "undefined")
        loadImages = msg.conf['loadImages']

    /** POST statuses */
    var API = mastodonAPI({ instance: msg.conf.instance, api_user_token: msg.conf.api_user_token});
    if (msg.method === "POST"){
        API.post(msg.action, msg.params, function(data) {
            if (msg.bgAction){
                console.log(JSON.stringify(data))
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
                        console.log(JSON.stringify(data[i]))
                        WorkerScript.sendMessage({ 'action': msg.action, 'success': true,  key: i, "data": data[i]})
                    }
                }
            }
        });
        return;
    }

    API.get(msg.action, msg.params, function(data) {
        var items = [];
        for (var i in data) {
            var item;
            if (data.hasOwnProperty(i)) {
                if(msg.action === "accounts/search") {
                    item = parseAccounts([], "", data[i]);
                    console.log(JSON.stringify(data[i]))
                    items.push(item)

                } else if(msg.action === "notifications") {
                    // notification
                    console.log("Get notification list")
                    console.log(JSON.stringify(data[i]))
                    item = parseNotification(data[i]);
                    items.push(item)

                } else if(msg.action.indexOf("statuses") >-1 && msg.action.indexOf("context") >-1 && i === "ancestors") {
                    // status ancestors toots - conversation
                    console.log("ancestors")
                    for (var j = 0; j < data[i].length; j ++) {
                        item = parseToot(data[i][j]);
                        item['id'] = item['status_id'];
                        if (typeof item['attachments'] === "undefined")
                            item['attachments'] = [];
                        items.push(item)
                        console.log(JSON.stringify(data[i][j]))
                    }
                    addDataToModel (msg.model, "prepend", items);
                    items = [];

                    //console.log(JSON.stringify(i))
                } else if(msg.action.indexOf("statuses") >-1 && msg.action.indexOf("context") >-1 && i === "descendants") {
                    // status descendants toots - conversation
                    console.log("descendants")
                    for (var j = 0; j < data[i].length; j ++) {
                        item = parseToot(data[i][j]);
                        item['id'] = item['status_id'];
                        if (typeof item['attachments'] === "undefined")
                            item['attachments'] = [];
                        items.push(item)
                        console.log(JSON.stringify(data[i][j]))
                    }
                    addDataToModel (msg.model, "append", items);
                    items = [];

                } else if (data[i].hasOwnProperty("content")){
                    //console.log("Get Toot")
                    item = parseToot(data[i]);
                    item['id'] = item['status_id']
                    items.push(item)

                } else {
                    WorkerScript.sendMessage({ 'action': msg.action, 'success': true,  key: i, "data": data[i] })
                }
            }
        }

        if(msg.model && items.length)
            addDataToModel(msg.model, msg.mode, items)
        /*if(msg.action === "notifications")
            orderNotifications(items)*/
    });
}

//WorkerScript.sendMessage({ 'notifyNewItems': length - i })
function addDataToModel (model, mode, items) {
    var length = items.length;
    console.log("Fetched > " +length)

    if (mode === "append") {
        model.append(items)
    } else if (mode === "prepend") {
        for(var i = length-1; i >= 0 ; i--) {
            model.insert(0,items[i])
        }
    }
    model.sync()
}

/** Function: Get Account Data */
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
    item['status_content'] = data["content"]
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
        item = parseAccounts(item, "", data['reblog']["account"])
        item = parseAccounts(item, "reblog_", data["account"])
    } else {
        item = parseAccounts(item, "", data["account"])
    }

    /** Replace HTML content in Toots */
    item['content'] = data['content']
    .replaceAll('</span><span class="invisible">', '')
    .replaceAll('<span class="invisible">', '')
    .replaceAll('</span><span class="ellipsis">', '')
    .replaceAll('class=""', '');

    /** Media attachements in Toots */
    item['attachments'] = [];
    for(i = 0; i < data['media_attachments'].length; i++) {
        var attachments = data['media_attachments'][i];
        item['content'] = item['content'].replaceAll(attachments['text_url'], '')
        var tmp = {
            id: attachments['id'],
            type: attachments['type'],
            url: attachments['remote_url'] && typeof attachments['remote_url'] == "string" ? attachments['remote_url'] : attachments['url'] ,
            preview_url: loadImages ? attachments['preview_url'] : ''
        }
        item['attachments'].push(tmp)
    }

    /** Media attachements in Reblogs */
    if(item['status_reblog']) {
        for(i = 0; i < data['reblog']['media_attachments'].length ; i++) {
            var attachments = data['reblog']['media_attachments'][i];
            item['content'] = item['content'].replaceAll(attachments['text_url'], '')
            var tmp = {
                id: attachments['id'],
                type: attachments['type'],
                url: attachments['remote_url'] && typeof attachments['remote_url'] == "string" ? attachments['remote_url'] : attachments['url'],
                preview_url: loadImages ? attachments['preview_url'] : ''
            }
            item['attachments'].push(tmp)
        }
    }

    return addEmojis(item, data);
}

/** Function: Display custom Emojis in Toots */
function addEmojis(item, data) {
    var emoji, i;
    for (i = 0; i < data["emojis"].length; i++) {
        emoji = data["emojis"][i];
        item['content'] = item['content'].replaceAll(":"+emoji.shortcode+":", "<img src=\"" + emoji.static_url+"\" align=\"top\" width=\"50\" height=\"50\">")
        //console.log(JSON.stringify(data["emojis"][i]))
    }
    if (data["reblog"])
        for (i = 0; i < data["reblog"]["emojis"].length; i++) {
            emoji = data["reblog"]["emojis"][i];
            item['content'] = item['content'].replaceAll(":"+emoji.shortcode+":", "<img src=\"" + emoji.static_url+"\" align=\"top\" width=\"50\" height=\"50\">")
        }

    return item;
}
