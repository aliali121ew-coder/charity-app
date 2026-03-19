// ─────────────────────────────────────────────────────────────────────────────
// StackedCardSelector
//
// Animated deck of payment-method cards.
// - Cards are stacked with perspective offsets behind the active card.
// - Tap the active card → cycle to next with a smooth flip + slide animation.
// - Tap a dot indicator or swipe → jump directly to a card.
// - Active card has an elevated, full-opacity glow; back cards are dimmed.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/payment_models.dart';

class StackedCardSelector extends StatefulWidget {
  const StackedCardSelector({
    super.key,
    required this.cards,
    required this.selectedIndex,
    required this.onCardSelected,
    this.cardNumberText,
  });

  final List<PaymentMethodCard> cards;
  final int selectedIndex;
  final ValueChanged<int> onCardSelected;
  final String? cardNumberText;

  @override
  State<StackedCardSelector> createState() => _StackedCardSelectorState();
}

class _StackedCardSelectorState extends State<StackedCardSelector>
    with TickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _flipAnim;
  late Animation<Offset> _slideAnim;

  int _currentIndex = 0;
  bool _isAnimating = false;

  static const _cardAspect = 1.586; // standard credit card ratio
  static const _stackDepth = 3;     // how many back-cards are visible

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInBack));
  }

  @override
  void didUpdateWidget(StackedCardSelector old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && !_isAnimating) {
      _animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Animation helpers ──────────────────────────────────────────────────────

  Future<void> _animateTo(int newIndex) async {
    if (_isAnimating || newIndex == _currentIndex) return;
    setState(() => _isAnimating = true);

    await _slideCtrl.forward();
    setState(() => _currentIndex = newIndex);
    _slideCtrl.reset();
    await _flipCtrl.forward(from: 0);
    _flipCtrl.reset();

    setState(() => _isAnimating = false);
    widget.onCardSelected(newIndex);
  }

  void _onTapActive() {
    if (_isAnimating) return;
    final next = (_currentIndex + 1) % widget.cards.length;
    _animateTo(next);
  }

  void _onTapDot(int index) {
    if (_isAnimating || index == _currentIndex) return;
    _animateTo(index);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final cardWidth = constraints.maxWidth.clamp(0.0, 400.0);
          final cardHeight = cardWidth / _cardAspect;
          return SizedBox(
            height: cardHeight + 24, // extra room for stack offset
            child: _buildStack(cardWidth, cardHeight),
          );
        }),
        const SizedBox(height: 16),
        _buildDots(),
      ],
    );
  }

  Widget _buildStack(double w, double h) {
    final visibleCount = math.min(_stackDepth, widget.cards.length);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Back cards (furthest first)
        for (int i = visibleCount - 1; i >= 1; i--)
          _buildBackCard(i, w, h, visibleCount),

        // Active card (front)
        _buildActiveCard(w, h),
      ],
    );
  }

  Widget _buildBackCard(int depth, double w, double h, int total) {
    final backIndex = (_currentIndex + depth) % widget.cards.length;
    final card = widget.cards[backIndex];

    final offsetY = -(depth * 8.0); // stack upward
    final scale = 1.0 - depth * 0.04;
    final opacity = 1.0 - depth * 0.25;

    return Positioned(
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, offsetY)
          ..scale(scale),
        transformAlignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: opacity,
          child: _CardFace(card: card, width: w, height: h, isActive: false),
        ),
      ),
    );
  }

  Widget _buildActiveCard(double w, double h) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flipAnim, _slideAnim]),
      builder: (context, child) {
        // During slide-out phase the card flies to the left
        final slideVal = _slideCtrl.isAnimating ? _slideAnim.value : Offset.zero;

        // During flip phase apply a Y-axis rotation
        final flipVal = _flipAnim.value;
        final angle = flipVal * math.pi * 0.15; // subtle tilt

        return Transform.translate(
          offset: Offset(slideVal.dx * w, 0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapActive,
        child: _CardFace(
          card: widget.cards[_currentIndex],
          width: w,
          height: h,
          isActive: true,
          cardNumberText: widget.cardNumberText,
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.cards.length, (i) {
        final isSelected = i == _currentIndex;
        return GestureDetector(
          onTap: () => _onTapDot(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isSelected ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isSelected
                  ? widget.cards[i].accentColor
                  : widget.cards[i].accentColor.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }
}

// ── Card Face ─────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.width,
    required this.height,
    required this.isActive,
    this.cardNumberText,
  });

  final PaymentMethodCard card;
  final double width;
  final double height;
  final bool isActive;
  final String? cardNumberText;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: card.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: card.accentColor.withOpacity(0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background circles decoration
            Positioned(
              right: -30,
              top: -30,
              child: _Circle(size: 120, color: card.accentColor.withOpacity(0.08)),
            ),
            Positioned(
              right: 20,
              bottom: -40,
              child: _Circle(size: 100, color: card.accentColor.withOpacity(0.06)),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: icon + recommended badge
                  Row(
                    children: [
                      _MethodIcon(card: card, size: 36),
                      const Spacer(),
                      if (card.isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: card.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: card.accentColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            'مُوصى به',
                            style: TextStyle(
                              color: card.accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Card number — Visa / MasterCard only
                  if (card.type == PaymentMethodType.visa ||
                      card.type == PaymentMethodType.mastercard) ...[
                    Text(
                      (cardNumberText?.isNotEmpty ?? false)
                          ? cardNumberText!
                          : '•••• •••• •••• ••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Method name
                  Text(
                    card.nameAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    card.descriptionAr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Bottom row: active indicator + fees
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: card.isActive
                              ? const Color(0xFF4ADE80)
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        card.isActive ? 'مفعّل' : 'غير متاح',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (card.feesNote != null)
                        Text(
                          card.feesNote!,
                          style: TextStyle(
                            color: card.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Active glow border
            if (isActive)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: card.accentColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

            // Tap hint on active card
            if (isActive)
              Positioned(
                right: 16,
                bottom: 16,
                child: Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white.withOpacity(0.25),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({required this.card, required this.size});

  final PaymentMethodCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: card.accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: card.accentColor.withOpacity(0.3)),
      ),
      child: Icon(card.icon, color: card.accentColor, size: size * 0.55),
    );
  }
}
