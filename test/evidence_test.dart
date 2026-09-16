import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/features/evidence/evidence.dart';

EvidenceMetadata _meta() => EvidenceMetadata(
      id: 'ev_1',
      deviceId: 'dev_1',
      capturedAt: DateTime.utc(2026, 9, 17, 4, 30),
      latitude: -7.6,
      longitude: 111.9,
      caption: 'Gate photo',
    );

void main() {
  group('validateEvidenceFile', () {
    test('accepts jpg/png/heic within limit', () {
      for (final String name in <String>['a.jpg', 'b.JPEG', 'c.png', 'd.heic']) {
        final EvidenceValidation v = validateEvidenceFile(
          fileName: name,
          sizeBytes: 1024,
        );
        expect(v.ok, isTrue, reason: name);
      }
    });

    test('rejects unsupported extension', () {
      final EvidenceValidation v = validateEvidenceFile(
        fileName: 'note.txt',
        sizeBytes: 1024,
      );
      expect(v.ok, isFalse);
      expect(v.reason, contains('.txt'));
    });

    test('rejects missing extension and empty name', () {
      expect(
        validateEvidenceFile(fileName: 'noext', sizeBytes: 10).ok,
        isFalse,
      );
      expect(
        validateEvidenceFile(fileName: '  ', sizeBytes: 10).ok,
        isFalse,
      );
    });

    test('rejects empty and oversized files', () {
      expect(
        validateEvidenceFile(fileName: 'a.jpg', sizeBytes: 0).ok,
        isFalse,
      );
      expect(
        validateEvidenceFile(
          fileName: 'a.jpg',
          sizeBytes: kMaxEvidenceBytes + 1,
        ).ok,
        isFalse,
      );
      expect(
        validateEvidenceFile(
          fileName: 'a.jpg',
          sizeBytes: kMaxEvidenceBytes,
        ).ok,
        isTrue,
      );
    });
  });

  group('extensionOf / mimeOf', () {
    test('lowercases and strips path', () {
      expect(extensionOf('/tmp/IMG_1.JPG'), equals('jpg'));
      expect(extensionOf(r'C:\pics\a.HeIc'), equals('heic'));
      expect(extensionOf('noext'), isEmpty);
      expect(extensionOf('trailing.'), isEmpty);
    });

    test('mime mapping covers supported types', () {
      expect(mimeOf('a.jpg'), equals('image/jpeg'));
      expect(mimeOf('a.jpeg'), equals('image/jpeg'));
      expect(mimeOf('a.png'), equals('image/png'));
      expect(mimeOf('a.heic'), equals('image/heic'));
      expect(mimeOf('a.pdf'), equals('application/pdf'));
      expect(mimeOf('a.bin'), equals('application/octet-stream'));
    });
  });

  group('buildStoragePath', () {
    test('deterministic evidence/<device>/<id>.<ext>', () {
      expect(
        buildStoragePath(
          deviceId: 'dev_1',
          evidenceId: 'ev_1',
          fileName: 'IMG.JPG',
        ),
        equals('evidence/dev_1/ev_1.jpg'),
      );
    });

    test('blank device falls back to unknown, never empty segment', () {
      expect(
        buildStoragePath(deviceId: '  ', evidenceId: 'ev_1', fileName: 'a.png'),
        equals('evidence/unknown/ev_1.png'),
      );
    });
  });

  group('EvidenceMetadata JSON', () {
    test('round-trips with location and caption', () {
      final EvidenceMetadata m = _meta();
      final EvidenceMetadata back =
          EvidenceMetadata.fromJson(m.toJson());
      expect(back.id, equals('ev_1'));
      expect(back.deviceId, equals('dev_1'));
      expect(back.latitude, equals(-7.6));
      expect(back.longitude, equals(111.9));
      expect(back.caption, equals('Gate photo'));
      expect(back.hasLocation, isTrue);
    });

    test('document type survives round-trip, unknown defaults to photo', () {
      final EvidenceMetadata doc =
          _meta().copyWith(type: EvidenceType.document);
      expect(
        EvidenceMetadata.fromJson(doc.toJson()).type,
        equals(EvidenceType.document),
      );
      final Map<String, dynamic> raw = _meta().toJson()..['type'] = 'weird';
      expect(
        EvidenceMetadata.fromJson(raw).type,
        equals(EvidenceType.photo),
      );
    });

    test('hasLocation false when cleared or partial', () {
      // copyWith follows ?? semantics: null keeps the old value, so an
      // explicit clearLocation flag wipes both coordinates at once.
      expect(_meta().copyWith(clearLocation: true).hasLocation, isFalse);
      expect(
        EvidenceMetadata(
          id: 'x',
          deviceId: 'd',
          capturedAt: DateTime.utc(2026, 1, 1),
          latitude: -7.6,
        ).hasLocation,
        isFalse,
      );
    });
  });

  group('EvidenceItem JSON', () {
    test('round-trips queued then uploaded state', () {
      final EvidenceItem q = EvidenceItem(
        metadata: EvidenceMetadata(
          id: 'ev_9',
          deviceId: 'dev_2',
          capturedAt: DateTime.utc(2026, 1, 1),
        ),
        localPath: '/tmp/a.jpg',
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 42,
      );
      final EvidenceItem back = EvidenceItem.fromJson(q.toJson());
      expect(back.id, equals('ev_9'));
      expect(back.uploaded, isFalse);
      expect(back.remotePath, isNull);

      final EvidenceItem up =
          back.copyWith(remotePath: 'evidence/dev_2/ev_9.jpg', uploaded: true);
      final EvidenceItem back2 = EvidenceItem.fromJson(up.toJson());
      expect(back2.uploaded, isTrue);
      expect(back2.remotePath, equals('evidence/dev_2/ev_9.jpg'));
    });
  });
}
