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

### 1.8 Link Previews (Cards)
**Effort:** 4-6 hours | **Priority:** Medium

**Problem:** Tooter doesn't display link previews (OpenGraph cards) for URLs in toots. Modern clients like Phanpy show rich previews with title, description, and thumbnail.

**Files to modify:**
- `qml/lib/Worker.js` - Parse `card` object from status response
- `qml/pages/components/VisualContainer.qml` - Add card display component

**API Data:** Mastodon includes a `card` object in status responses:
```json
{
  "card": {
    "url": "https://example.com/article",
    "title": "Article Title",
    "description": "Article description...",
    "type": "link",
    "image": "https://example.com/preview.jpg",
    "provider_name": "Example.com"
  }
}
```

**Implementation:**

1. **Worker.js - Parse card data in parseToot:**
```javascript
// In parseToot function, after existing fields
if (data["card"]) {
    item['card_url'] = data["card"]["url"]
    item['card_title'] = data["card"]["title"]
    item['card_description'] = data["card"]["description"]
    item['card_image'] = data["card"]["image"] || ''
    item['card_type'] = data["card"]["type"]  // link, photo, video, rich
    item['card_provider'] = data["card"]["provider_name"] || ''
} else {
    item['card_url'] = ''
}
```

2. **VisualContainer.qml - Add card display:**
```qml
// After the content Label, before MediaBlock
Rectangle {
    id: linkPreview
    visible: model.card_url && model.card_url.length > 0
    width: parent.width
    height: visible ? linkPreviewColumn.height + Theme.paddingMedium * 2 : 0
    color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
    radius: Theme.paddingSmall

    MouseArea {
        anchors.fill: parent
        onClicked: Qt.openUrlExternally(model.card_url)
    }

    Row {
        anchors.fill: parent
        anchors.margins: Theme.paddingMedium
        spacing: Theme.paddingMedium

        // Thumbnail (if available)
        Image {
            id: cardImage
            visible: model.card_image && model.card_image.length > 0
            width: visible ? Theme.itemSizeLarge : 0
            height: Theme.itemSizeLarge
            source: model.card_image
            fillMode: Image.PreserveAspectCrop
        }

        Column {
            id: linkPreviewColumn
            width: parent.width - (cardImage.visible ? cardImage.width + Theme.paddingMedium : 0)
            spacing: Theme.paddingSmall / 2

            // Provider name
            Label {
                visible: model.card_provider && model.card_provider.length > 0
                text: model.card_provider
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
                truncationMode: TruncationMode.Fade
                width: parent.width
            }

            // Title
            Label {
                text: model.card_title || ""
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                maximumLineCount: 2
                width: parent.width
            }

            // Description (truncated)
            Label {
                visible: model.card_description && model.card_description.length > 0
                text: model.card_description || ""
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
                maximumLineCount: 2
                width: parent.width
            }
        }
    }
}
```

**Card Types:**
- `link` - Standard web page with title/description
- `photo` - Image-focused preview
- `video` - Video embed (YouTube, etc.)
- `rich` - Interactive embed (rare)

**Considerations:**
- Cards only appear if the linked page has OpenGraph/Twitter Card meta tags
- Some servers cache cards; may take time to populate
- Videos should open in browser (not embed due to platform limitations)
- Consider caching card images to reduce bandwidth

---

### 1.9 Image Editor (Cropper)
**Effort:** 8-12 hours | **Priority:** Low

**Problem:** When attaching images to toots, users cannot crop or edit images before posting. This is useful for:
- Removing unwanted parts of screenshots
- Adjusting aspect ratio for better display
- Basic image adjustments

**Files to create/modify:**
- `qml/pages/components/ImageEditor.qml` - New component for image editing
- `qml/pages/ConversationPage.qml` - Integration with image picker flow

**Implementation Approach:**

1. **Basic Cropper Component:**
```qml
// ImageEditor.qml
import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    id: imageEditor
    property string sourceImage: ""
    property var cropRect: Qt.rect(0, 0, 1, 1)  // Normalized coordinates

    canAccept: true

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: qsTr("Edit Image")
                acceptText: qsTr("Apply")
            }

            Item {
                width: parent.width
                height: width  // Square editing area

                Image {
                    id: sourceImg
                    source: sourceImage
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    width: parent.width
                    height: parent.height
                }

                // Crop overlay with draggable corners
                Rectangle {
                    id: cropOverlay
                    color: "transparent"
                    border.color: Theme.highlightColor
                    border.width: 2

                    // Position based on cropRect
                    x: sourceImg.x + cropRect.x * sourceImg.paintedWidth
                    y: sourceImg.y + cropRect.y * sourceImg.paintedHeight
                    width: cropRect.width * sourceImg.paintedWidth
                    height: cropRect.height * sourceImg.paintedHeight

                    // Corner handles for resizing
                    Repeater {
                        model: 4  // Four corners
                        Rectangle {
                            width: Theme.paddingLarge
                            height: Theme.paddingLarge
                            color: Theme.highlightColor
                            radius: width / 2
                            // Position at corners...
                        }
                    }
                }
            }

            // Aspect ratio presets
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                Button {
                    text: "1:1"
                    onClicked: setAspectRatio(1, 1)
                }
                Button {
                    text: "4:3"
                    onClicked: setAspectRatio(4, 3)
                }
                Button {
                    text: "16:9"
                    onClicked: setAspectRatio(16, 9)
                }
                Button {
                    text: qsTr("Free")
                    onClicked: freeAspect = true
                }
            }
        }
    }

    function setAspectRatio(w, h) {
        // Adjust cropRect to maintain aspect ratio
    }

    onAccepted: {
        // Apply crop using C++ image processing or
        // pass crop coordinates to upload with server-side processing
    }
}
```

