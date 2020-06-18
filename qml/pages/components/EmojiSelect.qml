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
            header: PageHeader {
                title: qsTr("Emojis")
                description: qsTr("Tap to insert")
            }
            cellWidth: gridView.width / 6
            cellHeight: cellWidth
            anchors.fill: parent
            model: ListModel {
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
                    text: glyph
                    font.pixelSize: Theme.fontSizeLarge
                    color: (highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                    anchors.centerIn: parent
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

            VerticalScrollDecorator {flickable: listEmojis }
        }
    }
}
