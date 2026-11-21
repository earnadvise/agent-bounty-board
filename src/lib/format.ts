import { formatUnitsExact } from '@/onchain-money'

/** Format a raw token amount using the token's own decimals (BNB Chain USDC is not 6 decimals). */
export function formatToken(raw: bigint | undefined, decimals: number | undefined, maxFraction = 4): string {
  if (raw === undefined || decimals === undefined) return '...'
  const full = formatUnitsExact(raw, decimals)
  const [whole, frac = ''] = full.split('.')
  const trimmed = frac.slice(0, maxFraction).replace(/0+$/, '')
  const grouped = Number(whole).toLocaleString('en-US')
  return trimmed ? `${grouped}.${trimmed}` : grouped
}

export function formatDuration(totalSeconds: number): string {
  const s = Math.max(0, Math.floor(totalSeconds))
  const d = Math.floor(s / 86_400)
  const h = Math.floor((s % 86_400) / 3600)
  const m = Math.floor((s % 3600) / 60)
  if (d > 0) return `${d}d ${h}h`
  if (h > 0) return `${h}h ${m}m`
  return `${Math.max(1, m)}m`
}
