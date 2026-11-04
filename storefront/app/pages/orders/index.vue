<script setup lang="ts">
import type { Order, Paginated } from '#shared/types/api'

definePageMeta({ middleware: 'auth' })

const { t } = useI18n()
const { money, date } = useFormat()
useSeoMeta({ title: () => t('orders.title'), robots: 'noindex' })

const { data, status } = useApiFetch<Paginated<Order>>('/orders/', { key: 'orders' })
</script>

<template>
  <div class="max-w-2xl mx-auto">
    <h1 class="text-2xl font-extrabold mb-4">{{ t('orders.title') }}</h1>

    <div v-if="status === 'pending' && !data" class="space-y-3">
      <div v-for="i in 3" :key="i" class="card h-28 animate-pulse" />
    </div>

    <EmptyState v-else-if="!data?.results.length" emoji="📦" :title="t('orders.empty')" :text="t('orders.emptyHint')">
      <NuxtLinkLocale to="/" class="btn-primary px-6">{{ t('common.startShopping') }}</NuxtLinkLocale>
    </EmptyState>

    <ul v-else class="space-y-3">
      <li v-for="order in data.results" :key="order.id">
        <NuxtLinkLocale :to="`/orders/${order.id}`" class="card p-4 block hover:border-brand-200 transition">
          <div class="flex items-center justify-between gap-3">
            <p class="font-extrabold">{{ t('orders.number', { n: order.number }) }}</p>
            <OrderStatusBadge :status="order.status" :method="order.method" />
          </div>
          <p class="text-xs text-muted mt-1">{{ date(order.created_at, { day: 'numeric', month: 'long', hour: 'numeric', minute: '2-digit' }) }}</p>
          <div class="flex items-center justify-between mt-3">
            <div class="flex -space-x-2 rtl:space-x-reverse">
              <ProductImage
                v-for="item in order.items.slice(0, 5)"
                :key="item.sku"
                size="xs"
                :emoji="item.emoji"
                :color="item.color"
                :image="item.image"
                :alt="item.name"
                class="size-10 rounded-full ring-2 ring-white"
              />
              <span v-if="order.items.length > 5" class="size-10 rounded-full ring-2 ring-white bg-canvas grid place-items-center text-xs font-bold">+{{ order.items.length - 5 }}</span>
            </div>
            <span class="font-extrabold">{{ money(order.total) }}</span>
          </div>
        </NuxtLinkLocale>
      </li>
    </ul>
  </div>
</template>
