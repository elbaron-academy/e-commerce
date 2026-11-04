"""All API routes under /api/v1/. Storefront first, then the staff API under admin/."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from apps.accounts import admin_api as accounts_admin
from apps.accounts import views as accounts
from apps.catalog import admin_api as catalog_admin
from apps.catalog import views as catalog
from apps.notifications import admin_api as notifications_admin
from apps.orders import admin_api as orders_admin
from apps.orders import views as orders
from apps.payments import views as payments
from apps.promotions import admin_api as promotions_admin
from apps.shipping import admin_api as shipping_admin
from apps.shipping import views as shipping

router = DefaultRouter()
router.register("addresses", accounts.AddressViewSet, basename="address")
router.register("orders", orders.OrderViewSet, basename="order")

admin_router = DefaultRouter()
admin_router.register("categories", catalog_admin.CategoryAdminViewSet, basename="admin-category")
admin_router.register("brands", catalog_admin.BrandAdminViewSet, basename="admin-brand")
admin_router.register("vendors", catalog_admin.VendorAdminViewSet, basename="admin-vendor")
admin_router.register("products", catalog_admin.ProductAdminViewSet, basename="admin-product")
admin_router.register("product-images", catalog_admin.ProductImageAdminViewSet, basename="admin-product-image")
admin_router.register("variants", catalog_admin.VariantAdminViewSet, basename="admin-variant")
admin_router.register("banners", catalog_admin.BannerAdminViewSet, basename="admin-banner")
admin_router.register("home-sections", catalog_admin.HomeSectionAdminViewSet, basename="admin-home-section")
admin_router.register("orders", orders_admin.OrderAdminViewSet, basename="admin-order")
admin_router.register("customers", accounts_admin.CustomerAdminViewSet, basename="admin-customer")
admin_router.register("staff", accounts_admin.StaffUserAdminViewSet, basename="admin-staff")
admin_router.register("roles", accounts_admin.RoleAdminViewSet, basename="admin-role")
admin_router.register("coupons", promotions_admin.CouponAdminViewSet, basename="admin-coupon")
admin_router.register("zones", shipping_admin.ZoneAdminViewSet, basename="admin-zone")
admin_router.register("delivery-windows", shipping_admin.DeliveryWindowAdminViewSet, basename="admin-delivery-window")
admin_router.register("notifications", notifications_admin.NotificationLogAdminViewSet, basename="admin-notification")

admin_urls = [
    path("auth/login/", accounts.StaffLoginView.as_view(), name="admin-login"),
    path("dashboard/", orders_admin.DashboardView.as_view(), name="admin-dashboard"),
    path("settings/", shipping_admin.StoreSettingsAdminView.as_view(), name="admin-settings"),
    path("permissions/", accounts_admin.PermissionListView.as_view(), name="admin-permissions"),
    path("", include(admin_router.urls)),
]

urlpatterns = [
    # Catalog
    path("home/", catalog.HomeView.as_view(), name="home"),
    path("categories/", catalog.CategoryTreeView.as_view(), name="category-tree"),
    path("categories/<slug:slug>/products/", catalog.CategoryProductsView.as_view(), name="category-products"),
    path("products/", catalog.ProductListView.as_view(), name="product-list"),
    path("products/<slug:slug>/", catalog.ProductDetailView.as_view(), name="product-detail"),
    path("search/", catalog.SearchView.as_view(), name="search"),
    path("search/autocomplete/", catalog.AutocompleteView.as_view(), name="autocomplete"),
    # Delivery
    path("delivery/info/", shipping.DeliveryInfoView.as_view(), name="delivery-info"),
    path("delivery/slots/", shipping.DeliverySlotsView.as_view(), name="delivery-slots"),
    # Cart
    path("cart/quote/", orders.QuoteView.as_view(), name="cart-quote"),
    # Account
    path("auth/otp/send/", accounts.OTPSendView.as_view(), name="otp-send"),
    path("auth/otp/verify/", accounts.OTPVerifyView.as_view(), name="otp-verify"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("me/", accounts.MeView.as_view(), name="me"),
    path("me/phone/", accounts.ChangePhoneView.as_view(), name="me-phone"),
    # Payments
    path("payments/webhook/<slug:provider>/", payments.PaymentWebhookView.as_view(), name="payment-webhook"),
    path("payments/mock/confirm/", payments.MockPaymentConfirmView.as_view(), name="payment-mock-confirm"),
    # Staff API
    path("admin/", include(admin_urls)),
    path("", include(router.urls)),
]
