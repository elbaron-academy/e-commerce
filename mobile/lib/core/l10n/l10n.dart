import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import '../network/api_exception.dart';
import '../utils/formatters.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  Fmt get fmt => Fmt(lang, l10n);
}

/// A message to show for any error.
String errorText(Object error, AppLocalizations l10n) {
  if (error is ApiException) {
    if (error.isNetwork) return l10n.errorNetwork;
    if (error.message.isNotEmpty) return error.message;
  }
  return l10n.commonError;
}

String sortLabel(AppLocalizations l10n, String sort) => switch (sort) {
  'best' => l10n.sortBest,
  'price_asc' => l10n.sortPriceAsc,
  'price_desc' => l10n.sortPriceDesc,
  'discount' => l10n.sortDiscount,
  'newest' => l10n.sortNewest,
  _ => l10n.sortRecommended,
};

String tagTitle(AppLocalizations l10n, String tag) => switch (tag) {
  'offer' => l10n.searchTagsOffer,
  'best' => l10n.searchTagsBest,
  'new' => l10n.searchTagsNew,
  _ => l10n.searchTitle,
};

String orderStatusLabel(AppLocalizations l10n, String status, {required bool pickup}) => switch (status) {
  'pending_payment' => l10n.ordersStatusPendingPayment,
  'placed' => l10n.ordersStatusPlaced,
  'confirmed' => l10n.ordersStatusConfirmed,
  'preparing' => l10n.ordersStatusPreparing,
  'out_for_delivery' => l10n.ordersStatusOutForDelivery,
  'ready_for_pickup' => l10n.ordersStatusReadyForPickup,
  'delivered' => pickup ? l10n.ordersStatusCollected : l10n.ordersStatusDelivered,
  'cancelled' => l10n.ordersStatusCancelled,
  _ => status,
};
