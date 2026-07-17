import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/connectivity_providers.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/services/connectivity_service.dart';
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

/// User-driven override of the nearby-search center.
///
/// Default `null` → the search uses the user's GPS position. When the user
/// pans the map and taps "Search this area", the screen writes the new map
/// center here so [searchResultsProvider] refetches around that point
/// instead of the user's position. The GPS button clears the override.
class SearchCenterOverrideNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void setCenter(LatLng center) => state = center;
  void clear() => state = null;
}

final searchCenterOverrideProvider =
    NotifierProvider<SearchCenterOverrideNotifier, LatLng?>(
  SearchCenterOverrideNotifier.new,
);

final _placesDatasourceProvider = Provider<PlacesApiDatasource>(
  (ref) => PlacesApiDatasource(),
);

/// True when the nearby search couldn't run for lack of a location: no text
/// query, no "search this area" override, and the one-shot GPS fetch resolved
/// to `null` (services off / permission denied).
///
/// [searchResultsProvider] returns an empty list in that case, which is
/// indistinguishable from "nearby genuinely has nothing" — the sheet watches
/// this flag to show a "location unavailable" message instead of the
/// misleading "no restaurants nearby".
final searchLocationUnavailableProvider = Provider<bool>((ref) {
  if (ref.watch(searchQueryProvider).trim().length >= 2) return false;
  if (ref.watch(searchCenterOverrideProvider) != null) return false;
  final position = ref.watch(currentPositionProvider);
  return position.hasValue && position.value == null;
});

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

  // Offline (B-3-3-2): skip the Places query entirely — no network call, no
  // search analytics. `watch`ing connectivity means coming back online re-runs
  // this and search resumes normally; the UI shows a passive offline state.
  if (ref.watch(connectivityStatusProvider).asData?.value ==
      NetworkStatus.offline) {
    return const [];
  }

  final position = await ref.watch(currentPositionProvider.future);
  final override = ref.watch(searchCenterOverrideProvider);
  final datasource = ref.read(_placesDatasourceProvider);

  final List<NearbyRestaurant> results;
  if (query.length >= 2) {
    // Text search keeps the user's position as the bias — overrides only
    // matter for "Search this area" which is a nearby-mode affordance.
    results = await datasource.searchByText(
      query: query,
      languageCode: locale.languageCode,
      includedType: filterPrimaryType(filter),
      biasLatitude: position?.latitude,
      biasLongitude: position?.longitude,
    );
  } else {
    // No / too-short query → nearby. Use the override when set, else the
    // user's GPS position.
    final lat = override?.latitude ?? position?.latitude;
    final lng = override?.longitude ?? position?.longitude;
    // No fix and no query → nothing actually ran; don't log a search event.
    if (lat == null || lng == null) return const [];

    results = filter == SearchFilter.all
        ? await datasource.searchNearbyRestaurants(
            latitude: lat,
            longitude: lng,
            languageCode: locale.languageCode,
          )
        : await datasource.searchNearbyByType(
            latitude: lat,
            longitude: lng,
            primaryType: filterPrimaryType(filter)!,
            languageCode: locale.languageCode,
          );
  }

  // A real search executed. `currentPositionProvider` is a one-shot cached
  // fetch and the query is debounced, so each rebuild here is a genuine,
  // user-driven execution — not a per-keystroke or per-GPS-tick fire. The raw
  // query text is never logged; only whether one was present.
  ref.read(analyticsEventsProvider).search(
        hasTextQuery: query.isNotEmpty,
        filters: filter.name,
        resultCount: results.length,
      );
  return results;
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

/// Localized "Search this area" pill label.
String searchThisAreaLabel(String languageCode) {
  switch (languageCode) {
    case 'ja':
      return 'このエリアで検索';
    case 'ko':
      return '이 지역에서 검색';
    case 'en':
    default:
      return 'Search this area';
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
    required this.noResults,
    required this.tryDifferent,
    required this.clearSearch,
    required this.noNearby,
    required this.locationUnavailable,
  });

  final String nearYou;
  final String results;
  final String Function(int n) found;
  final String noResults;
  final String tryDifferent;
  final String clearSearch;
  final String noNearby;
  final String locationUnavailable;

  static SearchHeaderLabels of(String code) {
    switch (code) {
      case 'ja':
        return SearchHeaderLabels(
          nearYou: '近くのお店',
          results: '検索結果',
          found: (n) => '$n件',
          noResults: '結果が見つかりませんでした',
          tryDifferent: '別のキーワードでお試しください',
          clearSearch: '検索をクリア',
          noNearby: '近くにお店が見つかりませんでした',
          locationUnavailable: '位置情報を取得できません。位置情報の設定をご確認ください',
        );
      case 'ko':
        return SearchHeaderLabels(
          nearYou: '근처',
          results: '검색 결과',
          found: (n) => '$n개',
          noResults: '검색 결과가 없습니다',
          tryDifferent: '다른 키워드로 시도해 보세요',
          clearSearch: '검색 지우기',
          noNearby: '근처에 식당을 찾지 못했습니다',
          locationUnavailable: '위치 정보를 사용할 수 없습니다. 위치 권한을 확인해 주세요',
        );
      case 'en':
      default:
        return SearchHeaderLabels(
          nearYou: 'Near you',
          results: 'Results',
          found: (n) => '$n found',
          noResults: 'No results found',
          tryDifferent: 'Try different keywords',
          clearSearch: 'Clear search',
          noNearby: 'No restaurants nearby',
          locationUnavailable:
              'Location unavailable — check location permission',
        );
    }
  }
}
