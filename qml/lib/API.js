.pragma library
.import QtQuick.LocalStorage 2.0 as LS

var debug = false;
var db = LS.LocalStorage.openDatabaseSync("tooterb", "", "harbour-tooterb", 100000);
var conf = {};
var mediator = (function(){
    var subscribe = function(channel, fn){
        if(!mediator.channels[channel]) mediator.channels[channel] = [];
        mediator.channels[channel].push({ context : this, callback : fn });
        return this;
    };

    var publish = function(channel){
        if(!mediator.channels[channel]) return false;
        var args = Array.prototype.slice.call(arguments, 1);
        for(var i = 0, l = mediator.channels[channel].length; i < l; i++){
            var subscription = mediator.channels[channel][i];
            subscription.callback.apply(subscription.context, args);
        };
        return this;
    };

    return {
        channels : {},
        publish : publish,
        subscribe : subscribe,
        installTo : function(obj){
            obj.subscribe = subscribe;
            obj.publish = publish;
        }
    };
}());

function getActiveAccount() {
    // not sure if this can be used for dynamic qobject properties
    return conf.accounts[conf.activeAccount] || {}
}

function setActiveAccount(index) {
    var account = conf.accounts[index]
    conf.activeAccount = index

    api.setConfig("instance", account.instance)
    api.setConfig("api_user_token", account.api_user_token)

    clearModels()
}

function removeActiveAccount() {
    // returns true if login page must be shown
    conf.accounts.splice(conf.activeAccount, 1)
    if (conf.accounts.length)
        setActiveAccount(0)
    else {
        conf.activeAccount = null
        return true
    }
    return false
}

var init = function(){
    if (debug) console.log("db.version: "+db.version);
    if(db.version === '') {
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings ('
                          + ' key TEXT UNIQUE, '
                          + ' value TEXT '
                          + ');');
            //tx.executeSql('INSERT INTO settings (key, value) VALUES (?, ?)', ["conf", "{}"]);
        });
        db.changeVersion('', '0.1', function(tx) {

        });
    }
    db.transaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM settings;');
        if (debug) console.log("READING CONF FROM DB")
        for (var i = 0; i < rs.rows.length; i++) {
            //var json = JSON.parse(rs.rows.item(i).value);
            if (debug) console.log(rs.rows.item(i).key+" \t > \t "+rs.rows.item(i).value)
            conf[rs.rows.item(i).key] = JSON.parse(rs.rows.item(i).value)
        }
        if (debug) console.log("END OF READING")
        if (debug) console.log(JSON.stringify(conf));
        mediator.publish('confLoaded', { loaded: true});
    });
};

function saveData() {
    if (debug) console.log("SAVING CONF TO DB")
    db.transaction(function(tx) {
        for (var key in conf) {
            if (conf.hasOwnProperty(key)){
                if (debug) console.log(key + "\t>\t"+JSON.stringify(conf[key]));
                if (typeof conf[key] === "object" && conf[key] === null) {
                    tx.executeSql('DELETE FROM settings WHERE key=? ', [key])
                } else {
                    tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?) ', [key, JSON.stringify(conf[key])])
                }
            }
        }
        if (debug) console.log("END OF SAVING")
    });
}

var tootParser = function(data){
    if (debug) console.log(data)
    var ret = {};
    ret.id = data.id
    ret.content = data.content
    ret.created_at = data.created_at
    ret.in_reply_to_account_id = data.in_reply_to_account_id
    ret.in_reply_to_id = data.in_reply_to_id

    ret.user_id = data.account.id
    ret.user_locked = data.account.locked
    ret.username = data.account.username
    ret.display_name = data.account.display_name
    ret.avatar_static = data.account.avatar_static

    ret.favourited = data.favourited ? true : false
    ret.status_favourites_count = data.favourites_count ? data.favourites_count : 0

    ret.reblog = data.reblog ? true : false
    ret.reblogged = data.reblogged ? true : false
    ret.status_reblogs_count = data.reblogs_count ? data.reblogs_count : false

    ret.bookmarked = data.bookmarked ? true : false

    ret.muted = data.muted ? true : false
    ret.sensitive = data.sensitive ? true : false
    ret.visibility = data.visibility ? data.visibility : false

    if (debug) console.log(ret)
}

var test = 1;

Qt.include("Mastodon.js")

var modelTLhome = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');
var modelTLpublic = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');
var modelTLlocal = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');
var modelTLtrending = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');
var modelTLnotifications = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');
var modelTLsearch = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');
var modelTLbookmarks = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true }', Qt.application, 'InternalQmlObject');

function clearModels() {
    [modelTLhome, modelTLpublic, modelTLlocal, modelTLnotifications, modelTLsearch, modelTLbookmarks]
        .forEach(function(m) { m.clear() })
}

var notificationsList = []

