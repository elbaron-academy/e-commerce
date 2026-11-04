<script setup lang="ts">
import type { ProductSummary } from '#shared/types/api'

const props = withDefaults(defineProps<{ product: ProductSummary; sku?: string; size?: 'md' | 'lg' }>(), { sku: undefined, size: 'md' })

const cart = useCartStore()
const { t } = useI18n()
const { qty } = useFormat()
const toast = useToast()

const variant = computed(
  () => props.product.variants.find((v) => v.sku === (props.sku ?? props.product.default_sku)) ?? props.product.variants[0]!,
)
const line = computed(() => cart.find(variant.value.sku))
const height = computed(() => (props.size === 'lg' ? 'h-12 text-base' : 'h-10'))

function add() {
  if (!cart.add(props.product, variant.value)) toast.show(t('product.maxReached'))
}
function inc() {
  if (!cart.increment(variant.value.sku)) toast.show(t('product.maxReached'))
}
</script>

<template>
  <button v-if="!variant.in_stock" type="button" disabled class="btn w-full bg-canvas text-muted !opacity-100" :class="height">
    {{ t('product.outOfStock') }}
  </button>
  <button v-else-if="!line" type="button" class="btn-primary w-full" :class="height" @click="add">
    <AppIcon name="plus" :size="18" :stroke="2.6" />
    {{ size === 'lg' ? t('product.addToCart') : t('product.add') }}
  </button>
  <QtyStepper
    v-else
    :size="size"
    :label="qty(line.qty, line.sold_by_weight)"
    :at-min="line.qty <= line.min"
    :at-max="line.qty + line.step > line.max + 1e-9"
    @inc="inc"
    @dec="cart.decrement(variant.sku)"
  />
</template>
