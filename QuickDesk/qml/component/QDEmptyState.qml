// Fluent Design EmptyState Component
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Item {
    id: control
    
    // ============ Custom Properties ============
    
    property string iconSource: FluentIconGlyph.folderGlyph
    property color iconColor: Theme.textSecondary
    property string title: "暂无数据"
    property string description: ""
    property string actionText: ""
    
    signal actionClicked()
    
    // ============ Size & Style ============
    
    implicitWidth: 400
    implicitHeight: content.implicitHeight
    
    // ============ Content ============
    
    ColumnLayout {
        id: content
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacingLarge * 2, 400)
        spacing: Theme.spacingLarge
        
        // Icon
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120
            height: 120
            color: Qt.rgba(control.iconColor.r, control.iconColor.g, control.iconColor.b, 0.1)
            radius: width / 2
            
            Text {
                anchors.centerIn: parent
                text: control.iconSource
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 48
                color: control.iconColor
            }
        }
        
        // Text Content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall
            
            Text {
                text: control.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.text
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Text {
                visible: control.description !== ""
                text: control.description
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        
        // Action Button
        QDButton {
            visible: control.actionText !== ""
            text: control.actionText
            buttonType: QDButton.Type.Primary
            Layout.alignment: Qt.AlignHCenter
            onClicked: control.actionClicked()
        }
    }
}
