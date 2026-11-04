from django.core.management.base import BaseCommand

from apps.support.services import remind_unread_replies


class Command(BaseCommand):
    help = "Texts customers about support replies they haven't read yet. Run every minute."

    def handle(self, *args, **options):
        count = remind_unread_replies()
        self.stdout.write(f"Reminded {count} customer(s)")
