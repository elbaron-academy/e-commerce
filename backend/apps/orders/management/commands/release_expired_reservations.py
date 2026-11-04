from django.core.management.base import BaseCommand

from apps.orders.services import release_expired_reservations


class Command(BaseCommand):
    help = "Cancels unpaid orders past their stock hold and returns the stock. Run every minute."

    def handle(self, *args, **options):
        count = release_expired_reservations()
        self.stdout.write(f"Released {count} reservation(s)")
