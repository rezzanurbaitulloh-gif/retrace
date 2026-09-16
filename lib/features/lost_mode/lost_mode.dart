import 'package:flutter/foundation.dart';

/// Lost Mode state (§23-§24).
enum LostModeState {
  inactive,
  activating,
  active,
  deactivating,
}

@immutable
final class LostModeInfo {
  const LostModeInfo({
    required this.deviceId,
    required this.state,
    required this.activatedAt,
    this.deactivatedAt,
    this.recoveryId,
  });

  final String deviceId;
  final LostModeState state;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;
  final String? recoveryId;

  bool get isActive => state == LostModeState.active;

  LostModeInfo copyWith({
    LostModeState? state,
    DateTime? deactivatedAt,
    String? recoveryId,
  }) {
    return LostModeInfo(
      deviceId: deviceId,
      state: state ?? this.state,
      activatedAt: activatedAt,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      recoveryId: recoveryId ?? this.recoveryId,
    );
  }
}

/// Remote command types (§25).
enum CommandType {
  ring,
  vibrate,
  lock,
  showLostScreen,
  captureEvidence,
  requestLocation,
}

extension CommandTypeLabel on CommandType {
  String get label => switch (this) {
        CommandType.ring => 'Ring',
        CommandType.vibrate => 'Vibrate',
        CommandType.lock => 'Lock',
        CommandType.showLostScreen => 'Show Lost Screen',
        CommandType.captureEvidence => 'Capture Evidence',
        CommandType.requestLocation => 'Request Location',
      };

  String get apiValue => switch (this) {
        CommandType.ring => 'RING',
        CommandType.vibrate => 'VIBRATE',
        CommandType.lock => 'LOCK',
        CommandType.showLostScreen => 'SHOW_LOST_SCREEN',
        CommandType.captureEvidence => 'CAPTURE_EVIDENCE',
        CommandType.requestLocation => 'REQUEST_LOCATION',
      };
}

/// Command execution states (§25).
enum CommandStatus {
  pending,
  delivered,
  executing,
  success,
  failed,
  unsupported,
  expired,
}

@immutable
final class RemoteCommand {
  const RemoteCommand({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.executedAt,
    this.failureReason,
    this.requestedBy,
  });

  final String id;
  final String deviceId;
  final CommandType type;
  final CommandStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final String? failureReason;
  final String? requestedBy;

  RemoteCommand copyWith({
    CommandStatus? status,
    DateTime? executedAt,
    String? failureReason,
  }) {
    return RemoteCommand(
      id: id,
      deviceId: deviceId,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      executedAt: executedAt ?? this.executedAt,
      failureReason: failureReason ?? this.failureReason,
      requestedBy: requestedBy,
    );
  }

  bool get isTerminal =>
      status == CommandStatus.success ||
      status == CommandStatus.failed ||
      status == CommandStatus.unsupported ||
      status == CommandStatus.expired;
}

/// Lost Screen data for QR/Recovery (§30).
@immutable
final class LostScreenData {
  const LostScreenData({
    required this.recoveryId,
    required this.message,
    required this.contactUrl,
    this.qrData,
  });

  final String recoveryId;
  final String message;
  final String contactUrl;
  final String? qrData;
}