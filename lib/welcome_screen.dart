import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';

// --- GRADIENT TEXT HELPERS ---
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}

// --- ANIMATED FLOATING EMOJI ---
class FloatingEmoji extends StatefulWidget {
  final String emoji;
  final double left;
  final double top;
  final int delayMs;
  final int durationMs;

  const FloatingEmoji({
    super.key,
    required this.emoji,
    required this.left,
    required this.top,
    required this.delayMs,
    required this.durationMs,
  });

  @override
  State<FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<FloatingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left * MediaQuery.of(context).size.width,
      top: widget.top * 400,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -15 * _animation.value),
            child: Opacity(
              opacity: 0.7 + (0.3 * _animation.value),
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- TILTED CARD WITH HOVER ACTION ---
class HoverTiltedCard extends StatefulWidget {
  final Widget child;
  final double defaultTilt;

  const HoverTiltedCard({
    super.key,
    required this.child,
    this.defaultTilt = -0.05,
  });

  @override
  State<HoverTiltedCard> createState() => _HoverTiltedCardState();
}

class _HoverTiltedCardState extends State<HoverTiltedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedRotation(
        turns: _isHovered ? 0 : widget.defaultTilt / (2 * math.pi),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: widget.child,
        ),
      ),
    );
  }
}

// --- FEATURES GRID CARD ---
class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final double tilt;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.tilt,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return HoverTiltedCard(
      defaultTilt: widget.tilt,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? const Color(0xFFC084FC) : const Color(0xFFE9D5FF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(_isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 24 : 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN WELCOME/LANDING SCREEN ---
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();

  void _scrollToFeatures() {
    final context = _featuresKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. SCROLLABLE LANDING PAGE CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Spacer for fixed navbar
                const SizedBox(height: 80),

                // --- HERO SECTION ---
                _buildHeroSection(isDesktop),

                // --- FEATURES SECTION ---
                _buildFeaturesSection(isDesktop),

                // --- REAL-TIME REACTION SHOWCASE ---
                _buildRealtimeSection(isDesktop),

                // --- COMMUNITY SECTION ---
                _buildCommunitySection(isDesktop),

                // --- FINAL CTA BLOCK ---
                _buildCtaSection(isDesktop),

                // --- FOOTER ---
                _buildFooter(isDesktop),
              ],
            ),
          ),

          // 2. FIXED STYLISH BLURRED NAVBAR
          _buildNavbar(isDesktop),
        ],
      ),
    );
  }

  // NAVBAR
  Widget _buildNavbar(bool isDesktop) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF3E8FF), width: 2),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo & Branding
                GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/memeboard-logo_8b8c24a4.png',
                        height: 48,
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText(
                            'MEME',
                            gradient: LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          GradientText(
                            'BOARD',
                            gradient: LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    if (isDesktop)
                      TextButton(
                        onPressed: _scrollToFeatures,
                        child: const Text(
                          'Features',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _navigateToLogin,
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HERO SECTION
  Widget _buildHeroSection(bool isDesktop) {
    final headingStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: isDesktop ? 64 : 42,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF111827),
      height: 1.1,
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/memeboard-hero-bg_ce26d61f.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 48,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Floating animated background emojis
          const FloatingEmoji(emoji: '😂', left: 0.05, top: 0.1, delayMs: 0, durationMs: 4000),
          const FloatingEmoji(emoji: '🔥', left: 0.8, top: 0.2, delayMs: 400, durationMs: 4500),
          const FloatingEmoji(emoji: '💯', left: 0.2, top: 0.8, delayMs: 200, durationMs: 3800),
          const FloatingEmoji(emoji: '⚡', left: 0.9, top: 0.7, delayMs: 600, durationMs: 4200),

          // Layout grid
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Text Block
              Expanded(
                flex: isDesktop ? 6 : 0,
                child: Column(
                  crossAxisAlignment: isDesktop
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const GradientText(
                      'Make the',
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const GradientText(
                      'Group Chat',
                      gradient: LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Explode 💥',
                      style: headingStyle,
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Real-time meme sharing that actually keeps up with your chaos. Built with Flutter & Firebase. No delays. Just pure, unfiltered fun.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                      ),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 20,
                            ),
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _navigateToLogin,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Jump In & Create',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 20,
                            ),
                            side: const BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 2,
                            ),
                            foregroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _scrollToFeatures,
                          child: const Text(
                            'See It in Action',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Inline stats
                    Wrap(
                      spacing: 32,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildHeroStat('⚡', 'Real-Time Sync', 'Instant'),
                        _buildHeroStat('📱', 'Cross-Platform', 'Flutter'),
                        _buildHeroStat('🌍', 'Community', 'Global'),
                      ],
                    )
                  ],
                ),
              ),

              if (!isDesktop) const SizedBox(height: 64),

              // Hero Tilted Device Mockup
              Expanded(
                flex: isDesktop ? 5 : 0,
                child: Center(
                  child: HoverTiltedCard(
                    defaultTilt: -0.07,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/memeboard-flutter-firebase_95ee1b1d.png',
                          width: isDesktop ? 420 : 320,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String emoji, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        )
      ],
    );
  }

  // FEATURES SECTION
  Widget _buildFeaturesSection(bool isDesktop) {
    return Container(
      key: _featuresKey,
      width: double.infinity,
      color: const Color(0xFFF9F5FF), // Light purple bg
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Why You'll Obsess Over It",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Built for people who actually get meme culture. No corporate BS. Just speed, fun, and community.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 56),

          // Features Cards wrap
          Center(
            child: Wrap(
              spacing: 32,
              runSpacing: 32,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureCard(
                  Icons.bolt,
                  "Lightning Fast",
                  "Real-time uploads powered by Firebase. Watch reactions happen live.",
                  const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
                  -0.03,
                ),
                _buildFeatureCard(
                  Icons.smartphone,
                  "Works Everywhere",
                  "iOS, Android, Web. Built with Flutter. One codebase. Maximum chaos.",
                  const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                  0.02,
                ),
                _buildFeatureCard(
                  Icons.share,
                  "Instant Sharing",
                  "Drop a meme. Watch it spread. See reactions flood in real-time.",
                  const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEF4444)]),
                  -0.03,
                ),
                _buildFeatureCard(
                  Icons.cloud,
                  "Cloud Powered",
                  "Firebase Storage keeps your memes safe. Firestore syncs everything instantly.",
                  const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  0.03,
                ),
                _buildFeatureCard(
                  Icons.people,
                  "Community First",
                  "Connect with millions. Build your audience. Spread the laughs globally.",
                  const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
                  -0.02,
                ),
                _buildFeatureCard(
                  Icons.auto_awesome,
                  "Always Fresh",
                  "New features, filters, and ways to express yourself. Never boring.",
                  const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                  0.02,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Gradient gradient,
    double tilt,
  ) {
    return FeatureCard(
      icon: icon,
      title: title,
      description: description,
      gradient: gradient,
      tilt: tilt,
    );
  }

  // REALTIME FIRESTORE SECTION
  Widget _buildRealtimeSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 80,
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text & Details
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: Column(
              crossAxisAlignment: isDesktop
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Watch It Happen ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const GradientText(
                      'Live',
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Your memes don't just get shared—they explode. Reactions, comments, and shares flood in real-time. Firestore keeps everything perfectly synced across devices.",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                    height: 1.6,
                  ),
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Points List
                _buildPointRow('⚡', 'Instant upload and sync across devices'),
                _buildPointRow('❤️', 'Live reaction counters (hearts, fire, laughs)'),
                _buildPointRow('🔔', 'Real-time notifications for every share'),
                _buildPointRow('📱', 'Seamless multi-device experience'),

                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _navigateToLogin,
                  child: const Text(
                    'See It in Action',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isDesktop) const SizedBox(height: 56),

          // Tilted Image
          Expanded(
            flex: isDesktop ? 5 : 0,
            child: Center(
              child: HoverTiltedCard(
                defaultTilt: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.15),
                        blurRadius: 36,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/memeboard-realtime-feature_2e30868b.png',
                      width: isDesktop ? 400 : 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPointRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          )
        ],
      ),
    );
  }

  // COMMUNITY SECTION
  Widget _buildCommunitySection(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9FAFB),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 80,
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        children: [
          // Mockup Image (Left on Desktop)
          Expanded(
            flex: isDesktop ? 5 : 0,
            child: Center(
              child: HoverTiltedCard(
                defaultTilt: -0.05,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        blurRadius: 36,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/memeboard-community_2df69f22.png',
                      width: isDesktop ? 400 : 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (!isDesktop) const SizedBox(height: 56),

          // Details & Stats Grid (Right on Desktop)
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: Padding(
              padding: EdgeInsets.only(left: isDesktop ? 48 : 0),
              child: Column(
                crossAxisAlignment: isDesktop
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: isDesktop
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Join the ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const GradientText(
                        'Chaos',
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Millions of meme creators and enthusiasts sharing laughs in real-time. Your audience is waiting. Your next viral moment is one upload away.",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Stats grid (2x2)
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatBox('10M+', 'Meme Creators'),
                      _buildStatBox('500M+', 'Memes Shared'),
                      _buildStatBox('24/7', 'Live Feed'),
                      _buildStatBox('∞', 'Fun Guaranteed'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _navigateToLogin,
                    child: const Text(
                      'Start Your Reign',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            count,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            ),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // CTA DOWNLOAD SECTION
  Widget _buildCtaSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF581C87), Color(0xFF0F172A)], // Purple to Dark slate
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Column(
        
        children: [
          const Text(
            'Ready to Make Memes Legendary?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Download MemeBoard now. Share instantly. Watch it spread. Join millions of creators making the internet laugh.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE9D5FF),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Download buttons
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  backgroundColor: const Color(0xFFC084FC), // Light purple
                  foregroundColor: const Color(0xFF581C87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Download for iOS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  backgroundColor: const Color(0xFF22D3EE), // Cyan
                  foregroundColor: const Color(0xFF083344),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Download for Android',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Also on web. Free forever. No credit card. No BS.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC084FC),
            ),
          )
        ],
      ),
    );
  }

  // FOOTER
  Widget _buildFooter(bool isDesktop) {
    return Container(
      color: const Color(0xFF030712), // Black-gray footer
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 64,
      ),
      child: Column(
        children: [
          // Links Grid
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Slogan
              Column(
                crossAxisAlignment: isDesktop
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: isDesktop
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/memeboard-logo_8b8c24a4.png',
                        height: 36,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MEMEBOARD',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share memes. Share laughs. Share joy.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),

              if (!isDesktop) const SizedBox(height: 40),

              // Links List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFooterCol('Product', ['Features', 'Download', 'Pricing']),
                  const SizedBox(width: 48),
                  _buildFooterCol('Company', ['About', 'Blog', 'Contact']),
                  const SizedBox(width: 48),
                  _buildFooterCol('Legal', ['Privacy', 'Terms', 'Security']),
                ],
              )
            ],
          ),

          const SizedBox(height: 48),
          const Divider(color: Color(0xFF1F2937)),
          const SizedBox(height: 24),

          // Copyright
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '© 2026 MemeBoard. Built with ❤️ and 🔥 for the internet.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (!isDesktop) const SizedBox(height: 16),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('𝕏', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                  SizedBox(width: 24),
                  Text('📸', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                  SizedBox(width: 24),
                  Text('💬', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFooterCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC084FC),
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                link,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ))
      ],
    );
  }
}
