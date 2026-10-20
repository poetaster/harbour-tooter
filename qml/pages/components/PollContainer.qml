import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../lib/API.js" as Logic

Column {
    id: pollContainer

    width: parent.width - Theme.horizontalPageMargin * 2 - avatar.width - Theme.paddingMedium
    spacing: Theme.paddingSmall
    // old visible check    return pollData.id && pollData.id.length > 0
    // Parse all poll data from JSON string
    property var pollData: {
        try {
            var json = typeof model.poll_json !== "undefined" && model.poll_json ? model.poll_json : ''
            if (json.length === 0) return { id: '', options: [], votes_count: 0, voted: false, expired: false, multiple: false, own_votes: [] }
            return JSON.parse(json)
        } catch (e) {
            return { id: '', options: [], votes_count: 0, voted: false, expired: false, multiple: false, own_votes: [] }
        }
    }

    // Track selected options for voting
    property var selectedOptions: []
    property bool hasVoted: pollData.voted || false
    property bool isExpired: pollData.expired || false
    property bool canVote: !hasVoted && !isExpired
    property bool isMultiple: pollData.multiple || false

    // Helper to check if option is selected
    function isOptionSelected(idx) {
        return selectedOptions.indexOf(idx) !== -1
    }

    // Helper to check if user voted for this option
    function userVotedFor(idx) {
        var ownVotes = pollData.own_votes || []
        return ownVotes.indexOf(idx) !== -1
    }

    // Helper to get vote percentage
    function getVotePercentage(optionVotes) {
        var total = pollData.votes_count || 0
        if (total === 0) return 0
        return Math.round((optionVotes / total) * 100)
    }

    // Poll options using Repeater
    Repeater {
        model: pollContainer.pollData.options || []

        Rectangle {
            width: pollContainer.width
            height: Math.max(Theme.itemSizeSmall, optionText.implicitHeight + Theme.paddingMedium * 2)
            color: pollContainer.canVote && pollContainer.isOptionSelected(index) ? Theme.rgba(Theme.highlightColor, 0.3) : Theme.rgba(Theme.highlightBackgroundColor, 0.1)
            radius: Theme.paddingSmall
            border.color: pollContainer.userVotedFor(index) ? Theme.highlightColor : "transparent"
            border.width: pollContainer.userVotedFor(index) ? 2 : 0

            // Vote percentage bar (shown after voting or when expired)
            Rectangle {
                visible: !pollContainer.canVote
                width: parent.width * pollContainer.getVotePercentage(modelData.votes) / 100
                height: parent.height
                color: Theme.rgba(Theme.highlightColor, 0.2)
                radius: Theme.paddingSmall
            }

            Row {
                anchors.fill: parent
                anchors.margins: Theme.paddingMedium
                spacing: Theme.paddingSmall

                // Checkbox/Radio indicator for voting
                Rectangle {
                    visible: pollContainer.canVote
                    width: Theme.iconSizeSmall * 0.7
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: pollContainer.isMultiple ? Theme.paddingSmall / 2 : width / 2
                    color: pollContainer.isOptionSelected(index) ? Theme.highlightColor : "transparent"
                    border.color: Theme.highlightColor
                    border.width: 2
                }

                // Checkmark for voted option
                Icon {
                    visible: !pollContainer.canVote && pollContainer.userVotedFor(index)
                    width: Theme.iconSizeSmall
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-s-installed"
                    color: Theme.highlightColor
                }

                Label {
                    id: optionText
                    text: modelData.title
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                    width: parent.width - (pollContainer.canVote || pollContainer.userVotedFor(index) ? Theme.iconSizeSmall + Theme.paddingSmall : 0) - optionPercent.width - Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    id: optionPercent
                    visible: !pollContainer.canVote
                    text: pollContainer.getVotePercentage(modelData.votes) + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: pollContainer.canVote
                onClicked: {
                    if (pollContainer.isMultiple) {
                        var idx = pollContainer.selectedOptions.indexOf(index)
                        if (idx === -1) {
                            pollContainer.selectedOptions.push(index)
                        } else {
                            pollContainer.selectedOptions.splice(idx, 1)
                        }
                        pollContainer.selectedOptions = pollContainer.selectedOptions.slice()
                    } else {
                        pollContainer.selectedOptions = [index]
                    }
                }
            }
        }
    }

    // Vote button and poll info
    Row {
        width: parent.width
        height: Math.max(Theme.itemSizeSmall, implicitHeight)
        spacing: Theme.paddingMedium

        Button {
            id: voteButton
            visible: pollContainer.canVote
            enabled: pollContainer.selectedOptions.length > 0
            text: qsTr("Vote")
            preferredWidth: Theme.buttonWidthSmall
            onClicked: {
                // Build vote params - API expects {"choices": [0, 1, ...]}
                var choices = []
                for (var i = 0; i < pollContainer.selectedOptions.length; i++) {
                    choices.push(pollContainer.selectedOptions[i])
                }
                worker.sendMessage({
                                       "conf": Logic.conf,
                                       "params": { "choices": choices },
                                       "method": "POST",
                                       "bgAction": true,
                                       "action": "polls/" + pollContainer.pollData.id + "/votes"
                                   })
                // Update local state optimistically by rebuilding poll_json
                var newPollData = JSON.parse(JSON.stringify(pollContainer.pollData))
                newPollData.voted = true
                newPollData.own_votes = pollContainer.selectedOptions.slice()
                newPollData.votes_count = (newPollData.votes_count || 0) + 1
                model.poll_json = JSON.stringify(newPollData)
            }
        }

        Label {
            text: {
                var parts = []
                var total = pollContainer.pollData.votes_count || 0
                parts.push(total + " " + qsTr("votes"))

                if (pollContainer.isExpired) {
                    parts.push(qsTr("Closed"))
                } else if (pollContainer.pollData.expires_at) {
                    var now = new Date()
                    var expires = new Date(pollContainer.pollData.expires_at)
                    var diff = expires - now
                    if (diff > 0) {
                        var hours = Math.floor(diff / (1000 * 60 * 60))
                        var minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
                        if (hours > 24) {
                            var days = Math.floor(hours / 24)
                            parts.push(days + " " + qsTr("days left"))
                        } else if (hours > 0) {
                            parts.push(hours + " " + qsTr("hours left"))
                        } else {
                            parts.push(minutes + " " + qsTr("minutes left"))
                        }
                    }
                }
                return parts.join(" · ")
            }
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            anchors.verticalCenter: voteButton.visible ? voteButton.verticalCenter : undefined
            wrapMode: Text.Wrap
            width: parent.width - (voteButton.visible ? voteButton.width + Theme.paddingMedium : 0)
        }
    }
}
