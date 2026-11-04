"""Message texts per event and channel, in Arabic and English (BE-506)."""

TEMPLATES = {
    "otp": {
        # The last line enables WebOTP autofill on Android.
        "sms": {
            "ar": "كود الدخول لروكت ماركت: {code}\nمتشاركوش مع حد.\n\n@{domain} #{code}",
            "en": "Your Rocket Market code: {code}\nDon't share it with anyone.\n\n@{domain} #{code}",
        },
    },
    "order_placed": {
        "sms": {
            "ar": "اتأكد طلبك {number} من روكت ماركت بإجمالي {total} ج.م. تابعه من هنا: {url}",
            "en": "Your Rocket Market order {number} is confirmed. Total EGP {total}. Track it: {url}",
        },
        "push": {
            "title": {"ar": "اتأكد طلبك 🎉", "en": "Order confirmed 🎉"},
            "body": {"ar": "طلبك {number} بيتجهز دلوقتي.", "en": "We're getting order {number} ready."},
        },
    },
    "order_status": {
        "sms": {
            "ar": "طلبك {number} {status}. تفاصيل: {url}",
            "en": "Your order {number} {status}. Details: {url}",
        },
        "push": {
            "title": {"ar": "تحديث على طلبك", "en": "Order update"},
            "body": {"ar": "طلبك {number} {status}.", "en": "Your order {number} {status}."},
        },
    },
    "support_new": {
        "email": {
            "subject": {"ar": "محادثة دعم جديدة من {customer}", "en": "New support chat from {customer}"},
            "body": {
                "ar": "{customer} ({phone}) كتب:\n\n{message}\n\nرد من هنا: {url}",
                "en": "{customer} ({phone}) wrote:\n\n{message}\n\nReply here: {url}",
            },
        },
    },
    "support_reply": {
        "sms": {
            "ar": "فريق روكت ماركت رد على رسالتك. اقرا الرد: {url}",
            "en": "Rocket Market support replied to your message. Read it: {url}",
        },
        "push": {
            "title": {"ar": "رد جديد من الدعم", "en": "New reply from support"},
            "body": {"ar": "فريق روكت رد على رسالتك.", "en": "Rocket support replied to your message."},
        },
    },
    "low_stock": {
        "email": {
            "subject": {"ar": "تنبيه مخزون: {count} منتج", "en": "Low stock: {count} item(s)"},
            "body": {"ar": "المنتجات دي قربت تخلص:\n{lines}", "en": "These items are running low:\n{lines}"},
        },
    },
}


def render(event: str, channel: str, lang: str, context: dict) -> dict | None:
    template = TEMPLATES.get(event, {}).get(channel)
    if not template:
        return None
    lang = lang if lang in ("ar", "en") else "ar"
    if channel == "sms":
        return {"body": template[lang].format(**context)}
    if channel == "email":
        return {
            "subject": template["subject"][lang].format(**context),
            "body": template["body"][lang].format(**context),
        }
    return {"subject": template["title"][lang].format(**context), "body": template["body"][lang].format(**context)}
