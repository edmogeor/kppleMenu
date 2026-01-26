/*
 *  SPDX-FileCopyrightText: 2020 Kpple <info.kpple@gmail.com>
 *  SPDX-FileCopyrightText: 2024 Christian Tallner <chrtall@gmx.de>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: item

    signal clicked

    property alias text: label.text

    Layout.fillWidth: true
    height: row.height

    // Each item has its own highlight
    PlasmaExtras.Highlight {
        id: itemHighlight
        anchors.fill: parent
        visible: item.activeFocus
        hovered: item.activeFocus
        active: item.activeFocus
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            event.accepted = true
            item.clicked()
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            item.clicked()
        }
        onContainsMouseChanged: {
            if (area.containsMouse) {
                item.forceActiveFocus()
            }
        }
    }

    RowLayout {
        id: row
        // set space before the text item with a empty icon
        Item {
            id: emptySpace
            Layout.minimumWidth: 1 * Kirigami.Units.gridUnit
            Layout.maximumWidth: 1 * Kirigami.Units.gridUnit
        }

        Item {
            height: 24
            PlasmaComponents.Label {
                id: label
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
