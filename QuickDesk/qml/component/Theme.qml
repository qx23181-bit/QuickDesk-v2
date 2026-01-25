// Modern Fluent Design Theme Manager
// Singleton for global theme configuration with multiple theme support
pragma Singleton
import QtQuick

QtObject {
    id: root
    
    // ============ Theme Types ============
    
    enum ThemeType {
        FluentDark,      // 默认深色主题（蓝色）
        FluentLight,     // 浅色主题（蓝色）
        NordDark,        // Nord 深色主题（青色）
        DraculaDark,     // Dracula 深色主题（紫色）
        MonokaiDark,     // Monokai 深色主题（绿色）
        SolarizedLight   // Solarized 浅色主题（橙色）
    }
    
    // ============ Current Theme ============
    
    property int currentTheme: Theme.ThemeType.FluentDark
    
    // ============ Theme Configurations ============
    
    // Fluent Dark (默认 - 蓝色)
    readonly property var fluentDark: ({
        name: "Fluent Dark",
        background: "#1E1E1E",
        surface: "#252525",
        surfaceVariant: "#2D2D2D",
        surfaceHover: "#303030",
        primary: "#0078D4",
        primaryHover: "#1084D8",
        primaryPressed: "#005A9E",
        primaryDisabled: "#4A4A4A",
        accent: "#60A5FA",
        accentLight: "#93C5FD",
        border: "#3F3F3F",
        borderHover: "#505050",
        borderFocus: "#0078D4",
        text: "#FFFFFF",
        textSecondary: "#B4B4B4",
        textDisabled: "#6B6B6B",
        textOnPrimary: "#FFFFFF",
        success: "#10B981",
        successHover: "#059669",
        error: "#EF4444",
        errorHover: "#DC2626",
        warning: "#F59E0B",
        warningHover: "#D97706",
        info: "#3B82F6",
        infoHover: "#2563EB",
        shadowLight: "#00000040",
        shadowMedium: "#00000060",
        shadowDark: "#00000080",
        overlay: "#00000099"
    })
    
    // Fluent Light (浅色 - 蓝色)
    readonly property var fluentLight: ({
        name: "Fluent Light",
        background: "#F3F3F3",
        surface: "#FFFFFF",
        surfaceVariant: "#F9F9F9",
        surfaceHover: "#F5F5F5",
        primary: "#0078D4",
        primaryHover: "#106EBE",
        primaryPressed: "#005A9E",
        primaryDisabled: "#D1D1D1",
        accent: "#0078D4",
        accentLight: "#60A5FA",
        border: "#E0E0E0",
        borderHover: "#C0C0C0",
        borderFocus: "#0078D4",
        text: "#1E1E1E",
        textSecondary: "#616161",
        textDisabled: "#A0A0A0",
        textOnPrimary: "#FFFFFF",
        success: "#10B981",
        successHover: "#059669",
        error: "#DC2626",
        errorHover: "#B91C1C",
        warning: "#F59E0B",
        warningHover: "#D97706",
        info: "#3B82F6",
        infoHover: "#2563EB",
        shadowLight: "#00000010",
        shadowMedium: "#00000020",
        shadowDark: "#00000030",
        overlay: "#00000066"
    })
    
    // Nord Dark (青色主题)
    readonly property var nordDark: ({
        name: "Nord Dark",
        background: "#2E3440",
        surface: "#3B4252",
        surfaceVariant: "#434C5E",
        surfaceHover: "#4C566A",
        primary: "#88C0D0",
        primaryHover: "#8FBCBB",
        primaryPressed: "#81A1C1",
        primaryDisabled: "#4C566A",
        accent: "#88C0D0",
        accentLight: "#8FBCBB",
        border: "#4C566A",
        borderHover: "#5E6A7A",
        borderFocus: "#88C0D0",
        text: "#ECEFF4",
        textSecondary: "#D8DEE9",
        textDisabled: "#616E88",
        textOnPrimary: "#2E3440",
        success: "#A3BE8C",
        successHover: "#8DA376",
        error: "#BF616A",
        errorHover: "#A94952",
        warning: "#EBCB8B",
        warningHover: "#D5B574",
        info: "#5E81AC",
        infoHover: "#4C6A96",
        shadowLight: "#00000040",
        shadowMedium: "#00000060",
        shadowDark: "#00000080",
        overlay: "#00000099"
    })
    
    // Dracula Dark (紫色主题)
    readonly property var draculaDark: ({
        name: "Dracula",
        background: "#282A36",
        surface: "#44475A",
        surfaceVariant: "#4D5066",
        surfaceHover: "#565973",
        primary: "#BD93F9",
        primaryHover: "#C9A8FC",
        primaryPressed: "#A775E8",
        primaryDisabled: "#6272A4",
        accent: "#FF79C6",
        accentLight: "#FF92D0",
        border: "#6272A4",
        borderHover: "#7282B4",
        borderFocus: "#BD93F9",
        text: "#F8F8F2",
        textSecondary: "#BFBFBF",
        textDisabled: "#6272A4",
        textOnPrimary: "#282A36",
        success: "#50FA7B",
        successHover: "#5AFB85",
        error: "#FF5555",
        errorHover: "#FF6E6E",
        warning: "#FFB86C",
        warningHover: "#FFC280",
        info: "#8BE9FD",
        infoHover: "#9FEDFD",
        shadowLight: "#00000040",
        shadowMedium: "#00000060",
        shadowDark: "#00000080",
        overlay: "#00000099"
    })
    
    // Monokai Dark (绿色主题)
    readonly property var monokaiDark: ({
        name: "Monokai",
        background: "#272822",
        surface: "#3E3D32",
        surfaceVariant: "#49483E",
        surfaceHover: "#54534A",
        primary: "#A6E22E",
        primaryHover: "#B8E854",
        primaryPressed: "#8EC71F",
        primaryDisabled: "#75715E",
        accent: "#66D9EF",
        accentLight: "#80E3F5",
        border: "#75715E",
        borderHover: "#85816E",
        borderFocus: "#A6E22E",
        text: "#F8F8F2",
        textSecondary: "#CFCFC2",
        textDisabled: "#75715E",
        textOnPrimary: "#272822",
        success: "#A6E22E",
        successHover: "#B8E854",
        error: "#F92672",
        errorHover: "#FA4089",
        warning: "#FD971F",
        warningHover: "#FEA739",
        info: "#66D9EF",
        infoHover: "#80E3F5",
        shadowLight: "#00000040",
        shadowMedium: "#00000060",
        shadowDark: "#00000080",
        overlay: "#00000099"
    })
    
    // Solarized Light (浅色橙色主题)
    readonly property var solarizedLight: ({
        name: "Solarized Light",
        background: "#FDF6E3",
        surface: "#EEE8D5",
        surfaceVariant: "#F5EFD6",
        surfaceHover: "#E9E2CE",
        primary: "#268BD2",
        primaryHover: "#2AA0E8",
        primaryPressed: "#2075BA",
        primaryDisabled: "#93A1A1",
        accent: "#CB4B16",
        accentLight: "#DC6A3D",
        border: "#93A1A1",
        borderHover: "#839496",
        borderFocus: "#268BD2",
        text: "#073642",
        textSecondary: "#586E75",
        textDisabled: "#93A1A1",
        textOnPrimary: "#FDF6E3",
        success: "#859900",
        successHover: "#9BAF00",
        error: "#DC322F",
        errorHover: "#E74C3C",
        warning: "#CB4B16",
        warningHover: "#DC6A3D",
        info: "#268BD2",
        infoHover: "#2AA0E8",
        shadowLight: "#00000010",
        shadowMedium: "#00000020",
        shadowDark: "#00000030",
        overlay: "#00000066"
    })
    
    // ============ Active Theme Colors ============
    
    readonly property color background: _currentThemeConfig.background
    readonly property color surface: _currentThemeConfig.surface
    readonly property color surfaceVariant: _currentThemeConfig.surfaceVariant
    readonly property color surfaceHover: _currentThemeConfig.surfaceHover
    readonly property color surfacePressed: Qt.darker(_currentThemeConfig.surfaceHover, 1.1)
    
    readonly property color primary: _currentThemeConfig.primary
    readonly property color primaryHover: _currentThemeConfig.primaryHover
    readonly property color primaryPressed: _currentThemeConfig.primaryPressed
    readonly property color primaryDisabled: _currentThemeConfig.primaryDisabled
    
    readonly property color accent: _currentThemeConfig.accent
    readonly property color accentLight: _currentThemeConfig.accentLight
    
    readonly property color border: _currentThemeConfig.border
    readonly property color borderHover: _currentThemeConfig.borderHover
    readonly property color borderFocus: _currentThemeConfig.borderFocus
    
    readonly property color text: _currentThemeConfig.text
    readonly property color textSecondary: _currentThemeConfig.textSecondary
    readonly property color textDisabled: _currentThemeConfig.textDisabled
    readonly property color textOnPrimary: _currentThemeConfig.textOnPrimary
    
    readonly property color success: _currentThemeConfig.success
    readonly property color successHover: _currentThemeConfig.successHover
    readonly property color error: _currentThemeConfig.error
    readonly property color errorHover: _currentThemeConfig.errorHover
    readonly property color warning: _currentThemeConfig.warning
    readonly property color warningHover: _currentThemeConfig.warningHover
    readonly property color info: _currentThemeConfig.info
    readonly property color infoHover: _currentThemeConfig.infoHover
    
    readonly property color shadowLight: _currentThemeConfig.shadowLight
    readonly property color shadowMedium: _currentThemeConfig.shadowMedium
    readonly property color shadowDark: _currentThemeConfig.shadowDark
    readonly property color overlay: _currentThemeConfig.overlay
    
    // ============ Private Helper ============
    
    readonly property var _currentThemeConfig: {
        switch(currentTheme) {
            case Theme.ThemeType.FluentDark: return fluentDark
            case Theme.ThemeType.FluentLight: return fluentLight
            case Theme.ThemeType.NordDark: return nordDark
            case Theme.ThemeType.DraculaDark: return draculaDark
            case Theme.ThemeType.MonokaiDark: return monokaiDark
            case Theme.ThemeType.SolarizedLight: return solarizedLight
            default: return fluentDark
        }
    }
    
    readonly property string currentThemeName: _currentThemeConfig.name
    
    // ============ Dimensions (不随主题变化) ============
    
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusXLarge: 16
    readonly property int radiusFull: 9999
    
    readonly property int spacingXSmall: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingXLarge: 24
    readonly property int spacingXXLarge: 32
    
    readonly property int buttonHeightSmall: 28
    readonly property int buttonHeightMedium: 36
    readonly property int buttonHeightLarge: 44
    
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeMedium: 20
    readonly property int iconSizeLarge: 24
    
    readonly property int borderWidthThin: 1
    readonly property int borderWidthMedium: 2
    
    // ============ Typography (不随主题变化) ============
    
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeXLarge: 18
    readonly property int fontSizeTitle: 20
    readonly property int fontSizeHeading: 24
    
    readonly property string fontFamily: "Segoe UI"
    readonly property string fontFamilyMono: "Consolas"
    
    // ============ Animation (不随主题变化) ============
    
    readonly property int animationDurationFast: 150
    readonly property int animationDurationMedium: 250
    readonly property int animationDurationSlow: 350
    
    readonly property int animationEasingType: Easing.OutCubic
    
    // ============ Z-Index (不随主题变化) ============
    
    readonly property int zIndexBase: 0
    readonly property int zIndexDropdown: 100
    readonly property int zIndexModal: 200
    readonly property int zIndexToast: 300
    readonly property int zIndexTooltip: 400
}
