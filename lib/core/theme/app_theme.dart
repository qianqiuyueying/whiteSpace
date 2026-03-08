import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 留白日记 - 墨韵纸香主题
/// 
/// 设计理念：精致的 Moleskine 笔记本 + 现代极简设计
/// 温暖的纸张质感，墨色文字，靛蓝点缀
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════
  // 核心色彩系统 - 墨韵纸香
  // ═══════════════════════════════════════════════════════════
  
  /// 主色调 - 靛蓝墨色
  static const Color primaryColor = Color(0xFF3D5A80);
  static const Color primaryLight = Color(0xFF5C7BA8);
  static const Color primaryDark = Color(0xFF2B4058);
  
  /// 次要色 - 兼容旧代码
  static const Color secondaryColor = Color(0xFF5C7BA8);
  
  /// 点缀色 - 朱砂红
  static const Color accentColor = Color(0xFFE07A5F);
  static const Color accentLight = Color(0xFFF2A990);
  
  /// 金色点缀
  static const Color goldColor = Color(0xFFD4A574);
  
  // ═══════════════════════════════════════════════════════════
  // 浅色主题 - 温暖纸张
  // ═══════════════════════════════════════════════════════════
  
  /// 背景 - 温暖的米白色
  static const Color lightBackground = Color(0xFFFAF7F2);
  static const Color lightBackgroundSecondary = Color(0xFFF5F0E8);
  static const Color lightSurface = Color(0xFFF5F0E8); // 兼容旧代码
  
  /// 卡片 - 奶油白
  static const Color lightCard = Color(0xFFFFFDF9);
  static const Color lightCardHover = Color(0xFFF8F4EC);
  
  /// 文字 - 墨色层次
  static const Color lightText = Color(0xFF2C2C2C);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextTertiary = Color(0xFF9A9A9A);
  
  /// 边框与分割
  static const Color lightBorder = Color(0xFFE8E2D9);
  static const Color lightDivider = Color(0xFFF0EBE3);
  
  // ═══════════════════════════════════════════════════════════
  // 深色主题 - 深邃夜空
  // ═══════════════════════════════════════════════════════════
  
  /// 背景 - 深墨色
  static const Color darkBackground = Color(0xFF1A1A1F);
  static const Color darkBackgroundSecondary = Color(0xFF242429);
  static const Color darkSurface = Color(0xFF242429); // 兼容旧代码
  
  /// 卡片 - 暗灰
  static const Color darkCard = Color(0xFF2A2A30);
  static const Color darkCardHover = Color(0xFF333339);
  
  /// 文字 - 温暖白
  static const Color darkText = Color(0xFFF5F2ED);
  static const Color darkTextSecondary = Color(0xFFB0ADA6);
  static const Color darkTextTertiary = Color(0xFF7A7770);
  
  /// 边框与分割
  static const Color darkBorder = Color(0xFF3A3A40);
  static const Color darkDivider = Color(0xFF2F2F35);

  // ═══════════════════════════════════════════════════════════
  // 渐变色 - 柔和优雅
  // ═══════════════════════════════════════════════════════════
  
  /// 主渐变 - 靛蓝
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D5A80), Color(0xFF5C7BA8)],
  );
  
  /// 温暖渐变 - 日落
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE07A5F), Color(0xFFF2A990)],
  );
  
  /// 自然渐变 - 森林
  static const LinearGradient natureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C8A6B), Color(0xFF7BA889)],
  );
  
  /// 宁静渐变 - 湖水
  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B8E9F), Color(0xFF8FB3C4)],
  );
  
  /// 夜空渐变
  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  );

  // ═══════════════════════════════════════════════════════════
  // 阴影系统
  // ═══════════════════════════════════════════════════════════
  
  /// 柔和阴影
  static List<BoxShadow> softShadow([bool isDark = false]) => [
    BoxShadow(
      color: isDark 
          ? Colors.black.withValues(alpha: 0.3)
          : const Color(0xFF3D5A80).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// 卡片阴影
  static List<BoxShadow> cardShadow([bool isDark = false]) => [
    BoxShadow(
      color: isDark 
          ? Colors.black.withValues(alpha: 0.2)
          : const Color(0xFF3D5A80).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// 浮动按钮阴影
  static List<BoxShadow> fabShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // 圆角系统
  // ═══════════════════════════════════════════════════════════
  
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radius2XL = 32.0;

  // ═══════════════════════════════════════════════════════════
  // 间距系统
  // ═══════════════════════════════════════════════════════════
  
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double space2XL = 48.0;

  // ═══════════════════════════════════════════════════════════
  // 主题定义
  // ═══════════════════════════════════════════════════════════
  
  /// 浅色主题
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      tertiary: goldColor,
      surface: lightCard,
      onSurface: lightText,
      outline: lightBorder,
      outlineVariant: lightDivider,
    ),
    scaffoldBackgroundColor: lightBackground,
    
    // 应用栏主题
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: lightText, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    
    // 卡片主题
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // 浮动按钮主题
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    
    // 输入框主题
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBackgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(
        color: lightTextTertiary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // 底部导航栏主题
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightCard,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // 分割线主题
    dividerTheme: const DividerThemeData(
      color: lightDivider,
      thickness: 1,
      space: 1,
    ),
    
    // 图标按钮主题
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: lightTextSecondary,
        padding: const EdgeInsets.all(12),
      ),
    ),
    
    // 文字按钮主题
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
    ),
    
    // 填充按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    
    // 芯片主题
    chipTheme: ChipThemeData(
      backgroundColor: lightBackgroundSecondary,
      selectedColor: primaryColor.withValues(alpha: 0.12),
      labelStyle: const TextStyle(
        color: lightText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    
    // 底部表单主题
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
      ),
    ),
    
    // 对话框主题
    dialogTheme: DialogThemeData(
      backgroundColor: lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: const TextStyle(
        color: lightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: lightTextSecondary,
        fontSize: 15,
        height: 1.5,
      ),
    ),
    
    // 开关主题
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.3);
        }
        return null;
      }),
    ),
  );

  /// 深色主题
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryLight,
      secondary: accentLight,
      tertiary: goldColor,
      surface: darkCard,
      onSurface: darkText,
      outline: darkBorder,
      outlineVariant: darkDivider,
    ),
    scaffoldBackgroundColor: darkBackground,
    
    // 应用栏主题
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: darkText, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    
    // 卡片主题
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // 浮动按钮主题
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    
    // 输入框主题
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBackgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(
        color: darkTextTertiary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // 底部导航栏主题
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: primaryLight,
      unselectedItemColor: darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // 分割线主题
    dividerTheme: const DividerThemeData(
      color: darkDivider,
      thickness: 1,
      space: 1,
    ),
    
    // 图标按钮主题
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: darkTextSecondary,
        padding: const EdgeInsets.all(12),
      ),
    ),
    
    // 文字按钮主题
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
    ),
    
    // 填充按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    
    // 芯片主题
    chipTheme: ChipThemeData(
      backgroundColor: darkBackgroundSecondary,
      selectedColor: primaryLight.withValues(alpha: 0.15),
      labelStyle: const TextStyle(
        color: darkText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    
    // 底部表单主题
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
      ),
    ),
    
    // 对话框主题
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: const TextStyle(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: darkTextSecondary,
        fontSize: 15,
        height: 1.5,
      ),
    ),
    
    // 开关主题
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withValues(alpha: 0.3);
        }
        return null;
      }),
    ),
  );
}

