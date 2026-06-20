import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../../../shared/widgets/restaurant_row_skeleton.dart';
import '../../../home/data/datasources/places_api_datasource.dart';
import '../../../home/data/models/nearby_restaurant.dart';
import '../../domain/models/review_draft.dart';

/// In-screen restaurant picker shown when the write-review flow is opened
/// from the tab bar with no pre-selected place.
///
/// Owns its own debounced query controller — keeping it private to this
/// widget means the screen state doesn't have to manage another timer.
class RestaurantSearchSelect extends ConsumerStatefulWidget {
  const RestaurantSearchSelect({
    super.key,
    required this.onSelected,
    required this.l,
  });

  final void Function(ReviewRestaurant) onSelected;
  final RestaurantSearchLabels l;

  @override
  ConsumerState<RestaurantSearchSelect> createState() =>
      _RestaurantSearchSelectState();
}

class _RestaurantSearchSelectState
    extends ConsumerState<RestaurantSearchSelect> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  Future<List<NearbyRestaurant>>? _resultsFuture;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _resultsFuture = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _resultsFuture = _runQuery(value.trim()));
    });
  }

  Future<List<NearbyRestaurant>> _runQuery(String query) async {
    final locale = ref.read(appLocaleProvider);
    final position = await ref.read(currentPositionProvider.future);
    final datasource = PlacesApiDatasource();
    return datasource.searchByText(
      query: query,
      languageCode: locale.languageCode,
      biasLatitude: position?.latitude,
      biasLongitude: position?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: c.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.borderPrimary, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: widget.l.placeholder,
                        hintStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          if (_resultsFuture != null)
            FutureBuilder<List<NearbyRestaurant>>(
              future: _resultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
                    child: RestaurantRowSkeletonList(),
                  );
                }
                if (snapshot.hasError) {
                  return _Hint(text: widget.l.errorHint);
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return _Hint(text: widget.l.noResults);
                }
                return Column(
                  children: [
                    for (final r in items)
                      _ResultRow(
                        item: r,
                        onTap: () => widget.onSelected(_toReview(r)),
                      ),
                  ],
                );
              },
            )
          else
            _Hint(text: widget.l.emptyHint),
        ],
      ),
    );
  }

  ReviewRestaurant _toReview(NearbyRestaurant r) {
    return ReviewRestaurant(
      placeId: r.id,
      name: r.name,
      primaryType: r.primaryType,
      photoUrl:
          r.photoName != null ? PlacesApiDatasource.photoUrl(r.photoName!) : null,
    );
  }
}

class RestaurantSearchLabels {
  const RestaurantSearchLabels({
    required this.placeholder,
    required this.emptyHint,
    required this.noResults,
    required this.errorHint,
  });

  final String placeholder;
  final String emptyHint;
  final String noResults;
  final String errorHint;
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item, required this.onTap});

  final NearbyRestaurant item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceSm,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: item.photoName != null
                    ? FadeInNetworkImage(
                        url: PlacesApiDatasource.photoUrl(item.photoName!),
                        headers: kPlacesPhotoHeaders,
                        errorPlaceholder: _ph(c),
                      )
                    : _ph(c),
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.primaryType != null)
                        item.primaryType!.replaceAll('_', ' '),
                      if (item.formattedAddress != null) item.formattedAddress!,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph(AppColors c) {
    return Container(
      color: c.bgSkeleton,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, size: 18, color: c.textTertiary),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceLg,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
