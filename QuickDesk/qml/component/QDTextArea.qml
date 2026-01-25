// Fluent Design TextArea Component
import QtQuick
import QtQuick.Controls as Controls

Controls.ScrollView {
    id: control
    
    // ============ Properties ============
    
    property alias text: textArea.text
    property alias placeholderText: textArea.placeholderText
    property bool hasError: false
    property alias textArea: textArea
    
    // 内部状态属性，避免直接绑定 textArea 属性
    property bool _isFocused: false
    property bool _isHovered: false
    
    // ============ Size ============
    
    implicitWidth: 300
    implicitHeight: 120
    
    clip: true
    
    Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
    Controls.ScrollBar.vertical: QDScrollBar {}
    
    // ============ Background ============
    
    background: Rectangle {
        id: backgroundRect
        color: control.enabled ? Theme.surface : Theme.background
        border.width: control._isFocused ? 2 : Theme.borderWidthThin
        border.color: {
            if (!control.enabled) return Theme.border
            if (control.hasError) return Theme.error
            if (control._isFocused) return Theme.primary
            if (control._isHovered) return Theme.borderHover
            return Theme.border
        }
        radius: Theme.radiusMedium
        
        Behavior on border.width {
            NumberAnimation { duration: Theme.animationDurationFast }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
    }
    
    // ============ Text Area ============
    
    Controls.TextArea {
        id: textArea
        
        width: control.width
        
        padding: Theme.spacingMedium
        leftPadding: Theme.spacingMedium
        rightPadding: Theme.spacingMedium
        topPadding: Theme.spacingMedium
        bottomPadding: Theme.spacingMedium
        
        color: enabled ? Theme.text : Theme.textDisabled
        selectionColor: Theme.primary
        
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
        
        wrapMode: Controls.TextArea.Wrap
        selectByMouse: true
        
        background: null
        
        // 更新内部状态
        onActiveFocusChanged: control._isFocused = activeFocus
        onHoveredChanged: control._isHovered = hovered
    }
}
