// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandName => 'Rocket Market';

  @override
  String get brandTagline => 'Online supermarket: fresh produce and groceries to your door';

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navCart => 'Cart';

  @override
  String get navOrders => 'Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get navSearch => 'Search';

  @override
  String get navMain => 'Main navigation';

  @override
  String get headerSearchPlaceholder => 'Search products or categories…';

  @override
  String get headerLogin => 'Sign in';

  @override
  String get headerSwitchLang => 'عربي';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong. Please try again.';

  @override
  String get commonAll => 'All';

  @override
  String get commonOptional => 'optional';

  @override
  String get commonFree => 'Free';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonStartShopping => 'Start shopping';

  @override
  String get commonGoHome => 'Back to home';

  @override
  String get unitsKg => 'kg';

  @override
  String get unitsG => 'g';

  @override
  String get productAdd => 'Add';

  @override
  String get productAddToCart => 'Add to cart';

  @override
  String get productOutOfStock => 'Out of stock';

  @override
  String productOff(String n) {
    return '$n% off';
  }

  @override
  String get productInStock => 'In stock';

  @override
  String productLowStock(String n) {
    return 'Only $n left';
  }

  @override
  String get productDescription => 'About this product';

  @override
  String get productRelated => 'You might also like';

  @override
  String get productChooseSize => 'Choose size';

  @override
  String get productMaxReached => 'You\'ve reached the maximum for this item';

  @override
  String get productBrand => 'Brand';

  @override
  String productOfferEnds(String date) {
    return 'Offer ends $date';
  }

  @override
  String get productWeightNote => 'Weight is approximate. You pay for the actual weight when your order is packed.';

  @override
  String get productPerKg => 'per kg';

  @override
  String get productInCart => 'In cart';

  @override
  String get productDecrease => 'Decrease quantity';

  @override
  String get productIncrease => 'Increase quantity';

  @override
  String get productRemove => 'Remove from cart';

  @override
  String get productDeliveryPromise => 'Arrives today if you order before 9 PM';

  @override
  String get productNotFound => 'This product doesn\'t exist';

  @override
  String get sortLabel => 'Sort by';

  @override
  String get sortRecommended => 'Recommended';

  @override
  String get sortBest => 'Best sellers';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get sortDiscount => 'Biggest discount';

  @override
  String get sortNewest => 'Newest';

  @override
  String get homeCategories => 'Shop by category';

  @override
  String get homeExpress => 'Delivery in 60 minutes';

  @override
  String homeFreeDelivery(String amount) {
    return 'Free delivery over $amount';
  }

  @override
  String get homePickup => 'Pick up at Rocket Mall';

  @override
  String categoryCount(String n) {
    return '$n products';
  }

  @override
  String get categoryEmpty => 'No products here right now.';

  @override
  String get categoryAllCategories => 'All categories';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchPopular => 'Popular searches';

  @override
  String searchResults(String n, String q) {
    return '$n results for “$q”';
  }

  @override
  String searchNoResults(String q) {
    return 'No results for “$q”';
  }

  @override
  String get searchTryAnother => 'Try another word or browse the categories.';

  @override
  String get searchSubmit => 'Search';

  @override
  String get searchInCategory => 'Category';

  @override
  String get searchTagsOffer => 'Deals of the week';

  @override
  String get searchTagsBest => 'Best sellers';

  @override
  String get searchTagsNew => 'New arrivals';

  @override
  String get cartTitle => 'Your cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyHint => 'Add fresh produce and household essentials, and we\'ll bring them to you fast.';

  @override
  String cartItems(String n) {
    return '$n items';
  }

  @override
  String get cartSummary => 'Order summary';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartSavings => 'You save';

  @override
  String get cartCoupon => 'Promo code';

  @override
  String get cartCouponPlaceholder => 'Have a promo code?';

  @override
  String get cartApply => 'Apply';

  @override
  String get cartRemoveCoupon => 'Remove code';

  @override
  String get cartDelivery => 'Delivery';

  @override
  String get cartDeliveryFrom => 'Delivery (from)';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartVatIncluded => 'Prices include VAT';

  @override
  String get cartCheckout => 'Checkout';

  @override
  String get cartLoginToCheckout => 'Sign in to checkout';

  @override
  String cartFreeDeliveryLeft(String amount) {
    return 'Add $amount more for free delivery';
  }

  @override
  String get cartFreeDeliveryReached => 'Nice! Your delivery is free';

  @override
  String get cartRemoveUnavailable => 'Remove unavailable items';

  @override
  String get cartUnavailable => 'Currently unavailable';

  @override
  String get cartPriceUpdated => 'Price changed';

  @override
  String get cartOfflineEstimate => 'You\'re offline. Prices are estimates until you reconnect.';

  @override
  String get cartClear => 'Empty cart';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutMethod => 'How do you want it?';

  @override
  String get checkoutDelivery => 'Home delivery';

  @override
  String get checkoutPickup => 'Pick up at Rocket Mall';

  @override
  String get checkoutAddress => 'Delivery address';

  @override
  String get checkoutAddAddress => 'Add a new address';

  @override
  String get checkoutNoAddresses => 'No saved addresses yet. Add one so we can deliver to you.';

  @override
  String get checkoutTime => 'Delivery time';

  @override
  String get checkoutPickupTime => 'Pickup time';

  @override
  String get checkoutExpress => 'Express delivery in 60–90 minutes';

  @override
  String get checkoutToday => 'Today';

  @override
  String get checkoutTomorrow => 'Tomorrow';

  @override
  String get checkoutFull => 'Full';

  @override
  String get checkoutPayment => 'Payment method';

  @override
  String get checkoutCod => 'Cash on delivery';

  @override
  String checkoutCodUnavailable(String amount) {
    return 'Cash on delivery is available for orders up to $amount';
  }

  @override
  String get checkoutCard => 'Credit / debit card';

  @override
  String get checkoutCardHint => 'Visa or Mastercard, secured with 3D Secure';

  @override
  String get checkoutWallet => 'Mobile wallet';

  @override
  String get checkoutWalletHint => 'Vodafone Cash and other wallets';

  @override
  String get checkoutNotes => 'Notes for the courier';

  @override
  String get checkoutNotesPlaceholder => 'e.g. Ring the bell once';

  @override
  String get checkoutPlaceOrder => 'Place order';

  @override
  String checkoutPayNow(String amount) {
    return 'Pay $amount';
  }

  @override
  String get checkoutPlacing => 'Placing your order…';

  @override
  String get checkoutChooseAddress => 'Choose a delivery address';

  @override
  String get checkoutChooseSlot => 'Choose a time slot';

  @override
  String get checkoutEmptyCart => 'Your cart is empty. Add some products first.';

  @override
  String get addressLabel => 'Address name';

  @override
  String get addressLabelPlaceholder => 'Home, Work…';

  @override
  String get addressZone => 'Governorate';

  @override
  String get addressArea => 'Area';

  @override
  String get addressStreet => 'Street';

  @override
  String get addressBuilding => 'Building no.';

  @override
  String get addressFloor => 'Floor';

  @override
  String get addressApartment => 'Apartment';

  @override
  String get addressNotes => 'Landmark';

  @override
  String get addressUseLocation => 'Use my current location';

  @override
  String get addressLocating => 'Finding your location…';

  @override
  String get addressLocated => 'Location pinned';

  @override
  String get addressLocationFailed => 'We couldn\'t get your location';

  @override
  String get addressSave => 'Save address';

  @override
  String get addressDefault => 'Default';

  @override
  String addressDeliveryFee(String amount) {
    return 'Delivery fee $amount';
  }

  @override
  String get authTitle => 'Welcome to Rocket';

  @override
  String get authSubtitle => 'Sign in with your mobile number to checkout and track your orders.';

  @override
  String get authPhone => 'Mobile number';

  @override
  String get authPhonePlaceholder => '01xxxxxxxxx';

  @override
  String get authSendCode => 'Send verification code';

  @override
  String get authCodeTitle => 'Enter the code';

  @override
  String authCodeSent(String phone) {
    return 'We sent a 4-digit code to $phone';
  }

  @override
  String get authCode => 'Verification code';

  @override
  String get authVerify => 'Verify';

  @override
  String get authResend => 'Resend code';

  @override
  String authResendIn(String s) {
    return 'You can request a new code in ${s}s';
  }

  @override
  String get authChangePhone => 'Change number';

  @override
  String get authDemoHint => 'Demo build: the code is 1234';

  @override
  String get authNameTitle => 'What should we call you?';

  @override
  String get authName => 'Your name';

  @override
  String get authFinish => 'Start shopping';

  @override
  String get authSkip => 'Later';

  @override
  String get authInvalidPhone => 'Enter a valid 11-digit Egyptian mobile number';

  @override
  String get accountTitle => 'My account';

  @override
  String get accountProfile => 'Profile';

  @override
  String get accountName => 'Name';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountAddresses => 'My addresses';

  @override
  String get accountOrders => 'My orders';

  @override
  String get accountLogout => 'Sign out';

  @override
  String get accountSaved => 'Profile saved';

  @override
  String get accountGuest => 'Guest';

  @override
  String get ordersTitle => 'My orders';

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String get ordersEmptyHint => 'Your first order will show up here so you can track it live.';

  @override
  String ordersNumber(String n) {
    return 'Order $n';
  }

  @override
  String ordersItems(String n) {
    return '$n items';
  }

  @override
  String get ordersPlaced => 'Order confirmed! We\'re starting on it now.';

  @override
  String get ordersPaid => 'Payment successful. Your order is confirmed.';

  @override
  String get ordersTracking => 'Order tracking';

  @override
  String get ordersReorder => 'Order again';

  @override
  String get ordersReordered => 'Items added to your cart';

  @override
  String get ordersDeliverTo => 'Delivering to';

  @override
  String get ordersPickupFrom => 'Pick up from';

  @override
  String get ordersSlot => 'Time';

  @override
  String get ordersPaymentMethod => 'Payment';

  @override
  String get ordersDetails => 'Order details';

  @override
  String get ordersStatusPendingPayment => 'Awaiting payment';

  @override
  String get ordersStatusPlaced => 'Order received';

  @override
  String get ordersStatusConfirmed => 'Confirmed';

  @override
  String get ordersStatusPreparing => 'Being prepared';

  @override
  String get ordersStatusOutForDelivery => 'Out for delivery';

  @override
  String get ordersStatusReadyForPickup => 'Ready for pickup';

  @override
  String get ordersStatusDelivered => 'Delivered';

  @override
  String get ordersStatusCollected => 'Collected';

  @override
  String get ordersStatusCancelled => 'Cancelled';

  @override
  String get paymentTitle => 'Test payment gateway';

  @override
  String get paymentHint => 'This page stands in for the real payment gateway. Pick the result you want to test.';

  @override
  String get paymentAmount => 'Amount due';

  @override
  String get paymentSuccess => 'Pay successfully';

  @override
  String get paymentFail => 'Simulate a failed payment';

  @override
  String get paymentFailed => 'Payment didn\'t go through. The order was cancelled and your cart is unchanged.';

  @override
  String get paymentBackToCart => 'Back to cart';

  @override
  String get pwaOffline => 'You\'re offline. Showing the last saved data.';

  @override
  String get errorNotFound => 'This page doesn\'t exist';

  @override
  String get errorGeneric => 'Something unexpected happened';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountSignInPrompt => 'Sign in to see your orders and addresses.';

  @override
  String accountVersion(String version) {
    return 'Version $version';
  }

  @override
  String get paymentExternal => 'Finish paying in the page that opened, then come back to the app.';

  @override
  String get paymentCheckStatus => 'Check order status';

  @override
  String get errorNetwork => 'No internet connection. Try again.';

  @override
  String get errorSessionExpired => 'Your session expired. Please sign in again.';

  @override
  String get productQuantity => 'Quantity';

  @override
  String get sortApply => 'Sort results';

  @override
  String searchSeeResults(String q) {
    return 'See all results for “$q”';
  }

  @override
  String get addressTitle => 'New address';

  @override
  String checkoutSummaryItems(String n) {
    return '$n items';
  }

  @override
  String get ordersPullToRefresh => 'Pull down to refresh the status';

  @override
  String get chatTitle => 'Chat with us';

  @override
  String get chatSubtitle => 'The Rocket team replies within minutes';

  @override
  String get chatOpen => 'Chat with us';

  @override
  String get chatHelp => 'Need help?';

  @override
  String get chatHelpOrder => 'Question about this order? Chat with us';

  @override
  String get chatWelcome =>
      'Hi there! 👋 Ask us anything about your orders or our products and the Rocket team will get back to you shortly.';

  @override
  String get chatHours => 'We reply every day from 9 am to 11 pm.';

  @override
  String get chatPlaceholder => 'Write a message…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatPhoto => 'Send a photo';

  @override
  String get chatRemovePhoto => 'Remove photo';

  @override
  String chatAboutOrder(String number) {
    return 'About order $number';
  }

  @override
  String get chatRemoveOrder => 'Remove order';

  @override
  String get chatSupport => 'Rocket team';

  @override
  String get chatYou => 'You';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatSent => 'Sent';

  @override
  String get chatSeen => 'Seen';

  @override
  String get chatFailed => 'Not sent. Tap to try again';

  @override
  String get chatOlder => 'Older messages';

  @override
  String get chatClosed => 'This conversation has ended. Send a message if you need anything else.';

  @override
  String get chatNewMessages => 'New messages';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String chatUnread(String number) {
    return '$number new message(s)';
  }

  @override
  String get chatPhotoMessage => '📷 Photo';

  @override
  String get chatPhotoGallery => 'Choose from photos';

  @override
  String get chatPhotoCamera => 'Take a photo';

  @override
  String get chatPhotoFailed => 'Couldn\'t open that photo.';

  @override
  String get chatViewPhoto => 'Photo';
}
