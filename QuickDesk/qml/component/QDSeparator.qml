// Fluent Design Separator Component (Vertical)
import QtQuick

Rectangle {
    id: control
    
    // ============ Custom Properties ============
    
    enum Orientation {
        Vertical,
        Horizontal
    }
    
    property int orientation: QDSeparator.Orientation.Vertical
    property color separatorColor: Theme.border
    property int thickness: Theme.borderWidthThin
    
    // ============ Size & Style ============
    
    implicitWidth: orientation === QDSeparator.Orientation.Vertical ? thickness : parent.width
    implicitHeight: orientation === QDSeparator.Orientation.Horizontal ? thickness : parent.height
    
    color: separatorColor
    
    Behavior on color {
        ColorAnimation { duration: Theme.animationDurationFast }
    }
}
