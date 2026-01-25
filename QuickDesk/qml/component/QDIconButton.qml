// Fluent Design Icon Button Component
import QtQuick
import QtQuick.Controls as Controls

Controls.Button {
    id: control
    
    // ============ Custom Properties ============
    
    property string iconSource: ""
    property color iconColor: Theme.text
    property color iconHoverColor: Theme.primary
    property color iconPressedColor: Theme.primaryPressed
    
    enum Size {
        Small,
        Medium,
        Large
    }
    
    property int buttonSize: QDIconButton.Size.Medium
    
    enum Style {
        Standard,
        Subtle,
        Accent,
        Transparent
    }
    
    property int buttonStyle: QDIconButton.Style.Standard
    
    property bool circular: false
    
    // ============ Size & Style ============
    
    implicitWidth: {
        switch(buttonSize) {
            case QDIconButton.Size.Small: return 28
            case QDIconButton.Size.Large: return 48
            default: return 36
        }
    }
    
    implicitHeight: implicitWidth
    
    padding: 0
    
    // ============ Content ============
    
    contentItem: Text {
        text: control.iconSource
        font.family: "Segoe Fluent Icons"
        font.pixelSize: {
            switch(control.buttonSize) {
                case QDIconButton.Size.Small: return 14
                case QDIconButton.Size.Large: return 20
                default: return 16
            }
        }
        color: {
            if (!control.enabled) return Theme.textDisabled
            if (control.pressed) return control.iconPressedColor
            if (control.hovered) return control.iconHoverColor
            return control.iconColor
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
    }
    
    // ============ Background ============
    
    background: Rectangle {
        radius: control.circular ? width / 2 : Theme.radiusSmall
        color: {
            if (!control.enabled) return "transparent"
            
            if (control.buttonStyle === QDIconButton.Style.Accent) {
                return control.pressed ? Theme.primaryPressed :
                       control.hovered ? Theme.primaryHover : Theme.primary
            } else if (control.buttonStyle === QDIconButton.Style.Subtle) {
                return control.pressed ? Theme.surfacePressed :
                       control.hovered ? Theme.surfaceHover : Theme.surfaceVariant
            } else if (control.buttonStyle === QDIconButton.Style.Transparent) {
                return control.pressed ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) :
                       control.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05) : "transparent"
            } else {
                // Standard or undefined
                return control.pressed ? Theme.surfacePressed :
                       control.hovered ? Theme.surfaceHover : Theme.surface
            }
        }
        
        border.width: control.buttonStyle === QDIconButton.Style.Standard ? Theme.borderWidthThin : 0
        border.color: control.hovered ? Theme.border : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.5)
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
        
        // Ripple effect
        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: 0
            height: width
            radius: width / 2
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
            opacity: 0
            
            NumberAnimation on width {
                id: rippleAnimation
                from: 0
                to: parent.width * 1.5
                duration: Theme.animationDurationMedium
                easing.type: Easing.OutCubic
                running: false
            }
            
            NumberAnimation on opacity {
                id: rippleOpacityAnimation
                from: 0.5
                to: 0
                duration: Theme.animationDurationMedium
                easing.type: Easing.OutCubic
                running: false
            }
        }
    }
    
    // ============ Interactions ============
    
    onPressed: {
        rippleAnimation.restart()
        rippleOpacityAnimation.restart()
    }
    
    // Hover cursor
    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
    }
}
