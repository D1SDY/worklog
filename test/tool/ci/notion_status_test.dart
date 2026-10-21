import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ci/notion_status.dart';

void main() {
  group('storyIdFromBranch', () {
    test('extracts the ID from a story branch with a slug', () {
      expect(
        storyIdFromBranch('story/WORLOG-001-app-navigation-shell'),
        'WORLOG-001',
      );
    });

    test('extracts the ID from a story branch without a slug', () {
      expect(storyIdFromBranch('story/WORLOG-057'), 'WORLOG-057');
    });

    test('returns null for non-story branches', () {
      expect(storyIdFromBranch('develop'), isNull);
      expect(storyIdFromBranch('fix/WORLOG-001-typo'), isNull);
      expect(storyIdFromBranch('retro/rules-update'), isNull);
    });

    test('rejects an ID run straight into other characters', () {
      expect(storyIdFromBranch('story/WORLOG-001x'), isNull);
    });
  });

  group('shouldAdvance', () {
    test('moves a story in test to delivered', () {
      expect(shouldAdvance(current: 'In Test', target: 'Delivered'), isTrue);
    });

    test('moves a story that skipped In Test', () {
      expect(
        shouldAdvance(current: 'In Progress', target: 'Delivered'),
        isTrue,
      );
    });

    test('never moves a story backwards', () {
      expect(shouldAdvance(current: 'Deployed', target: 'Delivered'), isFalse);
    });

    test('does nothing when already at the target', () {
      expect(shouldAdvance(current: 'Delivered', target: 'Delivered'), isFalse);
    });

    test('treats an empty or unknown status as behind', () {
      expect(shouldAdvance(current: null, target: 'Delivered'), isTrue);
      expect(shouldAdvance(current: 'Renamed', target: 'Delivered'), isTrue);
    });

    test('throws for an unknown target', () {
      expect(
        () => shouldAdvance(current: 'In Test', target: 'Done'),
        throwsArgumentError,
      );
    });
  });

  group('storyQueryBody', () {
    test('filters on Story ID equality', () {
      expect(storyQueryBody('WORLOG-001'), <String, Object>{
        'filter': <String, Object>{
          'property': 'Story ID',
          'rich_text': <String, String>{'equals': 'WORLOG-001'},
        },
        'page_size': 2,
      });
    });
  });

  group('statusPatchBody', () {
    test('shapes a status-type property', () {
      expect(
        statusPatchBody(propertyType: 'status', status: 'Delivered'),
        <String, Object>{
          'properties': <String, Object>{
            'Status': <String, Object>{
              'status': <String, String>{'name': 'Delivered'},
            },
          },
        },
      );
    });

    test('shapes a select-type property', () {
      expect(
        statusPatchBody(propertyType: 'select', status: 'Delivered'),
        <String, Object>{
          'properties': <String, Object>{
            'Status': <String, Object>{
              'select': <String, String>{'name': 'Delivered'},
            },
          },
        },
      );
    });

    test('throws for any other property type', () {
      expect(
        () => statusPatchBody(propertyType: 'rich_text', status: 'Delivered'),
        throwsArgumentError,
      );
    });
  });

  group('readStatus', () {
    test('reads a status-type property', () {
      final ({String type, String? name}) status = readStatus(<String, dynamic>{
        'properties': <String, dynamic>{
          'Status': <String, dynamic>{
            'type': 'status',
            'status': <String, dynamic>{'name': 'In Test'},
          },
        },
      });

      expect(status.type, 'status');
      expect(status.name, 'In Test');
    });

    test('reads an empty select as no status', () {
      final ({String type, String? name}) status = readStatus(<String, dynamic>{
        'properties': <String, dynamic>{
          'Status': <String, dynamic>{'type': 'select', 'select': null},
        },
      });

      expect(status.type, 'select');
      expect(status.name, isNull);
    });
  });
}
