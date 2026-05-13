import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'trend_chart.dart';

class AnalyticsDashboard extends StatelessWidget {
  final Map<String, dynamic>? analytics;
  final bool loading;
  final int igFollowers;
  final int ytSubscribers;

  const AnalyticsDashboard({
    super.key,
    this.analytics, required this.loading,
    required this.igFollowers, required this.ytSubscribers,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final igAnalytics = analytics?['instagram'] as Map<String, dynamic>?;
    final ytAnalytics = analytics?['youtube'] as Map<String, dynamic>?;

    if (igAnalytics == null && ytAnalytics == null) {
      return _buildBasicStats();
    }

    return Column(
      children: [
        if (igAnalytics != null)
          PlatformAnalyticsCard(
            platform: 'Instagram',
            icon: Icons.camera_alt_rounded,
            gradient: AppColors.instagramGradient,
            color: AppColors.instagram,
            followers: igFollowers,
            analytics: igAnalytics,
            tier: igAnalytics['tier']?.toString() ?? '\u2014',
          ),
        if (igAnalytics != null && ytAnalytics != null) const SizedBox(height: 12),
        if (ytAnalytics != null)
          PlatformAnalyticsCard(
            platform: 'YouTube',
            icon: Icons.play_circle_rounded,
            gradient: AppColors.youtubeGradient,
            color: AppColors.youtube,
            followers: ytSubscribers,
            followersLabel: 'Subscribers',
            analytics: ytAnalytics,
            tier: ytAnalytics['tier']?.toString() ?? '\u2014',
          ),
      ],
    );
  }

  Widget _buildBasicStats() {
    final hasIG = igFollowers > 0;
    final hasYT = ytSubscribers > 0;
    if (!hasIG && !hasYT) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.textHint, size: 20),
            const SizedBox(width: 10),
            Text('No social platforms connected yet',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return Row(
      children: [
        if (hasIG)
          Expanded(child: SimpleStatBox(
            label: 'IG Followers', value: _fmt(igFollowers),
            color: AppColors.instagram, icon: Icons.camera_alt_rounded,
          )),
        if (hasIG && hasYT) const SizedBox(width: 12),
        if (hasYT)
          Expanded(child: SimpleStatBox(
            label: 'YT Subscribers', value: _fmt(ytSubscribers),
            color: AppColors.youtube, icon: Icons.play_circle_rounded,
          )),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class PlatformAnalyticsCard extends StatelessWidget {
  final String platform;
  final IconData icon;
  final LinearGradient gradient;
  final Color color;
  final int followers;
  final String followersLabel;
  final Map<String, dynamic> analytics;
  final String tier;

  const PlatformAnalyticsCard({
    super.key,
    required this.platform, required this.icon, required this.gradient,
    required this.color, required this.followers, required this.analytics,
    required this.tier, this.followersLabel = 'Followers',
  });

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _fmt(dynamic v) {
    final n = _toInt(v);
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    if (n == 0) return '\u2014';
    return n.toString();
  }

  Color _engColor(String rate) {
    final r = double.tryParse(rate) ?? 0;
    if (r >= 5) return AppColors.success;
    if (r >= 2) return Colors.orange;
    return AppColors.textHint;
  }

  // Format seconds as "M:SS" or "H:MM:SS"
  String _fmtDuration(dynamic v) {
    final secs = _toInt(v);
    if (secs == 0) return '\u2014';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '$m:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final engRate = analytics['engagement_rate']?.toString() ?? '0';
    final engColor = _engColor(engRate);
    final isInstagram = platform == 'Instagram';

    // Primary metrics
    final avgViews = analytics['avg_views'];
    final avgLikes = analytics['avg_likes'];
    final avgComments = analytics['avg_comments'];

    // Instagram-only
    final avgShares = analytics['avg_shares'];
    final avgSaves = analytics['avg_saves'];
    final avgReach = analytics['avg_reach'];
    final reach28d = analytics['reach_28d'];
    final impressions28d = analytics['impressions_28d'];
    final profileViews28d = analytics['profile_views_28d'];

    // YouTube-only
    final totalViews = analytics['total_views'];
    final videoCount = analytics['video_count'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Text(platform, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                TierBadge(tier: tier, color: color),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                // ── Hero row: Followers + Engagement ──
                Row(
                  children: [
                    Expanded(
                      child: HeroMetric(
                        label: followersLabel,
                        value: _fmt(followers),
                        icon: Icons.people_rounded,
                        color: color,
                      ),
                    ),
                    Container(width: 1, height: 44, color: AppColors.divider),
                    Expanded(
                      child: HeroMetric(
                        label: 'Engagement',
                        value: engRate == '0' ? '\u2014' : '$engRate%',
                        icon: Icons.trending_up_rounded,
                        color: engColor,
                      ),
                    ),
                    if (!isInstagram) ...[
                      Container(width: 1, height: 44, color: AppColors.divider),
                      Expanded(
                        child: HeroMetric(
                          label: 'Total Views',
                          value: _fmt(totalViews),
                          icon: Icons.visibility_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // ── Per-post averages ──
                SectionLabel2(label: isInstagram ? 'Per Post Averages' : 'Per Video Averages'),
                const SizedBox(height: 8),
                MetricGrid(
                  metrics: [
                    MetricItem(label: 'Avg Views', value: _fmt(avgViews), icon: Icons.play_arrow_rounded, color: color),
                    MetricItem(label: 'Avg Likes', value: _fmt(avgLikes), icon: Icons.favorite_rounded, color: const Color(0xFFE91E63)),
                    MetricItem(label: 'Avg Comments', value: _fmt(avgComments), icon: Icons.comment_rounded, color: const Color(0xFF0EA5E9)),
                    if (isInstagram) ...[
                      MetricItem(label: 'Avg Shares', value: _fmt(avgShares), icon: Icons.share_rounded, color: const Color(0xFF8B5CF6)),
                      MetricItem(label: 'Avg Saves', value: _fmt(avgSaves), icon: Icons.bookmark_rounded, color: const Color(0xFFF59E0B)),
                      MetricItem(label: 'Avg Reach', value: _fmt(avgReach), icon: Icons.radar_rounded, color: AppColors.success),
                    ] else ...[
                      MetricItem(label: 'Avg Duration', value: _fmtDuration(analytics['avg_duration']), icon: Icons.timer_rounded, color: const Color(0xFF8B5CF6)),
                      MetricItem(label: 'Total Videos', value: _fmt(videoCount), icon: Icons.video_library_rounded, color: AppColors.youtube),
                      MetricItem(label: 'Total Views', value: _fmt(analytics['total_views']), icon: Icons.visibility_rounded, color: const Color(0xFF6366F1)),
                    ],
                  ],
                ),

                // ── 28-day account insights (Instagram only) ──
                if (isInstagram && (reach28d != null || impressions28d != null || profileViews28d != null)) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  SectionLabel2(label: 'Last 28 Days (Account)'),
                  const SizedBox(height: 8),
                  MetricGrid(
                    metrics: [
                      if (reach28d != null)
                        MetricItem(label: 'Reach', value: _fmt(reach28d), icon: Icons.wifi_tethering_rounded, color: AppColors.instagram),
                      if (impressions28d != null)
                        MetricItem(label: 'Impressions', value: _fmt(impressions28d), icon: Icons.remove_red_eye_rounded, color: const Color(0xFF6366F1)),
                      if (profileViews28d != null)
                        MetricItem(label: 'Profile Views', value: _fmt(profileViews28d), icon: Icons.person_search_rounded, color: const Color(0xFF0EA5E9)),
                    ],
                  ),
                ],

                // ── YouTube Analytics API: 28-day data ──
                if (!isInstagram) YoutubeAnalytics28d(analytics: analytics, color: color),

                // ── Trend Charts ──
                TrendChartsSection(
                  trendData: analytics['trend_data'] as Map<String, dynamic>?,
                  isInstagram: isInstagram,
                  primaryColor: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── YouTube 28-day Analytics section ─────────────────────────────────────────

class YoutubeAnalytics28d extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final Color color;
  const YoutubeAnalytics28d({super.key, required this.analytics, required this.color});

  String _fmt(dynamic v) {
    if (v == null) return '\u2014';
    double n;
    if (v is double) n = v;
    else if (v is int) n = v.toDouble();
    else n = double.tryParse(v.toString()) ?? 0;
    if (n == 0) return '\u2014';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _fmtHours(dynamic v) {
    if (v == null) return '\u2014';
    final mins = (v is double) ? v : double.tryParse(v.toString()) ?? 0.0;
    if (mins == 0) return '\u2014';
    final hours = mins / 60;
    if (hours >= 1000) return '${(hours / 1000).toStringAsFixed(1)}Kh';
    return '${hours.toStringAsFixed(0)}h';
  }

  String _fmtDur(dynamic v) {
    if (v == null) return '\u2014';
    final secs = (v is double) ? v.toInt() : (v is int ? v : int.tryParse(v.toString()) ?? 0);
    if (secs == 0) return '\u2014';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _fmtPct(dynamic v) {
    if (v == null) return '\u2014';
    final pct = (v is double) ? v : double.tryParse(v.toString()) ?? 0.0;
    if (pct == 0) return '\u2014';
    return '${pct.toStringAsFixed(1)}%';
  }

  String _fmtCtr(dynamic v) {
    if (v == null) return '\u2014';
    final ctr = (v is double) ? v : double.tryParse(v.toString()) ?? 0.0;
    if (ctr == 0) return '\u2014';
    return '${(ctr * 100).toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final d = analytics['analytics_28d'] as Map<String, dynamic>?;
    final channelAge = analytics['channel_age_years'];
    final country = analytics['country'];
    final hasChannelMeta = channelAge != null || country != null;
    if (d == null && !hasChannelMeta) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d != null) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          SectionLabel2(label: 'Last 28 Days (YouTube Analytics)'),
          const SizedBox(height: 8),
          MetricGrid(
            metrics: [
              MetricItem(label: 'Watch Time', value: _fmtHours(d['estimatedMinutesWatched']), icon: Icons.access_time_rounded, color: AppColors.youtube),
              MetricItem(label: 'Avg View Duration', value: _fmtDur(d['averageViewDuration']), icon: Icons.timer_outlined, color: const Color(0xFF8B5CF6)),
              MetricItem(label: 'Avg % Viewed', value: _fmtPct(d['averageViewPercentage']), icon: Icons.data_usage_rounded, color: const Color(0xFF0EA5E9)),
              MetricItem(label: 'Impressions', value: _fmt(d['impressions']), icon: Icons.remove_red_eye_rounded, color: const Color(0xFF6366F1)),
              MetricItem(label: 'CTR', value: _fmtCtr(d['impressionClickThroughRate']), icon: Icons.ads_click_rounded, color: AppColors.success),
              MetricItem(label: 'Shares', value: _fmt(d['shares']), icon: Icons.share_rounded, color: const Color(0xFFE91E63)),
              MetricItem(label: 'Subs Gained', value: _fmt(d['subscribersGained']), icon: Icons.person_add_rounded, color: AppColors.success),
              MetricItem(label: 'Subs Lost', value: _fmt(d['subscribersLost']), icon: Icons.person_remove_rounded, color: const Color(0xFFEF4444)),
              MetricItem(label: 'Likes (28d)', value: _fmt(d['likes']), icon: Icons.thumb_up_rounded, color: const Color(0xFFF59E0B)),
            ],
          ),
        ],
        if (hasChannelMeta) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          SectionLabel2(label: 'Channel Info'),
          const SizedBox(height: 8),
          MetricGrid(
            metrics: [
              if (channelAge != null)
                MetricItem(
                  label: 'Channel Age',
                  value: '${channelAge}y',
                  icon: Icons.cake_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              if (country != null && country.toString().isNotEmpty)
                MetricItem(
                  label: 'Country',
                  value: country.toString(),
                  icon: Icons.public_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const HeroMetric({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class SectionLabel2 extends StatelessWidget {
  final String label;
  const SectionLabel2({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint,
              letterSpacing: 0.5)),
    );
  }
}

class MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const MetricItem({required this.label, required this.value, required this.icon, required this.color});
}

class MetricGrid extends StatelessWidget {
  final List<MetricItem> metrics;
  const MetricGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((m) => MetricTile(item: m)).toList(),
    );
  }
}

class MetricTile extends StatelessWidget {
  final MetricItem item;
  const MetricTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 40 - 28 - 16) / 3; // 3 per row
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(height: 5),
            Text(item.value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: item.color)),
            const SizedBox(height: 2),
            Text(item.label,
                style: TextStyle(fontSize: 9, color: AppColors.textHint),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class TierBadge extends StatelessWidget {
  final String tier;
  final Color color;
  const TierBadge({super.key, required this.tier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(tier, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class SimpleStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const SimpleStatBox({super.key, required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
