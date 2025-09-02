pragma ComponentBehavior: Bound

import ".."
import "../controls"
import "../images"
import qs.services
import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls

Item {
    id: root

    required property var dialog
    property alias currentItem: view.currentItem

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            radius: Appearance.rounding.small
        }
    }

    Loader {
        anchors.centerIn: parent
        active: view.count === 0
        asynchronous: true
        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.extraLarge * 2
                font.weight: 500
            }

            StyledText {
                text: qsTr("This folder is empty")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }
        }
    }

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Appearance.padding.small + Appearance.padding.normal

        cellWidth: Sizes.itemWidth + Appearance.spacing.small
        cellHeight: Sizes.itemWidth + Appearance.spacing.small * 2 + Appearance.padding.normal * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        Keys.onEscapePressed: currentIndex = -1

        Keys.onReturnPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted(currentItem.modelData.path);
        }
        Keys.onEnterPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted(currentItem.modelData.path);
        }

        ScrollBar.vertical: StyledScrollBar {}

        model: FileSystemModel {
            path: {
                if (root.dialog.cwd[0] === "Home")
                    return `${Paths.strip(Paths.home)}/${root.dialog.cwd.slice(1).join("/")}`;
                else
                    return root.dialog.cwd.join("/");
            }
            onPathChanged: view.currentIndex = -1
        }

        delegate: StyledRect {
            id: item

            required property int index
            required property FileSystemEntry modelData

            readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Appearance.padding.normal * 2

            implicitWidth: Sizes.itemWidth
            implicitHeight: nonAnimHeight

            radius: Appearance.rounding.normal
            color: Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, GridView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHighest.a : 0)
            z: GridView.isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
            clip: true

            StateLayer {
                onDoubleClicked: {
                    if (item.modelData.isDir)
                        root.dialog.cwd.push(item.modelData.name);
                    else if (root.dialog.selectionValid)
                        root.dialog.accepted(item.modelData.path);
                }

                function onClicked(): void {
                    view.currentIndex = item.index;
                }
            }

            CachingIconImage {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Appearance.padding.normal

                implicitSize: Sizes.itemWidth - Appearance.padding.normal * 2
                source: {
                    const file = item.modelData;
                    if (!file)
                        return Quickshell.iconPath("application-x-zerosize");

                    if (file.isImage)
                        return Qt.resolvedUrl(file.path);

                    if (!file.isDir)
                        return Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");

                    if (root.dialog.cwd.length === 1 && ["Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos"].includes(file.name))
                        return Quickshell.iconPath(`folder-${file.name.toLowerCase()}`);

                    return Quickshell.iconPath("inode-directory");
                }
            }

            StyledText {
                id: name

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: icon.bottom
                anchors.topMargin: Appearance.spacing.small
                anchors.margins: Appearance.padding.normal

                horizontalAlignment: Text.AlignHCenter
                text: item.modelData?.name ?? ""
                elide: item.GridView.isCurrentItem ? Text.ElideNone : Text.ElideRight
                wrapMode: item.GridView.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }

        populate: Transition {
            Anim {
                property: "scale"
                from: 0.7
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.padding.small

        currentItem: view.currentItem
    }
}
