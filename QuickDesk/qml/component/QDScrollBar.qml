// Fluent Design ScrollBar Component
import QtQuick
import QtQuick.Controls as Controls

Controls.ScrollBar {
    id: control
    
    // ============ Custom Properties ============
    
    property bool autoHide: true
    property int hideDelay: 1000
    
    // ============ Size & Style ============
    
    implicitWidth: orientation === Qt.Vertical ? 12 : contentItem.implicitWidth
    implicitHeight: orientation === Qt.Horizontal ? 12 : contentItem.implicitHeight
    
    padding: 2
    
    // ============ Visibility Control ============
    
    visible: control.size < 1.0
    opacity: (control.active || control.hovered || !control.autoHide) ? 1.0 : 0.0
    
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animationDurationFast
            easing.type: Easing.OutCubic
        }
    }
    
    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: control.hideDelay
        running: control.autoHide && control.active && !control.hovered
        onTriggered: control.active = false
    }
    
    // ============ Content (Handle) ============
    
    contentItem: Rectangle {
        implicitWidth: control.orientation === Qt.Vertical ? 8 : 100
        implicitHeight: control.orientation === Qt.Horizontal ? 8 : 100
        
        radius: width / 2
        color: control.pressed ? Theme.primary :
               control.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6) : 
               Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
        
        opacity: control.policy === Controls.ScrollBar.AlwaysOn || 
                 control.active || 
                 control.hovered ? 1.0 : 0.6
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
        
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animationDurationFast
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // ============ Background ============
    
    background: Rectangle {
        color: control.hovered ? Qt.rgba(Theme.text.r, 
                                       Theme.text.g, 
                                       Theme.text.b, 0.1) : "transparent"
        radius: width / 2
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
    }
    
    // Hover cursor
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
