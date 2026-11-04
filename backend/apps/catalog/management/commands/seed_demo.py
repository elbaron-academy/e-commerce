"""
Loads the demo store: 8 categories, 66 products, banners, home rows, delivery
zones and windows, store rules and coupons. Safe to run again (updates in place).

    python manage.py seed_demo
    python manage.py seed_demo --admin-phone 01000000000 --admin-password 'S3cure-pass'
"""

import json
from datetime import time, timedelta
from decimal import Decimal
from pathlib import Path

from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.catalog.models import Banner, Brand, Category, HomeSection, Product, Variant
from apps.promotions.models import Coupon
from apps.shipping.models import DeliveryWindow, StoreSettings, Zone

FIXTURE = Path(__file__).resolve().parents[2] / "fixtures" / "demo.json"


class Command(BaseCommand):
    help = "Loads the Rocket Market demo catalog and store settings."

    def add_arguments(self, parser):
        parser.add_argument("--admin-phone", help="Create/update a superuser with this phone")
        parser.add_argument("--admin-password", help="Password for --admin-phone")
        parser.add_argument("--if-empty", action="store_true", help="Only seed when there are no products yet")

    @transaction.atomic
    def handle(self, *args, **options):
        if options["if_empty"] and Product.objects.exists():
            self.stdout.write("Products already exist; skipping demo data.")
            return
        data = json.loads(FIXTURE.read_text(encoding="utf-8"))
        zones = self.seed_shipping(data)
        categories, brands = self.seed_categories(data)
        count = self.seed_products(data, categories, brands)
        self.seed_home(data, categories)
        self.seed_coupons(data)
        call_command("setup_roles", verbosity=0)
        if options.get("admin_phone"):
            self.seed_admin(options["admin_phone"], options.get("admin_password"))
        self.stdout.write(
            self.style.SUCCESS(f"Seeded {len(categories)} categories, {count} products, {len(zones)} zones.")
        )

    def seed_shipping(self, data):
        zones = {}
        for i, z in enumerate(data["zones"]):
            zones[z["id"]], _ = Zone.objects.update_or_create(
                code=z["id"],
                defaults={
                    "name_ar": z["name"][0],
                    "name_en": z["name"][1],
                    "fee": Decimal(str(z["fee"])),
                    "sort_order": i,
                    "is_active": True,
                },
            )
        rules = data["rules"]
        settings = StoreSettings.load()
        settings.free_delivery_threshold = Decimal(str(rules["freeDeliveryThreshold"]))
        settings.min_order = Decimal(str(rules["minOrder"]))
        settings.cod_limit = Decimal(str(rules["codLimit"]))
        settings.default_zone = zones.get(rules["defaultZone"])
        for key, (ar, en) in rules["pickup"].items():
            setattr(settings, f"pickup_{key}_ar", ar)
            setattr(settings, f"pickup_{key}_en", en)
        settings.save()
        if not DeliveryWindow.objects.exists():
            for start in range(9, 23, 2):
                DeliveryWindow.objects.create(start_time=time(start), end_time=time(start + 2), capacity=20)
        return zones

    def seed_categories(self, data):
        categories, brands = {}, {}
        for i, c in enumerate(data["categories"]):
            root, _ = Category.objects.update_or_create(
                slug=c["slug"],
                defaults={
                    "name_ar": c["name"][0],
                    "name_en": c["name"][1],
                    "emoji": c["emoji"],
                    "color": c["color"],
                    "sort_order": i,
                    "is_active": True,
                    "parent": None,
                },
            )
            categories[c["slug"]] = root
            for j, (slug, (ar, en)) in enumerate(c["subs"]):
                categories[f"{c['slug']}/{slug}"], _ = Category.objects.update_or_create(
                    slug=slug,
                    defaults={
                        "name_ar": ar,
                        "name_en": en,
                        "parent": root,
                        "emoji": c["emoji"],
                        "color": c["color"],
                        "sort_order": j,
                        "is_active": True,
                    },
                )
            brand_slug = c["brand"][1].lower().replace(" ", "-")
            brands[c["slug"]], _ = Brand.objects.update_or_create(
                slug=brand_slug, defaults={"name_ar": c["brand"][0], "name_en": c["brand"][1]}
            )
        return categories, brands

    def seed_products(self, data, categories, brands):
        descriptions = {c["slug"]: c["description"] for c in data["categories"]}
        now = timezone.localtime()
        for p in data["products"]:
            weight = bool(p.get("weight"))
            description = descriptions[p["cat"]]
            product, _ = Product.objects.update_or_create(
                slug=p["slug"],
                defaults={
                    "category": categories[f"{p['cat']}/{p['sub']}"],
                    "brand": brands[p["cat"]],
                    "name_ar": p["name"][0],
                    "name_en": p["name"][1],
                    "description_ar": description[0],
                    "description_en": description[1],
                    "emoji": p["emoji"],
                    "sold_by_weight": weight,
                    "qty_step": Decimal("0.25") if weight else Decimal("1"),
                    "min_qty": Decimal("0.5") if weight else Decimal("1"),
                    "max_per_order": Decimal("5") if weight else Decimal("20"),
                    "is_bestseller": "best" in p["tags"],
                    "is_new": "new" in p["tags"],
                    "sold_count": (1000 if "best" in p["tags"] else 0) + (p["id"] * 37) % 300,
                    "is_active": True,
                },
            )
            sale_ends = (now + timedelta(days=(p["id"] % 5) + 2)).replace(hour=23, minute=59, second=0, microsecond=0)
            for i, v in enumerate(p["variants"]):
                Variant.objects.update_or_create(
                    sku=f"RK-{p['id']:04d}-{i + 1}",
                    defaults={
                        "product": product,
                        "label_ar": v["label"][0],
                        "label_en": v["label"][1],
                        "price": Decimal(str(v["price"])),
                        "sale_price": Decimal(str(v["sale"])) if v.get("sale") else None,
                        "sale_ends_at": sale_ends if v.get("sale") else None,
                        "stock": Decimal(str(v["stock"])),
                        "low_stock_threshold": Decimal("2") if weight else Decimal("5"),
                        "sort_order": i,
                        "is_active": True,
                    },
                )
        return len(data["products"])

    def seed_home(self, data, categories):
        for i, b in enumerate(data["banners"]):
            Banner.objects.update_or_create(
                link=b["link"],
                defaults={
                    "title_ar": b["title"][0],
                    "title_en": b["title"][1],
                    "subtitle_ar": b["subtitle"][0],
                    "subtitle_en": b["subtitle"][1],
                    "cta_ar": b["cta"][0],
                    "cta_en": b["cta"][1],
                    "emoji": b["emoji"],
                    "tone": b["tone"],
                    "sort_order": i,
                    "is_active": True,
                },
            )
        sections = [
            ("offers", HomeSection.Kind.OFFERS, ("عروض الأسبوع", "Deals of the week"), None),
            ("best", HomeSection.Kind.BEST, ("الأكثر مبيعًا", "Best sellers"), None),
            ("fresh", HomeSection.Kind.CATEGORY, ("خضار وفاكهة طازة", "Fresh produce"), "fruits-vegetables"),
            ("dairy", HomeSection.Kind.CATEGORY, ("ألبان وبيض", "Dairy & eggs"), "dairy-eggs"),
            ("new", HomeSection.Kind.NEW, ("وصل حديثًا", "New arrivals"), None),
        ]
        for i, (key, kind, (ar, en), category) in enumerate(sections):
            HomeSection.objects.update_or_create(
                key=key,
                defaults={
                    "kind": kind,
                    "title_ar": ar,
                    "title_en": en,
                    "category": categories.get(category),
                    "sort_order": i,
                    "is_active": True,
                },
            )

    def seed_coupons(self, data):
        types = {"percent": Coupon.Type.PERCENT, "fixed": Coupon.Type.FIXED, "free_delivery": Coupon.Type.FREE_DELIVERY}
        for code, rule in data["coupons"].items():
            Coupon.objects.update_or_create(
                code=code,
                defaults={
                    "type": types[rule["type"]],
                    "value": Decimal(str(rule["value"])),
                    "min_subtotal": Decimal(str(rule["min"])),
                    "max_discount": Decimal(str(rule["max"])) if rule.get("max") else None,
                    "per_customer_limit": None,  # demo codes can be reused
                    "is_active": True,
                },
            )

    def seed_admin(self, phone, password):
        from apps.accounts.models import User
        from apps.core.text import normalize_phone

        user, created = User.objects.get_or_create(phone=normalize_phone(phone), defaults={"name": "Admin"})
        user.is_staff = user.is_superuser = True
        if password:
            user.set_password(password)
        user.save()
        self.stdout.write(f"{'Created' if created else 'Updated'} superuser {user.phone}")
