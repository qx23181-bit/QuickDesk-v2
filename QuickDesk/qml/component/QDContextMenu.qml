// Fluent Design Context Menu Component
import QtQuick
import QtQuick.Controls as Controls

QDMenu {
    id: control
    
    // ============ Custom Properties ============
    
    property Item target: null
    
    // ============ Context Menu Behavior ============
    
    modal: true
    dim: false
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    
    // ============ Functions ============
    
    function popup(item) {
        if (item) {
            control.target = item
        }
        
        // Position at mouse cursor
        var pos = control.parent.mapFromGlobal(mouseX, mouseY)
        control.x = pos.x
        control.y = pos.y
        
        control.open()
    }
    
    function popupAt(item, x, y) {
        if (item) {
            control.target = item
        }
        
        control.x = x
        control.y = y
        control.open()
    }
    
    // ============ Mouse Area for Right Click ============
    
    Component.onCompleted: {
        if (control.parent) {
            var contextArea = contextMenuAreaComponent.createObject(control.parent)
            contextArea.menu = control
        }
    }
    
    Component {
        id: contextMenuAreaComponent
        
        MouseArea {
            property var menu: null
            
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            propagateComposedEvents: true
            
            onClicked: function(mouse) {
                if (menu) {
                    menu.x = mouse.x
                    menu.y = mouse.y
                    menu.open()
                }
                mouse.accepted = true
            }
        }
    }
}
