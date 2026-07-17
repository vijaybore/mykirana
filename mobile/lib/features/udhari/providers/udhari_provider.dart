import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/udhari_models.dart';
import '../../../services/api_service.dart';
import '../../../services/local_db_service.dart';

final _apiServiceProvider = Provider((ref) => ApiService());
final _localDbProvider = Provider((ref) => LocalDbService());
const _uuid = Uuid();

/// Owner-side: the udhari customer list for a shop, sorted by balance
/// owed (highest first) — reads local cache immediately, then
/// refreshes from the backend in the background.
class UdhariCustomerListNotifier
    extends StateNotifier<AsyncValue<List<UdhariCustomerSummary>>> {
  UdhariCustomerListNotifier(this._api, this._localDb, this.shopId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final ApiService _api;
  final LocalDbService _localDb;
  final String shopId;

  Future<void> _load() async {
    // Serve cached data instantly if we have it — no spinner on a warm start.
    final cached = await _localDb.getCachedCustomerList(shopId);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(
        cached.map((r) => UdhariCustomerSummary.fromJson(r)).toList(),
      );
    }

    try {
      final fresh = await _api.getUdhariCustomers(shopId);
      await _localDb.cacheCustomerList(shopId, fresh);
      state = AsyncValue.data(
        fresh.map((r) => UdhariCustomerSummary.fromJson(r)).toList(),
      );
    } catch (e, st) {
      // Offline or backend unreachable — fall back to whatever we cached.
      // Only surface an error state if we truly have nothing to show.
      if (cached.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => _load();
}

final udhariCustomerListProvider = StateNotifierProvider.family<
    UdhariCustomerListNotifier, AsyncValue<List<UdhariCustomerSummary>>, String>(
  (ref, shopId) => UdhariCustomerListNotifier(
    ref.watch(_apiServiceProvider),
    ref.watch(_localDbProvider),
    shopId,
  ),
);

/// Shared by both owner (viewing one customer's history) and customer
/// (viewing their own history) — same data shape, different entry point.
class UdhariHistoryNotifier
    extends StateNotifier<AsyncValue<List<UdhariTransaction>>> {
  UdhariHistoryNotifier(this._api, this._localDb, this.shopId, this.customerId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final ApiService _api;
  final LocalDbService _localDb;
  final String shopId;
  final String customerId;

  Future<void> _load() async {
    final cached = await _localDb.getCachedHistory(shopId, customerId);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(
        cached.map((r) => UdhariTransaction.fromJson(r)).toList(),
      );
    }

    try {
      final fresh = await _api.getUdhariHistory(shopId, customerId);
      for (final row in fresh) {
        await _localDb.cacheTransaction(row);
      }
      state = AsyncValue.data(
        fresh.map((r) => UdhariTransaction.fromJson(r)).toList(),
      );
    } catch (e, st) {
      if (cached.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  double get balance {
    final txns = state.value ?? [];
    return txns.fold<double>(
      0,
      (sum, t) =>
          sum + (t.type == UdhariType.credit ? t.amount : -t.amount),
    );
  }

  /// Adds an entry offline-first: writes to local cache immediately so
  /// the UI updates instantly, then tries to push to the backend. If
  /// that fails (no signal), it stays flagged pending_sync and a
  /// background sync job (wired up alongside connectivity_plus) will
  /// retry once the connection is back.
  Future<void> addEntry({
    required UdhariType type,
    required double amount,
    String? note,
  }) async {
    final localRow = {
      'id': _uuid.v4(),
      'shop_id': shopId,
      'customer_id': customerId,
      'type': type.apiValue,
      'amount': amount,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _localDb.cacheTransaction(localRow, pendingSync: true);
    // Optimistic UI update
    state = AsyncValue.data([
      UdhariTransaction.fromJson(localRow),
      ...(state.value ?? []),
    ]);

    try {
      final saved = await _api.addUdhariEntry(
        shopId: shopId,
        customerId: customerId,
        type: type.apiValue,
        amount: amount,
        note: note,
      );
      await _localDb.markSynced(localRow['id'] as String);
      // Replace the optimistic row with the backend's authoritative one
      final updated = [...(state.value ?? [])];
      final idx = updated.indexWhere((t) => t.id == localRow['id']);
      if (idx != -1) {
        updated[idx] = UdhariTransaction.fromJson(saved);
      }
      state = AsyncValue.data(updated.cast<UdhariTransaction>());
    } catch (_) {
      // Stays pending_sync = 1 locally — will retry on reconnect.
      // The optimistic entry remains visible so the owner/customer
      // sees their entry was recorded, just not yet synced.
    }
  }
}

final udhariHistoryProvider = StateNotifierProvider.family<
    UdhariHistoryNotifier,
    AsyncValue<List<UdhariTransaction>>,
    ({String shopId, String customerId})>(
  (ref, args) => UdhariHistoryNotifier(
    ref.watch(_apiServiceProvider),
    ref.watch(_localDbProvider),
    args.shopId,
    args.customerId,
  ),
);

