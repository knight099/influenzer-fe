import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A premium mini line-chart card that displays 7-day or 30-day trend data.
/// Draws a smooth gradient-filled area chart using CustomPainter.
class TrendChartCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<num> data7d;
  final List<num> data30d;

  const TrendChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.data7d,
    required this.data30d,
  });

  @override
  State<TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<TrendChartCard>
    with SingleTickerProviderStateMixin {
  bool _show30d = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleRange() {
    _animController.reverse().then((_) {
      setState(() => _show30d = !_show30d);
      _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _show30d ? widget.data30d : widget.data7d;
    final lastVal = data.isNotEmpty ? data.last : 0;
    final firstVal = data.isNotEmpty ? data.first : 0;
    final changePercent = firstVal > 0
        ? ((lastVal - firstVal) / firstVal * 100)
        : 0.0;
    final isPositive = changePercent >= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(widget.icon, size: 15, color: widget.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Toggle
                GestureDetector(
                  onTap: _toggleRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _show30d
                          ? widget.color.withOpacity(0.12)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _show30d
                            ? widget.color.withOpacity(0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _show30d ? '30d' : '7d',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _show30d ? widget.color : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Value + change
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(lastVal.toInt()),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: widget.color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SizedBox(
                height: 80,
                child: CustomPaint(
                  size: const Size(double.infinity, 80),
                  painter: _TrendLinePainter(
                    data: data.map((e) => e.toDouble()).toList(),
                    lineColor: widget.color,
                    fillColor: widget.color.withOpacity(0.10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  _TrendLinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final n = data.length;
    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal;
    if (range == 0) return;

    final w = size.width;
    final h = size.height;
    final paddingTop = 4.0;
    final paddingBottom = 4.0;
    final usableH = h - paddingTop - paddingBottom;

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * w;
      final y = paddingTop + usableH - ((data[i] - minVal) / range) * usableH;
      points.add(Offset(x, y));
    }

    // Build smooth path using cubic bezier
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Draw fill
    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillColor, fillColor.withOpacity(0.01)],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.fill,
    );

    // Draw line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw dot at the last point
    final lastP = points.last;
    canvas.drawCircle(lastP, 4, Paint()..color = lineColor);
    canvas.drawCircle(lastP, 2, Paint()..color = Colors.white);

    // Draw horizontal grid lines (3 lines)
    final gridPaint = Paint()
      ..color = lineColor.withOpacity(0.08)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final gy = paddingTop + (usableH / 4) * i;
      canvas.drawLine(Offset(0, gy), Offset(w, gy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}

/// A container that holds multiple TrendChartCards in a 2-column grid.
class TrendChartsSection extends StatelessWidget {
  final Map<String, dynamic>? trendData;
  final bool isInstagram;
  final Color primaryColor;

  const TrendChartsSection({
    super.key,
    required this.trendData,
    required this.isInstagram,
    required this.primaryColor,
  });

  List<num> _toNumList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e is num) ? e : (num.tryParse(e.toString()) ?? 0)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (trendData == null || trendData!.isEmpty) return const SizedBox.shrink();

    final charts = <Widget>[];

    if (isInstagram) {
      final pv7d = _toNumList(trendData!['profile_views_7d']);
      final pv30d = _toNumList(trendData!['profile_views_30d']);
      final likes7d = _toNumList(trendData!['likes_7d']);
      final likes30d = _toNumList(trendData!['likes_30d']);
      final reach7d = _toNumList(trendData!['reach_7d']);
      final reach30d = _toNumList(trendData!['reach_30d']);

      if (pv7d.isNotEmpty) {
        charts.add(TrendChartCard(
          title: 'Profile Views',
          icon: Icons.person_search_rounded,
          color: const Color(0xFF0EA5E9),
          data7d: pv7d,
          data30d: pv30d.isNotEmpty ? pv30d : pv7d,
        ));
      }
      if (likes7d.isNotEmpty) {
        charts.add(TrendChartCard(
          title: 'Likes Trend',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE91E63),
          data7d: likes7d,
          data30d: likes30d.isNotEmpty ? likes30d : likes7d,
        ));
      }
      if (reach7d.isNotEmpty) {
        charts.add(TrendChartCard(
          title: 'Reach',
          icon: Icons.radar_rounded,
          color: AppColors.success,
          data7d: reach7d,
          data30d: reach30d.isNotEmpty ? reach30d : reach7d,
        ));
      }
    } else {
      // YouTube
      final views7d = _toNumList(trendData!['views_7d']);
      final views30d = _toNumList(trendData!['views_30d']);
      final likes7d = _toNumList(trendData!['likes_7d']);
      final likes30d = _toNumList(trendData!['likes_30d']);
      final subs7d = _toNumList(trendData!['subscribers_7d']);

      if (views7d.isNotEmpty) {
        charts.add(TrendChartCard(
          title: 'Views Trend',
          icon: Icons.visibility_rounded,
          color: AppColors.youtube,
          data7d: views7d,
          data30d: views30d.isNotEmpty ? views30d : views7d,
        ));
      }
      if (likes7d.isNotEmpty) {
        charts.add(TrendChartCard(
          title: 'Likes Trend',
          icon: Icons.thumb_up_rounded,
          color: const Color(0xFFF59E0B),
          data7d: likes7d,
          data30d: likes30d.isNotEmpty ? likes30d : likes7d,
        ));
      }
      if (subs7d.isNotEmpty) {
        charts.add(TrendChartCard(
          title: 'New Subscribers',
          icon: Icons.person_add_rounded,
          color: AppColors.success,
          data7d: subs7d,
          data30d: subs7d, // only 7d available
        ));
      }
    }

    if (charts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 14, color: primaryColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'Engagement Trends',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...charts.map((chart) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: chart,
        )),
      ],
    );
  }
}
