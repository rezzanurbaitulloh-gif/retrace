/// Explicit view states for every async surface (§74).
///
/// Riverpod `AsyncValue` remains the transport inside controllers; screens map
/// it onto these cases so loading / empty / error / offline / restricted are
/// never silently skipped.
enum ViewState {
  initial,
  loading,
  loaded,
  empty,
  error,
  offline,
  syncing,
  success,
  restricted,
}
