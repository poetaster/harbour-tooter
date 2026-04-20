//@ This file is part of opal-linkhandler.
//@ https://github.com/Pretty-SFOS/opal-linkhandler
//@ SPDX-FileCopyrightText: 2025 roundedrectangle
//@ SPDX-FileCopyrightText: 2025 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick 2.0
QtObject{readonly property int auto:0
readonly property int enabled:1
readonly property int disabledIfMobile:2
readonly property int disabled:3
}