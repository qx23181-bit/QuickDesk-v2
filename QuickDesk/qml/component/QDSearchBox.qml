// Fluent Design SearchBox Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
    id: control
    
    // ============ Custom Properties ============
    
    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property bool clearButtonVisible: text.length > 0
    
    // ============ Signals ============
    
    signal searchRequested(string query)
    signal textEdited(string text)  // 改名避免与 text 属性的 textChanged 信号冲突
    signal cleared()
    
    // ============ Size & Style ============
    
    implicitWidth: 300
    implicitHeight: Theme.buttonHeightMedium
    
    color: control.enabled ? Theme.surface : Theme.surfaceDisabled
    border.width: textField.activeFocus ? 2 : Theme.borderWidthThin
    border.color: {
        if (!control.enabled) return Theme.borderDisabled
        if (textField.activeFocus) return Theme.primary
        if (mouseArea.containsMouse) return Theme.borderHover
        return Theme.border
    }
    radius: Theme.radiusMedium
    
    Behavior on border.width {
        NumberAnimation { duration: Theme.animationDurationFast }
    }
    
    Behavior on border.color {
        ColorAnimation { duration: Theme.animationDurationFast }
    }
    
    // ============ Hover Detection ============
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.IBeamCursor
    }
    
    // ============ Content Layout ============
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingSmall
        anchors.rightMargin: Theme.spacingSmall
        spacing: Theme.spacingSmall
        
        // Search Icon
        Text {
            text: FluentIconGlyph.searchGlyph
            font.family: "Segoe Fluent Icons"
            font.pixelSize: 16
            color: textField.activeFocus ? Theme.primary : Theme.textSecondary
            verticalAlignment: Text.AlignVCenter
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
        }
        
        // Text Input
        Controls.TextField {
            id: textField
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            color: enabled ? Theme.text : Theme.textDisabled
            placeholderTextColor: Theme.textSecondary
            selectionColor: Theme.primary
            selectedTextColor: Theme.textOnPrimary
            selectByMouse: true
            
            background: Item {}
            
            onTextChanged: control.textEdited(text)
            
            Keys.onReturnPressed: {
                control.searchRequested(text)
            }
            
            Keys.onEnterPressed: {
                control.searchRequested(text)
            }
        }
        
        // Clear Button
        Rectangle {
            visible: control.clearButtonVisible
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            color: clearMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
            radius: Theme.radiusSmall
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
            
            Text {
                anchors.centerIn: parent
                text: FluentIconGlyph.cancelGlyph
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 12
                color: Theme.textSecondary
            }
            
            MouseArea {
                id: clearMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    textField.text = ""
                    control.cleared()
                    textField.forceActiveFocus()
                }
            }
        }
    }
}
