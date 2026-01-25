// Fluent Design TabButton Component
import QtQuick
import QtQuick.Controls as Controls

Controls.TabButton {
    id: control
    
    // ============ Custom Properties ============
    
    property string iconSource: ""
    property bool showCloseButton: false
    signal closeClicked()
    
    // ============ Size & Style ============
    
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                           implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                            implicitContentHeight + topPadding + bottomPadding)
    
    padding: Theme.spacingMedium
    spacing: Theme.spacingSmall
    
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeMedium
    
    // ============ Content ============
    
    contentItem: Row {
        spacing: control.spacing
        
        // Icon
        Text {
            visible: control.iconSource !== ""
            text: control.iconSource
            font.family: "Segoe Fluent Icons"
            font.pixelSize: Theme.fontSizeMedium
            color: control.checked ? Theme.primary : 
                   control.hovered ? Theme.text : Theme.textSecondary
            verticalAlignment: Text.AlignVCenter
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
        }
        
        // Text
        Text {
            text: control.text
            font: control.font
            color: control.checked ? Theme.primary : 
                   control.hovered ? Theme.text : Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
        }
        
        // Close button
        Rectangle {
            visible: control.showCloseButton
            width: 20
            height: 20
            radius: Theme.radiusSmall
            color: closeMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
            
            Text {
                anchors.centerIn: parent
                text: FluentIconGlyph.cancelGlyph
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 12
                color: Theme.textSecondary
            }
            
            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    mouse.accepted = true
                    control.closeClicked()
                }
            }
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
        }
    }
    
    // ============ Background ============
    
    background: Rectangle {
        color: control.checked ? Theme.surfaceHover : 
               control.hovered ? Qt.rgba(Theme.surfaceHover.r, 
                                       Theme.surfaceHover.g, 
                                       Theme.surfaceHover.b, 0.5) : "transparent"
        
        // Active indicator
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 2
            color: Theme.primary
            visible: control.checked
        }
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
    }
    
    // Hover cursor
    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
    }
}
