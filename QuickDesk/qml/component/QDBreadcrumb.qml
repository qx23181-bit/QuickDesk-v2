// Fluent Design Breadcrumb Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Item {
    id: control
    
    // ============ Custom Properties ============
    
    property var items: []  // Array of strings or objects with {text, icon}
    property string separator: "/"
    property bool showSeparatorIcon: true
    
    signal itemClicked(int index, string text)
    
    // ============ Size & Style ============
    
    implicitWidth: breadcrumbRow.implicitWidth
    implicitHeight: Theme.buttonHeightMedium
    
    // ============ Content ============
    
    RowLayout {
        id: breadcrumbRow
        anchors.fill: parent
        spacing: Theme.spacingSmall
        
        Repeater {
            model: control.items
            
            RowLayout {
                spacing: Theme.spacingSmall
                
                // Breadcrumb Item
                Rectangle {
                    Layout.preferredHeight: Theme.buttonHeightSmall
                    Layout.preferredWidth: itemContent.implicitWidth + Theme.spacingMedium * 2
                    color: itemArea.containsMouse ? Theme.surfaceHover : "transparent"
                    radius: Theme.radiusSmall
                    
                    RowLayout {
                        id: itemContent
                        anchors.centerIn: parent
                        spacing: Theme.spacingSmall
                        
                        // Icon (if provided)
                        Text {
                            visible: typeof modelData === 'object' && (modelData.icon !== undefined && modelData.icon !== "")
                            text: typeof modelData === 'object' ? (modelData.icon || "") : ""
                            font.family: "Segoe Fluent Icons"
                            font.pixelSize: Theme.fontSizeSmall
                            color: index === control.items.length - 1 ? Theme.primary : Theme.text
                        }
                        
                        // Text
                        Text {
                            text: typeof modelData === 'string' ? modelData : (modelData.text || "")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeMedium
                            color: index === control.items.length - 1 ? Theme.primary : Theme.text
                            font.weight: index === control.items.length - 1 ? Font.DemiBold : Font.Normal
                        }
                    }
                    
                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: index < control.items.length - 1  // Last item not clickable
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        
                        onClicked: {
                            var itemText = typeof modelData === 'string' ? modelData : (modelData.text || "")
                            control.itemClicked(index, itemText)
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: Theme.animationDurationFast }
                    }
                }
                
                // Separator
                Text {
                    visible: index < control.items.length - 1
                    text: control.showSeparatorIcon ? FluentIconGlyph.chevronRightGlyph : control.separator
                    font.family: control.showSeparatorIcon ? "Segoe Fluent Icons" : Theme.fontFamily
                    font.pixelSize: control.showSeparatorIcon ? 12 : Theme.fontSizeMedium
                    color: Theme.textSecondary
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
