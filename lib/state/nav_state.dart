import 'package:flutter/foundation.dart';

/// A date/type picked on a search bar, handed to the search tab.
class SearchRequest {
  final String? date;
  final String? type;

  /// Plain "open search" (bottom-nav circle / header icon): drop any type
  /// filter left over from a home section link, keep the chosen date.
  final bool showAll;
  const SearchRequest({this.date, this.type, this.showAll = false});
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
  /// With neither, the tab opens on all trips (no type filter).
  static void openSearch({String? date, String? type}) {
    searchRequest.value = date != null || type != null
        ? SearchRequest(date: date, type: type)
        // Not const: a new instance so the
        // ValueNotifier fires every time.
        : SearchRequest(showAll: true);
    tab.value = searchTab;
  }
}
