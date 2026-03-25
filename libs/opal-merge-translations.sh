#!/bin/bash
#
# This file is part of Opal.
# SPDX-License-Identifier: CC-BY-SA-4.0
# SPDX-FileCopyrightText: 2021-2025 Mirian Margiani
#
# See https://github.com/Pretty-SFOS/opal/blob/main/snippets/opal-merge-translations.md
# for documentation.
#
# @@@ FILE VERSION 1.0.0
#

shopt -s extglob

function log() {
    IFS=' ' printf -- "%s\n" "$*" >&2
}

if (( $# == 0 )); then
    echo "usage: $(basename "$0") TRANSLATIONS [LCONVERT]"
    echo
    echo "TRANSLATIONS: path to app translations"
    echo "LCONVERT: path to lconvert tool (optional)"
    echo
    echo "This script has to be run next to the opal-translations directory."
    exit 0
fi

cLCONVERT=lconvert

if ! which "$2" 2> /dev/null >&2; then
    if ! which "$cLCONVERT" 2> /dev/null >&2; then
        if ! which "$cLCONVERT-qt5" 2> /dev/null >&2; then
            log "error: lconvert tool not found"
            log "       Specify a valid path as the second argument to this script."
            exit 2
        else
            cLCONVERT="$cLCONVERT-qt5"
        fi
    else
        cLCONVERT="$cLCONVERT"
    fi
else
    cLCONVERT="$2"
fi

cOPAL_TR="opal-translations"
if [[ ! -d "$cOPAL_TR" ]]; then
    log "error: $cOPAL_TR directory not found"
    exit 2
fi

cBASE_TR="$1"
if [[ ! -d "$cBASE_TR" ]]; then
    log "error: translations directory not found at '$cBASE_TR'"
    log "       Specify a valid path as the first argument to this script."
    exit 2
fi

mapfile -d $'\0' -t app_tr < <(find "$cBASE_TR" -iregex ".*\.ts" -type "f" -print0)

for tr in "${app_tr[@]}"; do
    commands=("$cLCONVERT" "-i" "$tr")
    have_extra=false

    set -o pipefail
    lang="$(sed -re 's/.*?[-_]([a-z]{2}([-_][A-Z]{2})?)\.[Tt][Ss]/\1/g; T fail; t ok; :ok; q 0; :fail; q 100' <<<"$tr" | tr '_' '-')" || {
        log "skipping '$tr': no language"
        continue
    }

    opal_tr_full=()
    mapfile -d $'\0' -t opal_tr_full < <(find "$cOPAL_TR" -iregex ".*-$lang\.ts" -type "f" -print0)

    for otf in "${opal_tr_full[@]}"; do
        commands+=("-i" "$otf")
    done

    opal_tr_short=()
    if [[ "$lang" == *-* ]]; then
        lang_short="${lang%-*}"
        mapfile -d $'\0' -t opal_tr_short < <(find "$cOPAL_TR" -iregex ".*-$lang_short\.ts" -type "f" -print0)

        for ots in "${opal_tr_short[@]}"; do
            commands+=("-i" "$ots")
        done
    fi

    if (( ${#opal_tr_full[@]} > 0 || ${#opal_tr_short[@]} > 0 )); then
        have_extra=true
    fi

    if [[ "$have_extra" == true ]]; then
        commands+=("-o" "$tr")
        log "merging $tr ($lang)..."
        log "+" "${commands[@]}"
        "${commands[@]}"
    else
        log "nothing to be done for $tr ($lang)"
    fi
done

log
log "IMPORTANT: it is recommended to manually update translations once after"
log "           changing many strings, so the same-text heuristic can pick up"
log "           any strings that have moved."
log
log "           Typically, the command is:"
log "               $cLCONVERT qml src -ts translations/*.ts"
log
log "           Otherwise, you may lose translations because the Sailfish SDK"
log "           drops 'obsolete' translations by default (option '-no-obsolete')."
