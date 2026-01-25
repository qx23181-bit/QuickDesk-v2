// Fluent Design ListView Component
import QtQuick
import QtQuick.Controls as Controls

ListView {
    id: control
    
    // ============ Custom Properties ============
    
    property bool showSeparators: true
    property color separatorColor: Theme.border
    property bool alternatingRowColors: false
    
    // ============ Size & Style ============
    
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    
    spacing: 0
    
    // ============ ScrollBar ============
    
    Controls.ScrollBar.vertical: QDScrollBar {
        autoHide: true
    }
    
    // ============ Highlight ============
    
    highlightMoveDuration: Theme.animationDurationFast
    highlightMoveVelocity: -1
    
    highlight: Rectangle {
        color: Theme.surfaceHover
        radius: Theme.radiusSmall
        
        Behavior on y {
            NumberAnimation {
                duration: Theme.animationDurationFast
                easing.type: Easing.OutCubic
            }
        }
    }
    
    highlightFollowsCurrentItem: true
}
