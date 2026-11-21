import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { Loader2, X } from 'lucide-react'
import type { BoardData } from '@/hooks/useBoardData'
import type { BoardActions } from '@/hooks/useBoardActions'
import { CATEGORIES, CLAIM_WINDOW_OPTIONS } from '@/lib/board'
import { formatToken } from '@/lib/format'
import { formatUnitsExact, parseUnitsExact } from '@/onchain-money'

type Props = {
  open: boolean
  onClose: () => void
  data: BoardData
  actions: BoardActions
}

const TITLE_MAX = 80
const DETAILS_MAX = 500

function byteLength(value: string): number {
  return new TextEncoder().encode(value).length
}

export function PostSheet({ open, onClose, data, actions }: Props) {
  const [title, setTitle] = useState('')
  const [details, setDetails] = useState('')
  const [amount, setAmount] = useState('')
  const [windowSeconds, setWindowSeconds] = useState<number>(CLAIM_WINDOW_OPTIONS[1].seconds)
  const [category, setCategory] = useState<number>(0)

  let reward: bigint | undefined
  if (amount && data.decimals !== undefined) {
    try {
      reward = parseUnitsExact(amount, data.decimals)
    } catch {
      reward = undefined
    }
  }

  const titleOk = title.trim().length > 0 && byteLength(title) <= TITLE_MAX
  const detailsOk = byteLength(details) <= DETAILS_MAX
  const enoughBalance = reward !== undefined && data.tokenBalance !== undefined && reward <= data.tokenBalance
  const needsApproval = reward !== undefined && data.allowance !== undefined && data.allowance < reward
  const ready = titleOk && detailsOk && reward !== undefined && reward > 0n && enoughBalance && Boolean(data.token)
  const posting = actions.busy === 'post'

  async function submit() {
    if (!ready || reward === undefined || !data.token) return
    const ok = await actions.post({
      title: title.trim(),
      details: details.trim(),
      reward,
      claimWindow: windowSeconds,
      category,
      token: data.token,
      allowance: data.allowance ?? 0n,
    })
    if (ok) {
      setTitle('')
      setDetails('')
      setAmount('')
      onClose()
    }
  }

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          className="fixed inset-0 z-50 flex items-end justify-center"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
        >
          <div className="absolute inset-0 bg-black/25 backdrop-blur-sm" />
          <motion.section
            role="dialog"
            aria-label="Post a bounty"
            className="relative max-h-[92dvh] w-full max-w-md overflow-y-auto rounded-t-3xl"
            style={{
              background: 'rgba(255,255,255,0.92)',
              backdropFilter: 'blur(40px) saturate(200%)',
              WebkitBackdropFilter: 'blur(40px) saturate(200%)',
            }}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 380, damping: 36 }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-center pt-3">
              <div className="h-1 w-10 rounded-full bg-black/10" />
            </div>
            <div className="px-5 pb-6 pt-2">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="display text-xl font-bold" style={{ color: 'var(--ink)' }}>
                  Post a bounty
                </h2>
                <button onClick={onClose} aria-label="Close" className="flex size-11 items-center justify-center rounded-full">
                  <X className="size-5" style={{ color: 'var(--muted)' }} />
                </button>
              </div>

              <div className="mb-3 flex flex-wrap gap-2">
                {CATEGORIES.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => setCategory(c.id)}
                    className="min-h-11 rounded-xl px-3.5 text-xs font-semibold"
                    style={
                      category === c.id
                        ? { background: 'var(--accent)', color: '#fff' }
                        : { background: 'var(--surface-muted)', border: '1px solid var(--border)', color: 'var(--ink-2)' }
                    }
                  >
                    {c.label}
                  </button>
                ))}
              </div>

              <label className="text-xs font-semibold" style={{ color: 'var(--muted)' }} htmlFor="b-title">
                Title
              </label>
              <input
                id="b-title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Design a logo for my agent"
                className="inner mt-1 w-full rounded-2xl px-4 py-3 text-sm outline-none"
              />
              <div className="mt-1 text-right text-[11px] tabular-nums" style={{ color: byteLength(title) > TITLE_MAX ? 'var(--danger)' : 'var(--subtle)' }}>
                {byteLength(title)}/{TITLE_MAX}
              </div>

              <label className="text-xs font-semibold" style={{ color: 'var(--muted)' }} htmlFor="b-details">
                Details
              </label>
              <textarea
                id="b-details"
                value={details}
                onChange={(e) => setDetails(e.target.value)}
                rows={3}
                placeholder="What should be delivered, and how will you judge it?"
                className="inner mt-1 w-full resize-none rounded-2xl px-4 py-3 text-sm outline-none"
              />
              <div className="mt-1 text-right text-[11px] tabular-nums" style={{ color: byteLength(details) > DETAILS_MAX ? 'var(--danger)' : 'var(--subtle)' }}>
                {byteLength(details)}/{DETAILS_MAX}
              </div>

              <div className="inner mt-2 rounded-2xl p-4">
                <input
                  inputMode="decimal"
                  value={amount}
                  onChange={(e) => {
                    const v = e.target.value.replace(/[^0-9.]/g, '')
                    if (/^\d*\.?\d*$/.test(v)) setAmount(v)
                  }}
                  placeholder="0.00"
                  aria-label="Reward amount"
                  className="display w-full bg-transparent text-4xl font-bold tabular-nums outline-none placeholder:text-slate-300"
                  style={{ color: 'var(--ink)' }}
                />
                <div className="mt-2 flex items-center justify-between">
                  <span className="text-xs" style={{ color: 'var(--subtle)' }}>
                    {data.symbol ?? 'USDC'} reward, held in escrow
                  </span>
                  <button
                    type="button"
                    disabled={data.tokenBalance === undefined || data.decimals === undefined}
                    onClick={() => {
                      if (data.tokenBalance !== undefined && data.decimals !== undefined) {
                        setAmount(formatUnitsExact(data.tokenBalance, data.decimals))
                      }
                    }}
                    className="text-xs font-semibold disabled:opacity-40"
                    style={{ color: 'var(--accent-hover)' }}
                  >
                    Balance: {formatToken(data.tokenBalance, data.decimals, 2)} Max
                  </button>
                </div>
              </div>
              {reward !== undefined && data.tokenBalance !== undefined && !enoughBalance && (
                <p className="mt-2 text-xs" style={{ color: 'var(--danger)' }}>
                  Insufficient balance. You have {formatToken(data.tokenBalance, data.decimals, 4)} {data.symbol}.
                </p>
              )}

              <div className="mt-4">
                <div className="text-xs font-semibold" style={{ color: 'var(--muted)' }}>
                  Time to deliver after a claim
                </div>
                <div className="mt-1.5 grid grid-cols-4 gap-2">
                  {CLAIM_WINDOW_OPTIONS.map((o) => (
                    <button
                      key={o.seconds}
                      type="button"
                      onClick={() => setWindowSeconds(o.seconds)}
                      className="min-h-11 rounded-xl text-xs font-semibold"
                      style={
                        windowSeconds === o.seconds
                          ? { background: 'var(--accent)', color: '#fff' }
                          : { background: 'var(--surface-muted)', border: '1px solid var(--border)', color: 'var(--ink-2)' }
                      }
                    >
                      {o.label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="inner mt-4 rounded-2xl p-3 text-xs leading-relaxed" style={{ color: 'var(--ink-2)' }}>
                {needsApproval ? 'You will sign two transactions: an approval for exactly this reward, then the post. ' : ''}
                Your reward stays in the contract until you approve the work or cancel an unclaimed bounty. If you
                do not respond within 7 days of a submission, the worker can collect it.
              </div>

              <button
                onClick={() => void submit()}
                disabled={!ready || posting}
                className="mt-4 min-h-12 w-full rounded-2xl text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-40"
                style={{ background: 'var(--accent)' }}
              >
                {posting ? (
                  <span className="flex items-center justify-center gap-2">
                    <Loader2 className="size-4 animate-spin" /> Confirm in wallet...
                  </span>
                ) : needsApproval ? (
                  'Approve and post'
                ) : (
                  'Post bounty'
                )}
              </button>
            </div>
          </motion.section>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