var notificationGenerator = function(item){
    var notification;
    switch (item.urgency){
    case "normal":
        notification = Qt.createQmlObject('import org.nemomobile.notifications 1.0;  Notification {  category: "x-harbour.tooterb.activity";  appName: "Tooter β"; itemCount: 1; remoteActions: [  { "name": "default", "displayName": "Do something", "icon": "icon-s-certificates",  "service": "org.sailfishos.fileservice",  "path": "/",  "iface": "org.sailfishos.fileservice",  "method": "openUrl", "arguments": [ "'+item.key+'" ] }];  urgency: Notification.Normal;  }', Qt.application, 'InternalQmlObject');
        break;
    case "critical":
        notification = Qt.createQmlObject('import org.nemomobile.notifications 1.0; Notification { appName: "Tooter β"; itemCount: 1; remoteActions: [ { "name": "default", "displayName": "Do something", "icon": "icon-s-certificates", "service": "org.sailfishos.fileservice", "path": "/", "iface": "org.sailfishos.fileservice", "method": "openUrl", "arguments": [ "'+item.key+'" ] }]; urgency: Notification.Critical;  }', Qt.application, 'InternalQmlObject');
        break;
    default:
        notification = Qt.createQmlObject('import org.nemomobile.notifications 1.0; Notification { category: "x-harbour.tooterb.activity"; appName: "Tooter β"; itemCount: 1; remoteActions: [ { "name": "default", "displayName": "Do something", "icon": "icon-s-certificates", "service": "org.sailfishos.fileservice", "path": "/", "iface": "org.sailfishos.fileservice", "method": "openUrl", "arguments": [  "'+item.key+'" ] }]; urgency: Notification.Low;  }', Qt.application, 'InternalQmlObject');
    }

    notification.timestamp = item.timestamp
    notification.summary = item.summary
    notification.body = item.body
    if(item.previewBody)
        notification.previewBody = item.previewBody;
    else
        notification.previewBody = item.body;
    if(item.previewSummary)
        notification.previewSummary = item.previewSummary;
    else
        notification.previewSummary = item.summary
    if(notification.replacesId){ notification.replacesId = 0 }
    notification.publish()
}

var notifier = function(item){

 /* do not process messages older than 12 hours*/
 var today = new Date();
 var itemDate = item.created_at;
 if (Date.parse(today) - Date.parse(itemDate) > 43200000 ) {
     return;
 }

    item.content = item.content.replace(/(<([^>]+)>)/ig,"").replaceAll("&quot;", "\"")

    var msg;
    switch (item.type){
    case "favourite":
        msg = {
            urgency: "normal",
            timestamp: item.created_at,
            summary: (item.reblog_account_display_name !== "" ? item.reblog_account_display_name : '@'+item.reblog_account_username) + ' ' + qsTr("favourited"),
            body: item.content,
            service: 'toot',
            key: item.status_url
        }
        break;

    case "follow":
        msg = {
            urgency: "critical",
            timestamp: item.created_at,
            summary: (item.account_display_name !== "" ? item.account_display_name : '@'+item.account_username),
            body: qsTr("followed you"),
            service: 'profile',
            key: item.account_username
        }
        break;

    case "reblog":
        msg = {
            urgency: "low",
            timestamp: item.created_at,
            summary: (item.reblog_account_display_name !== "" ? item.reblog_account_display_name : '@'+item.reblog_account_username) + ' ' + qsTr("boosted"),
            body: item.content,
            service: 'toot',
            key: item.status_url
        }
        break;

    case "mention":
        msg = {
            urgency: "critical",
            timestamp: item.created_at,
            summary: (item.account_display_name !== "" ? item.account_display_name : '@'+item.account_username) + ' ' + qsTr("said"),
            body: item.content,
            previewBody: (item.account_display_name !== "" ? item.account_display_name : '@'+item.account_username) + ' ' + qsTr("said") + ': ' + item.content,
            service: 'toot',
            key: item.status_url
        }
        break;

    default:
        //console.log(JSON.stringify(messageObject.data))
        return;
    }
    notificationGenerator(msg)
}


var api;

function func() {
    if (debug) console.log(api)
}

/**
 * Parse a URL to detect if it's a Mastodon resource (status, profile, tag)
 * Returns: { type: "status"|"profile"|"tag"|"unknown", data: {...} }
 *
 * Supported patterns:
 * - Status: https://instance.tld/@username/123456789
 * - Status (alt): https://instance.tld/users/username/statuses/123456789
 * - Profile: https://instance.tld/@username
 * - Profile (alt): https://instance.tld/users/username
 * - Tag: https://instance.tld/tags/tagname or /tag/tagname
 */
