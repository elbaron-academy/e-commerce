/**
 * Normalizes Arabic and English text for search (BE-303):
 * أ/إ/آ → ا, ة → ه, ى → ي, removes diacritics and tatweel, lowercases.
 */
export function normalizeText(input: string): string {
  return input
    .toLowerCase()
    .replace(/[ً-ٰٟ]/g, '')
    .replace(/ـ/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

/** Removes the Arabic definite article so "الموز" matches "موز". */
export function stripArticle(word: string): string {
  return word.length > 3 && word.startsWith('ال') ? word.slice(2) : word
}

export function roundMoney(value: number): number {
  return Math.round(value * 100) / 100
}
