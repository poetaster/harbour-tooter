import QtQuick 2.2
import Sailfish.Silica 1.0

Icon {
    id: hint
    color: palette.primaryColor
    source: "image://theme/graphic-gesture-hint"

    property alias running: animation.running
    property alias loops: animation.loops

    opacity: 0
    scale: 1.5

    onRunningChanged: {
        if (!running) opacity = 0
    }

    SequentialAnimation {
        id: animation
        loops: Animation.Infinite

        PauseAnimation { duration: 2000 }

        ParallelAnimation {
            OpacityAnimator {
                target: hint
                from: 0.0
                to: 1.0
                duration: 300
            }

            ScaleAnimator {
                target: hint
                from: 1.0
                to: 0.75
                //easing.type: Easing.OutInQuad
                duration: 300
            }
        }

        PauseAnimation { duration: 1000 }

        ParallelAnimation {
            OpacityAnimator {
                target: hint
                from: 1.0
                to: 0.0
                duration: 300
            }

            ScaleAnimator {
                target: hint
                from: 0.75
                to: 1.0
                //easing.type: Easing.InOutQuad
                duration: 300
            }
        }
    }
}
