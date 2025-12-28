import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

class SyncProvider with ChangeNotifier {
  final SyncService _syncService;

  SyncProvider(this._syncService) {
    _syncService.startListening();
  }

  bool get isOnline => _syncService.isOnline;
  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSync => _syncService.lastSync;
  bool get hasPendingChanges => _syncService.hasPendingChanges();
  int get pendingChangesCount => _syncService.getPendingChangesCount();

  Future<void> forceSync() async {
    await _syncService.forceSync();
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
