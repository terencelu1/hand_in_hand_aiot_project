import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../theme.dart';

class LiquidGlassBackground extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;

  const LiquidGlassBackground({
    super.key,
    required this.child,
    this.enableAnimation = false, // 預設關閉動畫以提升效能
  });

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late Animation<double> _primaryAnimation;
  late Animation<double> _secondaryAnimation;

  @override
  void initState() {
    super.initState();
    
    _primaryController = AnimationController(
      duration: const Duration(seconds: 30), // 放慢動畫速度
      vsync: this,
    );
    
    _secondaryController = AnimationController(
      duration: const Duration(seconds: 25), // 放慢動畫速度
      vsync: this,
    );

    _primaryAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_primaryController);

    _secondaryAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_secondaryController);

    if (widget.enableAnimation) {
      _primaryController.repeat();
      _secondaryController.repeat();
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Stack(
      children: [
        // 背景漸變
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E293B),
                      const Color(0xFF334155),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFE2E8F0),
                      const Color(0xFFCBD5E1),
                    ],
            ),
          ),
        ),
        
        // 動態液體效果
        if (widget.enableAnimation)
          AnimatedBuilder(
            animation: Listenable.merge([_primaryAnimation, _secondaryAnimation]),
            builder: (context, child) {
              return CustomPaint(
                painter: LiquidGlassPainter(
                  primaryProgress: _primaryAnimation.value,
                  secondaryProgress: _secondaryAnimation.value,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),
        
        // 內容
        widget.child,
      ],
    );
  }
}

class LiquidGlassPainter extends CustomPainter {
  final double primaryProgress;
  final double secondaryProgress;
  final bool isDark;

  LiquidGlassPainter({
    required this.primaryProgress,
    required this.secondaryProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // 減少模糊強度

    // 主要的液體形狀
    final primaryPath = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 創建流動的橢圓形狀 - 簡化計算
    final primaryRadiusX = 180 + 30 * math.sin(primaryProgress);
    final primaryRadiusY = 120 + 20 * math.cos(primaryProgress);
    final primaryOffsetX = centerX + 60 * math.cos(primaryProgress * 0.3);
    final primaryOffsetY = centerY + 50 * math.sin(primaryProgress * 0.5);

    primaryPath.addOval(Rect.fromCenter(
      center: Offset(primaryOffsetX, primaryOffsetY),
      width: primaryRadiusX,
      height: primaryRadiusY,
    ));

    // 次要的液體形狀 - 簡化計算
    final secondaryPath = Path();
    final secondaryRadiusX = 120 + 25 * math.sin(secondaryProgress);
    final secondaryRadiusY = 90 + 15 * math.cos(secondaryProgress);
    final secondaryOffsetX = centerX + 80 * math.cos(secondaryProgress * 0.4);
    final secondaryOffsetY = centerY + 60 * math.sin(secondaryProgress * 0.6);

    secondaryPath.addOval(Rect.fromCenter(
      center: Offset(secondaryOffsetX, secondaryOffsetY),
      width: secondaryRadiusX,
      height: secondaryRadiusY,
    ));

    // 繪製主要液體 - 簡化漸變
    paint.shader = RadialGradient(
      colors: isDark
          ? [
              LiquidGlassColors.accentCyan.withOpacity(0.2),
              Colors.transparent,
            ]
          : [
              LiquidGlassColors.accentCyan.withOpacity(0.1),
              Colors.transparent,
            ],
      stops: const [0.0, 1.0], // 簡化停止點
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(primaryPath, paint);

    // 繪製次要液體 - 簡化漸變
    paint.shader = RadialGradient(
      colors: isDark
          ? [
              LiquidGlassColors.accentPink.withOpacity(0.15),
              Colors.transparent,
            ]
          : [
              LiquidGlassColors.accentPink.withOpacity(0.08),
              Colors.transparent,
            ],
      stops: const [0.0, 1.0], // 簡化停止點
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(secondaryPath, paint);
  }

  @override
  bool shouldRepaint(LiquidGlassPainter oldDelegate) {
    return oldDelegate.primaryProgress != primaryProgress ||
           oldDelegate.secondaryProgress != secondaryProgress ||
           oldDelegate.isDark != isDark;
  }
}

class FloatingGlassOrbs extends StatefulWidget {
  final int orbCount;
  final bool enableAnimation;

  const FloatingGlassOrbs({
    super.key,
    this.orbCount = 3,
    this.enableAnimation = true,
  });

  @override
  State<FloatingGlassOrbs> createState() => _FloatingGlassOrbsState();
}

class _FloatingGlassOrbsState extends State<FloatingGlassOrbs>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(
      widget.orbCount,
      (index) => AnimationController(
        duration: Duration(seconds: 15 + index * 5), // 放慢動畫速度
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) =>
        Tween<double>(begin: 0, end: 2 * math.pi).animate(controller)).toList();

    if (widget.enableAnimation) {
      for (var controller in _controllers) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Stack(
      children: List.generate(widget.orbCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final progress = _animations[index].value;
            final size = 60.0 + 20 * math.sin(progress + index);
            final x = 50.0 + 100 * math.cos(progress * 0.5 + index);
            final y = 100.0 + 80 * math.sin(progress * 0.8 + index);
            
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? LiquidGlassColors.glassWhite : LiquidGlassColors.glassDark)
                          .withOpacity(0.05), // 降低透明度
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0], // 明確指定停止點
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LiquidGlassColors.glassShadow,
                      blurRadius: 12, // 減少模糊半徑
                      spreadRadius: 2, // 減少擴散
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
