import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Share 1.0

Page {
    id: readerPage
    property string articleUrl: ""
    property bool loading: true
    property string errorMessage: ""
    property string articleTitle: ""
    property string articleContent: ""
    property string articleSiteName: ""

    ShareAction {
        id: shareAction
        mimeType: "text/x-url"
        // Properties set dynamically before trigger()
    }

    function shareLink() {
        shareAction.title = articleTitle.length > 0 ? articleTitle : articleSiteName
        shareAction.resources = [{
            "type": "text/x-url",
            "linkTitle": articleTitle,
            "status": articleUrl
        }]
        shareAction.trigger()
    }

    // File extensions that are not readable articles
    property var nonReadableExtensions: [
        // Images
        "gif", "jpg", "jpeg", "png", "webp", "svg", "bmp", "ico", "tiff", "tif",
        // Videos
        "mp4", "webm", "avi", "mov", "mkv", "m4v", "flv", "wmv",
        // Audio
        "mp3", "wav", "ogg", "flac", "aac", "m4a",
        // Documents (binary)
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp",
        // Archives
        "zip", "rar", "7z", "tar", "gz", "bz2",
        // Other
        "exe", "dmg", "apk", "ipa", "bin", "iso", "rpm", "deb"
    ]

    Component.onCompleted: {
        console.log("ReaderPage: loaded with url = " + articleUrl)
        if (articleUrl) {
            // Check URL extension before fetching - open directly in browser if not readable
            if (isNonReadableUrl(articleUrl)) {
                console.log("ReaderPage: Non-readable URL, opening in browser")
                Qt.openUrlExternally(articleUrl)
                pageStack.pop()
            } else {
                fetchArticle()
            }
        }
    }

    // Check if URL points to a non-readable file type
    function isNonReadableUrl(url) {
        // Extract path from URL (remove query string and fragment)
        var path = url.split("?")[0].split("#")[0].toLowerCase()
        // Get extension
        var lastDot = path.lastIndexOf(".")
        var lastSlash = path.lastIndexOf("/")
        // Only check extension if dot is after the last slash
        if (lastDot > lastSlash && lastDot > 0) {
            var ext = path.substring(lastDot + 1)
            for (var i = 0; i < nonReadableExtensions.length; i++) {
                if (ext === nonReadableExtensions[i]) {
                    console.log("ReaderPage: Non-readable extension detected: " + ext)
                    return true
                }
            }
        }
        return false
    }

    // Check Content-Type header to determine if content is readable
    function isReadableContentType(contentType) {
        if (!contentType) return true  // Assume readable if no header
        var type = contentType.toLowerCase().split(";")[0].trim()
        // Readable types
        if (type.indexOf("text/html") === 0) return true
        if (type.indexOf("text/plain") === 0) return true
        if (type.indexOf("application/xhtml") === 0) return true
        // Non-readable types
        if (type.indexOf("image/") === 0) return false
        if (type.indexOf("video/") === 0) return false
        if (type.indexOf("audio/") === 0) return false
        if (type.indexOf("application/pdf") === 0) return false
        if (type.indexOf("application/zip") === 0) return false
        if (type.indexOf("application/octet-stream") === 0) return false
        // Default to readable for unknown types
        return true
    }

    function fetchArticle() {
        loading = true
        errorMessage = ""
        console.log("ReaderPage: Fetching " + articleUrl)

        var http = new XMLHttpRequest()
        http.open("GET", articleUrl, true)
        http.setRequestHeader("User-Agent", "Mozilla/5.0 (Linux; Sailfish) Tooter/1.0")

        http.onreadystatechange = function() {
            if (http.readyState === 4) {
                console.log("ReaderPage: Got response, status=" + http.status)
                if (http.status === 200) {
                    // Check Content-Type before parsing
                    var contentType = http.getResponseHeader("Content-Type")
                    console.log("ReaderPage: Content-Type = " + contentType)
                    if (!isReadableContentType(contentType)) {
                        console.log("ReaderPage: Non-readable Content-Type, opening in browser")
                        Qt.openUrlExternally(articleUrl)
                        pageStack.pop()
                        return
                    }
                    parseArticle(http.responseText)
                } else if (http.status === 0) {
                    errorMessage = "Network error - could not connect"
                    loading = false
                } else if (http.status === 401) {
                    errorMessage = "This site requires login or blocks reader mode"
                    loading = false
                } else if (http.status === 403) {
                    errorMessage = "This site blocks automated access"
                    loading = false
                } else if (http.status === 404) {
                    errorMessage = "Article not found"
                    loading = false
                } else {
                    errorMessage = "Could not load article (HTTP " + http.status + ")"
                    loading = false
                }
            }
        }

        http.onerror = function() {
            console.log("ReaderPage: XHR error")
            errorMessage = "Network error"
            loading = false
        }

        http.send()
    }

    function parseArticle(html) {
        console.log("ReaderPage: Parsing, length=" + html.length)
        try {
            // Extract title
            var titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i)
            if (titleMatch) {
                articleTitle = titleMatch[1].trim()
            }

            // Extract site name from og:site_name
            var siteMatch = html.match(/<meta[^>]+property=.og:site_name.[^>]+content=.([^"']+)./i)
            if (siteMatch) {
                articleSiteName = siteMatch[1]
            }

            // Simple content extraction
            var content = html
            content = content.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
            content = content.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
            content = content.replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, '')
            content = content.replace(/<header[^>]*>[\s\S]*?<\/header>/gi, '')
            content = content.replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, '')

            // Try to find article or main content
            var articleMatch = content.match(/<article[^>]*>([\s\S]*?)<\/article>/i)
            if (articleMatch) {
                content = articleMatch[1]
            } else {
                var mainMatch = content.match(/<main[^>]*>([\s\S]*?)<\/main>/i)
                if (mainMatch) {
                    content = mainMatch[1]
                }
            }

            // Convert to text
            content = content.replace(/<\/p>/gi, '\n\n')
            content = content.replace(/<br\s*\/?>/gi, '\n')
            content = content.replace(/<[^>]+>/g, '')
            content = content.replace(/&nbsp;/g, ' ')
            content = content.replace(/&amp;/g, '&')
            content = content.replace(/&lt;/g, '<')
            content = content.replace(/&gt;/g, '>')
            content = content.replace(/[ \t]+/g, ' ')
            content = content.replace(/\n\s*\n\s*\n/g, '\n\n')
            content = content.trim()

            if (content.length > 100) {
                articleContent = content
            } else {
                errorMessage = "Could not extract content"
            }
        } catch (e) {
            console.log("ReaderPage: Parse error - " + e)
            errorMessage = "Parse error"
        }
        loading = false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Share")
                onClicked: shareLink()
            }
            MenuItem {
                text: qsTr("Copy link")
                onClicked: Clipboard.text = articleUrl
            }
            MenuItem {
                text: qsTr("Open in browser")
                onClicked: Qt.openUrlExternally(articleUrl)
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: articleSiteName.length > 0 ? articleSiteName : "Reader"
            }

            BusyIndicator {
                visible: loading
                running: loading
                size: BusyIndicatorSize.Large
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                visible: loading
                text: "Loading..."
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                visible: errorMessage.length > 0
                text: errorMessage
                color: Theme.errorColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                visible: errorMessage.length > 0
                text: "Open in browser instead"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Qt.openUrlExternally(articleUrl)
                    pageStack.pop()
                }
            }

            Label {
                visible: !loading && articleTitle.length > 0
                text: articleTitle
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
            }

            Label {
                visible: !loading && articleContent.length > 0
                text: articleContent
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
            }
        }

        VerticalScrollDecorator {}
    }
}
