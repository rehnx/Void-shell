pragma Singleton
import QtQuick
import "../services"

QtObject {
    // Runtime semantic tokens. ThemeManager is the only writer; UI components
    // continue consuming this singleton and never select palettes themselves.
    property string name: "Void Dark"
    property bool dark: true
    property color background: "#151b25"
    property color paletteSurface: "#df202735"
    property color paletteSurfaceElevated: "#ed283243"
    property color paletteSurfaceBottom: "#ef1c2330"
    property color paletteSurfaceCard: "#80333e50"
    property color paletteSurfaceCardBottom: "#602b3546"
    property color paletteSurfaceInset: "#90202a39"
    readonly property color surface: transparentSurface(paletteSurface)
    readonly property color surfaceElevated: transparentSurface(paletteSurfaceElevated)
    readonly property color surfaceBottom: transparentSurface(paletteSurfaceBottom)
    readonly property color surfaceCard: transparentSurface(paletteSurfaceCard)
    readonly property color surfaceCardBottom: transparentSurface(paletteSurfaceCardBottom)
    readonly property color surfaceInset: transparentSurface(paletteSurfaceInset)
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
    property bool paletteBlurEnabled: true
    readonly property bool blurEnabled: paletteBlurEnabled && Settings.blurStrength > 0
    readonly property real densityScale: Settings.density * (Settings.layoutMode === "compact" ? 0.85 : 1)
    readonly property bool barAtBottom: Settings.barPosition === "bottom"
    readonly property int panelDirection: barAtBottom ? 1 : -1

    // 0 = opaque, 1 = the palette's original glass alpha. Text never fades.
    function transparentSurface(color) {
        return Qt.rgba(color.r, color.g, color.b, 1 - (1 - color.a) * Settings.transparency);
    }
    function spacing(value) { return Math.max(1, Math.round(value * densityScale)); }
    function dimension(value) { return Math.round(value * Math.max(1, Settings.fontScale, densityScale)); }
    function controlHeight(value) {
        return Math.round(value * Math.max(densityScale, Settings.fontScale * 0.75));
    }
    function panelY(availableHeight, height) {
        return barAtBottom ? Math.max(spacingMedium, availableHeight - height - panelTop) : panelTop;
    }

    function applyPalette(palette) {
        if (!palette) return;
        name = palette.name;
        dark = palette.dark;
        background = palette.background;
        paletteSurface = palette.surface;
        paletteSurfaceElevated = palette.surfaceElevated;
        paletteSurfaceBottom = palette.surfaceBottom;
        paletteSurfaceCard = palette.surfaceCard;
        paletteSurfaceCardBottom = palette.surfaceCardBottom;
        paletteSurfaceInset = palette.surfaceInset;
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
        paletteBlurEnabled = palette.blurEnabled;
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
    readonly property int radiusSmall: Math.round(Settings.cornerRadius * 10 / 28)
    readonly property int radiusMedium: Math.round(Settings.cornerRadius * 18 / 28)
    readonly property int radiusLarge: Settings.cornerRadius
    readonly property int radiusPill: 999
    readonly property int spacingTiny: spacing(4)
    readonly property int spacingSmall: spacing(8)
    readonly property int spacingCompact: spacing(12)
    readonly property int spacingMedium: spacing(16)
    readonly property int spacingLarge: spacing(24)
    readonly property int spacingXLarge: spacing(32)
    readonly property int panelPadding: spacingLarge
    readonly property int cardPadding: spacingMedium
    readonly property int panelWidth: dimension(420)
    readonly property int panelCompactWidth: dimension(400)
    readonly property int panelHeight: dimension(600)
    readonly property int panelTop: barHeight + spacingMedium
    readonly property int launcherWidth: dimension(620)
    readonly property int launcherHeight: dimension(540)
    readonly property int barHeight: Math.max(controlHeight(48), buttonHeight + spacingSmall + barInset * 2)
    readonly property int barInset: 4
    readonly property int buttonHeight: Math.max(controlHeight(32), Math.ceil(fontLabel * lineHeight) + spacingSmall * 2)
    readonly property int inputHeight: Math.max(controlHeight(44), fontBody * 2)
    readonly property int appRowHeight: controlHeight(56)
    readonly property int toggleHeight: dimension(140)
    readonly property int toggleWidth: dimension(160)
    readonly property int toggleIconSize: 44
    readonly property int sliderCardHeight: dimension(96)
    readonly property int sliderTrackHeight: 6
    readonly property int sliderHandleSize: 18
    readonly property int iconSmall: 16
    readonly property int iconMedium: 20
    readonly property int iconLarge: 24
    readonly property int iconApplication: 32
    readonly property int artworkSize: 88
    readonly property int artworkCompactSize: 28
    readonly property int workspaceWidth: dimension(28)
    readonly property int workspaceHeight: controlHeight(24)
    readonly property int calendarCellHeight: controlHeight(36)
    readonly property int mediaWidgetWidth: dimension(240)
    readonly property int mediaWidgetMinimum: dimension(128)
    readonly property int statusMaximumWidth: dimension(160)
    readonly property int activeWindowMaximumWidth: dimension(320)
    readonly property int osdWidth: dimension(320)
    readonly property int osdHeight: dimension(88)
    readonly property int osdBottom: Math.max(56, barAtBottom ? panelTop : spacingLarge)

    property string fontFamily: Settings.fontFamily
    readonly property int fontDisplay: Math.round(26 * Settings.fontScale)
    readonly property int fontTitle: Math.round(21 * Settings.fontScale)
    readonly property int fontBody: Math.round(14 * Settings.fontScale)
    readonly property int fontLabel: Math.round(13 * Settings.fontScale)
    readonly property int fontCaption: Math.round(12 * Settings.fontScale)
    readonly property int weightRegular: Font.Normal
    readonly property int weightLabel: Font.Medium
    readonly property int weightTitle: Font.DemiBold
    readonly property real trackingLabel: 1.5
    readonly property real lineHeight: 1.2
}