2. **Integration Flow:**
   - After image is selected from picker, open ImageEditor
   - User can crop/adjust the image
   - On accept, either:
     a. Process locally using Qt's QImage (requires C++ helper)
     b. Store crop coordinates and apply before upload
     c. Upload original and let server crop (if supported)

**Technical Considerations:**
- **Pure QML limitation:** QML cannot directly manipulate image pixels
- **Options for cropping:**
  1. **C++ Helper:** Create a simple C++ class to crop images using Qt's QImage
  2. **Canvas element:** Use HTML5 Canvas in QML for basic operations
  3. **External tool:** Call ImageMagick via Bash (if available on device)
  4. **Server-side:** Some instances support focal point for cropping

**Minimal C++ Helper (if needed):**
```cpp
// ImageCropper.h
class ImageCropper : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE QString cropImage(const QString &sourcePath,
                                   int x, int y, int width, int height);
};

// Returns path to cropped temp file
QString ImageCropper::cropImage(...) {
    QImage img(sourcePath);
    QImage cropped = img.copy(x, y, width, height);
    QString tempPath = QDir::temp().filePath("cropped_" + ...);
    cropped.save(tempPath);
    return tempPath;
}
```

**Simpler Alternative - Focal Point:**
Instead of full cropping, implement focal point selection:
- User taps on the most important part of the image
- This point is sent with the upload as `focus` parameter
- Mastodon uses this for thumbnail generation

```javascript
// In upload params
{
    "file": imageData,
    "focus": "0.5,-0.2"  // x,y from -1.0 to 1.0
}
```

---

### 1.10 Quote Boosts (Quote Posts)
**Effort:** 4-6 hours | **Priority:** Medium

**Problem:** Mastodon now supports native quote posts (quote boosts), where a user can quote another post with their own commentary. Tooter doesn't currently display these quoted posts inline.

**API Data:** When a status quotes another, the API returns a `quote` object:
```json
{
  "id": "123456",
  "content": "<p>My commentary on this post</p>",
  "quote": {
    "id": "789012",
    "content": "<p>The original quoted post content</p>",
    "account": {
      "display_name": "Original Author",
      "acct": "author@instance.social",
      "avatar": "https://..."
    },
    "created_at": "2024-01-01T12:00:00Z",
    "media_attachments": []
  }
}
```

**Files to modify:**
- `qml/lib/Worker.js` - Parse `quote` object from status response
- `qml/pages/components/VisualContainer.qml` - Add quoted post display component

**Implementation:**

1. **Worker.js - Parse quote data in parseToot:**
```javascript
// In parseToot function, after card parsing
if (data["quote"]) {
    item['quote_id'] = data["quote"]["id"]
    item['quote_content'] = data["quote"]["content"]
    item['quote_account_display_name'] = data["quote"]["account"]["display_name"]
    item['quote_account_acct'] = data["quote"]["account"]["acct"]
    item['quote_account_avatar'] = data["quote"]["account"]["avatar"]
    item['quote_created_at'] = new Date(data["quote"]["created_at"])
    item['quote_url'] = data["quote"]["url"] || ''
} else {
    item['quote_id'] = ''
}

// Handle quotes in reblogs too
if (item['status_reblog'] && data["reblog"]["quote"]) {
    var q = data["reblog"]["quote"]
    item['quote_id'] = q["id"]
    item['quote_content'] = q["content"]
    // ... same fields
}
```

2. **VisualContainer.qml - Add quoted post display:**
```qml
// After linkPreview, before context menu
Rectangle {
    id: quotedPost
    visible: typeof model.quote_id !== "undefined" && model.quote_id.length > 0
    width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
    height: visible ? quotedContent.height + Theme.paddingMedium * 2 : 0
    color: "transparent"
    border.color: Theme.rgba(Theme.highlightColor, 0.3)
    border.width: 1
    radius: Theme.paddingSmall
    anchors {
        left: lblContent.left
        right: lblContent.right
        top: linkPreview.visible ? linkPreview.bottom :
             ((typeof attachments !== "undefined" && attachments.count) ? media.bottom :
             (showMoreLabel.visible ? showMoreLabel.bottom : lblContent.bottom))
        topMargin: Theme.paddingMedium
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Navigate to the quoted post
            if (model.quote_url) Qt.openUrlExternally(model.quote_url)
        }
    }

    Column {
        id: quotedContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        // Quoted post header (avatar + name)
        Row {
            spacing: Theme.paddingSmall
            Image {
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                source: model.quote_account_avatar || ""
                fillMode: Image.PreserveAspectCrop
            }
            Label {
                text: model.quote_account_display_name || ""
                font.pixelSize: Theme.fontSizeExtraSmall
                font.bold: true
                color: Theme.highlightColor
            }
            Label {
                text: "@" + (model.quote_account_acct || "")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }

        // Quoted post content (truncated)
        Label {
            text: model.quote_content || ""
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.primaryColor
            wrapMode: Text.Wrap
            maximumLineCount: 4
            truncationMode: TruncationMode.Elide
            width: parent.width
            textFormat: Text.StyledText
        }
    }
}
```

**Considerations:**
- Quote posts are a relatively new Mastodon feature (added in Mastodon 4.x)
- Need to check server compatibility - older servers may not support quotes
- Quoted posts can themselves have media attachments (consider showing thumbnail)
- Clicking on quoted post should navigate to that post's conversation
- Consider visual distinction (border, background) to clearly show it's a quote

**Creating Quote Posts:**
To allow users to create quote posts, ConversationPage.qml would need:
- Accept a `quote_id` parameter
- Show preview of quoted post in compose area
- Send `quote_id` with POST to `/api/v1/statuses`

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
