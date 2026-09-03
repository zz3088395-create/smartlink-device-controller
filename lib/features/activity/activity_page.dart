import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/widgets.dart';
import '../history/activity_row.dart';
import '../history/activity_summary.dart';
import '../history/history_provider.dart';

/// Connection history from `GET /app/history` with a local weekly roll-up.
class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(activityFeedProvider);
    final summary = ref.watch(weeklySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: feed.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is ApiException
              ? error.message
              : 'We could not load your activity.',
          onRetry: () => ref.invalidate(activityFeedProvider),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(activityFeedProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xs,
              AppSpacing.page,
              AppSpacing.xxxl,
            ),
            children: [
              _WeekSummaryCard(summary: summary),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'Sessions'),
              if (data.records.isEmpty)
                const AppCard(
                  child: Row(
                    children: [
                      IconTile(
                        icon: Icons.history_rounded,
                        color: AppColors.textSecondary,
                        background: AppColors.surfaceMuted,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'No sessions yet. Connect a device to start your history.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < data.records.length; i++) ...[
                        if (i > 0) const Divider(),
                        ActivityRow(record: data.records[i]),
                      ],
                    ],
                  ),
                ),
              if (data.hasMore) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton.secondary(
                  label: 'Load more',
                  onPressed: () => ref.read(activityFeedProvider.notifier).loadMore(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekSummaryCard extends StatelessWidget {
  const _WeekSummaryCard({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('This Week', style: AppTextStyles.subtitle)),
              Text('Last 7 days', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Metric(label: 'Sessions', value: '${summary.sessions}'),
              _Metric(
                label: 'Total Time',
                value: formatDurationCompact(summary.totalSeconds),
              ),
              _Metric(
                label: 'Average',
                value: formatDurationSeconds(summary.averageSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.metric,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
