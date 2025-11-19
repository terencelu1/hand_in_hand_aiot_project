/// 效能配置檔案
/// 用於控制應用程式的視覺效果和動畫，以平衡美觀與效能
class PerformanceConfig {
  // 預設配置實例（用於向後兼容）
  static const PerformanceConfig defaultConfig = PerformanceConfig._standard();
  
  // 預設值（用於快速存取）
  static const bool defaultEnableBackgroundAnimation = false; // 預設關閉背景動畫
  static const bool defaultEnableGlassOrbs = false; // 預設關閉浮動玻璃球
  static const bool defaultEnableCardAnimations = true; // 保留卡片動畫
  static const double defaultBlurIntensity = 4.0; // 降低模糊強度 (原本 8-10)
  static const double defaultShadowBlurRadius = 12.0; // 降低陰影模糊半徑 (原本 20-40)
  static const int defaultMaxGradientStops = 2; // 限制漸變停止點數量
  static const double defaultReducedOpacity = 0.8; // 降低透明度乘數
  
  /// 根據裝置效能調整配置
  static PerformanceConfig getOptimizedConfig({bool isLowEndDevice = false}) {
    if (isLowEndDevice) {
      return PerformanceConfig._lowEnd();
    }
    return PerformanceConfig._standard();
  }
  
  // 低端裝置配置
  const PerformanceConfig._lowEnd() : 
    enableBackgroundAnimation = false,
    enableGlassOrbs = false,
    enableCardAnimations = false,
    blurIntensity = 2.0,
    shadowBlurRadius = 8.0,
    maxGradientStops = 2,
    reducedOpacity = 0.6,
    slowAnimationDuration = const Duration(seconds: 45),
    mediumAnimationDuration = const Duration(seconds: 30),
    fastAnimationDuration = const Duration(seconds: 15);
    
  // 標準配置
  const PerformanceConfig._standard() : 
    enableBackgroundAnimation = false,
    enableGlassOrbs = false,
    enableCardAnimations = true,
    blurIntensity = 4.0,
    shadowBlurRadius = 12.0,
    maxGradientStops = 2,
    reducedOpacity = 0.8,
    slowAnimationDuration = const Duration(seconds: 30),
    mediumAnimationDuration = const Duration(seconds: 20),
    fastAnimationDuration = const Duration(seconds: 10);
    
  final bool enableBackgroundAnimation;
  final bool enableGlassOrbs;
  final bool enableCardAnimations;
  final double blurIntensity;
  final double shadowBlurRadius;
  final int maxGradientStops;
  final double reducedOpacity;
  final Duration slowAnimationDuration;
  final Duration mediumAnimationDuration;
  final Duration fastAnimationDuration;
}
