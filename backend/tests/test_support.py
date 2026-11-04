from datetime import timedelta
from io import BytesIO

import pytest
from django.contrib.auth.models import Group
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.management import call_command
from django.utils import timezone
from PIL import Image
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.notifications.models import NotificationLog
from apps.support.models import Conversation, Message
from apps.support.services import remind_unread_replies

from .conftest import client_for

pytestmark = pytest.mark.django_db

CHAT = "/api/v1/support/chat/"
SEND = "/api/v1/support/chat/messages/"
INBOX = "/api/v1/admin/support/conversations/"


@pytest.fixture(autouse=True)
def _media(settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path


def send(client, body="", **extra):
    return client.post(SEND, {"body": body, **extra}, format="json")


def photo(size=(2400, 1800), fmt="JPEG", exif=True) -> SimpleUploadedFile:
    image = Image.new("RGB", size, "#0e7c5a")
    out = BytesIO()
    kwargs = {}
    if exif:
        data = Image.Exif()
        data[0x010F] = "PhoneMaker"  # Make
        data[0x8825] = {2: (30.0, 2.0, 40.0)}  # GPS latitude
        kwargs["exif"] = data
    image.save(out, fmt, **kwargs)
    return SimpleUploadedFile("IMG_0001.jpg", out.getvalue(), content_type="image/jpeg")


@pytest.fixture
def support_agent(db):
    call_command("setup_roles", verbosity=0)
    user = User.objects.create_user(phone="01088887777", password="Str0ng-pass!", name="Salma", is_staff=True)
    user.groups.add(Group.objects.get(name="Support"))
    return user


@pytest.fixture
def agent_api(support_agent):
    return client_for(support_agent)


def test_first_message_opens_a_conversation(customer, customer_api, django_capture_on_commit_callbacks):
    with django_capture_on_commit_callbacks(execute=True):
        res = send(customer_api, "  السلام عليكم، الطلب اتأخر  ")
    assert res.status_code == 201, res.content
    message = res.json()
    assert message["body"] == "السلام عليكم، الطلب اتأخر"
    assert message["sender"] == "customer" and message["kind"] == "text" and message["image"] is None

    conversation = Conversation.objects.get(customer=customer)
    assert conversation.status == "open" and conversation.last_message_id == message["id"]
    # Staff get an email with a link to the inbox.
    email = NotificationLog.objects.get(event="support_new", channel="email")
    assert email.recipient == "ops@rocket.test" and "/admin/support/conversation/inbox/#" in email.body

    # The next message joins the same conversation and doesn't email again.
    with django_capture_on_commit_callbacks(execute=True):
        assert send(customer_api, "رقم الطلب RK-000003").status_code == 201
    assert Conversation.objects.filter(customer=customer).count() == 1
    assert NotificationLog.objects.filter(event="support_new").count() == 1

    state = customer_api.get(CHAT).json()
    assert [m["sender"] for m in state["messages"]] == ["customer", "customer"]
    assert state["conversation"]["status"] == "open" and state["unread"] == 0 and state["has_older"] is False


def test_staff_reply_unread_polling_and_read_receipts(customer, customer_api, staff_api, staff):
    first = send(customer_api, "فين طلبي؟").json()
    conversation = Conversation.objects.get(customer=customer)

    listing = staff_api.get(INBOX, {"needs_reply": "true"}).json()
    assert [c["id"] for c in listing["results"]] == [conversation.pk]
    assert listing["results"][0]["unread"] == 1
    assert staff_api.get(f"{INBOX}summary/").json() == {"open": 1, "needs_reply": 1, "mine": 0}

    reply = staff_api.post(f"{INBOX}{conversation.pk}/messages/", {"body": "جاي في الطريق 🚚"}, format="json")
    assert reply.status_code == 201, reply.content
    assert reply.json()["sender"] == "staff"
    conversation.refresh_from_db()
    assert conversation.assigned_to == staff  # replying claims the conversation
    assert conversation.staff_last_read == reply.json()["id"]

    # Polling with `after` returns only the new message.
    state = customer_api.get(CHAT, {"after": first["id"]}).json()
    assert [m["id"] for m in state["messages"]] == [reply.json()["id"]]
    assert state["unread"] == 1
    assert customer_api.get("/api/v1/support/chat/unread/").json() == {"unread": 1}

    assert customer_api.post("/api/v1/support/chat/read/", {}, format="json").json() == {"unread": 0}
    detail = staff_api.get(f"{INBOX}{conversation.pk}/").json()
    assert detail["customer_last_read"] == reply.json()["id"]  # staff see ✓✓
    assert detail["customer"]["phone"] == customer.phone

    # Staff read the customer's message.
    assert staff_api.post(f"{INBOX}{conversation.pk}/read/", {}, format="json").status_code == 204
    assert staff_api.get(f"{INBOX}summary/").json()["needs_reply"] == 0


def test_closing_starts_a_new_conversation_but_one_chat_for_the_customer(customer, customer_api, staff_api):
    send(customer_api, "مشكلة")
    old = Conversation.objects.get(customer=customer)
    res = staff_api.post(f"{INBOX}{old.pk}/close/", format="json")
    assert res.status_code == 200 and res.json()["status"] == "closed"

    # Staff can't reply to a closed conversation.
    res = staff_api.post(f"{INBOX}{old.pk}/messages/", {"body": "تمام"}, format="json")
    assert res.status_code == 409 and res.json()["code"] == "conversation_closed"

    assert send(customer_api, "مشكلة تانية").status_code == 201
    new = Conversation.objects.get(customer=customer, status="open")
    assert new.pk != old.pk

    state = customer_api.get(CHAT).json()
    assert [(m["kind"], m["conversation"]) for m in state["messages"]] == [
        ("text", old.pk),
        ("event", old.pk),
        ("text", new.pk),
    ]
    assert state["messages"][1]["event"] == "closed"
    assert state["conversation"]["id"] == new.pk
    assert state["unread"] == 0  # the "closed" line isn't an unread message

    # Reopening the old one is refused while another is open.
    res = staff_api.post(f"{INBOX}{old.pk}/reopen/", format="json")
    assert res.status_code == 409 and res.json()["code"] == "customer_has_open_conversation"


def test_history_paging(customer, customer_api):
    for i in range(35):
        send(customer_api, f"رسالة {i}")
    state = customer_api.get(CHAT).json()
    assert len(state["messages"]) == 30 and state["has_older"] is True
    assert state["messages"][-1]["body"] == "رسالة 34"
    older = customer_api.get(CHAT, {"before": state["messages"][0]["id"]}).json()
    assert [m["body"] for m in older["messages"]] == [f"رسالة {i}" for i in range(5)]
    assert older["has_older"] is False


def test_message_validation(customer_api, api):
    assert api.get(CHAT).status_code == 401
    res = send(customer_api, "   ")
    assert res.status_code == 400 and res.json()["field"] == "body"
    res = send(customer_api, "x" * 2001)
    assert res.status_code == 400 and res.json()["field"] == "body"
    res = customer_api.get(CHAT, {"after": "abc"})
    assert res.status_code == 400 and res.json()["field"] == "after"


def test_order_reference_must_be_yours(place, customer_api):
    order = place().json()["order"]
    res = send(customer_api, "عندي سؤال عن الطلب", order=order["id"])
    assert res.status_code == 201
    assert res.json()["order"] == {"id": order["id"], "number": order["number"]}

    stranger = client_for(User.objects.create_user(phone="01155556666"))
    res = send(stranger, "طلب مش بتاعي", order=order["id"])
    assert res.status_code == 400 and res.json()["field"] == "order"


def test_photo_is_resized_and_location_removed(customer, customer_api):
    res = customer_api.post(SEND, {"body": "", "image": photo()}, format="multipart")
    assert res.status_code == 201, res.content
    image = res.json()["image"]
    assert image["url"].startswith("http://testserver/media/support/") and image["url"].endswith(".jpg")
    assert (image["width"], image["height"]) == (1600, 1200)

    saved = Message.objects.get(pk=res.json()["id"]).image
    with Image.open(saved.path) as stored:
        assert stored.format == "JPEG" and stored.size == (1600, 1200)
        assert not stored.getexif()  # no camera or GPS data


def test_photo_validation(customer_api, settings):
    junk = SimpleUploadedFile("notes.jpg", b"not an image", content_type="image/jpeg")
    res = customer_api.post(SEND, {"image": junk}, format="multipart")
    assert res.status_code == 400 and res.json()["code"] == "invalid_image"

    settings.SUPPORT_IMAGE_MAX_MB = 0
    res = customer_api.post(SEND, {"image": photo(exif=False)}, format="multipart")
    assert res.status_code == 400 and res.json()["code"] == "image_too_large"


def test_chats_are_private(customer_api, customer):
    send(customer_api, "رسالتي")
    other = client_for(User.objects.create_user(phone="01155556666"))
    assert other.get(CHAT).json()["messages"] == []
    assert other.get(CHAT).json()["conversation"] is None
    # Customers can't use the staff inbox.
    assert customer_api.get(INBOX).status_code == 403


def test_support_role_permissions(customer_api, customer, agent_api, support_agent):
    send(customer_api, "مساعدة")
    conversation = Conversation.objects.get(customer=customer)
    assert agent_api.get(INBOX).json()["count"] == 1
    res = agent_api.post(f"{INBOX}{conversation.pk}/assign/", {"user": support_agent.pk}, format="json")
    assert res.status_code == 200 and res.json()["assigned_to"]["id"] == support_agent.pk
    assert agent_api.get(INBOX, {"assigned": "me"}).json()["count"] == 1
    reply = agent_api.post(f"{INBOX}{conversation.pk}/messages/", {"body": "أهلاً يا منى"}, format="json")
    assert reply.status_code == 201 and reply.json()["sender_name"] == "Salma"

    catalog = User.objects.create_user(phone="01077776666", password="Str0ng-pass!", is_staff=True)
    catalog.groups.add(Group.objects.get(name="Catalog manager"))
    catalog_api = client_for(catalog)
    assert catalog_api.get(INBOX).status_code == 403
    assert catalog_api.post(f"{INBOX}{conversation.pk}/messages/", {"body": "x"}, format="json").status_code == 403


def test_reply_reminder_sms_once(customer, customer_api, staff_api):
    send(customer_api, "سؤال")
    conversation = Conversation.objects.get(customer=customer)
    reply = staff_api.post(f"{INBOX}{conversation.pk}/messages/", {"body": "الرد"}, format="json").json()

    assert remind_unread_replies() == 0  # too soon
    later = timezone.now() + timedelta(minutes=11)
    assert remind_unread_replies(now=later) == 1
    sms = NotificationLog.objects.get(event="support_reply", channel="sms")
    assert sms.recipient == customer.phone and sms.body.endswith("/chat")
    assert remind_unread_replies(now=later) == 0  # only once per reply

    # Once read, a later reply gets its own reminder only if it's unread too.
    customer_api.post("/api/v1/support/chat/read/", {"message_id": reply["id"]}, format="json")
    staff_api.post(f"{INBOX}{conversation.pk}/messages/", {"body": "رد تاني"}, format="json")
    assert remind_unread_replies(now=timezone.now() + timedelta(minutes=11)) == 1


def test_admin_inbox_page_and_session_api(staff, customer_api, customer):
    send(customer_api, "مرحبا")
    client = APIClient(enforce_csrf_checks=True)
    client.force_login(staff)
    page = client.get("/admin/support/conversation/inbox/")
    assert page.status_code == 200
    config = page.context["inbox_config"]
    assert config["api"] == INBOX and config["can_reply"] is True

    # The inbox page talks to the staff API with the admin session.
    conversation = Conversation.objects.get(customer=customer)
    assert client.get(INBOX).json()["count"] == 1
    url = f"{INBOX}{conversation.pk}/messages/"
    assert client.post(url, {"body": "بدون CSRF"}, format="json").status_code == 403
    res = client.post(url, {"body": "أهلاً"}, format="json", HTTP_X_CSRFTOKEN=config["csrf"])
    assert res.status_code == 201, res.content

    # Not for customers.
    plain = APIClient()
    plain.force_login(customer)
    assert plain.get("/admin/support/conversation/inbox/").status_code == 302
