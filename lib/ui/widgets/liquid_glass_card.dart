import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? gradientStart;
  final Color? gradientEnd;
  final bool enableBlur;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.gradientStart,
    this.gradientEnd,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 根據主題選擇玻璃效果色彩
    final glassColor = isDark ? LiquidGlassColors.glassDark : LiquidGlassColors.glassWhite;
    final borderColor = isDark ? LiquidGlassColors.glassBorder : LiquidGlassColors.glassBorder.withOpacity(0.3);
    
    Widget cardContent = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientStart != null && gradientEnd != null
              ? [gradientStart!, gradientEnd!]
              : [
                  glassColor,
                  glassColor.withOpacity(0.8),
                  glassColor.withOpacity(0.6),
                ],
        ),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: LiquidGlassColors.glassShadow,
            blurRadius: 12, // 減少模糊半徑
            offset: const Offset(0, 4), // 減少偏移
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: enableBlur
            ? Stack(
                children: [
                  // 背景模糊效果
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // 進一步減少模糊強度
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 前景內容（不受模糊影響）
                  Container(
                    padding: padding ?? const EdgeInsets.all(20),
                    child: child,
                  ),
                ],
              )
            : Container(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class LiquidGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isLoading;
  final Color? gradientStart;
  final Color? gradientEnd;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
    this.isLoading = false,
    this.gradientStart,
    this.gradientEnd,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final glassColor = isDark ? LiquidGlassColors.glassDark : LiquidGlassColors.glassWhite;
    final borderColor = isDark ? LiquidGlassColors.glassBorder : LiquidGlassColors.glassBorder.withOpacity(0.3);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.gradientStart != null && widget.gradientEnd != null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [widget.gradientStart!, widget.gradientEnd!],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          glassColor,
                          glassColor.withOpacity(0.8),
                          glassColor.withOpacity(0.6),
                        ],
                      ),
                border: Border.all(
                  color: _isPressed 
                      ? (widget.gradientStart ?? LiquidGlassColors.primaryPurple).withOpacity(0.8)
                      : borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LiquidGlassColors.glassShadow,
                    blurRadius: _isPressed ? 6 : 12, // 減少模糊半徑
                    offset: Offset(0, _isPressed ? 2 : 4), // 減少偏移
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 背景模糊效果
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // 進一步減少模糊強度
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(_isPressed ? 0.15 : 0.08),
                              Colors.white.withOpacity(_isPressed ? 0.08 : 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 前景內容（不受模糊影響）
                  Container(
                    padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    alignment: Alignment.center,
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : widget.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

