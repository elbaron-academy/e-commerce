"""Catalog cache (BE-202). Any catalog change bumps a version, which retires every cached entry."""

from django.core.cache import cache

from .i18n import current_lang

VERSION_KEY = "catalog:version"


def catalog_version() -> int:
    version = cache.get(VERSION_KEY)
    if version is None:
        version = 1
        cache.set(VERSION_KEY, version, None)
    return version


def bump_catalog_version() -> None:
    try:
        cache.incr(VERSION_KEY)
    except ValueError:
        cache.set(VERSION_KEY, 2, None)


def cached_catalog(key: str, builder, timeout: int = 300):
    full_key = f"catalog:{key}:v{catalog_version()}:{current_lang()}"
    return cache.get_or_set(full_key, builder, timeout)
