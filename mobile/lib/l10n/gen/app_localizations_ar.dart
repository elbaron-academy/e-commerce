// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get brandName => 'روكت ماركت';

  @override
  String get brandTagline => 'سوبر ماركت أونلاين: خضار وفاكهة وبقالة لحد باب البيت';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCategories => 'الأقسام';

  @override
  String get navCart => 'السلة';

  @override
  String get navOrders => 'طلباتي';

  @override
  String get navAccount => 'حسابي';

  @override
  String get navSearch => 'بحث';

  @override
  String get navMain => 'التنقل الرئيسي';

  @override
  String get headerSearchPlaceholder => 'دوّر على منتج أو قسم…';

  @override
  String get headerLogin => 'دخول';

  @override
  String get headerSwitchLang => 'English';

  @override
  String get commonSeeAll => 'عرض الكل';

  @override
  String get commonLoadMore => 'عرض المزيد';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonRetry => 'حاول تاني';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonLoading => 'جاري التحميل…';

  @override
  String get commonError => 'حصلت مشكلة، حاول تاني.';

  @override
  String get commonAll => 'الكل';

  @override
  String get commonOptional => 'اختياري';

  @override
  String get commonFree => 'مجانًا';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonStartShopping => 'ابدأ التسوق';

  @override
  String get commonGoHome => 'الرجوع للرئيسية';

  @override
  String get unitsKg => 'كجم';

  @override
  String get unitsG => 'جم';

  @override
  String get productAdd => 'أضف';

  @override
  String get productAddToCart => 'أضف للسلة';

  @override
  String get productOutOfStock => 'غير متوفر';

  @override
  String productOff(String n) {
    return 'خصم $n%';
  }

  @override
  String get productInStock => 'متوفر';

  @override
  String productLowStock(String n) {
    return 'باقي $n بس';
  }

  @override
  String get productDescription => 'عن المنتج';

  @override
  String get productRelated => 'منتجات ممكن تعجبك';

  @override
  String get productChooseSize => 'اختار الحجم';

  @override
  String get productMaxReached => 'وصلت للحد الأقصى لكمية المنتج ده';

  @override
  String get productBrand => 'الماركة';

  @override
  String productOfferEnds(String date) {
    return 'العرض لحد $date';
  }

  @override
  String get productWeightNote => 'الوزن تقريبي. هتدفع حسب الوزن الفعلي وقت التجهيز.';

  @override
  String get productPerKg => 'للكيلو';

  @override
  String get productInCart => 'في السلة';

  @override
  String get productDecrease => 'قلل الكمية';

  @override
  String get productIncrease => 'زود الكمية';

  @override
  String get productRemove => 'شيل من السلة';

  @override
  String get productDeliveryPromise => 'يوصلك النهارده لو طلبت قبل 9 بالليل';

  @override
  String get productNotFound => 'المنتج ده مش موجود';

  @override
  String get sortLabel => 'ترتيب حسب';

  @override
  String get sortRecommended => 'المقترح';

  @override
  String get sortBest => 'الأكثر مبيعًا';

  @override
  String get sortPriceAsc => 'السعر: من الأقل';

  @override
  String get sortPriceDesc => 'السعر: من الأعلى';

  @override
  String get sortDiscount => 'أعلى خصم';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get homeCategories => 'تسوق حسب القسم';

  @override
  String get homeExpress => 'توصيل خلال 60 دقيقة';

  @override
  String homeFreeDelivery(String amount) {
    return 'توصيل مجاني فوق $amount';
  }

  @override
  String get homePickup => 'استلم من روكت مول';

  @override
  String categoryCount(String n) {
    return '$n منتج';
  }

  @override
  String get categoryEmpty => 'مفيش منتجات هنا دلوقتي.';

  @override
  String get categoryAllCategories => 'كل الأقسام';

  @override
  String get searchTitle => 'البحث';

  @override
  String get searchRecent => 'عمليات البحث الأخيرة';

  @override
  String get searchClear => 'مسح';

  @override
  String get searchPopular => 'الأكثر بحثًا';

  @override
  String searchResults(String n, String q) {
    return '$n نتيجة لـ «$q»';
  }

  @override
  String searchNoResults(String q) {
    return 'مفيش نتائج لـ «$q»';
  }

  @override
  String get searchTryAnother => 'جرب كلمة تانية أو تصفح الأقسام.';

  @override
  String get searchSubmit => 'بحث';

  @override
  String get searchInCategory => 'قسم';

  @override
  String get searchTagsOffer => 'عروض الأسبوع';

  @override
  String get searchTagsBest => 'الأكثر مبيعًا';

  @override
  String get searchTagsNew => 'وصل حديثًا';

  @override
  String get cartTitle => 'سلة المشتريات';

  @override
  String get cartEmpty => 'سلتك فاضية';

  @override
  String get cartEmptyHint => 'ضيف خضار وفاكهة وكل طلبات البيت، وهنوصلهالك بسرعة.';

  @override
  String cartItems(String n) {
    return '$n منتج';
  }

  @override
  String get cartSummary => 'ملخص الطلب';

  @override
  String get cartSubtotal => 'المجموع الفرعي';

  @override
  String get cartSavings => 'وفرت';

  @override
  String get cartCoupon => 'كود الخصم';

  @override
  String get cartCouponPlaceholder => 'عندك كود خصم؟';

  @override
  String get cartApply => 'تطبيق';

  @override
  String get cartRemoveCoupon => 'شيل الكود';

  @override
  String get cartDelivery => 'التوصيل';

  @override
  String get cartDeliveryFrom => 'التوصيل (يبدأ من)';

  @override
  String get cartTotal => 'الإجمالي';

  @override
  String get cartVatIncluded => 'الأسعار شاملة ضريبة القيمة المضافة';

  @override
  String get cartCheckout => 'إتمام الطلب';

  @override
  String get cartLoginToCheckout => 'سجل دخول وكمل الطلب';

  @override
  String cartFreeDeliveryLeft(String amount) {
    return 'ضيف $amount كمان والتوصيل يبقى مجاني';
  }

  @override
  String get cartFreeDeliveryReached => 'مبروك! التوصيل مجاني لطلبك';

  @override
  String get cartRemoveUnavailable => 'شيل المنتجات غير المتوفرة';

  @override
  String get cartUnavailable => 'مش متوفر دلوقتي';

  @override
  String get cartPriceUpdated => 'السعر اتغير';

  @override
  String get cartOfflineEstimate => 'أنت أوفلاين: الأسعار تقريبية لحد ما النت يرجع.';

  @override
  String get cartClear => 'فضّي السلة';

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get checkoutMethod => 'طريقة الاستلام';

  @override
  String get checkoutDelivery => 'توصيل للبيت';

  @override
  String get checkoutPickup => 'استلام من روكت مول';

  @override
  String get checkoutAddress => 'عنوان التوصيل';

  @override
  String get checkoutAddAddress => 'إضافة عنوان جديد';

  @override
  String get checkoutNoAddresses => 'مفيش عناوين محفوظة. ضيف عنوانك عشان نوصلك.';

  @override
  String get checkoutTime => 'ميعاد التوصيل';

  @override
  String get checkoutPickupTime => 'ميعاد الاستلام';

  @override
  String get checkoutExpress => 'توصيل سريع خلال 60–90 دقيقة';

  @override
  String get checkoutToday => 'النهارده';

  @override
  String get checkoutTomorrow => 'بكرة';

  @override
  String get checkoutFull => 'محجوز';

  @override
  String get checkoutPayment => 'طريقة الدفع';

  @override
  String get checkoutCod => 'كاش عند الاستلام';

  @override
  String checkoutCodUnavailable(String amount) {
    return 'الدفع كاش متاح للطلبات لحد $amount';
  }

  @override
  String get checkoutCard => 'بطاقة بنكية';

  @override
  String get checkoutCardHint => 'فيزا أو ماستركارد، دفع آمن بـ 3D Secure';

  @override
  String get checkoutWallet => 'محفظة إلكترونية';

  @override
  String get checkoutWalletHint => 'فودافون كاش وغيرها';

  @override
  String get checkoutNotes => 'ملاحظات للمندوب';

  @override
  String get checkoutNotesPlaceholder => 'مثلًا: رن الجرس مرة واحدة';

  @override
  String get checkoutPlaceOrder => 'تأكيد الطلب';

  @override
  String checkoutPayNow(String amount) {
    return 'ادفع $amount';
  }

  @override
  String get checkoutPlacing => 'جاري تأكيد الطلب…';

  @override
  String get checkoutChooseAddress => 'اختار عنوان التوصيل';

  @override
  String get checkoutChooseSlot => 'اختار ميعاد';

  @override
  String get checkoutEmptyCart => 'سلتك فاضية، ضيف منتجات الأول.';

  @override
  String get addressLabel => 'اسم العنوان';

  @override
  String get addressLabelPlaceholder => 'البيت، الشغل…';

  @override
  String get addressZone => 'المحافظة';

  @override
  String get addressArea => 'المنطقة';

  @override
  String get addressStreet => 'الشارع';

  @override
  String get addressBuilding => 'رقم العمارة';

  @override
  String get addressFloor => 'الدور';

  @override
  String get addressApartment => 'الشقة';

  @override
  String get addressNotes => 'علامة مميزة';

  @override
  String get addressUseLocation => 'حدد موقعي الحالي';

  @override
  String get addressLocating => 'بنحدد موقعك…';

  @override
  String get addressLocated => 'تم تحديد الموقع';

  @override
  String get addressLocationFailed => 'مقدرناش نحدد موقعك';

  @override
  String get addressSave => 'حفظ العنوان';

  @override
  String get addressDefault => 'الافتراضي';

  @override
  String addressDeliveryFee(String amount) {
    return 'رسوم التوصيل $amount';
  }

  @override
  String get authTitle => 'أهلًا بيك في روكت';

  @override
  String get authSubtitle => 'سجل دخول برقم موبايلك عشان تكمل طلبك وتتابعه.';

  @override
  String get authPhone => 'رقم الموبايل';

  @override
  String get authPhonePlaceholder => '01xxxxxxxxx';

  @override
  String get authSendCode => 'ابعت كود التحقق';

  @override
  String get authCodeTitle => 'اكتب كود التحقق';

  @override
  String authCodeSent(String phone) {
    return 'بعتنا كود من 4 أرقام على $phone';
  }

  @override
  String get authCode => 'كود التحقق';

  @override
  String get authVerify => 'تأكيد';

  @override
  String get authResend => 'ابعت الكود تاني';

  @override
  String authResendIn(String s) {
    return 'تقدر تطلب كود جديد بعد $s ثانية';
  }

  @override
  String get authChangePhone => 'غير الرقم';

  @override
  String get authDemoHint => 'نسخة تجريبية: الكود هو 1234';

  @override
  String get authNameTitle => 'نتعرف عليك؟';

  @override
  String get authName => 'اسمك';

  @override
  String get authFinish => 'يلا نتسوق';

  @override
  String get authSkip => 'بعدين';

  @override
  String get authInvalidPhone => 'اكتب رقم موبايل مصري صحيح (11 رقم)';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get accountProfile => 'بياناتي';

  @override
  String get accountName => 'الاسم';

  @override
  String get accountEmail => 'البريد الإلكتروني';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get accountAddresses => 'عناويني';

  @override
  String get accountOrders => 'طلباتي';

  @override
  String get accountLogout => 'تسجيل الخروج';

  @override
  String get accountSaved => 'اتحفظت البيانات';

  @override
  String get accountGuest => 'زائر';

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String get ordersEmpty => 'لسه مطلبتش حاجة';

  @override
  String get ordersEmptyHint => 'أول طلب ليك هيظهر هنا وتقدر تتابعه لحظة بلحظة.';

  @override
  String ordersNumber(String n) {
    return 'طلب رقم $n';
  }

  @override
  String ordersItems(String n) {
    return '$n منتج';
  }

  @override
  String get ordersPlaced => 'اتأكد طلبك! هنبدأ نجهزه دلوقتي.';

  @override
  String get ordersPaid => 'تم الدفع بنجاح وطلبك اتأكد.';

  @override
  String get ordersTracking => 'متابعة الطلب';

  @override
  String get ordersReorder => 'اطلبه تاني';

  @override
  String get ordersReordered => 'المنتجات اتضافت للسلة';

  @override
  String get ordersDeliverTo => 'التوصيل إلى';

  @override
  String get ordersPickupFrom => 'الاستلام من';

  @override
  String get ordersSlot => 'الميعاد';

  @override
  String get ordersPaymentMethod => 'الدفع';

  @override
  String get ordersDetails => 'تفاصيل الطلب';

  @override
  String get ordersStatusPendingPayment => 'في انتظار الدفع';

  @override
  String get ordersStatusPlaced => 'تم استلام الطلب';

  @override
  String get ordersStatusConfirmed => 'تم التأكيد';

  @override
  String get ordersStatusPreparing => 'بيتجهز';

  @override
  String get ordersStatusOutForDelivery => 'مع المندوب';

  @override
  String get ordersStatusReadyForPickup => 'جاهز للاستلام';

  @override
  String get ordersStatusDelivered => 'تم التوصيل';

  @override
  String get ordersStatusCollected => 'تم الاستلام';

  @override
  String get ordersStatusCancelled => 'اتلغى';

  @override
  String get paymentTitle => 'بوابة الدفع التجريبية';

  @override
  String get paymentHint => 'دي صفحة تجريبية بدل بوابة الدفع الحقيقية. اختار النتيجة اللي عايز تجربها.';

  @override
  String get paymentAmount => 'المبلغ المطلوب';

  @override
  String get paymentSuccess => 'ادفع بنجاح';

  @override
  String get paymentFail => 'جرب فشل الدفع';

  @override
  String get paymentFailed => 'الدفع مكملش. الطلب اتلغى وسلتك لسه زي ما هي.';

  @override
  String get paymentBackToCart => 'الرجوع للسلة';

  @override
  String get pwaOffline => 'أنت أوفلاين دلوقتي، وبنعرضلك آخر بيانات محفوظة.';

  @override
  String get errorNotFound => 'الصفحة دي مش موجودة';

  @override
  String get errorGeneric => 'حصلت مشكلة غير متوقعة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountSignInPrompt => 'سجل دخول عشان تتابع طلباتك وعناوينك.';

  @override
  String accountVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get paymentExternal => 'كمل الدفع في الصفحة اللي اتفتحت، وبعدين ارجع للتطبيق.';

  @override
  String get paymentCheckStatus => 'شوف حالة الطلب';

  @override
  String get errorNetwork => 'مفيش اتصال بالنت. جرب تاني.';

  @override
  String get errorSessionExpired => 'انتهت الجلسة، سجل دخول تاني.';

  @override
  String get productQuantity => 'الكمية';

  @override
  String get sortApply => 'ترتيب النتائج';

  @override
  String searchSeeResults(String q) {
    return 'عرض كل النتائج لـ «$q»';
  }

  @override
  String get addressTitle => 'عنوان جديد';

  @override
  String checkoutSummaryItems(String n) {
    return '$n منتج';
  }

  @override
  String get ordersPullToRefresh => 'اسحب لتحديث حالة الطلب';

  @override
  String get chatTitle => 'كلّمنا';

  @override
  String get chatSubtitle => 'فريق روكت بيرد عليك في دقايق';

  @override
  String get chatOpen => 'كلّمنا';

  @override
  String get chatHelp => 'محتاج مساعدة؟';

  @override
  String get chatHelpOrder => 'عندك سؤال عن الطلب ده؟ كلّمنا';

  @override
  String get chatWelcome => 'أهلاً بيك! 👋 ابعتلنا سؤالك عن أي طلب أو منتج، وفريق روكت هيرد عليك في أسرع وقت.';

  @override
  String get chatHours => 'بنرد من 9 الصبح لـ 11 بالليل كل يوم.';

  @override
  String get chatPlaceholder => 'اكتب رسالتك…';

  @override
  String get chatSend => 'ابعت';

  @override
  String get chatPhoto => 'ابعت صورة';

  @override
  String get chatRemovePhoto => 'شيل الصورة';

  @override
  String chatAboutOrder(String number) {
    return 'بخصوص طلب $number';
  }

  @override
  String get chatRemoveOrder => 'شيل الطلب';

  @override
  String get chatSupport => 'فريق روكت';

  @override
  String get chatYou => 'إنت';

  @override
  String get chatSending => 'بيتبعت…';

  @override
  String get chatSent => 'اتبعتت';

  @override
  String get chatSeen => 'اتشافت';

  @override
  String get chatFailed => 'متبعتتش. دوس عشان تحاول تاني';

  @override
  String get chatOlder => 'رسائل أقدم';

  @override
  String get chatClosed => 'المحادثة دي خلصت. ابعت رسالة لو محتاج حاجة تانية.';

  @override
  String get chatNewMessages => 'رسائل جديدة';

  @override
  String get chatToday => 'النهارده';

  @override
  String get chatYesterday => 'امبارح';

  @override
  String chatUnread(String number) {
    return '$number رسالة جديدة';
  }

  @override
  String get chatPhotoMessage => '📷 صورة';

  @override
  String get chatPhotoGallery => 'من الصور';

  @override
  String get chatPhotoCamera => 'صوّر دلوقتي';

  @override
  String get chatPhotoFailed => 'مقدرناش نفتح الصورة.';

  @override
  String get chatViewPhoto => 'الصورة';
}
