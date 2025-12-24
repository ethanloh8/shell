import Quickshell.Io

JsonObject {
    property bool enabled: true
    property DesktopClock desktopClock: DesktopClock {}
    property Visualiser visualiser: Visualiser {}
    property Swww swww: Swww {}

    component DesktopClock: JsonObject {
        property bool enabled: false
    }

    component Visualiser: JsonObject {
        property bool enabled: false
        property bool autoHide: true
        property bool blur: false
        property real rounding: 1
        property real spacing: 1
    }

    component Swww: JsonObject {
        property bool enabled: true // Use swww as wallpaper backend
        property string transitionType: "grow" // wipe, wave, grow, center, any, outer, random, simple, none
        property real transitionDuration: 1 // Duration in seconds
        property int transitionStep: 90 // How fast the transition approaches end (1-255)
        property int transitionFps: 60 // FPS for the transition animation
    }
}
