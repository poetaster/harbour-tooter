//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2025 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import org.freedesktop.contextkit 1.0
Item{id:root
property bool networkIsConnected:false
property bool networkIsWifi:false
ContextProperty{id:checkNetworkEnabled
key:"Internet.NetworkState"
value:"waiting"
onValueChanged:{console.log("[Opal.About] network state:",key,"=",value)
networkIsConnected=checkNetworkEnabled.value==="connected"
}}ContextProperty{id:checkNetworkType
key:"Internet.NetworkType"
onValueChanged:{console.log("[Opal.About] network type:",key,"=",value)
networkIsWifi=checkNetworkType.value==="WLAN"
}}}