//@ This file is part of opal-linkhandler.
//@ https://github.com/Pretty-SFOS/opal-linkhandler
//@ SPDX-FileCopyrightText: 2021-2026 Mirian Margiani
//@ SPDX-FileCopyrightText: 2025 roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Share 1.0
import".."
Page{id:root
property var allowedSchemesRegex:new RegExp(/^https:\/\// )
property url externalUrl
property string title:""
property int previewMode:LinkPreviewMode.disabled
readonly property bool _schemeAllowed:allowedSchemesRegex.test(externalUrl)
property bool _networkIsConnected:netCheck.item?netCheck.item.networkIsConnected:false
property bool _networkIsWifi:netCheck.item?netCheck.item.networkIsWifi:false
property bool _networkStatus:_networkIsConnected&&_networkIsWifi
property bool _haveWebviewModule:false
property bool _haveWebviewModuleTested:false
property bool _previewEnabled:_schemeAllowed&&previewMode!=LinkPreviewMode.disabled&&(_haveWebviewModule||(!_haveWebviewModuleTested&&_testWebview()))&&(previewMode==LinkPreviewMode.enabled||_networkIsConnected&&(previewMode==LinkPreviewMode.auto||(previewMode==LinkPreviewMode.disabledIfMobile&&_networkIsWifi)))
allowedOrientations:Orientation.All
onPreviewModeChanged:console.log("[Opal.LinkHandler] mode:",previewMode)
on_NetworkStatusChanged:console.log("[Opal.LinkHandler] network connected:",_networkIsConnected,"| is wifi:",_networkIsWifi)
on_HaveWebviewModuleChanged:console.log("[Opal.LinkHandler] have webview module:",_haveWebviewModule)
on_PreviewEnabledChanged:{console.log("[Opal.LinkHandler] preview enabled:",_previewEnabled)
if(!_previewEnabled&&pageStack.nextPage(root)&&pageStack.nextPage(root).hasOwnProperty("__linkhandler_webview")){pageStack.popAttached()
}}function _testWebview(){if(!_haveWebviewModuleTested){try{const tester=Qt.createQmlObject("\n                        import Sailfish.WebView 1.0\n                        import QtQuick 2.0\n                        QtObject {}",root,"WebviewTester [inline]")
}catch(err){console.log(err)
_haveWebviewModule=false
}if(typeof tester!=="undefined"){tester.destroy()
_haveWebviewModule=true
}_haveWebviewModuleTested=true
}return _haveWebviewModule
}function _copyAndClose(text){Clipboard.text=text
Notices.show(qsTranslate("Opal.LinkHandler","Copied to clipboard: %1").arg(Clipboard.text),5000,Notice.Top)
pageStack.pop()
}Loader{id:netCheck
active:previewMode==LinkPreviewMode.auto||previewMode==LinkPreviewMode.disabledIfMobile
asynchronous:true
source:Qt.resolvedUrl("ConnectivityCheck.qml")
}Timer{interval:0
running:_previewEnabled
onTriggered:pageStack.pushAttached(Qt.resolvedUrl("PreviewPage.qml"),{externalUrl:externalUrl})
}ShareAction{id:shareHandler
mimeType:"text/x-url"
title:qsTranslate("Opal.LinkHandler","Share link")
}Column{width:parent.width
spacing:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.itemSizeExtraSmall:Theme.itemSizeSmall
y:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.paddingLarge:Theme.itemSizeExtraLarge
Label{text:title?title:(externalUrl.toString().substring(0,4)==="tel:"?qsTranslate("Opal.LinkHandler","Phone number"):qsTranslate("Opal.LinkHandler","External link"))
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeExtraLarge
wrapMode:Text.Wrap
}Label{text:externalUrl
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeMedium
wrapMode:Text.Wrap
}}Column{anchors{bottom:parent.bottom
bottomMargin:(root.isLandscape&&Screen.sizeCategory<=Screen.Medium)?Theme.itemSizeExtraSmall:Theme.itemSizeMedium
}width:parent.width
spacing:Theme.paddingLarge
height:implicitHeight
Behavior on height{NumberAnimation{duration:200
}}ButtonLayout{preferredWidth:Theme.buttonWidthLarge
Button{ButtonLayout.newLine:root.isPortrait
text:/^http[s]?:\/\// .test(externalUrl)?qsTranslate("Opal.LinkHandler","Open in browser"):qsTranslate("Opal.LinkHandler","Open externally")
onClicked:{Qt.openUrlExternally(externalUrl)
pageStack.pop()
}}Button{text:qsTranslate("Opal.LinkHandler","Share")
onClicked:{shareHandler.resources=[{"type":"text/x-url","linkTitle":title,"status":externalUrl.toString()}]
shareHandler.trigger()
pageStack.pop()
}}}ButtonLayout{preferredWidth:root.isPortrait&&!!title?Theme.buttonWidthSmall:Theme.buttonWidthLarge
Button{text:qsTranslate("Opal.LinkHandler","Copy link")
onClicked:_copyAndClose(externalUrl.toString())
}Button{text:qsTranslate("Opal.LinkHandler","Copy text")
visible:!!title
onClicked:_copyAndClose(title)
}}Label{text:qsTr("Swipe left to preview.")+(_networkIsConnected&&!_networkIsWifi?"\n"+qsTr("You are using a mobile data connection."):"")
visible:canNavigateForward&&pageStack.nextPage(root).hasOwnProperty("__linkhandler_webview")
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.secondaryHighlightColor
font.pixelSize:Theme.fontSizeSmall
wrapMode:Text.Wrap
}}}