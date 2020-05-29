import QtQuick 2.0
import Sailfish.Silica 1.0


Component {
    id: emojiComponent
    Dialog {
        id: emoticonsDialog
        canAccept: false //selector.currentIndex >= 0
        onAcceptPendingChanged: {
            if (acceptPending) {
                // Tell the destination page what the selected category is
                // acceptDestinationInstance.category = selector.value
            }
        }
        SilicaGridView {
            id: gridView
            anchors.fill: parent
            //anchors.rightMargin: Theme.paddingLarge
            //anchors.leftMargin: Theme.paddingLarge
            cellWidth: gridView.width / 6
            cellHeight: cellWidth
            VerticalScrollDecorator {flickable: listEmojis }
            header: PageHeader {
                title: qsTr("Emojis")
                description: qsTr("Tap to insert")
            }
            model: ListModel {
                id: listEmojis
                ListElement { section: "smileys"; glyph: "😁" }
                ListElement { section: "smileys"; glyph: "😂" }
                ListElement { section: "smileys"; glyph: "😃" }
                ListElement { section: "smileys"; glyph: "😄" }
                ListElement { section: "smileys"; glyph: "😅" }
                ListElement { section: "smileys"; glyph: "😆" }
                ListElement { section: "smileys"; glyph: "😉" }
                ListElement { section: "smileys"; glyph: "😊" }
                ListElement { section: "smileys"; glyph: "😋" }
                ListElement { section: "smileys"; glyph: "😎" }
                ListElement { section: "smileys"; glyph: "😌" }
                ListElement { section: "smileys"; glyph: "😍" }
                ListElement { section: "smileys"; glyph: "😘" }
                ListElement { section: "smileys"; glyph: "😏" }
                ListElement { section: "smileys"; glyph: "😒" }
                ListElement { section: "smileys"; glyph: "😓" }
                ListElement { section: "smileys"; glyph: "😔" }
                ListElement { section: "smileys"; glyph: "😖" }
                ListElement { section: "smileys"; glyph: "😚" }
                ListElement { section: "smileys"; glyph: "😜" }
                ListElement { section: "smileys"; glyph: "😝" }
                ListElement { section: "smileys"; glyph: "😞" }
                ListElement { section: "smileys"; glyph: "😠" }
                ListElement { section: "smileys"; glyph: "😡" }
                ListElement { section: "smileys"; glyph: "😢" }
                ListElement { section: "smileys"; glyph: "😣" }
                ListElement { section: "smileys"; glyph: "😤" }
                ListElement { section: "smileys"; glyph: "😥" }
                ListElement { section: "smileys"; glyph: "😨" }
                ListElement { section: "smileys"; glyph: "😩" }
                ListElement { section: "smileys"; glyph: "😪" }
                ListElement { section: "smileys"; glyph: "😫" }
                ListElement { section: "smileys"; glyph: "😭" }
                ListElement { section: "smileys"; glyph: "😰" }
                ListElement { section: "smileys"; glyph: "😱" }
                ListElement { section: "smileys"; glyph: "😲" }
                ListElement { section: "smileys"; glyph: "😳" }
                ListElement { section: "smileys"; glyph: "😵" }
                ListElement { section: "smileys"; glyph: "😷" }
                ListElement { section: "smileys"; glyph: "😸" }
                ListElement { section: "smileys"; glyph: "😹" }
                ListElement { section: "smileys"; glyph: "😺" }
                ListElement { section: "smileys"; glyph: "😻" }
                ListElement { section: "smileys"; glyph: "😼" }
                ListElement { section: "smileys"; glyph: "😽" }
                ListElement { section: "smileys"; glyph: "😾" }
                ListElement { section: "smileys"; glyph: "😿" }
                ListElement { section: "smileys"; glyph: "🙀" }

                ListElement { section: "People and Fantasy"; glyph: "🙅" }
                ListElement { section: "People and Fantasy"; glyph: "🙆" }
                ListElement { section: "People and Fantasy"; glyph: "🙇" }
                ListElement { section: "People and Fantasy"; glyph: "🙈" }
                ListElement { section: "People and Fantasy"; glyph: "🙉" }
                ListElement { section: "People and Fantasy"; glyph: "🙊" }
                ListElement { section: "People and Fantasy"; glyph: "🙋" }
                ListElement { section: "People and Fantasy"; glyph: "🙍" }
                ListElement { section: "People and Fantasy"; glyph: "🙎" }
                ListElement { section: "People and Fantasy"; glyph: "👍" }
                ListElement { section: "People and Fantasy"; glyph: "👎" }
                ListElement { section: "People and Fantasy"; glyph: "🙌" }
                ListElement { section: "People and Fantasy"; glyph: "✊" }
                ListElement { section: "People and Fantasy"; glyph: "💪" }
                ListElement { section: "People and Fantasy"; glyph: "👉" }
                ListElement { section: "People and Fantasy"; glyph: "🙏" }

                ListElement { section: "Transport and Map"; glyph: "🚀" }
                ListElement { section: "Transport and Map"; glyph: "🚃" }
                ListElement { section: "Transport and Map"; glyph: "🚀" }
                ListElement { section: "Transport and Map"; glyph: "🚄" }
                ListElement { section: "Transport and Map"; glyph: "🚅" }
                ListElement { section: "Transport and Map"; glyph: "🚇" }
                ListElement { section: "Transport and Map"; glyph: "🚉" }
                ListElement { section: "Transport and Map"; glyph: "🚌" }
                ListElement { section: "Transport and Map"; glyph: "🚏" }
                ListElement { section: "Transport and Map"; glyph: "🚑" }
                ListElement { section: "Transport and Map"; glyph: "🚒" }
                ListElement { section: "Transport and Map"; glyph: "🚓" }
                ListElement { section: "Transport and Map"; glyph: "🚕" }
                ListElement { section: "Transport and Map"; glyph: "🚗" }
                ListElement { section: "Transport and Map"; glyph: "🚙" }
                ListElement { section: "Transport and Map"; glyph: "🚚" }
                ListElement { section: "Transport and Map"; glyph: "🚢" }
                ListElement { section: "Transport and Map"; glyph: "🚨" }
                ListElement { section: "Transport and Map"; glyph: "🚩" }
                ListElement { section: "Transport and Map"; glyph: "🚪" }
                ListElement { section: "Transport and Map"; glyph: "🚫" }
                ListElement { section: "Transport and Map"; glyph: "🚬" }
                ListElement { section: "Transport and Map"; glyph: "🚭" }
                ListElement { section: "Transport and Map"; glyph: "🚲" }
                ListElement { section: "Transport and Map"; glyph: "🚶" }
                ListElement { section: "Transport and Map"; glyph: "🚹" }
                ListElement { section: "Transport and Map"; glyph: "🚺" }
                ListElement { section: "Transport and Map"; glyph: "🚻" }
                ListElement { section: "Transport and Map"; glyph: "🚼" }
                ListElement { section: "Transport and Map"; glyph: "🚽" }
                ListElement { section: "Transport and Map"; glyph: "🚾" }
                ListElement { section: "Transport and Map"; glyph: "🛀" }

                ListElement { section: "Horoscope Signs"; glyph: "♈" }
                ListElement { section: "Horoscope Signs"; glyph: "♉" }
                ListElement { section: "Horoscope Signs"; glyph: "♊" }
                ListElement { section: "Horoscope Signs"; glyph: "♋" }
                ListElement { section: "Horoscope Signs"; glyph: "♌" }
                ListElement { section: "Horoscope Signs"; glyph: "♍" }
                ListElement { section: "Horoscope Signs"; glyph: "♎" }
                ListElement { section: "Horoscope Signs"; glyph: "♏" }
                ListElement { section: "Horoscope Signs"; glyph: "♐" }
                ListElement { section: "Horoscope Signs"; glyph: "♑" }
                ListElement { section: "Horoscope Signs"; glyph: "♒" }
                ListElement { section: "Horoscope Signs"; glyph: "♓" }
            }
            delegate: BackgroundItem {
                width: gridView.cellWidth
                height: gridView.cellHeight
                Label {
                    anchors.centerIn: parent
                    color: (highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                    font.pixelSize: Theme.fontSizeLarge
                    text: glyph
                }
                onClicked: {
                    var cursorPosition = toot.cursorPosition
                    toot.text = toot.text.substring(
                                0, cursorPosition) + model.glyph + toot.text.substring(
                                cursorPosition)
                    toot.cursorPosition = cursorPosition + model.glyph.length
                    emoticonsDialog.canAccept = true
                    emoticonsDialog.accept()
                }
            }
        }
    }

}