/// 预设主题色
class ThemeColors {
  static const List<Color> accentColors = [
    Color(0xFF3D5A80), // 靛蓝
    Color(0xFFE07A5F), // 朱砂
    Color(0xFF5C8A6B), // 森林
    Color(0xFF6B8E9F), // 湖水
    Color(0xFFD4A574), // 金色
    Color(0xFF9B7EBD), // 薰衣草
    Color(0xFFC4786B), // 赭石
    Color(0xFF6B8E8E), // 青瓷
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 纸墨流年 - 扩展装饰色系
/// ═══════════════════════════════════════════════════════════════════════════

/// 水墨色系 - 用于背景和装饰
class InkColors {
  /// 淡墨
  static const Color lightInk = Color(0xFFE8E4DC);
  /// 中墨
  static const Color mediumInk = Color(0xFF8B8680);
  /// 浓墨
  static const Color darkInk = Color(0xFF3D3D3D);
  /// 焦墨
  static const Color deepInk = Color(0xFF1A1A1A);
  
  /// 深色模式下的水墨色
  static const Color darkModeLightInk = Color(0xFF4A4A50);
  static const Color darkModeMediumInk = Color(0xFF6A6A70);
}

/// 印章色系 - 用于点缀和强调
class SealColors {
  /// 朱砂红
  static const Color vermilion = Color(0xFFE07A5F);
  /// 丹红
  static const Color cinnabar = Color(0xFFC75B5B);
  /// 印泥红
  static const Color pasteRed = Color(0xFFB8433F);
  
  /// 金印
  static const Color goldSeal = Color(0xFFD4A574);
  /// 银印
  static const Color silverSeal = Color(0xFF9A9A9A);
}

/// 心情色系 - 用于心情指示
class MoodColors {
  /// 开心 - 暖阳金
  static const Color happy = Color(0xFFF2A950);
  /// 平静 - 湖水蓝
  static const Color calm = Color(0xFF6B8E9F);
  /// 难过 - 淡紫灰
  static const Color sad = Color(0xFF7A7A9E);
  /// 生气 - 朱砂红
  static const Color angry = Color(0xFFC75B5B);
  /// 焦虑 - 赭石
  static const Color anxious = Color(0xFF8B7355);
  /// 兴奋 - 珊瑚橙
  static const Color excited = Color(0xFFE07A5F);
  /// 疲惫 - 青灰
  static const Color tired = Color(0xFF6B8E8E);
  /// 一般 - 靛蓝
  static const Color neutral = Color(0xFF3D5A80);
  
  /// 获取心情对应的颜色
  static Color getMoodColor(int index) {
    const colors = [
      happy, calm, sad, angry, anxious, excited, tired, neutral
    ];
    return colors[index.clamp(0, colors.length - 1)];
  }
  
  /// 获取心情对应的渐变
  static LinearGradient getMoodGradient(int index) {
    final color = getMoodColor(index);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color,
        color.withValues(alpha: 0.7),
      ],
    );
  }
}

