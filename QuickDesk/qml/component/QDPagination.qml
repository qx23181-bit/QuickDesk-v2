// Fluent Design Pagination Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Item {
    id: control
    
    // ============ Custom Properties ============
    
    property int total: 0
    property int current: 1
    property int pageSize: 10
    property bool showSizeChanger: true
    property bool showQuickJumper: false
    property var pageSizeOptions: [10, 20, 50, 100]
    
    signal pageChanged(int page)
    
    // Computed properties
    readonly property int totalPages: Math.ceil(control.total / control.pageSize)
    readonly property int startItem: (control.current - 1) * control.pageSize + 1
    readonly property int endItem: Math.min(control.current * control.pageSize, control.total)
    
    // ============ Size & Style ============
    
    implicitWidth: paginationRow.implicitWidth
    implicitHeight: Theme.buttonHeightMedium
    
    // ============ Content ============
    
    RowLayout {
        id: paginationRow
        anchors.fill: parent
        spacing: Theme.spacingMedium
        
        // Total info
        Text {
            text: "共 " + control.total + " 项"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textSecondary
            visible: control.total > 0
        }
        
        // Previous button
        QDIconButton {
            buttonSize: QDIconButton.Size.Small
            iconSource: FluentIconGlyph.chevronLeftGlyph
            enabled: control.current > 1
            onClicked: {
                if (control.current > 1) {
                    control.current--
                    control.pageChanged(control.current)
                }
            }
        }
        
        // Page numbers
        Item {
            Layout.preferredWidth: 300  // 固定宽度，防止按钮位置跳动
            Layout.preferredHeight: 32
            
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingSmall
                
                Repeater {
                    model: getPageNumbers()
                    
                    Rectangle {
                        width: modelData === "..." ? 30 : 32
                        height: 32
                        color: {
                            if (modelData === control.current) return Theme.primary
                            if (modelData !== "..." && pageButtonArea.containsMouse) return Theme.surfaceHover
                            return Theme.surface
                        }
                        border.width: Theme.borderWidthThin
                        border.color: modelData === control.current ? Theme.primary : Theme.border
                        radius: Theme.radiusSmall
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: modelData === control.current ? Theme.textOnPrimary : Theme.text
                        }
                        
                        MouseArea {
                            id: pageButtonArea
                            anchors.fill: parent
                            hoverEnabled: modelData !== "..."
                            cursorShape: modelData !== "..." ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: modelData !== "..." && modelData !== control.current
                            
                            onClicked: {
                                if (typeof modelData === 'number') {
                                    control.current = modelData
                                    control.pageChanged(control.current)
                                }
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: Theme.animationDurationFast }
                        }
                    }
                }
            }
        }
        
        // Next button
        QDIconButton {
            buttonSize: QDIconButton.Size.Small
            iconSource: FluentIconGlyph.chevronRightGlyph
            enabled: control.current < control.totalPages
            onClicked: {
                if (control.current < control.totalPages) {
                    control.current++
                    control.pageChanged(control.current)
                }
            }
        }
        
        // Page size changer
        Row {
            visible: control.showSizeChanger
            spacing: Theme.spacingSmall
            
            Text {
                text: "每页"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }
            
            QDComboBox {
                width: 80
                model: control.pageSizeOptions
                currentIndex: control.pageSizeOptions.indexOf(control.pageSize)
                onCurrentValueChanged: {
                    if (currentValue && currentValue !== control.pageSize) {
                        control.pageSize = currentValue
                        control.current = 1
                    }
                }
            }
            
            Text {
                text: "条"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        // Range info
        Text {
            text: control.startItem + "-" + control.endItem
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.text
            visible: control.total > 0
        }
    }
    
    // ============ Functions ============
    
    function getPageNumbers() {
        var pages = []
        var total = control.totalPages
        var current = control.current
        
        if (total <= 7) {
            // Show all pages
            for (var i = 1; i <= total; i++) {
                pages.push(i)
            }
        } else {
            // Show first, last, current and nearby pages
            pages.push(1)
            
            if (current > 3) {
                pages.push("...")
            }
            
            var start = Math.max(2, current - 1)
            var end = Math.min(total - 1, current + 1)
            
            for (var j = start; j <= end; j++) {
                pages.push(j)
            }
            
            if (current < total - 2) {
                pages.push("...")
            }
            
            pages.push(total)
        }
        
        return pages
    }
}
