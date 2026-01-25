// Fluent Design Rating Component
import QtQuick
import QtQuick.Controls as Controls

Item {
    id: control
    
    // ============ Custom Properties ============
    
    property int count: 5
    property real value: 0
    property bool readOnly: false
    property color activeColor: Theme.warning
    property color inactiveColor: Theme.border
    
    enum Size {
        Small,
        Medium,
        Large
    }
    
    property int ratingSize: QDRating.Size.Medium
    
    signal ratingChanged(real newValue)
    
    // ============ Size & Style ============
    
    implicitWidth: starRow.implicitWidth
    implicitHeight: getStarSize()
    
    function getStarSize() {
        switch(ratingSize) {
            case QDRating.Size.Small: return 20
            case QDRating.Size.Large: return 32
            default: return 24
        }
    }
    
    // ============ Content ============
    
    Row {
        id: starRow
        spacing: Theme.spacingSmall
        
        Repeater {
            model: control.count
            
            Item {
                width: control.getStarSize()
                height: control.getStarSize()
                
                // Background star (empty)
                Text {
                    anchors.centerIn: parent
                    text: FluentIconGlyph.favoriteStarGlyph
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: control.getStarSize()
                    color: control.inactiveColor
                }
                
                // Foreground star (filled)
                Text {
                    anchors.centerIn: parent
                    text: FluentIconGlyph.favoriteStarFillGlyph
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: control.getStarSize()
                    color: control.activeColor
                    opacity: {
                        if (control.value >= index + 1) return 1.0
                        if (control.value > index && control.value < index + 1) {
                            return control.value - index
                        }
                        return 0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animationDurationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                
                // Hover effect
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: width / 2
                    color: Qt.rgba(control.activeColor.r, control.activeColor.g, control.activeColor.b, 0.1)
                    visible: !control.readOnly && starArea.containsMouse
                }
                
                MouseArea {
                    id: starArea
                    anchors.fill: parent
                    hoverEnabled: !control.readOnly
                    cursorShape: control.readOnly ? Qt.ArrowCursor : Qt.PointingHandCursor
                    
                    onClicked: {
                        if (!control.readOnly) {
                            control.value = index + 1
                            control.ratingChanged(control.value)
                        }
                    }
                    
                    onPositionChanged: {
                        if (!control.readOnly && pressed) {
                            // Allow half-star ratings by mouse position
                            var halfStar = mouse.x < width / 2
                            control.value = index + (halfStar ? 0.5 : 1)
                        }
                    }
                }
            }
        }
    }
}
