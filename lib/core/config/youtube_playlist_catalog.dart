import '../../domain/entities/course.dart';
import 'youtube_config.dart';

class YoutubePlaylistCatalog {
  YoutubePlaylistCatalog._();

  static const String _course1 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_1',
    defaultValue: 'PLMDrOnfT8EAhsiJwkzspHp_Ob6oRCHxv0', // Flutter Basics
  );
  static const String _course2 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_2',
    defaultValue: 'PLmQ0KfqeaHAuud_Aav-94nfToArf6Uh4K', // UI/UX Design
  );
  static const String _course3 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_3',
    defaultValue: 'PLYyqC4bNbCIcxKO_r77w5MN1SRRnnfvNQ', // Python
  );
  static const String _course4 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_4',
    defaultValue: 'PLCInYL3l2AajqOUW_2SwjWeMwf4vL4RSp', // Data Structures
  );
  static const String _course5 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_5',
    defaultValue: 'PL9b6wgodx-C2_nzF7GF7vnJZvjOkPgu_X', // Flutter Animations
  );
  static const String _course6 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_6',
    defaultValue: 'PLmQ0KfqeaHAuud_Aav-94nfToArf6Uh4K', // Product (UX focused)
  );
  static const String _course7 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_7',
    defaultValue: 'PL93xoMrxRJIutlMCImcV3CYMmjS0MmlWL', // Dart & OOP
  );
  static const String _course8 = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COURSE_8',
    defaultValue: 'PLzNfs-3kBUJllCa8_6pLYDMnIlg6Lfvu4', // Software Testing
  );

  static const String _programming = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_PROGRAMMING',
    defaultValue: 'PLMDrOnfT8EAhsiJwkzspHp_Ob6oRCHxv0',
  );
  static const String _design = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_DESIGN',
    defaultValue: 'PLmQ0KfqeaHAuud_Aav-94nfToArf6Uh4K',
  );
  static const String _backend = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_BACKEND',
    defaultValue: 'PLYyqC4bNbCIcxKO_r77w5MN1SRRnnfvNQ',
  );
  static const String _computerScience = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_COMPUTER_SCIENCE',
    defaultValue: 'PLCInYL3l2AajqOUW_2SwjWeMwf4vL4RSp',
  );
  static const String _product = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_PRODUCT',
    defaultValue: 'PL93xoMrxRJIutlMCImcV3CYMmjS0MmlWL',
  );
  static const String _testing = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_TESTING',
    defaultValue: 'PLzNfs-3kBUJllCa8_6pLYDMnIlg6Lfvu4',
  );

  static String? playlistIdForCourse(Course course) {
    final byCourse = _coursePlaylistById[course.id];
    if (_isConfigured(byCourse)) {
      return byCourse!.trim();
    }

    final byCategory = _categoryPlaylistByName[course.category];
    if (_isConfigured(byCategory)) {
      return byCategory!.trim();
    }

    // Keep current behavior for backend/Firebase courses as a fallback
    // when only one playlist is configured globally.
    final fallback = YoutubeConfig.defaultPlaylistId.trim();
    final title = course.title.toLowerCase();
    final category = course.category.toLowerCase();
    final looksLikeBackend =
        category.contains('backend') || title.contains('firebase');
    if (looksLikeBackend && _isConfigured(fallback)) {
      return fallback;
    }

    return null;
  }

  static bool _isConfigured(String? value) {
    if (value == null) return false;
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    final upper = normalized.toUpperCase();
    if (upper == 'YOUR_KEY' || upper == 'YOUR_REAL_KEY') return false;
    if (upper.contains('YOUR_')) return false;
    return true;
  }

  static final Map<String, String> _coursePlaylistById = <String, String>{
    'course_1': _course1,
    'course_2': _course2,
    'course_3': _course3,
    'course_4': _course4,
    'course_5': _course5,
    'course_6': _course6,
    'course_7': _course7,
    'course_8': _course8,
  };

  static final Map<String, String> _categoryPlaylistByName = <String, String>{
    'Programming': _programming,
    'Design': _design,
    'Backend': _backend,
    'Computer Science': _computerScience,
    'Product': _product,
    'Testing': _testing,
  };
}
