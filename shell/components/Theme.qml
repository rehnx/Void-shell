pragma Singleton
import QtQuick

QtObject {
    // Runtime semantic tokens. ThemeManager is the only writer; UI components
    // continue consuming this singleton and never select palettes themselves.
    property string name: "Void Dark"
    property bool dark: true
    property color background: "#151b25"
    property color surface: "#df202735"
    property color surfaceElevated: "#ed283243"
    property color surfaceBottom: "#ef1c2330"
    property color surfaceCard: "#80333e50"
    property color surfaceCardBottom: "#602b3546"
    property color surfaceInset: "#90202a39"
    property color textPrimary: "#f0f4fa"
    property color textSecondary: "#b5c1d2"
    property color textMuted: "#8f9eb4"
    property color accent: "#a4ccfa"
    property color secondary: "#8faed2"
    property color textOnAccent: "#17283e"
    property color hover: "#183fa8ff"
    property color pressed: "#354faaff"
    property color selected: "#284faaff"
    property color border: "#28cfdef3"
    property color borderStrong: "#4dcfdef3"
    property color innerBorder: "#0cffffff"
    property color separator: "#19cfdef3"
    property color shadowNear: "#24050810"
    property color shadowFar: "#10050810"
    property color scrim: "#101823"
    property bool shadowsEnabled: true
    property bool blurEnabled: true

    function applyPalette(palette) {
        if (!palette) return;
        name = palette.name;
        dark = palette.dark;
        background = palette.background;
        surface = palette.surface;
        surfaceElevated = palette.surfaceElevated;
        surfaceBottom = palette.surfaceBottom;
        surfaceCard = palette.surfaceCard;
        surfaceCardBottom = palette.surfaceCardBottom;
        surfaceInset = palette.surfaceInset;
        textPrimary = palette.textPrimary;
        textSecondary = palette.textSecondary;
        textMuted = palette.textMuted;
        accent = palette.accent;
        secondary = palette.secondary;
        textOnAccent = palette.textOnAccent;
        hover = palette.hover;
        pressed = palette.pressed;
        selected = palette.selected;
        border = palette.border;
        borderStrong = palette.borderStrong;
        innerBorder = palette.innerBorder;
        separator = palette.separator;
        shadowNear = palette.shadowNear;
        shadowFar = palette.shadowFar;
        scrim = palette.scrim;
        shadowsEnabled = palette.shadowsEnabled;
        blurEnabled = palette.blurEnabled;
    }

    readonly property real scrimOpacity: 0.18
    readonly property real disabledOpacity: 0.5
    readonly property real mutedOpacity: 0.55
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
    readonly property int shadowNearSpread: 3
    readonly property int shadowFarSpread: 7
    readonly property int shadowOffset: 3
    readonly property int elevationNone: 0
    readonly property int elevationCard: 1
    readonly property int elevationPanel: 2
    readonly property int radiusSmall: 10
    readonly property int radiusMedium: 18
    readonly property int radiusLarge: 28
    readonly property int radiusPill: 999
    readonly property int spacingTiny: 4
    readonly property int spacingSmall: 8
    readonly property int spacingCompact: 12
    readonly property int spacingMedium: 16
    readonly property int spacingLarge: 24
    readonly property int spacingXLarge: 32
    readonly property int panelPadding: 24
    readonly property int cardPadding: 16
    readonly property int panelWidth: 420
    readonly property int panelCompactWidth: 400
    readonly property int panelHeight: 600
    readonly property int panelTop: 64
    readonly property int launcherWidth: 620
    readonly property int launcherHeight: 540
    readonly property int barHeight: 48
    readonly property int barInset: 4
    readonly property int buttonHeight: 32
    readonly property int inputHeight: 44
    readonly property int appRowHeight: 56
    readonly property int toggleHeight: 140
    readonly property int toggleWidth: 160
    readonly property int toggleIconSize: 44
    readonly property int sliderCardHeight: 96
    readonly property int sliderTrackHeight: 6
    readonly property int sliderHandleSize: 18
    readonly property int iconSmall: 16
    readonly property int iconMedium: 20
    readonly property int iconLarge: 24
    readonly property int iconApplication: 32
    readonly property int artworkSize: 88
    readonly property int artworkCompactSize: 28
    readonly property int workspaceWidth: 28
    readonly property int workspaceHeight: 24
    readonly property int calendarCellHeight: 36
    readonly property int mediaWidgetWidth: 240
    readonly property int mediaWidgetMinimum: 128
    readonly property int statusMaximumWidth: 160
    readonly property int activeWindowMaximumWidth: 320
    readonly property int osdWidth: 320
    readonly property int osdHeight: 88
    readonly property int osdBottom: 56

    property string fontFamily: "Sans Serif"
    readonly property int fontDisplay: 26
    readonly property int fontTitle: 21
    readonly property int fontBody: 14
    readonly property int fontLabel: 13
    readonly property int fontCaption: 12
    readonly property int weightRegular: Font.Normal
    readonly property int weightLabel: Font.Medium
    readonly property int weightTitle: Font.DemiBold
    readonly property real trackingLabel: 1.5
    readonly property real lineHeight: 1.2
}
