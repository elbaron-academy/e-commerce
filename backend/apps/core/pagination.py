from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class StandardPagination(PageNumberPagination):
    """{count, next, previous, results}, where next/previous are page numbers."""

    page_size = 24
    page_size_query_param = "page_size"
    max_page_size = 48

    def get_paginated_response(self, data):
        page = self.page
        return Response(
            {
                "count": page.paginator.count,
                "next": page.next_page_number() if page.has_next() else None,
                "previous": page.previous_page_number() if page.has_previous() else None,
                "results": data,
            }
        )

    def get_paginated_response_schema(self, schema):
        return {
            "type": "object",
            "required": ["count", "results"],
            "properties": {
                "count": {"type": "integer"},
                "next": {"type": "integer", "nullable": True},
                "previous": {"type": "integer", "nullable": True},
                "results": schema,
            },
        }


class AdminPagination(StandardPagination):
    page_size = 25
    max_page_size = 200
