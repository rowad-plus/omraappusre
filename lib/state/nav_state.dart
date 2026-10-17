import 'package:flutter/foundation.dart';

/// A date/type picked on a search bar, handed to the search tab.
class SearchRequest {
  final String? date;
  final String? type;
  const SearchRequest({this.date, this.type});
}

/// Selected bottom-nav tab of [AppShell]. Lives outside the shell so any
/// screen can switch tabs by setting the index.
class NavState {
  static final tab = ValueNotifier<int>(0);

  /// Index of the search (trip results) tab — after the 4 regular tabs.
  static const searchTab = 4;

  /// The last search-bar request; the search tab applies it when it changes.
  static final searchRequest = ValueNotifier<SearchRequest?>(null);

  /// Switches to the search tab, optionally applying a picked date/type.
  static void openSearch({String? date, String? type}) {
    if (date != null || type != null) {
      searchRequest.value = SearchRequest(date: date, type: type);
    }
    tab.value = searchTab;
  }
}
