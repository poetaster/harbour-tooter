# Proposed Changes for Harbour-Tooter

## Overview

This document outlines proposed improvements to bring Tooter closer to feature parity with modern Mastodon clients like Phanpy, along with performance optimizations.

**All changes are QML/JavaScript only - no SDK or compilation required.**

Files can be synced to device via:
```bash
rsync -avz qml/ nemo@<device-ip>:/usr/share/harbour-tooterb/qml/
```

---

## Part 1: New Features

### 1.1 Delete Status
**Effort:** 1-2 hours | **Priority:** High

**Files to modify:**
- `qml/lib/Mastodon.js` - Fix delete method (currently uses unavailable jQuery)
- `qml/pages/components/VisualContainer.qml` - Add "Delete" menu item

**Implementation:**
```javascript
// Mastodon.js - Replace jQuery-based delete with XMLHttpRequest
delete: function (endpoint, callback) {
    var http = new XMLHttpRequest();
    http.open("DELETE", apiBase + endpoint, true);
    http.setRequestHeader("Authorization", "Bearer " + config.api_user_token);
    http.setRequestHeader("Content-Type", "application/json");
    http.onreadystatechange = function() {
        if (http.readyState === 4 && http.status === 200) {
            callback(JSON.parse(http.response), http.status);
        }
    };
    http.send();
}
```

**UI:** Add MenuItem in VisualContainer.qml context menu, visible only for own posts. Include confirmation dialog (RemorseItem).

---

### 1.2 Edit Status
**Effort:** 3-5 hours | **Priority:** High

**Files to modify:**
- `qml/lib/Mastodon.js` - Add PUT method
- `qml/lib/Worker.js` - Handle edit action, fetch source
- `qml/pages/components/VisualContainer.qml` - Add "Edit" menu item
- `qml/pages/ConversationPage.qml` - Support edit mode

**API endpoints:**
- `GET /api/v1/statuses/:id/source` - Get original text for editing
- `PUT /api/v1/statuses/:id` - Submit edited status

**Implementation:**
```javascript
// Mastodon.js - Add PUT method
put: function (endpoint, putData, callback) {
    var http = new XMLHttpRequest();
    http.open("PUT", apiBase + endpoint, true);
    http.setRequestHeader("Authorization", "Bearer " + config.api_user_token);
    http.setRequestHeader("Content-Type", "application/json");
    http.onreadystatechange = function() {
        if (http.readyState === 4 && http.status === 200) {
            callback(JSON.parse(http.response), http.status);
        }
    };
    http.send(JSON.stringify(putData));
}
```

---

### 1.3 Alt-Text Display
**Effort:** 1-2 hours | **Priority:** High

**Files to modify:**
- `qml/lib/Worker.js:402-408` - Capture description field
- `qml/pages/components/MyMedia.qml` - Display alt-text icon/overlay
- `qml/pages/components/MediaFullScreen.qml` - Show alt-text as caption

**Implementation:**
```javascript
// Worker.js - In parseToot, media attachments section (~line 402)
var tmp = {
    id: attachments['id'],
    type: attachments['type'],
    url: attachments['remote_url'] && typeof attachments['remote_url'] == "string"
         ? attachments['remote_url'] : attachments['url'],
    preview_url: loadImages ? attachments['preview_url'] : '',
    description: attachments['description'] || ''  // ADD THIS
}
```

**UI:** Show "ALT" badge on images that have descriptions. On long-press or in fullscreen view, display the description text.

---

### 1.4 Collapsible Long Posts
**Effort:** 2-3 hours | **Priority:** High

**Files to modify:**
- `qml/pages/components/VisualContainer.qml` - Add expand/collapse logic

**Implementation:**
```qml
// VisualContainer.qml - Add properties
property bool expanded: false
property int charLimit: 500

function getTextLength(html) {
    return html.replace(/<[^>]*>/g, '').length
}

function truncateHtml(html, limit) {
    var text = html.replace(/<[^>]*>/g, '')
    if (text.length <= limit) return html
    // Find a good break point, preserve HTML structure
    var truncated = text.substring(0, limit)
    var lastSpace = truncated.lastIndexOf(' ')
    if (lastSpace > limit - 50) truncated = truncated.substring(0, lastSpace)
    return truncated + '...'
}

property bool isLongPost: getTextLength(content) > charLimit
```