function parseMastodonUrl(url) {
    if (!url || typeof url !== "string") {
        return { type: "unknown", url: url }
    }

    // Ensure it's an HTTP(S) URL
    if (!url.match(/^https?:\/\//i)) {
        return { type: "unknown", url: url }
    }

    // Normalize: remove trailing slash(es) before parsing
    var normalizedUrl = url.replace(/\/+$/, '')

    var parts = normalizedUrl.split("/")
   if (debug) console.log("logging parts");
   if (debug) console.log(parts);
    parts[0] = "https:", parts[1] = "", parts[2] = "instance.tld"
    //, parts[3] = path

    /*if (parts.length < 4) {
        return { type: "unknown", url: url }
    }*/

    var instance = parts[2]
    var pathPart1 = parts[3]
    var pathPart2 = parts.length > 4 ? parts[4] : null
    var pathPart3 = parts.length > 5 ? parts[5] : null
    var pathPart4 = parts.length > 6 ? parts[6] : null


    // Tag patterns: /tags/tagname or /tag/tagname
    if (parts.length === 5 && (pathPart1 === "tags" || pathPart1 === "tag")) {
        return {
            type: "tag",
            instance: instance,
            tag: decodeURIComponent(pathPart2),
            url: url
        }
    }

    // Profile pattern: /@username (length 4, starts with @)
    if (parts.length === 4 && pathPart1 && pathPart1[0] === "@") {
        return {
            type: "profile",
            instance: instance,
            username: pathPart1.substring(1),  // Remove the @
            acct: pathPart1.substring(1) + "@" + instance,
            url: url
        }
    }

    // Status pattern: /@username/123456789 (length 5, starts with @, numeric ID)
    if (parts.length === 5 && pathPart1 && pathPart1[0] === "@" && /^\d+$/.test(pathPart2)) {
        return {
            type: "status",
            instance: instance,
            username: pathPart1.substring(1),
            statusId: pathPart2,
            url: url
        }
    }

    // Alternative profile pattern: /users/username (length 5)
    if (parts.length === 5 && pathPart1 === "users") {
        return {
            type: "profile",
            instance: instance,
            username: pathPart2,
            acct: pathPart2 + "@" + instance,
            url: url
        }
    }

    // Alternative status pattern: /users/username/statuses/123456789 (length 7)
    if (parts.length === 7 && pathPart1 === "users" && pathPart3 === "statuses" && /^\d+$/.test(pathPart4)) {
        return {
            type: "status",
            instance: instance,
            username: pathPart2,
            statusId: pathPart4,
            url: url
        }
    }

    return { type: "unknown", url: url }
}

// seqDecode(str) -> decoded string
// Decodes %XX sequences (UTF-8 aware). Invalid % sequences are kept as-is.
function seqDecode(input) {
        if (typeof input !== "string")
            return input;
        // Decode an array of bytes (0-255) as UTF-8, falling back to raw chars
        function utf8ToString(bytes) {
            var s = "";
            var i = 0;
            while (i < bytes.length) {
                var b1 = bytes[i];
                var code, need;
                if (b1 < 0x80)       { code = b1;            need = 0; }
                else if (b1 < 0xC0)  { code = b1;            need = 0; } // stray continuation byte
                else if (b1 < 0xE0)  { code = b1 & 0x1F;     need = 1; }
                else if (b1 < 0xF0)  { code = b1 & 0x0F;     need = 2; }
                else if (b1 < 0xF8)  { code = b1 & 0x07;     need = 3; }
                else                 { code = b1;            need = 0; } // invalid lead byte

                var ok = true;
                for (var k = 1; k <= need; ++k) {
                    if (i + k >= bytes.length || (bytes[i + k] & 0xC0) !== 0x80) {
                        ok = false;
                        break;
                    }
                    code = (code << 6) | (bytes[i + k] & 0x3F);
                }

                if (!ok) {
                    s += String.fromCharCode(b1);   // keep raw byte, skip one
                    i += 1;
                } else {
                    if (code > 0xFFFF) {            // astral char -> surrogate pair
                        code -= 0x10000;
                        s += String.fromCharCode(0xD800 + (code >> 10), 0xDC00 + (code & 0x3F));
                    } else {
                        s += String.fromCharCode(code);
                    }
                    i += 1 + need;
                }
            }
            return s;
        }

        var out = "";
        var bytes = [];
        var i = 0;
        var n = input.length;

        function flush() {
            if (bytes.length) {
                out += utf8ToString(bytes);
                bytes = [];
            }
        }

        while (i < n) {
            var c = input.charAt(i);
            if (c === "%" && i + 2 < n) {
                var hex = input.substring(i + 1, i + 3);
                if (/^[0-9A-Fa-f]{2}$/.test(hex)) {
                    bytes.push(parseInt(hex, 16));
                    i += 3;
                    continue;
                }
            }
            flush();
            out += c;
            i += 1;
        }
        flush();

        return out;
}

