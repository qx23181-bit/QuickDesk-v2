// Fluent Design StatusBar Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
    id: control
    
    // ============ Custom Properties ============
    
    property string message: ""
    property string leftText: ""
    property string rightText: ""
    property bool showSeparator: true
    
    default property alias content: contentRow.data
    
    // ============ Size & Style ============
    
    implicitHeight: Theme.buttonHeightMedium
    color: Theme.surfaceVariant
    
    // Top border
    Rectangle {
        visible: control.showSeparator
        anchors.top: parent.top
        width: parent.width
        height: Theme.borderWidthThin
        color: Theme.border
    }
    
    // ============ Content ============
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingMedium
        
        // Left Text
        Text {
            visible: control.leftText !== ""
            text: control.leftText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.text
            verticalAlignment: Text.AlignVCenter
        }
        
        // Message
        Text {
            visible: control.message !== ""
            text: control.message
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.text
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        // Custom Content
        Row {
            id: contentRow
            spacing: Theme.spacingSmall
            Layout.fillWidth: control.message === ""
        }
        
        // Right Text
        Text {
            visible: control.rightText !== ""
            text: control.rightText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textSecondary
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    Behavior on color {
        ColorAnimation { duration: Theme.animationDurationFast }
    }
}
