from django.contrib.auth.models import Group, Permission
from django.core.management.base import BaseCommand

ROLES = {
    "Admin": {"accounts", "catalog", "orders", "payments", "promotions", "shipping", "notifications", "support"},
    "Catalog manager": {"catalog.*", "promotions.view_coupon"},
    "Order manager": {
        "orders.*",
        "payments.view_payment",
        "accounts.view_user",
        "accounts.view_address",
        "catalog.view_product",
        "catalog.view_variant",
        "support.view_conversation",
        "support.add_message",
    },
    "Support": {
        "orders.view_order",
        "orders.view_orderitem",
        "accounts.view_user",
        "accounts.view_address",
        "accounts.change_user",
        "support.view_conversation",
        "support.change_conversation",
        "support.view_message",
        "support.add_message",
    },
}


class Command(BaseCommand):
    help = "Creates the default staff roles (Admin, Catalog manager, Order manager, Support)."

    def handle(self, *args, **options):
        for name, rules in ROLES.items():
            perms = Permission.objects.none()
            for rule in rules:
                app, _, codename = rule.partition(".")
                qs = Permission.objects.filter(content_type__app_label=app)
                if codename and codename != "*":
                    qs = qs.filter(codename=codename)
                perms = perms | qs
            group, _ = Group.objects.get_or_create(name=name)
            group.permissions.set(perms.distinct())
            if options["verbosity"]:
                self.stdout.write(f"{name}: {group.permissions.count()} permissions")
