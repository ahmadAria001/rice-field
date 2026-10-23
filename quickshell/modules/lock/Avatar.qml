// Circular avatar with a soft radial accent glow and a thin accent ring.
// Falls back to a monogram when the image is missing or fails to load.
// The source image must come from ~/Pictures/Wallpapers/. Nothing outside that
// directory is used, by request.

import "../../theme"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Shapes

Item {
    // Circular crop.

    id: root

    property string source: ""
    property string name: ""
    property int size: 104
    // Set when the image fails, so the monogram takes over.
    property bool imageFailed: false
    readonly property bool showMonogram: source === "" || imageFailed
    // Overall diameter of the glow halo around the disc.
    readonly property int glowSize: Math.round(size * 2.1)

    implicitWidth: size
    implicitHeight: size

    // Soft falloff glow: a true radial gradient, so there is no visible edge.
    Shape {
        anchors.centerIn: parent
        width: root.glowSize
        height: root.glowSize
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            startX: root.glowSize / 2
            startY: 0

            PathAngleArc {
                centerX: root.glowSize / 2
                centerY: root.glowSize / 2
                radiusX: root.glowSize / 2
                radiusY: root.glowSize / 2
                startAngle: 0
                sweepAngle: 360
            }

            fillGradient: RadialGradient {
                centerX: root.glowSize / 2
                centerY: root.glowSize / 2
                centerRadius: root.glowSize / 2
                focalX: root.glowSize / 2
                focalY: root.glowSize / 2

                GradientStop {
                    position: 0
                    color: Qt.rgba(Theme.accentMauve.r, Theme.accentMauve.g, Theme.accentMauve.b, 0.22)
                }

                GradientStop {
                    position: 0.55
                    color: Qt.rgba(Theme.accentMauve.r, Theme.accentMauve.g, Theme.accentMauve.b, 0.07)
                }

                GradientStop {
                    position: 1
                    color: Qt.rgba(Theme.accentMauve.r, Theme.accentMauve.g, Theme.accentMauve.b, 0)
                }

            }

        }

    }

    // Done with Qt5Compat's OpacityMask rather than MultiEffect's mask. MultiEffect's
    // maskSource comes back empty in this build (noctalia-qs is built against Qt 6.11
    // while the system ships 6.12), and ShaderEffectSource with hideSource has the same
    // problem: the mask texture reads as transparent and the image is masked away.
    Item {
        id: maskHolder

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "white"
        }

    }

    // The disc behind the image, so a transparent or missing image still reads as a
    // circle rather than a hole.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surface0
    }

    Image {
        id: portrait

        anchors.fill: parent
        source: root.source
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        // The mask effect renders the image, so the source itself stays hidden.
        visible: false
        onStatusChanged: {
            if (status === Image.Error)
                root.imageFailed = true;
            else if (status === Image.Ready)
                root.imageFailed = false;
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: portrait
        maskSource: maskHolder
        visible: !root.showMonogram
    }

    Text {
        anchors.centerIn: parent
        visible: root.showMonogram
        text: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : "?"
        font.family: "sans-serif"
        font.pixelSize: Math.round(root.size * 0.38)
        font.bold: true
        color: Theme.accentPink
    }

    // Accent ring on top of the crop.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: Theme.accentMauve
        border.width: 2
    }

}
