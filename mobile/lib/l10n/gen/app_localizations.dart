import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @brandName.
  ///
  /// In ar, this message translates to:
  /// **'روكت ماركت'**
  String get brandName;

  /// No description provided for @brandTagline.
  ///
  /// In ar, this message translates to:
  /// **'سوبر ماركت أونلاين: خضار وفاكهة وبقالة لحد باب البيت'**
  String get brandTagline;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navCategories.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get navCategories;

  /// No description provided for @navCart.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get navCart;

  /// No description provided for @navOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get navOrders;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navAccount;

  /// No description provided for @navSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get navSearch;

  /// No description provided for @navMain.
  ///
  /// In ar, this message translates to:
  /// **'التنقل الرئيسي'**
  String get navMain;

  /// No description provided for @headerSearchPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على منتج أو قسم…'**
  String get headerSearchPlaceholder;

  /// No description provided for @headerLogin.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get headerLogin;

  /// No description provided for @headerSwitchLang.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get headerSwitchLang;

  /// No description provided for @commonSeeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get commonSeeAll;

  /// No description provided for @commonLoadMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get commonLoadMore;

  /// No description provided for @commonBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة، حاول تاني.'**
  String get commonError;

  /// No description provided for @commonAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get commonAll;

  /// No description provided for @commonOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get commonOptional;

  /// No description provided for @commonFree.
  ///
  /// In ar, this message translates to:
  /// **'مجانًا'**
  String get commonFree;

  /// No description provided for @commonEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get commonEdit;

  /// No description provided for @commonContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get commonContinue;

  /// No description provided for @commonStartShopping.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسوق'**
  String get commonStartShopping;

  /// No description provided for @commonGoHome.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للرئيسية'**
  String get commonGoHome;

  /// No description provided for @unitsKg.
  ///
  /// In ar, this message translates to:
  /// **'كجم'**
  String get unitsKg;

  /// No description provided for @unitsG.
  ///
  /// In ar, this message translates to:
  /// **'جم'**
  String get unitsG;

  /// No description provided for @productAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get productAdd;

  /// No description provided for @productAddToCart.
  ///
  /// In ar, this message translates to:
  /// **'أضف للسلة'**
  String get productAddToCart;

  /// No description provided for @productOutOfStock.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get productOutOfStock;

  /// No description provided for @productOff.
  ///
  /// In ar, this message translates to:
  /// **'خصم {n}%'**
  String productOff(String n);

  /// No description provided for @productInStock.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get productInStock;

  /// No description provided for @productLowStock.
  ///
  /// In ar, this message translates to:
  /// **'باقي {n} بس'**
  String productLowStock(String n);

  /// No description provided for @productDescription.
  ///
  /// In ar, this message translates to:
  /// **'عن المنتج'**
  String get productDescription;

  /// No description provided for @productRelated.
  ///
  /// In ar, this message translates to:
  /// **'منتجات ممكن تعجبك'**
  String get productRelated;

  /// No description provided for @productChooseSize.
  ///
  /// In ar, this message translates to:
  /// **'اختار الحجم'**
  String get productChooseSize;

  /// No description provided for @productMaxReached.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للحد الأقصى لكمية المنتج ده'**
  String get productMaxReached;

  /// No description provided for @productBrand.
  ///
  /// In ar, this message translates to:
  /// **'الماركة'**
  String get productBrand;

  /// No description provided for @productOfferEnds.
  ///
  /// In ar, this message translates to:
  /// **'العرض لحد {date}'**
  String productOfferEnds(String date);

  /// No description provided for @productWeightNote.
  ///
  /// In ar, this message translates to:
  /// **'الوزن تقريبي. هتدفع حسب الوزن الفعلي وقت التجهيز.'**
  String get productWeightNote;

  /// No description provided for @productPerKg.
  ///
  /// In ar, this message translates to:
  /// **'للكيلو'**
  String get productPerKg;

  /// No description provided for @productInCart.
  ///
  /// In ar, this message translates to:
  /// **'في السلة'**
  String get productInCart;

  /// No description provided for @productDecrease.
  ///
  /// In ar, this message translates to:
  /// **'قلل الكمية'**
  String get productDecrease;

  /// No description provided for @productIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زود الكمية'**
  String get productIncrease;

  /// No description provided for @productRemove.
  ///
  /// In ar, this message translates to:
  /// **'شيل من السلة'**
  String get productRemove;

  /// No description provided for @productDeliveryPromise.
  ///
  /// In ar, this message translates to:
  /// **'يوصلك النهارده لو طلبت قبل 9 بالليل'**
  String get productDeliveryPromise;

  /// No description provided for @productNotFound.
  ///
  /// In ar, this message translates to:
  /// **'المنتج ده مش موجود'**
  String get productNotFound;

  /// No description provided for @sortLabel.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب'**
  String get sortLabel;

  /// No description provided for @sortRecommended.
  ///
  /// In ar, this message translates to:
  /// **'المقترح'**
  String get sortRecommended;

  /// No description provided for @sortBest.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر مبيعًا'**
  String get sortBest;

  /// No description provided for @sortPriceAsc.
  ///
  /// In ar, this message translates to:
  /// **'السعر: من الأقل'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In ar, this message translates to:
  /// **'السعر: من الأعلى'**
  String get sortPriceDesc;

  /// No description provided for @sortDiscount.
  ///
  /// In ar, this message translates to:
  /// **'أعلى خصم'**
  String get sortDiscount;

  /// No description provided for @sortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get sortNewest;

  /// No description provided for @homeCategories.
  ///
  /// In ar, this message translates to:
  /// **'تسوق حسب القسم'**
  String get homeCategories;

  /// No description provided for @homeExpress.
  ///
  /// In ar, this message translates to:
  /// **'توصيل خلال 60 دقيقة'**
  String get homeExpress;

  /// No description provided for @homeFreeDelivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل مجاني فوق {amount}'**
  String homeFreeDelivery(String amount);

  /// No description provided for @homePickup.
  ///
  /// In ar, this message translates to:
  /// **'استلم من روكت مول'**
  String get homePickup;

  /// No description provided for @categoryCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} منتج'**
  String categoryCount(String n);

  /// No description provided for @categoryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش منتجات هنا دلوقتي.'**
  String get categoryEmpty;

  /// No description provided for @categoryAllCategories.
  ///
  /// In ar, this message translates to:
  /// **'كل الأقسام'**
  String get categoryAllCategories;

  /// No description provided for @searchTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get searchTitle;

  /// No description provided for @searchRecent.
  ///
  /// In ar, this message translates to:
  /// **'عمليات البحث الأخيرة'**
  String get searchRecent;

  /// No description provided for @searchClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get searchClear;

  /// No description provided for @searchPopular.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر بحثًا'**
  String get searchPopular;

  /// No description provided for @searchResults.
  ///
  /// In ar, this message translates to:
  /// **'{n} نتيجة لـ «{q}»'**
  String searchResults(String n, String q);

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتائج لـ «{q}»'**
  String searchNoResults(String q);

  /// No description provided for @searchTryAnother.
  ///
  /// In ar, this message translates to:
  /// **'جرب كلمة تانية أو تصفح الأقسام.'**
  String get searchTryAnother;

  /// No description provided for @searchSubmit.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get searchSubmit;

  /// No description provided for @searchInCategory.
  ///
  /// In ar, this message translates to:
  /// **'قسم'**
  String get searchInCategory;

  /// No description provided for @searchTagsOffer.
  ///
  /// In ar, this message translates to:
  /// **'عروض الأسبوع'**
  String get searchTagsOffer;

  /// No description provided for @searchTagsBest.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر مبيعًا'**
  String get searchTagsBest;

  /// No description provided for @searchTagsNew.
  ///
  /// In ar, this message translates to:
  /// **'وصل حديثًا'**
  String get searchTagsNew;

  /// No description provided for @cartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلة المشتريات'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'سلتك فاضية'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ضيف خضار وفاكهة وكل طلبات البيت، وهنوصلهالك بسرعة.'**
  String get cartEmptyHint;

  /// No description provided for @cartItems.
  ///
  /// In ar, this message translates to:
  /// **'{n} منتج'**
  String cartItems(String n);

  /// No description provided for @cartSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطلب'**
  String get cartSummary;

  /// No description provided for @cartSubtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get cartSubtotal;

  /// No description provided for @cartSavings.
  ///
  /// In ar, this message translates to:
  /// **'وفرت'**
  String get cartSavings;

  /// No description provided for @cartCoupon.
  ///
  /// In ar, this message translates to:
  /// **'كود الخصم'**
  String get cartCoupon;

  /// No description provided for @cartCouponPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'عندك كود خصم؟'**
  String get cartCouponPlaceholder;

  /// No description provided for @cartApply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get cartApply;

  /// No description provided for @cartRemoveCoupon.
  ///
  /// In ar, this message translates to:
  /// **'شيل الكود'**
  String get cartRemoveCoupon;

  /// No description provided for @cartDelivery.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل'**
  String get cartDelivery;

  /// No description provided for @cartDeliveryFrom.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل (يبدأ من)'**
  String get cartDeliveryFrom;

  /// No description provided for @cartTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get cartTotal;

  /// No description provided for @cartVatIncluded.
  ///
  /// In ar, this message translates to:
  /// **'الأسعار شاملة ضريبة القيمة المضافة'**
  String get cartVatIncluded;

  /// No description provided for @cartCheckout.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get cartCheckout;

  /// No description provided for @cartLoginToCheckout.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخول وكمل الطلب'**
  String get cartLoginToCheckout;

  /// No description provided for @cartFreeDeliveryLeft.
  ///
  /// In ar, this message translates to:
  /// **'ضيف {amount} كمان والتوصيل يبقى مجاني'**
  String cartFreeDeliveryLeft(String amount);

  /// No description provided for @cartFreeDeliveryReached.
  ///
  /// In ar, this message translates to:
  /// **'مبروك! التوصيل مجاني لطلبك'**
  String get cartFreeDeliveryReached;

  /// No description provided for @cartRemoveUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'شيل المنتجات غير المتوفرة'**
  String get cartRemoveUnavailable;

  /// No description provided for @cartUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'مش متوفر دلوقتي'**
  String get cartUnavailable;

  /// No description provided for @cartPriceUpdated.
  ///
  /// In ar, this message translates to:
  /// **'السعر اتغير'**
  String get cartPriceUpdated;

  /// No description provided for @cartOfflineEstimate.
  ///
  /// In ar, this message translates to:
  /// **'أنت أوفلاين: الأسعار تقريبية لحد ما النت يرجع.'**
  String get cartOfflineEstimate;

  /// No description provided for @cartClear.
  ///
  /// In ar, this message translates to:
  /// **'فضّي السلة'**
  String get cartClear;

  /// No description provided for @checkoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get checkoutTitle;

  /// No description provided for @checkoutMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الاستلام'**
  String get checkoutMethod;

  /// No description provided for @checkoutDelivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل للبيت'**
  String get checkoutDelivery;

  /// No description provided for @checkoutPickup.
  ///
  /// In ar, this message translates to:
  /// **'استلام من روكت مول'**
  String get checkoutPickup;

  /// No description provided for @checkoutAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get checkoutAddress;

  /// No description provided for @checkoutAddAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get checkoutAddAddress;

  /// No description provided for @checkoutNoAddresses.
  ///
  /// In ar, this message translates to:
  /// **'مفيش عناوين محفوظة. ضيف عنوانك عشان نوصلك.'**
  String get checkoutNoAddresses;

  /// No description provided for @checkoutTime.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد التوصيل'**
  String get checkoutTime;

  /// No description provided for @checkoutPickupTime.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد الاستلام'**
  String get checkoutPickupTime;

  /// No description provided for @checkoutExpress.
  ///
  /// In ar, this message translates to:
  /// **'توصيل سريع خلال 60–90 دقيقة'**
  String get checkoutExpress;

  /// No description provided for @checkoutToday.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get checkoutToday;

  /// No description provided for @checkoutTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'بكرة'**
  String get checkoutTomorrow;

  /// No description provided for @checkoutFull.
  ///
  /// In ar, this message translates to:
  /// **'محجوز'**
  String get checkoutFull;

  /// No description provided for @checkoutPayment.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get checkoutPayment;

  /// No description provided for @checkoutCod.
  ///
  /// In ar, this message translates to:
  /// **'كاش عند الاستلام'**
  String get checkoutCod;

  /// No description provided for @checkoutCodUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الدفع كاش متاح للطلبات لحد {amount}'**
  String checkoutCodUnavailable(String amount);

  /// No description provided for @checkoutCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة بنكية'**
  String get checkoutCard;

  /// No description provided for @checkoutCardHint.
  ///
  /// In ar, this message translates to:
  /// **'فيزا أو ماستركارد، دفع آمن بـ 3D Secure'**
  String get checkoutCardHint;

  /// No description provided for @checkoutWallet.
  ///
  /// In ar, this message translates to:
  /// **'محفظة إلكترونية'**
  String get checkoutWallet;

  /// No description provided for @checkoutWalletHint.
  ///
  /// In ar, this message translates to:
  /// **'فودافون كاش وغيرها'**
  String get checkoutWalletHint;

  /// No description provided for @checkoutNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات للمندوب'**
  String get checkoutNotes;

  /// No description provided for @checkoutNotesPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا: رن الجرس مرة واحدة'**
  String get checkoutNotesPlaceholder;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب'**
  String get checkoutPlaceOrder;

  /// No description provided for @checkoutPayNow.
  ///
  /// In ar, this message translates to:
  /// **'ادفع {amount}'**
  String checkoutPayNow(String amount);

  /// No description provided for @checkoutPlacing.
  ///
  /// In ar, this message translates to:
  /// **'جاري تأكيد الطلب…'**
  String get checkoutPlacing;

  /// No description provided for @checkoutChooseAddress.
  ///
  /// In ar, this message translates to:
  /// **'اختار عنوان التوصيل'**
  String get checkoutChooseAddress;

  /// No description provided for @checkoutChooseSlot.
  ///
  /// In ar, this message translates to:
  /// **'اختار ميعاد'**
  String get checkoutChooseSlot;

  /// No description provided for @checkoutEmptyCart.
  ///
  /// In ar, this message translates to:
  /// **'سلتك فاضية، ضيف منتجات الأول.'**
  String get checkoutEmptyCart;

  /// No description provided for @addressLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان'**
  String get addressLabel;

  /// No description provided for @addressLabelPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'البيت، الشغل…'**
  String get addressLabelPlaceholder;

  /// No description provided for @addressZone.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get addressZone;

  /// No description provided for @addressArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get addressArea;

  /// No description provided for @addressStreet.
  ///
  /// In ar, this message translates to:
  /// **'الشارع'**
  String get addressStreet;

  /// No description provided for @addressBuilding.
  ///
  /// In ar, this message translates to:
  /// **'رقم العمارة'**
  String get addressBuilding;

  /// No description provided for @addressFloor.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get addressFloor;

  /// No description provided for @addressApartment.
  ///
  /// In ar, this message translates to:
  /// **'الشقة'**
  String get addressApartment;

  /// No description provided for @addressNotes.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة'**
  String get addressNotes;

  /// No description provided for @addressUseLocation.
  ///
  /// In ar, this message translates to:
  /// **'حدد موقعي الحالي'**
  String get addressUseLocation;

  /// No description provided for @addressLocating.
  ///
  /// In ar, this message translates to:
  /// **'بنحدد موقعك…'**
  String get addressLocating;

  /// No description provided for @addressLocated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد الموقع'**
  String get addressLocated;

  /// No description provided for @addressLocationFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحدد موقعك'**
  String get addressLocationFailed;

  /// No description provided for @addressSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان'**
  String get addressSave;

  /// No description provided for @addressDefault.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get addressDefault;

  /// No description provided for @addressDeliveryFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل {amount}'**
  String addressDeliveryFee(String amount);

  /// No description provided for @authTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيك في روكت'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخول برقم موبايلك عشان تكمل طلبك وتتابعه.'**
  String get authSubtitle;

  /// No description provided for @authPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get authPhone;

  /// No description provided for @authPhonePlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'01xxxxxxxxx'**
  String get authPhonePlaceholder;

  /// No description provided for @authSendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعت كود التحقق'**
  String get authSendCode;

  /// No description provided for @authCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود التحقق'**
  String get authCodeTitle;

  /// No description provided for @authCodeSent.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا كود من 4 أرقام على {phone}'**
  String authCodeSent(String phone);

  /// No description provided for @authCode.
  ///
  /// In ar, this message translates to:
  /// **'كود التحقق'**
  String get authCode;

  /// No description provided for @authVerify.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get authVerify;

  /// No description provided for @authResend.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الكود تاني'**
  String get authResend;

  /// No description provided for @authResendIn.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تطلب كود جديد بعد {s} ثانية'**
  String authResendIn(String s);

  /// No description provided for @authChangePhone.
  ///
  /// In ar, this message translates to:
  /// **'غير الرقم'**
  String get authChangePhone;

  /// No description provided for @authDemoHint.
  ///
  /// In ar, this message translates to:
  /// **'نسخة تجريبية: الكود هو 1234'**
  String get authDemoHint;

  /// No description provided for @authNameTitle.
  ///
  /// In ar, this message translates to:
  /// **'نتعرف عليك؟'**
  String get authNameTitle;

  /// No description provided for @authName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get authName;

  /// No description provided for @authFinish.
  ///
  /// In ar, this message translates to:
  /// **'يلا نتسوق'**
  String get authFinish;

  /// No description provided for @authSkip.
  ///
  /// In ar, this message translates to:
  /// **'بعدين'**
  String get authSkip;

  /// No description provided for @authInvalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم موبايل مصري صحيح (11 رقم)'**
  String get authInvalidPhone;

  /// No description provided for @accountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get accountTitle;

  /// No description provided for @accountProfile.
  ///
  /// In ar, this message translates to:
  /// **'بياناتي'**
  String get accountProfile;

  /// No description provided for @accountName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get accountName;

  /// No description provided for @accountEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get accountEmail;

  /// No description provided for @accountLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get accountLanguage;

  /// No description provided for @accountAddresses.
  ///
  /// In ar, this message translates to:
  /// **'عناويني'**
  String get accountAddresses;

  /// No description provided for @accountOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get accountOrders;

  /// No description provided for @accountLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get accountLogout;

  /// No description provided for @accountSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت البيانات'**
  String get accountSaved;

  /// No description provided for @accountGuest.
  ///
  /// In ar, this message translates to:
  /// **'زائر'**
  String get accountGuest;

  /// No description provided for @ordersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مطلبتش حاجة'**
  String get ordersEmpty;

  /// No description provided for @ordersEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'أول طلب ليك هيظهر هنا وتقدر تتابعه لحظة بلحظة.'**
  String get ordersEmptyHint;

  /// No description provided for @ordersNumber.
  ///
  /// In ar, this message translates to:
  /// **'طلب رقم {n}'**
  String ordersNumber(String n);

  /// No description provided for @ordersItems.
  ///
  /// In ar, this message translates to:
  /// **'{n} منتج'**
  String ordersItems(String n);

  /// No description provided for @ordersPlaced.
  ///
  /// In ar, this message translates to:
  /// **'اتأكد طلبك! هنبدأ نجهزه دلوقتي.'**
  String get ordersPlaced;

  /// No description provided for @ordersPaid.
  ///
  /// In ar, this message translates to:
  /// **'تم الدفع بنجاح وطلبك اتأكد.'**
  String get ordersPaid;

  /// No description provided for @ordersTracking.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الطلب'**
  String get ordersTracking;

  /// No description provided for @ordersReorder.
  ///
  /// In ar, this message translates to:
  /// **'اطلبه تاني'**
  String get ordersReorder;

  /// No description provided for @ordersReordered.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات اتضافت للسلة'**
  String get ordersReordered;

  /// No description provided for @ordersDeliverTo.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل إلى'**
  String get ordersDeliverTo;

  /// No description provided for @ordersPickupFrom.
  ///
  /// In ar, this message translates to:
  /// **'الاستلام من'**
  String get ordersPickupFrom;

  /// No description provided for @ordersSlot.
  ///
  /// In ar, this message translates to:
  /// **'الميعاد'**
  String get ordersSlot;

  /// No description provided for @ordersPaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get ordersPaymentMethod;

  /// No description provided for @ordersDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get ordersDetails;

  /// No description provided for @ordersStatusPendingPayment.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار الدفع'**
  String get ordersStatusPendingPayment;

  /// No description provided for @ordersStatusPlaced.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام الطلب'**
  String get ordersStatusPlaced;

  /// No description provided for @ordersStatusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم التأكيد'**
  String get ordersStatusConfirmed;

  /// No description provided for @ordersStatusPreparing.
  ///
  /// In ar, this message translates to:
  /// **'بيتجهز'**
  String get ordersStatusPreparing;

  /// No description provided for @ordersStatusOutForDelivery.
  ///
  /// In ar, this message translates to:
  /// **'مع المندوب'**
  String get ordersStatusOutForDelivery;

  /// No description provided for @ordersStatusReadyForPickup.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للاستلام'**
  String get ordersStatusReadyForPickup;

  /// No description provided for @ordersStatusDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get ordersStatusDelivered;

  /// No description provided for @ordersStatusCollected.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستلام'**
  String get ordersStatusCollected;

  /// No description provided for @ordersStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'اتلغى'**
  String get ordersStatusCancelled;

  /// No description provided for @paymentTitle.
  ///
  /// In ar, this message translates to:
  /// **'بوابة الدفع التجريبية'**
  String get paymentTitle;

  /// No description provided for @paymentHint.
  ///
  /// In ar, this message translates to:
  /// **'دي صفحة تجريبية بدل بوابة الدفع الحقيقية. اختار النتيجة اللي عايز تجربها.'**
  String get paymentHint;

  /// No description provided for @paymentAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المطلوب'**
  String get paymentAmount;

  /// No description provided for @paymentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'ادفع بنجاح'**
  String get paymentSuccess;

  /// No description provided for @paymentFail.
  ///
  /// In ar, this message translates to:
  /// **'جرب فشل الدفع'**
  String get paymentFail;

  /// No description provided for @paymentFailed.
  ///
  /// In ar, this message translates to:
  /// **'الدفع مكملش. الطلب اتلغى وسلتك لسه زي ما هي.'**
  String get paymentFailed;

  /// No description provided for @paymentBackToCart.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للسلة'**
  String get paymentBackToCart;

  /// No description provided for @pwaOffline.
  ///
  /// In ar, this message translates to:
  /// **'أنت أوفلاين دلوقتي، وبنعرضلك آخر بيانات محفوظة.'**
  String get pwaOffline;

  /// No description provided for @errorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة دي مش موجودة'**
  String get errorNotFound;

  /// No description provided for @errorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة غير متوقعة'**
  String get errorGeneric;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @accountSignInPrompt.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخول عشان تتابع طلباتك وعناوينك.'**
  String get accountSignInPrompt;

  /// No description provided for @accountVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String accountVersion(String version);

  /// No description provided for @paymentExternal.
  ///
  /// In ar, this message translates to:
  /// **'كمل الدفع في الصفحة اللي اتفتحت، وبعدين ارجع للتطبيق.'**
  String get paymentExternal;

  /// No description provided for @paymentCheckStatus.
  ///
  /// In ar, this message translates to:
  /// **'شوف حالة الطلب'**
  String get paymentCheckStatus;

  /// No description provided for @errorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالنت. جرب تاني.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة، سجل دخول تاني.'**
  String get errorSessionExpired;

  /// No description provided for @productQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get productQuantity;

  /// No description provided for @sortApply.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب النتائج'**
  String get sortApply;

  /// No description provided for @searchSeeResults.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل النتائج لـ «{q}»'**
  String searchSeeResults(String q);

  /// No description provided for @addressTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان جديد'**
  String get addressTitle;

  /// No description provided for @checkoutSummaryItems.
  ///
  /// In ar, this message translates to:
  /// **'{n} منتج'**
  String checkoutSummaryItems(String n);

  /// No description provided for @ordersPullToRefresh.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لتحديث حالة الطلب'**
  String get ordersPullToRefresh;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
