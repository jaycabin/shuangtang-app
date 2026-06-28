import 'dart:math';
import 'package:flutter/material.dart';

/// 糖晶飘落动画组件 — 用于纪念日全屏庆祝效果
class SugarParticles extends StatefulWidget {
  final Widget child;
  const SugarParticles({super.key, required this.child});

  @override
  State<SugarParticles> createState() => _SugarParticlesState();
}

class _SugarParticlesState extends State<SugarParticles>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  final _particles = <_Particle>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        speed: 0.02 + _rng.nextDouble() * 0.03,
        size: 12 + _rng.nextDouble() * 20,
        delay: _rng.nextDouble() * 3,
        emoji: ['🍬', '✨', '💖', '🌸', '🌟'][_rng.nextInt(5)],
      ));
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明背景
        Container(color: Colors.black.withOpacity(0.3)),
        // 粒子
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(_particles, _ctrl.value),
          ),
        ),
        // 内容
        Center(child: widget.child),
      ],
    );
  }
}

class _Particle {
  final double x, speed, size, delay;
  final String emoji;
  _Particle({required this.x, required this.speed, required this.size, required this.delay, required this.emoji});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final p in particles) {
      final y = ((progress * 6 - p.delay).clamp(0, 1) * size.height) % size.height;
      final x = p.x * size.width + sin(progress * 4 + p.x * 10) * 20;
      tp.text = TextSpan(text: p.emoji, style: TextStyle(fontSize: p.size));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
