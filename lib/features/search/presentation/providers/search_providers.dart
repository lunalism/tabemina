import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../home/data/datasources/places_api_datasource.dart';
import '../../../home/data/models/nearby_restaurant.dart';

/// Cuisine filter for the Search tab's chip row.
///
/// Stored as a tiny enum (not a string) so the UI / API mapping can drift
/// independently — labels are localized via [filterChipLabel] and the API
/// primary-type names come from [filterPrimaryType].
enum SearchFilter { all, ramen, sushi, izakaya, cafe, yakiniku }

/// Selected chip. Resets on app start, not persisted — filters feel cheap
/// enough that "remember my last filter" would be more confusing than
/// useful.
class SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() => SearchFilter.all;

  void select(SearchFilter value) => state = value;
}

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilter>(
  SearchFilterNotifier.new,
);

/// Debounced text-search query. The search bar writes here after the user
/// pauses typing for 500ms (see `SearchBarOverlay`).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final _placesDatasourceProvider = Provider<PlacesApiDatasource>(
  (ref) => PlacesApiDatasource(),
);

/// Restaurants shown in the Search tab — either nearby (no query) or text
/// search (≥ 2 chars), narrowed by the active filter chip.
///
/// Watches the locale + filter + query + user position so any change auto-
/// refetches. Returns an empty list when there's no fix *and* no query so
/// the UI shows its empty state rather than a stuck spinner.
final searchResultsProvider =
    FutureProvider<List<NearbyRestaurant>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final filter = ref.watch(searchFilterProvider);
  final locale = ref.watch(appLocaleProvider);
  final position = await ref.watch(currentPositionProvider.future);
  final datasource = ref.read(_placesDatasourceProvider);

  if (query.length >= 2) {
    return datasource.searchByText(
      query: query,
      languageCode: locale.languageCode,
      includedType: filterPrimaryType(filter),
      biasLatitude: position?.latitude,
      biasLongitude: position?.longitude,
    );
  }

  // No / too-short query → nearby. Need a position for the bias circle.
  if (position == null) return const [];

  if (filter == SearchFilter.all) {
    return datasource.searchNearbyRestaurants(
      latitude: position.latitude,
      longitude: position.longitude,
      languageCode: locale.languageCode,
    );
  }
  return datasource.searchNearbyByType(
    latitude: position.latitude,
    longitude: position.longitude,
    primaryType: filterPrimaryType(filter)!,
    languageCode: locale.languageCode,
  );
});

/// Maps a chip to the Places API `primaryType` / `includedType` string.
///
/// `all` returns `null` so the caller skips the field entirely — Google
/// doesn't recognize a generic "restaurant" includedType in text search the
/// same way it does in nearby search, so dropping the field matches the
/// user's intent best.
///
/// Note: Google's Places (New) taxonomy has no `izakaya` or `yakiniku`
/// primary type, so we use the closest neighbours (`bar` and
/// `barbecue_restaurant`). Worth revisiting if Google adds the JP-specific
/// types later.
String? filterPrimaryType(SearchFilter filter) {
  switch (filter) {
    case SearchFilter.all:
      return null;
    case SearchFilter.ramen:
      return 'ramen_restaurant';
    case SearchFilter.sushi:
      return 'sushi_restaurant';
    case SearchFilter.izakaya:
      return 'bar';
    case SearchFilter.cafe:
      return 'cafe';
    case SearchFilter.yakiniku:
      return 'barbecue_restaurant';
  }
}

/// Localized chip label.
String filterChipLabel(SearchFilter filter, String languageCode) {
  switch (languageCode) {
    case 'ja':
      switch (filter) {
        case SearchFilter.all:
          return 'すべて';
        case SearchFilter.ramen:
          return 'ラーメン';
        case SearchFilter.sushi:
          return '寿司';
        case SearchFilter.izakaya:
          return '居酒屋';
        case SearchFilter.cafe:
          return 'カフェ';
        case SearchFilter.yakiniku:
          return '焼肉';
      }
    case 'ko':
      switch (filter) {
        case SearchFilter.all:
          return '전체';
        case SearchFilter.ramen:
          return '라멘';
        case SearchFilter.sushi:
          return '스시';
        case SearchFilter.izakaya:
          return '이자카야';
        case SearchFilter.cafe:
          return '카페';
        case SearchFilter.yakiniku:
          return '야키니쿠';
      }
    case 'en':
    default:
      switch (filter) {
        case SearchFilter.all:
          return 'All';
        case SearchFilter.ramen:
          return 'Ramen';
        case SearchFilter.sushi:
          return 'Sushi';
        case SearchFilter.izakaya:
          return 'Izakaya';
        case SearchFilter.cafe:
          return 'Cafe';
        case SearchFilter.yakiniku:
          return 'Yakiniku';
      }
  }
}

/// Localized search-bar placeholder.
String searchPlaceholder(String languageCode) {
  switch (languageCode) {
    case 'ja':
      return 'レストラン、エリアを検索...';
    case 'ko':
      return '식당, 지역 검색...';
    case 'en':
    default:
      return 'Search restaurants, areas...';
  }
}

/// Localized sheet header strings used when toggling between "Near you" and
/// the search-results state.
class SearchHeaderLabels {
  const SearchHeaderLabels({
    required this.nearYou,
    required this.results,
    required this.found,
    required this.filter,
    required this.noResults,
    required this.tryDifferent,
    required this.clearSearch,
  });

  final String nearYou;
  final String results;
  final String Function(int n) found;
  final String filter;
  final String noResults;
  final String tryDifferent;
  final String clearSearch;

  static SearchHeaderLabels of(String code) {
    switch (code) {
      case 'ja':
        return SearchHeaderLabels(
          nearYou: '近くのお店',
          results: '検索結果',
          found: (n) => '$n件',
          filter: 'フィルター',
          noResults: '結果が見つかりませんでした',
          tryDifferent: '別のキーワードでお試しください',
          clearSearch: '検索をクリア',
        );
      case 'ko':
        return SearchHeaderLabels(
          nearYou: '근처',
          results: '검색 결과',
          found: (n) => '$n개',
          filter: '필터',
          noResults: '검색 결과가 없습니다',
          tryDifferent: '다른 키워드로 시도해 보세요',
          clearSearch: '검색 지우기',
        );
      case 'en':
      default:
        return SearchHeaderLabels(
          nearYou: 'Near you',
          results: 'Results',
          found: (n) => '$n found',
          filter: 'Filter',
          noResults: 'No results found',
          tryDifferent: 'Try different keywords',
          clearSearch: 'Clear search',
        );
    }
  }
}
