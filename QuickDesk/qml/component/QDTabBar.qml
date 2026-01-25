// Fluent Design TabBar Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Controls.TabBar {
    id: control
    
    // ============ Custom Properties ============
    
    enum Position {
        Top,
        Bottom,
        Left,
        Right
    }
    
    property int tabPosition: QDTabBar.Position.Top
    
    // ============ Size & Style ============
    
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                           contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                            contentHeight + topPadding + bottomPadding)
    
    spacing: 0
    
    // ============ Background ============
    
    background: Rectangle {
        color: "transparent"
        
        // Bottom border for top position
        Rectangle {
            visible: control.tabPosition === QDTabBar.Position.Top
            anchors.bottom: parent.bottom
            width: parent.width
            height: Theme.borderWidthThin
            color: Theme.border
        }
        
        // Top border for bottom position
        Rectangle {
            visible: control.tabPosition === QDTabBar.Position.Bottom
            anchors.top: parent.top
            width: parent.width
            height: Theme.borderWidthThin
            color: Theme.border
        }
        
        // Right border for left position
        Rectangle {
            visible: control.tabPosition === QDTabBar.Position.Left
            anchors.right: parent.right
            width: Theme.borderWidthThin
            height: parent.height
            color: Theme.border
        }
        
        // Left border for right position
        Rectangle {
            visible: control.tabPosition === QDTabBar.Position.Right
            anchors.left: parent.left
            width: Theme.borderWidthThin
            height: parent.height
            color: Theme.border
        }
    }
    
    // ============ Content Layout ============
    
    contentItem: ListView {
        model: control.contentModel
        currentIndex: control.currentIndex
        
        spacing: control.spacing
        orientation: (control.tabPosition === QDTabBar.Position.Left || 
                     control.tabPosition === QDTabBar.Position.Right) ? 
                     ListView.Vertical : ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        snapMode: ListView.SnapToItem
        
        highlightMoveDuration: Theme.animationDurationMedium
        highlightResizeDuration: 0
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: 40
        preferredHighlightEnd: width - 40
    }
}
