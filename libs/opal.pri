# This file is part of Opal.
# SPDX-FileCopyrightText: 2023-2025 Mirian Margiani
# SPDX-License-Identifier: CC-BY-SA-4.0
#
# Include this file in your main .pro file to use Opal modules in C++.
#
# Read the docs at:
# https://github.com/Pretty-SFOS/opal/blob/main/README.md#using-opal
#
# NOTE: this is a generic helper file used by all Opal modules.
# You can safely overwrite it when updating a module.

# Enable autocompletion for Opal modules in QtCreator
QML_IMPORT_PATH += qml/modules

# Make C++ headers available for inclusion
INCLUDEPATH += $$relative_path($$PWD/opal)

# Search for any project include files and include them now
message(Searching for Opal source modules...)

OPAL_SOURCE_MODULES = $$files($$PWD/opal/*)
for (module, OPAL_SOURCE_MODULES) {
    module_includes = $$files($$module/*.pri)

    for (to_include, module_includes) {
        message(Enabling Opal source module <libs/$$relative_path($$dirname(to_include))>)
        include($$to_include)
    }
}
