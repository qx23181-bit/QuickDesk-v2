// Fluent Design ToggleButtonGroup Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
    id: control
    
    // ============ Custom Properties ============
    
    property var options: []  // Array of strings or {text, icon, value}
    property int currentIndex: 0
    property var currentValue: null
    
    enum Orientation {
        Horizontal,
        Vertical
    }
    
    property int orientation: QDToggleButtonGroup.Orientation.Horizontal
    
    enum Size {
        Small,
        Medium,
        Large
    }
    
    property int buttonSize: QDToggleButtonGroup.Size.Medium
    
    signal valueChanged(var value)
    
    // ============ Size & Style ============
    
    implicitWidth: {
        if (orientation === QDToggleButtonGroup.Orientation.Horizontal) {
            var totalWidth = 0
            for (var i = 0; i < options.length; i++) {
                totalWidth += 100 // 每个按钮默认100像素
            }
            return totalWidth
        }
        return 200
    }
    implicitHeight: getButtonHeight()
    
    color: Theme.surface
    border.width: Theme.borderWidthThin
    border.color: Theme.border
    radius: Theme.radiusMedium
    
    function getButtonHeight() {
        switch(buttonSize) {
            case QDToggleButtonGroup.Size.Small: return Theme.buttonHeightSmall
            case QDToggleButtonGroup.Size.Large: return Theme.buttonHeightLarge
            default: return Theme.buttonHeightMedium
        }
    }
    
    // ============ Content ============
    
    Row {
        id: buttonRow
        anchors.fill: parent
        spacing: 0
        
        Repeater {
            model: control.options
            
            Rectangle {
                required property int index
                required property var modelData
                
                width: control.width / control.options.length
                height: control.height
                
                color: {
                    if (index === control.currentIndex) return Theme.primary
                    if (buttonArea.containsMouse) return Theme.surfaceHover
                    return "transparent"
                }
                
                radius: {
                    if (control.options.length === 1) return Theme.radiusMedium
                    if (index === 0) return Theme.radiusMedium
                    if (index === control.options.length - 1) return Theme.radiusMedium
                    return 0
                }
                
                // Clip corners for middle buttons
                Rectangle {
                    visible: index > 0 && index < control.options.length - 1
                    anchors.fill: parent
                    anchors.leftMargin: parent.radius
                    anchors.rightMargin: parent.radius
                    color: parent.color
                }
                
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingSmall
                    
                    Text {
                        visible: typeof modelData === 'object' && (modelData.icon !== undefined && modelData.icon !== "")
                        text: typeof modelData === 'object' ? (modelData.icon || "") : ""
                        font.family: "Segoe Fluent Icons"
                        font.pixelSize: {
                            switch(control.buttonSize) {
                                case QDToggleButtonGroup.Size.Small: return Theme.fontSizeSmall
                                case QDToggleButtonGroup.Size.Large: return Theme.fontSizeLarge
                                default: return Theme.fontSizeMedium
                            }
                        }
                        color: index === control.currentIndex ? Theme.textOnPrimary : Theme.text
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    Text {
                        text: typeof modelData === 'string' ? modelData : (modelData.text || "")
                        font.family: Theme.fontFamily
                        font.pixelSize: {
                            switch(control.buttonSize) {
                                case QDToggleButtonGroup.Size.Small: return Theme.fontSizeSmall
                                case QDToggleButtonGroup.Size.Large: return Theme.fontSizeLarge
                                default: return Theme.fontSizeMedium
                            }
                        }
                        color: index === control.currentIndex ? Theme.textOnPrimary : Theme.text
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                // Separator
                Rectangle {
                    visible: index < control.options.length - 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Theme.spacingSmall
                    anchors.bottomMargin: Theme.spacingSmall
                    width: Theme.borderWidthThin
                    color: Theme.border
                }
                
                MouseArea {
                    id: buttonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        control.currentIndex = index
                        control.currentValue = typeof modelData === 'object' ? 
                                              (modelData.value !== undefined ? modelData.value : modelData.text) :
                                              modelData
                        control.valueChanged(control.currentValue)
                    }
                }
                
                Behavior on color {
                    ColorAnimation { duration: Theme.animationDurationFast }
                }
            }
        }
    }
}