**UI:** When collapsed, show truncated content with "Show more" link. When expanded, show full content with "Show less" link.

---

### 1.5 Thread Indicators
**Effort:** 2-3 hours | **Priority:** Medium

**Files to modify:**
- `qml/lib/Worker.js` - Track thread position in parseToot
- `qml/pages/components/MiniHeader.qml` or `VisualContainer.qml` - Display indicator

**Implementation:**
- When fetching context, count ancestors + 1 (current) + descendants
- Pass `thread_position` and `thread_total` to model
- Display "1/5" style badge near timestamp

---

### 1.6 Expanded Search
**Effort:** 4-6 hours | **Priority:** Medium

**Files to modify:**
- `qml/lib/Worker.js` - Handle search results for statuses
- `qml/pages/MainPage.qml` - Add search type selector (Accounts | Tags | Posts)

**API:** `GET /api/v2/search?q=term&type=statuses`

**Note:** Full-text search for all posts requires server-side Elasticsearch. Without it, only searches user's own posts, favorites, and bookmarks.

---

### 1.7 Grouped Notifications
**Effort:** 6-10 hours | **Priority:** Medium

**Files to modify:**
- `qml/lib/Mastodon.js` - Support `/api/v2/notifications` endpoint
- `qml/lib/Worker.js` - Parse grouped notification structure
- `qml/pages/components/VisualContainer.qml` - New UI for grouped display

**API:** `GET /api/v2/notifications` (Mastodon 4.3+)

**Complexity:**
- New data structure with `group_key`, `notifications_count`, `sample_account_ids`
- UI needs stacked avatars and "X people boosted" text
- Requires server version detection for fallback to v1

---

## Part 2: Performance Improvements

### 2.1 Deduplication Algorithm - O(n²) → O(n)
**File:** `qml/pages/components/MyList.qml:260-308`
**Impact:** High - runs on every model update

**Problem:**
```javascript
// Current: O(n²) - removeDuplicates called inside loop
for(i = 0 ; i < model.count ; i++) {
    ids.push(model.get(i).id)
    uniqueItems = removeDuplicates(ids)  // Called n times!
}
```

**Solution:**
```javascript
// Use object as hash set - O(n)
function deDouble() {
    var seen = {}
    var toRemove = []
    for (var i = 0; i < model.count; i++) {
        var id = model.get(i).id
        if (seen[id]) {
            toRemove.push(i)
        } else {
            seen[id] = true
        }
    }
    // Remove in reverse order to preserve indices
    for (var j = toRemove.length - 1; j >= 0; j--) {
        model.remove(toRemove[j], 1)
    }
}
```

---

### 2.2 Worker.js knownIds Lookup - O(n) → O(1)
**File:** `qml/lib/Worker.js:202, 214`
**Impact:** Medium - runs for every item in timeline

**Problem:**
```javascript
if (knownIds.indexOf(items[i]["id"]) === -1)  // O(n) lookup
```

**Solution:**
```javascript
// Convert to object for O(1) lookup
var knownIdsSet = {}
// When receiving ids:
for (var i = 0; i < knownIds.length; i++) {
    knownIdsSet[knownIds[i]] = true
}
// When checking:
if (!knownIdsSet[items[i]["id"]])
```

---

### 2.3 Content HTML Processing - Multiple Passes → Single Pass
**File:** `qml/lib/Worker.js:390-394`
**Impact:** Medium - runs for every toot

**Problem:**
```javascript
// 4 separate regex operations
item['content'] = item['content']
    .replaceAll('</span><span class="invisible">', '')
    .replaceAll('<span class="invisible">', '')
    .replaceAll('</span><span class="ellipsis">', '')
    .replaceAll('class=""', '');
```

**Solution:**
```javascript
// Single regex with alternation
item['content'] = item['content'].replace(
    /<\/span><span class="invisible">|<span class="invisible">|<\/span><span class="ellipsis">|class=""/g,
    ''
);
```

---

