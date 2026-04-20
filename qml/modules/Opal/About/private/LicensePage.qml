//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import".."
Page{id:root
property Attribution mainAttribution
property list<Attribution>attributions
property bool enableSourceHint:true
property alias pageDescription:pageHeader.description
property int allowDownloadingLicenses:NetworkMode.auto
property list<License>licenses
property string appName
property string mainSources
property string mainHomepage
property bool includeOpal:true
function _downloadLicenses(){for(var i=0;i<mainAttribution.licenses.length;++i){mainAttribution.licenses[i].__online=true
}for(var k=0;k<attributions.length;++k){for(var j=0;j<attributions[j].licenses.length;++j){attributions[k].licenses[j].__online=true
}}for(var m=0;m<opalAttributions.loadedAttributions.length;++m){for(var l=0;l<opalAttributions.loadedAttributions[m].licenses.length;++l){opalAttributions.loadedAttributions[m].licenses[l].__online=true
}}}allowedOrientations:Orientation.All
Loader{id:netCheck
active:allowDownloadingLicenses==NetworkMode.auto||allowDownloadingLicenses==NetworkMode.enabled
asynchronous:true
source:Qt.resolvedUrl("ConnectivityCheck.qml")
property bool _networkIsConnected:item?item.networkIsConnected:false
property bool _networkIsWifi:item?item.networkIsWifi:false
}OpalAttributionsLoader{id:opalAttributions
enabled:includeOpal
}SilicaFlickable{id:flick
anchors.fill:parent
contentHeight:column.height+Theme.horizontalPageMargin
VerticalScrollDecorator{flickable:flick
}PullDownMenu{visible:allowDownloadingLicenses==NetworkMode.enabled||(allowDownloadingLicenses==NetworkMode.auto&&netCheck._networkIsConnected)
enabled:visible
MenuItem{text:qsTranslate("Opal.About","Download license texts")
onClicked:_downloadLicenses()
}MenuLabel{visible:netCheck._networkIsConnected&&!netCheck._networkIsWifi
text:qsTranslate("Opal.About","You are using a mobile data connection.")
}}Column{id:column
width:parent.width
spacing:Theme.paddingMedium
PageHeader{id:pageHeader
title:(!includeOpal&&root.mainAttribution.licenses.length+attributions.length===0)?qsTranslate("Opal.About","Details"):qsTranslate("Opal.About","License(s)","",root.mainAttribution.licenses.length+attributions.length)
description:mainAttribution.name
}Label{visible:enableSourceHint
width:parent.width-2*Theme.horizontalPageMargin
height:visible?implicitHeight+Theme.paddingLarge:0
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignLeft
wrapMode:Text.Wrap
font.pixelSize:Theme.fontSizeExtraSmall
color:Theme.highlightColor
text:qsTranslate("Opal.About","Note: please check the source code for most accurate information.")
}LicenseListPart{visible:root.mainAttribution.licenses.length>0||root.mainAttribution.__effectiveEntries.length>0||root.mainAttribution.description!==""
title:root.mainAttribution.name
headerVisible:root.mainAttribution.name!==""&&root.attributions.length>0
licenses:root.mainAttribution.licenses
extraTexts:root.mainAttribution.__effectiveEntries
description:root.mainAttribution.description
initiallyExpanded:root.mainAttribution.licenses.length===1&&root.attributions.length===0
homepage:root.mainAttribution.homepage
sources:root.mainAttribution.sources
}LicenseListRepeater{model:attributions
mainModule:root.pageDescription
initiallyExpanded:root.licenses.length===0&&root.attributions.length===1&&root.attributions[0].licenses.length===1&&!root.includeOpal
}LicenseListRepeater{model:opalAttributions.loadedAttributions
initiallyExpanded:false
}}}}