// Fluent Design ListItem Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Controls.ItemDelegate {
    id: control
    
    // ============ Custom Properties ============
    
    property string iconSource: ""
    property color iconColor: Theme.primary
    property string subtitle: ""
    property string trailing: ""
    property bool showChevron: false
    property bool showSeparator: false
    
    // ============ Size & Style ============
    
    implicitWidth: ListView.view ? ListView.view.width : 300
    implicitHeight: subtitle !== "" ? Theme.buttonHeightLarge + Theme.spacingMedium : Theme.buttonHeightLarge
    
    padding: Theme.spacingMedium
    
    // ============ Content ============
    
    contentItem: RowLayout {
        spacing: Theme.spacingMedium
        
        // Leading Icon
        Rectangle {
            visible: control.iconSource !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: Qt.rgba(control.iconColor.r, control.iconColor.g, control.iconColor.b, 0.1)
            radius: Theme.radiusMedium
            
            Text {
                anchors.centerIn: parent
                text: control.iconSource
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 20
                color: control.iconColor
            }
        }
        
        // Text Content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXSmall
            
            Text {
                text: control.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                color: control.enabled ? Theme.text : Theme.textDisabled
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                visible: control.subtitle !== ""
                text: control.subtitle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        
        // Trailing Text
        Text {
            visible: control.trailing !== ""
            text: control.trailing
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textSecondary
            verticalAlignment: Text.AlignVCenter
        }
        
        // Trailing Chevron
        Text {
            visible: control.showChevron
            text: FluentIconGlyph.chevronRightGlyph
            font.family: "Segoe Fluent Icons"
            font.pixelSize: 14
            color: Theme.textSecondary
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    // ============ Background ============
    
    background: Item {
        Rectangle {
            id: bgRect
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingSmall
            anchors.rightMargin: Theme.spacingSmall
            color: control.pressed ? Theme.surfacePressed :
                   control.hovered ? Theme.surfaceHover :
                   control.highlighted ? Theme.surfaceVariant : "transparent"
            
            radius: Theme.radiusSmall
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
        }
        
        // Bottom Separator
        Rectangle {
            visible: control.showSeparator
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: control.padding + Theme.spacingSmall
            anchors.rightMargin: Theme.spacingSmall
            height: Theme.borderWidthThin
            color: Theme.border
        }
    }
    
    // Hover cursor
    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
    }
}
