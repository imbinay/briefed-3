import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ACCENT BUTTON — primary orange-red gradient CTA
// ─────────────────────────────────────────────────────────────────────────────

class AccentButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final double? fontSize;
  final EdgeInsets? padding;

  const AccentButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4500), Color(0xFFCC3700)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:       const Color(0xFFFF4500).withOpacity(0.35),
              blurRadius:  20,
              offset:      const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize:   fontSize ?? 15,
                fontWeight: FontWeight.w800,
                color:      Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OUTLINE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: context.border2Color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.subColor, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize:   14,
                fontWeight: FontWeight.w600,
                color:      context.subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRIEFED CARD
// ─────────────────────────────────────────────────────────────────────────────

class BriefedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color?  borderColor;
  final double  borderRadius;
  final VoidCallback? onTap;

  const BriefedCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:    padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        context.cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border:       Border.all(
            color: borderColor ?? context.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY TAG
// ─────────────────────────────────────────────────────────────────────────────

class CategoryTag extends StatelessWidget {
  final String category;
  final bool   small;
  final bool   showIcon;

  const CategoryTag({
    super.key,
    required this.category,
    this.small    = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category);
    final bg    = AppColors.categoryBg(category);
    final icon  = _iconFor(category);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8  : 12,
        vertical:   small ? 3  : 5,
      ),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: small ? 8 : 10, color: color),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            category,
            style: GoogleFonts.poppins(
              fontSize:   small ? 9 : 11,
              fontWeight: FontWeight.w700,
              color:      color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String cat) {
    switch (cat.toLowerCase()) {
      case 'world':         return Icons.language_rounded;
      case 'technology':
      case 'tech':          return Icons.memory_rounded;
      case 'business':      return Icons.trending_up_rounded;
      case 'science':       return Icons.science_rounded;
      case 'sports':        return Icons.sports_soccer_rounded;
      case 'entertainment': return Icons.star_rounded;
      default:              return Icons.language_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BriefedCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  32, height: 32,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize:   17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color:      context.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize:   8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color:      context.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMER RING
// ─────────────────────────────────────────────────────────────────────────────

class TimerRing extends StatelessWidget {
  final int timeLeft;
  final int totalTime;
  final bool answered;

  const TimerRing({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    if (answered) {
      ringColor = AppColors.green;
    } else if (timeLeft > totalTime * 0.5) {
      ringColor = AppColors.green;
    } else if (timeLeft > totalTime * 0.25) {
      ringColor = AppColors.gold;
    } else {
      ringColor = AppColors.red;
    }

    return SizedBox(
      width: 40, height: 40,
      child: Stack(
        children: [
          SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(
              value:            answered ? 1 : timeLeft / totalTime,
              strokeWidth:      2.5,
              backgroundColor:  context.inputBg,
              valueColor:       AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Center(
            child: answered
                ? const Icon(Icons.check_rounded, color: AppColors.green, size: 16)
                : Text(
                    '$timeLeft',
                    style: GoogleFonts.poppins(
                      fontSize:   12,
                      fontWeight: FontWeight.w800,
                      color:      context.textColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER LOADING
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width:  widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin:  Alignment.centerLeft,
              end:    Alignment.centerRight,
              stops:  [
                (_anim.value - 1).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 1).clamp(0.0, 1.0),
              ],
              colors: context.isDark
                  ? [
                      const Color(0xFF1C1C1C),
                      const Color(0xFF2C2C2C),
                      const Color(0xFF1C1C1C),
                    ]
                  : [
                      const Color(0xFFEEEEEA),
                      const Color(0xFFFFFFFF),
                      const Color(0xFFEEEEEA),
                    ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ OPTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class OptionButton extends StatelessWidget {
  final String  text;
  final int     index;
  final bool    isSelected;
  final bool    isCorrect;
  final bool    isRevealed;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, textColor;
    Widget indicator;

    if (isRevealed) {
      if (isCorrect) {
        bg        = AppColors.green.withOpacity(0.10);
        border    = AppColors.green.withOpacity(0.40);
        textColor = AppColors.green;
        indicator = Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color:        AppColors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColors.green.withOpacity(0.4)),
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.green, size: 18),
        );
      } else if (isSelected) {
        bg        = AppColors.red.withOpacity(0.10);
        border    = AppColors.red.withOpacity(0.40);
        textColor = AppColors.red;
        indicator = Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color:        AppColors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColors.red.withOpacity(0.4)),
          ),
          child: const Icon(Icons.cancel_rounded,
              color: AppColors.red, size: 18),
        );
      } else {
        bg        = context.cardColor;
        border    = context.borderColor;
        textColor = context.hintColor;
        indicator = _letterBox(context, dimmed: true);
      }
    } else {
      bg        = context.cardColor;
      border    = context.borderColor;
      textColor = context.subColor;
      indicator = _letterBox(context);
    }

    return GestureDetector(
      onTap: isRevealed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(18),
          border:       Border.all(color: border),
          boxShadow: isRevealed
              ? []
              : [
                  BoxShadow(
                    color:      Colors.black.withOpacity(
                        context.isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            indicator,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                  color:      textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterBox(BuildContext context, {bool dimmed = false}) {
    final labels = ['A', 'B', 'C', 'D'];
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color:        context.inputBg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: context.borderColor),
      ),
      child: Center(
        child: Text(
          labels[index],
          style: GoogleFonts.poppins(
            fontSize:   12,
            fontWeight: FontWeight.w800,
            color:      dimmed ? context.hintColor : context.hintColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEWS STORY ROW (small)
// ─────────────────────────────────────────────────────────────────────────────

class StoryRow extends StatelessWidget {
  final String title;
  final String sourceName;
  final String category;
  final String timeAgo;
  final bool   isLast;
  final VoidCallback? onTap;

  const StoryRow({
    super.key,
    required this.title,
    required this.sourceName,
    required this.category,
    required this.timeAgo,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColor(category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: context.borderColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source row
                  Row(
                    children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color:        AppColors.categoryBg(category),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text(
                            sourceName.substring(0, sourceName.length.clamp(0, 2)).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize:   7,
                              fontWeight: FontWeight.w900,
                              color:      catColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sourceName,
                        style: GoogleFonts.poppins(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      context.hintColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('·', style: TextStyle(color: context.hintColor, fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize:   11,
                          color:      context.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize:      15,
                      fontWeight:    FontWeight.w600,
                      color:         context.textColor,
                      letterSpacing: 0.1,
                      height:        1.55,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER AVATAR — photo from Google, initials from name, or fallback icon
// ─────────────────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 36,
  });

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsWidget(),
        ),
      );
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.poppins(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