/// 纸张色系 - 用于背景和卡片
class PaperColors {
  /// 宣纸白
  static const Color xuanPaper = Color(0xFFFAF7F2);
  /// 毛边纸
  static const Color roughPaper = Color(0xFFF5F0E8);
  /// 道林纸
  static const Color daoLinPaper = Color(0xFFFFFDF9);
  /// 牛皮纸
  static const Color kraftPaper = Color(0xFFE8DFD0);
  
  /// 深色模式纸张
  static const Color darkPaper = Color(0xFF2A2A30);
  static const Color darkPaperSecondary = Color(0xFF333339);
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 扩展渐变效果
/// ═══════════════════════════════════════════════════════════════════════════

class AppGradients {
  /// 水墨渐变 - 浅色模式
  static const LinearGradient inkWashLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF7F2),
      Color(0xFFF5F0E8),
      Color(0xFFFAF7F2),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// 水墨渐变 - 深色模式
  static const LinearGradient inkWashDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1F),
      Color(0xFF1E1E24),
      Color(0xFF1A1A1F),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// 印章渐变
  static const LinearGradient sealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE07A5F),
      Color(0xFFC75B5B),
    ],
  );
  
  /// 金色渐变
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4A574),
      Color(0xFFC49A6C),
    ],
  );
  
  /// 玻璃效果渐变
  static LinearGradient glassGradient(bool isDark) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
    ],
  );
  
  /// 光晕效果
  static RadialGradient glowGradient(Color color, {double opacity = 0.3}) => RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      color.withValues(alpha: opacity),
      color.withValues(alpha: opacity * 0.5),
      Colors.transparent,
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 扩展阴影效果
/// ═══════════════════════════════════════════════════════════════════════════

class AppShadows {
  /// 水墨阴影 - 模拟墨迹扩散
  static List<BoxShadow> inkShadow(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : InkColors.darkInk.withValues(alpha: 0.08),
      blurRadius: 30,
      spreadRadius: -5,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.2)
          : InkColors.mediumInk.withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// 浮动阴影 - 用于悬浮元素
  static List<BoxShadow> floatingShadow(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.5)
          : AppTheme.primaryColor.withValues(alpha: 0.12),
      blurRadius: 40,
      spreadRadius: -10,
      offset: const Offset(0, 20),
    ),
  ];
  
  /// 发光阴影 - 用于强调元素
  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: color.withValues(alpha: opacity * 0.5),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];
  
  /// 内阴影效果 - 用于凹陷元素
  static List<BoxShadow> innerShadow(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.8),
      blurRadius: 0,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      blurRadius: 0,
      offset: const Offset(0, -1),
    ),
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 装饰性边框
/// ═══════════════════════════════════════════════════════════════════════════

class AppBorders {
  /// 水墨边框
  static Border inkBorder(bool isDark, {double width = 1}) => Border.all(
    color: isDark ? InkColors.darkModeLightInk : InkColors.lightInk,
    width: width,
  );
  
  /// 印章边框
  static Border sealBorder({double width = 2}) => Border.all(
    color: SealColors.vermilion,
    width: width,
  );
  
  /// 金色边框
  static Border goldBorder({double width = 1}) => Border.all(
    color: SealColors.goldSeal,
    width: width,
  );
  
  /// 渐变边框装饰
  static BoxDecoration gradientBorder({
    required Gradient gradient,
    required double radius,
    double borderWidth = 2,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: gradient,
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 动画时长预设
/// ═══════════════════════════════════════════════════════════════════════════

class AnimationDurations {
  /// 快速 - 用于微交互
  static const Duration fast = Duration(milliseconds: 150);
  /// 普通 - 用于常规动画
  static const Duration normal = Duration(milliseconds: 300);
  /// 慢速 - 用于强调动画
  static const Duration slow = Duration(milliseconds: 500);
  /// 弹性 - 用于特殊效果
  static const Duration elastic = Duration(milliseconds: 600);
  /// 页面转场
  static const Duration pageTransition = Duration(milliseconds: 400);
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 动画曲线预设
/// ═══════════════════════════════════════════════════════════════════════════

class AnimationCurves {
  /// 水墨扩散
  static const Curve inkSpread = Curves.easeOutCubic;
  /// 弹性回弹
  static const Curve bounce = Curves.elasticOut;
  /// 平滑过渡
  static const Curve smooth = Curves.easeInOutCubic;
  /// 强调出现
  static const Curve emphasize = Curves.easeOutBack;
}