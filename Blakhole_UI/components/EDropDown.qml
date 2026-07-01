// EDropDown.qml — 自定义下拉选择组件
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var model: []
    property int currentIndex: 0
    property string currentText: model && model.length > currentIndex ? model[currentIndex] : ""
    property int preferredWidth: 140

    signal activated(int index)

    implicitWidth: preferredWidth
    implicitHeight: 34

    // 选中显示按钮
    Rectangle {
        id: buttonBg
        anchors.fill: parent
        radius: 8
        color: mouseArea.containsMouse
            ? Qt.darker(theme.primaryColor, 1.15)
            : theme.primaryColor
        border.color: popup.visible ? theme.focusColor : theme.borderColor
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            spacing: 4

            Text {
                text: root.currentText
                color: theme.textColor
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            Text {
                text: popup.visible ? "\uf077" : "\uf078"
                font.family: iconFont.name
                font.pixelSize: 10
                color: theme.borderColor
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }
    }

    // 下拉弹出
    Popup {
        id: popup
        y: root.height + 4
        x: 0
        width: root.width
        implicitHeight: listView.contentHeight + 8
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 8
            color: theme.secondaryColor
            border.color: theme.focusColor
            border.width: 1
        }

        ListView {
            id: listView
            anchors.fill: parent
            implicitHeight: contentHeight
            model: root.model
            clip: true
            interactive: false

            delegate: Rectangle {
                width: listView.width
                height: 32
                radius: 6
                color: index === root.currentIndex
                    ? theme.focusColor
                    : (itemMouse.containsMouse ? Qt.darker(theme.secondaryColor, 1.2) : "transparent")

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    text: modelData
                    color: index === root.currentIndex ? "#ffffff" : theme.textColor
                    font.pixelSize: 13
                    font.bold: index === root.currentIndex
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index
                        popup.close()
                        root.activated(index)
                    }
                }
            }
        }
    }
}
