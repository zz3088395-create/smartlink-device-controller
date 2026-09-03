import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'activity_summary.dart';
import 'history_models.dart';
import 'history_repository.dart';

/// Three most recent sessions for the home screen.
final recentActivityProvider = FutureProvider<List<ConnectionRecord>>((ref) async {
  ref.watch(currentUserIdProvider);
  final page = await ref.watch(historyRepositoryProvider).list(pageSize: 3);
  return page.list;
});

/// Full activity list with simple "load more" paging.
class ActivityFeed {
  const ActivityFeed({required this.records, required this.total, required this.page});

  final List<ConnectionRecord> records;
  final int total;
  final int page;

  bool get hasMore => records.length < total;
}

class ActivityFeedNotifier extends AsyncNotifier<ActivityFeed> {
  static const int pageSize = 30;

  @override
  Future<ActivityFeed> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(historyRepositoryProvider).list(pageSize: pageSize);
    return ActivityFeed(records: page.list, total: page.total, page: 1);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Reflected in [state].
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final next = current.page + 1;
    final page = await ref
        .read(historyRepositoryProvider)
        .list(pageNum: next, pageSize: pageSize);
    state = AsyncData(
      ActivityFeed(
        records: [...current.records, ...page.list],
        total: page.total,
        page: next,
      ),
    );
  }
}

final activityFeedProvider =
    AsyncNotifierProvider<ActivityFeedNotifier, ActivityFeed>(ActivityFeedNotifier.new);

/// "This Week" roll-up over the loaded feed.
final weeklySummaryProvider = Provider<ActivitySummary>((ref) {
  final feed = ref.watch(activityFeedProvider).value;
  if (feed == null) return ActivitySummary.empty;
  return ActivitySummary.lastSevenDays(feed.records);
});
