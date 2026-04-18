// widgets/animated_typing_text.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AnimatedTypingText extends StatefulWidget {
  final String message;
  final ThemeData theme;
  final TypingTextStyle style;
  final VoidCallback? onTypingComplete;
  final bool showCursor;
  final Duration typingSpeed;
  final Duration cursorBlinkSpeed;
  final Curve typingCurve;

  const AnimatedTypingText({
    Key? key,
    required this.message,
    required this.theme,
    this.style = const TypingTextStyle(),
    this.onTypingComplete,
    this.showCursor = true,
    this.typingSpeed = const Duration(milliseconds: 25),
    this.cursorBlinkSpeed = const Duration(milliseconds: 500),
    this.typingCurve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  _AnimatedTypingTextState createState() => _AnimatedTypingTextState();
}

class _AnimatedTypingTextState extends State<AnimatedTypingText>
    with SingleTickerProviderStateMixin {
  String _visibleText = '';
  int _index = 0;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  late AnimationController _cursorController;
  late AnimationController _glowController;
  bool _isTypingComplete = false;
  final Random _random = Random();

  // Enhanced typing patterns for more natural feel
  static const List<Duration> _typingVariations = [
    Duration(milliseconds: 15),
    Duration(milliseconds: 25),
    Duration(milliseconds: 35),
    Duration(milliseconds: 45),
  ];

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: widget.cursorBlinkSpeed,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    _glowController.forward();

    // Smart typing with variable speed for natural feel
    _typingTimer = Timer.periodic(_getNextTypingDelay(), (timer) {
      if (_index < widget.message.length) {
        setState(() {
          _visibleText += widget.message[_index];
          _index++;

          // Add subtle glow effect on certain characters
          if (_index % 10 == 0) {
            _glowController.forward(from: 0.0);
          }
        });
      } else {
        _completeTyping();
      }
    });
  }

  Duration _getNextTypingDelay() {
    // Add natural variation to typing speed
    if (_index > 0 && _index < widget.message.length - 1) {
      final baseDelay = widget.typingSpeed.inMilliseconds;
      final variation = _random.nextInt(20) - 10; // -10 to +10 ms variation
      return Duration(milliseconds: max(5, baseDelay + variation));
    }
    return widget.typingSpeed;
  }

  void _completeTyping() {
    _typingTimer?.cancel();
    _isTypingComplete = true;

    // Final glow effect
    _glowController.forward(from: 0.0);

    // Notify completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTypingComplete?.call();
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _cursorController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.theme.brightness == Brightness.dark;

    return Container(
      padding: widget.style.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: widget.style.containerDecoration ??
          BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDarkMode
                ? Colors.grey[900]!.withOpacity(0.5)
                : Colors.grey[50]!.withOpacity(0.8),
            boxShadow: [
              if (widget.style.enableShadows)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated text with glow effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final glowValue = _glowController.value;
              return Stack(
                children: [
                  // Main text
                  _buildMarkdownText(),

                  // Glow overlay
                  if (glowValue > 0)
                    Opacity(
                      opacity: glowValue * 0.3,
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              widget.style.glowColor ??
                                  (isDarkMode ? Colors.blueAccent : Colors.blue),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.8],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: _buildMarkdownText(),
                      ),
                    ),
                ],
              );
            },
          ),

          // Animated cursor
          if (widget.showCursor && !_isTypingComplete)
            _buildAnimatedCursor(),
        ],
      ),
    );
  }

  Widget _buildMarkdownText() {
    final isDarkMode = widget.theme.brightness == Brightness.dark;
    final baseTextStyle = widget.style.textStyle ??
        widget.theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          letterSpacing: 0.2,
        );

    return MarkdownBody(
      data: _visibleText,
      styleSheet: MarkdownStyleSheet(
        p: baseTextStyle?.copyWith(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: widget.style.fontSize,
          fontWeight: widget.style.fontWeight,
        ),
        strong: baseTextStyle?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: (widget.style.fontSize ?? 14) * 1.1,
        ),
        em: baseTextStyle?.copyWith(
          fontStyle: FontStyle.italic,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        code: baseTextStyle?.copyWith(
          fontFamily: 'FiraCode',
          backgroundColor: isDarkMode ? Colors.blueGrey[800] : Colors.blueGrey[100],
          color: isDarkMode ? Colors.cyanAccent : Colors.blue[800],
          fontSize: (widget.style.fontSize ?? 14) * 0.9,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? Colors.blueGrey[900] : Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.blueGrey[700]! : Colors.blueGrey[200]!,
            width: 1,
          ),
        ),
        blockquote: baseTextStyle?.copyWith(
          fontStyle: FontStyle.italic,
          color: isDarkMode ? Colors.greenAccent : Colors.green[800],
        ),
        blockquoteDecoration: BoxDecoration(
          color: isDarkMode ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50]!,
          border: Border(
            left: BorderSide(
              color: isDarkMode ? Colors.greenAccent : Colors.green!,
              width: 4,
            ),
          ),
        ),
        h1: baseTextStyle?.copyWith(
          fontSize: (widget.style.fontSize ?? 14) * 1.8,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        h2: baseTextStyle?.copyWith(
          fontSize: (widget.style.fontSize ?? 14) * 1.5,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        h3: baseTextStyle?.copyWith(
          fontSize: (widget.style.fontSize ?? 14) * 1.3,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        listBullet: baseTextStyle?.copyWith(
          color: isDarkMode ? Colors.orangeAccent : Colors.orange[800],
        ),
      ),
    );
  }

  Widget _buildAnimatedCursor() {
    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, child) {
        return Opacity(
          opacity: _cursorController.value,
          child: Container(
            width: 2,
            height: widget.style.cursorHeight ?? 20,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: widget.style.cursorColor ??
                  (widget.theme.brightness == Brightness.dark
                      ? Colors.blueAccent
                      : Colors.blue),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: (widget.style.cursorColor ?? Colors.blue).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Professional styling configuration for the typing text
class TypingTextStyle {
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final Decoration? containerDecoration;
  final Color? cursorColor;
  final double cursorHeight;
  final Color? glowColor;
  final bool enableShadows;

  const TypingTextStyle({
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.containerDecoration,
    this.cursorColor,
    this.cursorHeight = 20,
    this.glowColor,
    this.enableShadows = true,
  });

  TypingTextStyle copyWith({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsetsGeometry? padding,
    Decoration? containerDecoration,
    Color? cursorColor,
    double? cursorHeight,
    Color? glowColor,
    bool? enableShadows,
  }) {
    return TypingTextStyle(
      textStyle: textStyle ?? this.textStyle,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      padding: padding ?? this.padding,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      glowColor: glowColor ?? this.glowColor,
      enableShadows: enableShadows ?? this.enableShadows,
    );
  }
}

/// Premium version with advanced features
class PremiumTypingText extends StatelessWidget {
  final String message;
  final ThemeData theme;
  final TypingTextVariant variant;

  const PremiumTypingText({
    Key? key,
    required this.message,
    required this.theme,
    this.variant = TypingTextVariant.professional,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = _getStyleForVariant(variant, theme);

    return AnimatedTypingText(
      message: message,
      theme: theme,
      style: style,
      typingSpeed: const Duration(milliseconds: 20),
      onTypingComplete: () {
        // Haptic feedback or other premium features
      },
    );
  }

  TypingTextStyle _getStyleForVariant(TypingTextVariant variant, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    switch (variant) {
      case TypingTextVariant.professional:
        return TypingTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          containerDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.grey[900]! : Colors.white,
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          cursorColor: isDark ? Colors.blueAccent : Colors.blue[700],
        );

      case TypingTextVariant.modern:
        return TypingTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          containerDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.grey[50]!, Colors.grey[100]!],
            ),
          ),
          glowColor: isDark ? Colors.purpleAccent : Colors.purple,
        );

      case TypingTextVariant.creative:
        return TypingTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          padding: const EdgeInsets.all(16),
          containerDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? Colors.blueGrey[900]! : Colors.blue[50]!,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          cursorColor: isDark ? Colors.cyanAccent : Colors.cyan[700]!,
        );
    }
  }
}

enum TypingTextVariant {
  professional,
  modern,
  creative,
}

/// Usage example:
/*
PremiumTypingText(
  message: "# Hello World\nThis is **professional** typing text with _markdown_ support.\n\n```dart\nvoid main() {\n  print('Hello World!');\n}\n```",
  theme: Theme.of(context),
  variant: TypingTextVariant.professional,
)
*/