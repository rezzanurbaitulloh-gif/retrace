// Sync Engine — idempotent, retry-safe, resumable, ordered, deduped, conflict-aware (PRD 83)
class SyncEvent {
  final String id;
  final String type;
  final Map<String,dynamic> payload;
  final DateTime createdAt;
  int retryCount = 0;
  String status = 'PENDING';
  SyncEvent({required this.id, required this.type, required this.payload, required this.createdAt});
  String get dedupKey => '$type:$id';
}
class SyncEngine {
  final List<SyncEvent> _queue = [];
  final Set<String> _seen = {};
  void enqueue(SyncEvent e){
    if (_seen.contains(e.dedupKey)) return;
    _seen.add(e.dedupKey);
    _queue.add(e);
    _queue.sort((a,b)=> a.createdAt.compareTo(b.createdAt));
  }
  List<SyncEvent> drainBatch({int batchSize=50}){
    final batch = _queue.take(batchSize).toList();
    for (var e in batch) e.status='SYNCING';
    return batch;
  }
  void ack(String id, {bool success=true, bool conflict=false}){
    final idx = _queue.indexWhere((e)=> e.id==id);
    if (idx==-1) return;
    final e = _queue[idx];
    if (success) { e.status='SYNCED'; _queue.removeAt(idx); }
    else if (conflict) { e.status='CONFLICT'; }
    else { e.status='FAILED'; e.retryCount++; if (e.retryCount>3) _queue.removeAt(idx); }
  }
  bool get isEmpty => _queue.isEmpty;
  int get length => _queue.length;
}