### 2.4 Emoji Replacement - Batch Processing
**File:** `qml/lib/Worker.js:430-444`
**Impact:** Medium - runs for posts with custom emojis

**Problem:**
```javascript
// Creates new regex for each emoji
for (i = 0; i < data["emojis"].length; i++) {
    emoji = data["emojis"][i];
    item['content'] = item['content'].replaceAll(
        ":"+emoji.shortcode+":",
        "<img...>"
    );
}
```

**Solution:**
```javascript
// Build single regex for all emojis
if (data["emojis"].length > 0) {
    var emojiMap = {}
    var pattern = data["emojis"].map(function(e) {
        emojiMap[':' + e.shortcode + ':'] = '<img src="' + e.static_url + '" align="top" width="50" height="50">'
        return ':' + e.shortcode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ':'
    }).join('|')

    item['content'] = item['content'].replace(new RegExp(pattern, 'g'), function(match) {
        return emojiMap[match]
    })
}
```

---

### 2.5 QML Binding Optimization
**File:** `qml/pages/components/VisualContainer.qml:173`
**Impact:** Low-Medium - recalculates on press state change

**Problem:**
```qml
// Regex runs every time 'pressed' changes
text: content.replace(new RegExp("<a ", 'g'), '<a style="..."')
```

**Solution:**
```qml
// Cache the processed content
property string processedContent: content.replace(/<a /g, '<a style="text-decoration: none; color:' + Theme.highlightColor + '" ')
property string processedContentPressed: content.replace(/<a /g, '<a style="text-decoration: none; color:' + Theme.secondaryColor + '" ')

text: pressed ? processedContentPressed : processedContent
```

---

### 2.6 Avoid Dynamic QML Object Creation
**File:** `qml/pages/components/VisualContainer.qml:264, 422`
**Impact:** Low - runs on user interaction

**Problem:**
```qml
// Creates new QML object at runtime - expensive
Qt.createQmlObject('import QtQuick 2.0; ListModel { }', ...)
```

**Solution:**
- Pre-create reusable ListModel in component
- Or use a pool of pre-created models
- For the MediaBlock case, handle empty attachments in the component itself

---

### 2.7 uniqueIds Array Rebuilding
**File:** `qml/pages/components/MyList.qml:321-325`
**Impact:** Medium - runs on every loadData call

**Problem:**
```javascript
// Rebuilds entire array every time
for(var i = 0 ; i < model.count ; i++) {
    uniqueIds.push(model.get(i).id)
}
uniqueIds = removeDuplicates(uniqueIds)
```

**Solution:**
- Maintain uniqueIds incrementally
- Add new IDs when items are added to model
- Don't rebuild from scratch each time

---

## Part 3: Summary

### Implementation Order (Recommended)

| Phase | Features | Effort |
|-------|----------|--------|
| 1 | Delete, Alt-Text, Collapsible Posts | 4-7h |
| 2 | Edit Status | 3-5h |
| 3 | Performance fixes (2.1, 2.2, 2.3) | 2-3h |
| 4 | Thread Indicators | 2-3h |
| 5 | Expanded Search | 4-6h |
| 6 | Grouped Notifications | 6-10h |

**Total: ~21-34 hours**

### Files Modified Summary

| File | Changes |
|------|---------|
| `qml/lib/Mastodon.js` | Add PUT, fix DELETE |
| `qml/lib/Worker.js` | Alt-text, performance, thread tracking |
| `qml/pages/components/VisualContainer.qml` | Delete/Edit menu, collapsible, performance |
| `qml/pages/components/MyMedia.qml` | Alt-text display |
| `qml/pages/components/MyList.qml` | Performance fixes |
| `qml/pages/components/MiniHeader.qml` | Thread indicator |
| `qml/pages/ConversationPage.qml` | Edit mode |
| `qml/pages/MainPage.qml` | Search type selector |

---

## Testing Checklist

- [ ] Delete own post
- [ ] Edit own post
- [ ] View alt-text on images
- [ ] Long posts collapse/expand
- [ ] Thread position shows correctly
- [ ] Search finds posts (if server supports)
- [ ] Grouped notifications display (Mastodon 4.3+)
- [ ] Performance: smooth scrolling with 100+ items
- [ ] No duplicate posts in timeline
