/** Sets lang/dir on <html>, hreflang links and the title template. */
export function useAppHead() {
  const { t } = useI18n()
  const head = useLocaleHead({ seo: true })
  useHead(() => ({
    htmlAttrs: { lang: head.value.htmlAttrs.lang, dir: head.value.htmlAttrs.dir },
    link: head.value.link,
    meta: head.value.meta,
    titleTemplate: (title?: string) => (title ? `${title} · ${t('brand.name')}` : `${t('brand.name')} · ${t('brand.tagline')}`),
  }))
}
