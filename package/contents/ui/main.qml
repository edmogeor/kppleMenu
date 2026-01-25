/*
 *  SPDX-FileCopyrightText: 2020 Kpple <info.kpple@gmail.com>
 *  SPDX-FileCopyrightText: 2024 Christian Tallner <chrtall@gmx.de>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    toolTipSubText: i18n("Shortcuts for shutdown, reboot, logout, settings etc.")
    hideOnWindowDeactivate: true
    Plasmoid.icon: plasmoid.configuration.icon
    property bool fullRepHasFocus: false

    // Parse menu items from configuration
    property var menuItemsModel: {
        try {
            return JSON.parse(plasmoid.configuration.menuItems)
        } catch (e) {
            console.error("Failed to parse menuItems:", e)
            return []
        }
    }

    // define exec system ( call commands ) : by Uswitch applet!
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: {
            var stdout = data["stdout"]

            if (callbacks[sourceName] !== undefined) {
                callbacks[sourceName](stdout);
            }

            exited(sourceName, stdout)
            disconnectSource(sourceName) // exec finished
        }

        function exec(cmd, onNewDataCallback) {
            // Hide Applet Window after a cmd was selected by the user.
            root.expanded = false
            if (onNewDataCallback !== undefined){
                callbacks[cmd] = onNewDataCallback
            }
            connectSource(cmd)
        }
        signal exited(string sourceName, string stdout)
    }

    //define highlight
    PlasmaExtras.Highlight {
        id: delegateHighlight
        visible: false
    }

    onExpandedChanged : (expanded) => {
        if(expanded){
            // Always focus fullRep, when applet is expanded to enable keyboard navigation.
            root.fullRepHasFocus = true
        }else {
            // Deactivate Highlight and focus, when applet is minimized/hidden, else navigation state would persist.
            if (delegateHighlight.parent) {
                delegateHighlight.parent.focus = false
                delegateHighlight.parent = null
            }
            root.fullRepHasFocus = false
        }
    }

    fullRepresentation: Item {
        id: fullRep

        readonly property double iwSize: Kirigami.Units.gridUnit * 12.6 // item width
        readonly property double shSize: 1.1 // separator height

        Layout.preferredWidth: iwSize
        Layout.preferredHeight: columnLayout.implicitHeight

        focus: root.fullRepHasFocus
        Keys.onPressed: (event) => {
            // Find first and last visible items for keyboard navigation
            var firstItem = null
            var lastItem = null
            for (var i = 0; i < menuRepeater.count; i++) {
                var item = menuRepeater.itemAt(i)
                if (item && item.isMenuItem) {
                    if (!firstItem) firstItem = item
                    lastItem = item
                }
            }

            switch (event.key) {
                case Qt.Key_Up:
                    if (lastItem) lastItem.forceActiveFocus()
                    break;
                case Qt.Key_Down:
                    if (firstItem) firstItem.forceActiveFocus()
                    break;
            }
        }

        ColumnLayout {
            id: columnLayout
            anchors.fill: parent
            spacing: 2

            Repeater {
                id: menuRepeater
                model: root.menuItemsModel

                delegate: Loader {
                    id: delegateLoader
                    Layout.fillWidth: true

                    property bool isMenuItem: modelData.type === "item"
                    property int itemIndex: index

                    sourceComponent: modelData.type === "divider" ? dividerComponent : menuItemComponent

                    // Forward focus methods to loaded item
                    function forceActiveFocus() {
                        if (item && item.forceActiveFocus) {
                            item.forceActiveFocus()
                        }
                    }

                    Component {
                        id: dividerComponent
                        MenuSeparator {
                            padding: 0
                            topPadding: 5
                            bottomPadding: 5
                            contentItem: Rectangle {
                                implicitWidth: fullRep.iwSize
                                implicitHeight: fullRep.shSize
                                color: "#1E000000"
                            }
                        }
                    }

                    Component {
                        id: menuItemComponent
                        ListDelegate {
                            id: menuItem
                            highlight: delegateHighlight
                            text: modelData.name || ""

                            PlasmaComponents.Label {
                                visible: modelData.shortcut ? true : false
                                text: modelData.shortcut ? modelData.shortcut + " " : ""
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onClicked: {
                                if (modelData.command) {
                                    executable.exec(modelData.command)
                                }
                            }

                            activeFocusOnTab: true

                            // Dynamic keyboard navigation
                            KeyNavigation.up: {
                                // Find previous menu item
                                for (var i = delegateLoader.itemIndex - 1; i >= 0; i--) {
                                    var item = menuRepeater.itemAt(i)
                                    if (item && item.isMenuItem) return item
                                }
                                // Wrap to last item
                                for (var j = menuRepeater.count - 1; j > delegateLoader.itemIndex; j--) {
                                    var item2 = menuRepeater.itemAt(j)
                                    if (item2 && item2.isMenuItem) return item2
                                }
                                return null
                            }

                            KeyNavigation.down: {
                                // Find next menu item
                                for (var i = delegateLoader.itemIndex + 1; i < menuRepeater.count; i++) {
                                    var item = menuRepeater.itemAt(i)
                                    if (item && item.isMenuItem) return item
                                }
                                // Wrap to first item
                                for (var j = 0; j < delegateLoader.itemIndex; j++) {
                                    var item2 = menuRepeater.itemAt(j)
                                    if (item2 && item2.isMenuItem) return item2
                                }
                                return null
                            }
                        }
                    }
                }
            }
        }
    }

} // end item
