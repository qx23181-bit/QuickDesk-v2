// Fluent Design Table Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Item {
    id: control
    
    // ============ Custom Properties ============
    
    property var columns: []  // Array of {title, role, width}
    property alias model: tableView.model
    property bool showHeader: true
    property bool showBorder: true
    property bool alternatingRowColors: true
    property bool sortable: false
    
    property int currentRow: -1
    
    signal rowClicked(int row, var rowData)
    signal cellClicked(int row, int column, var cellData)
    
    // ============ Size & Style ============
    
    implicitWidth: 600
    implicitHeight: 400
    
    // ============ Content ============
    
    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.width: control.showBorder ? Theme.borderWidthThin : 0
        border.color: Theme.border
        radius: Theme.radiusMedium
        
        Column {
            anchors.fill: parent
            spacing: 0
            
            // Header
            Rectangle {
                visible: control.showHeader
                width: parent.width
                height: Theme.buttonHeightMedium
                color: Theme.surfaceVariant
                radius: control.showBorder ? Theme.radiusMedium : 0
                
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.radius
                    color: parent.color
                }
                
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingMedium
                    spacing: Theme.spacingSmall
                    
                    Repeater {
                        model: control.columns
                        
                        Rectangle {
                            width: modelData.width || (parent.width - parent.spacing * (control.columns.length - 1)) / control.columns.length
                            height: parent.height
                            color: "transparent"
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingSmall
                                
                                Text {
                                    text: modelData.title || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.text
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                Text {
                                    visible: control.sortable
                                    text: FluentIconGlyph.sortGlyph
                                    font.family: "Segoe Fluent Icons"
                                    font.pixelSize: 12
                                    color: Theme.textSecondary
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Theme.borderWidthThin
                    color: Theme.border
                }
            }
            
            // Table Content
            Controls.ScrollView {
                width: parent.width
                height: parent.height - (control.showHeader ? Theme.buttonHeightMedium : 0)
                clip: true
                
                Controls.ScrollBar.vertical: QDScrollBar {
                    autoHide: true
                }
                
                ListView {
                    id: tableView
                    
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        
                        width: tableView.width
                        height: Theme.buttonHeightMedium
                        color: {
                            if (index === control.currentRow) return Theme.surfaceHover
                            if (control.alternatingRowColors && index % 2 === 1) return Theme.surfaceVariant
                            return "transparent"
                        }
                        
                        property int rowIndex: index
                        property var rowData: modelData
                        
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingMedium
                            anchors.rightMargin: Theme.spacingMedium
                            spacing: Theme.spacingSmall
                            
                            Repeater {
                                model: control.columns
                                
                                Rectangle {
                                    required property int index
                                    required property var modelData
                                    
                                    width: modelData.width || (parent.width - parent.spacing * (control.columns.length - 1)) / control.columns.length
                                    height: parent.height
                                    color: "transparent"
                                    
                                    property int columnIndex: index
                                    property var columnData: modelData
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        text: {
                                            var rowIdx = parent.parent.parent.rowIndex
                                            var colRole = parent.columnData.role
                                            var value = tableView.model.get ? 
                                                       tableView.model.get(rowIdx)[colRole] :
                                                       tableView.model[rowIdx][colRole]
                                            return value !== undefined ? value : ""
                                        }
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: Theme.text
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignLeft
                                        elide: Text.ElideRight
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            var rowIdx = parent.parent.parent.rowIndex
                                            var colRole = parent.columnData.role
                                            var cellData = tableView.model.get ? 
                                                          tableView.model.get(rowIdx)[colRole] :
                                                          tableView.model[rowIdx][colRole]
                                            control.cellClicked(rowIdx, parent.columnIndex, cellData)
                                        }
                                    }
                                }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                control.currentRow = parent.rowIndex
                                var rowData = tableView.model.get ? 
                                             tableView.model.get(parent.rowIndex) :
                                             tableView.model[parent.rowIndex]
                                control.rowClicked(parent.rowIndex, rowData)
                            }
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Theme.spacingMedium
                            height: Theme.borderWidthThin
                            color: Theme.border
                            opacity: 0.5
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: Theme.animationDurationFast }
                        }
                    }
                }
            }
        }
    }
}
