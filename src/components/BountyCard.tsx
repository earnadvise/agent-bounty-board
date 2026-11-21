import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Clock, Loader2 } from 'lucide-react'
import { AgentAvatar } from '@/components/AgentAvatar'
import type { BoardData } from '@/hooks/useBoardData'
import type { BoardActions } from '@/hooks/useBoardActions'
import { CATEGORIES, REVIEW_WINDOW_SECONDS, STATUS, STATUS_LABEL, shortAddress, type BountyWithId } from '@/lib/board'
import { formatDuration, formatToken } from '@/lib/format'

type Props = {
  bounty: BountyWithId
  data: BoardData
  actions: BoardActions
  now: number
}

const same = (a?: string, b?: string) => Boolean(a && b && a.toLowerCase() === b.toLowerCase())

export function BountyCard({ bounty, data, actions, now }: Props) {
  const { address, isConnected } = useAccount()
  const [proof, setProof] = useState('')
  const isPoster = same(address, bounty.poster)
  const isWorker = same(address, bounty.worker)
  const id = bounty.id
  const busyKey = (fn: string) => `${fn}-${id}`
  const busy = actions.busy?.endsWith(`-${id}`) ?? false

  const deadline = Number(bounty.claimDeadline)
  const reviewEnds = Number(bounty.submittedAt) + REVIEW_WINDOW_SECONDS
  const claimExpired = bounty.status === STATUS.Claimed && now > deadline
  const reviewOver = bounty.status === STATUS.Submitted && now >= reviewEnds
  const proofBytes = new TextEncoder().encode(proof).length

  const tone =
    bounty.status === STATUS.Paid
      ? 'var(--success)'
      : bounty.status === STATUS.Cancelled
        ? 'var(--subtle)'
        : bounty.status === STATUS.Open
          ? 'var(--accent-hover)'
          : 'var(--warn)'

  return (
    <article className="card rounded-3xl p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="text-[11px] font-semibold uppercase tracking-[0.08em]" style={{ color: tone }}>
            {STATUS_LABEL[bounty.status] ?? 'Unknown'} · #{id.toString()}
            <span className="ml-2 rounded-md px-1.5 py-0.5" style={{ background: 'var(--surface-muted)', color: 'var(--muted)' }}>
              {CATEGORIES[bounty.category]?.label ?? 'Other'}
            </span>
          </div>
          <h3 className="display mt-1 text-lg font-bold text-balance break-words" style={{ color: 'var(--ink)' }}>
            {bounty.title}
          </h3>
        </div>
        <div className="shrink-0 text-right">
          <div className="display text-xl font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
            {formatToken(bounty.reward, data.decimals)}
          </div>
          <div className="text-xs" style={{ color: 'var(--subtle)' }}>
            {data.symbol ?? 'USDC'}
          </div>
        </div>
      </div>

      {bounty.details && (
        <p className="mt-2 break-words text-sm text-pretty" style={{ color: 'var(--ink-2)' }}>
          {bounty.details}
        </p>
      )}

      <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs" style={{ color: 'var(--muted)' }}>
        <span className="flex items-center gap-1">
          <AgentAvatar address={bounty.poster} size={18} /> Poster <span className="mono">{shortAddress(bounty.poster)}</span>
          {isPoster && ' (you)'}
        </span>
        {bounty.status === STATUS.Claimed && (
          <span className="flex items-center gap-1">
            <Clock className="size-3" />
            {claimExpired ? 'Claim expired' : `${formatDuration(deadline - now)} left to deliver`}
          </span>
        )}
        {bounty.status === STATUS.Submitted && (
          <span className="flex items-center gap-1">
            <Clock className="size-3" />
            {reviewOver ? 'Review window over' : `${formatDuration(reviewEnds - now)} to review`}
          </span>
        )}
      </div>

      {bounty.status >= STATUS.Claimed && bounty.status <= STATUS.Submitted && (
        <div className="mt-2 text-xs" style={{ color: 'var(--muted)' }}>
          Worker <span className="mono">{shortAddress(bounty.worker)}</span>
          {isWorker && ' (you)'}
        </div>
      )}

      {bounty.proof && (
        <div className="inner mt-3 break-words rounded-2xl p-3 text-xs" style={{ color: 'var(--ink-2)' }}>
          <div className="mb-1 font-semibold" style={{ color: 'var(--muted)' }}>
            Submitted work
          </div>
          {bounty.proof}
        </div>
      )}

      <div className="mt-4 space-y-2">
        {bounty.status === STATUS.Open && isPoster && (
          <Action label="Cancel and refund" busy={busy} loading={actions.busy === busyKey('cancelBounty')} onClick={() => void actions.cancel(id)} ghost />
        )}
        {bounty.status === STATUS.Open && !isPoster && (
          <Action
            label={data.isHolder ? 'Claim this bounty' : isConnected ? 'Agent ID required to claim' : 'Connect to claim'}
            busy={busy}
            disabled={!data.isHolder}
            loading={actions.busy === busyKey('claimBounty')}
            onClick={() => void actions.claim(id)}
          />
        )}

        {bounty.status === STATUS.Claimed && isWorker && (
          <>
            <textarea
              value={proof}
              onChange={(e) => setProof(e.target.value)}
              rows={2}
              placeholder="Link or note proving your work (max 500 bytes)"
              aria-label="Proof of work"
              className="inner w-full resize-none rounded-2xl px-4 py-3 text-sm outline-none"
            />
            <Action
              label="Submit work"
              busy={busy}
              disabled={proof.trim().length === 0 || proofBytes > 500 || claimExpired}
              loading={actions.busy === busyKey('submitWork')}
              onClick={() => void actions.submit(id, proof.trim())}
            />
            <Action label="Release claim" busy={busy} loading={actions.busy === busyKey('releaseClaim')} onClick={() => void actions.release(id)} ghost />
          </>
        )}
        {claimExpired && !isWorker && isConnected && (
          <Action label="Reopen expired claim" busy={busy} loading={actions.busy === busyKey('releaseClaim')} onClick={() => void actions.release(id)} ghost />
        )}

        {bounty.status === STATUS.Submitted && isPoster && (
          <>
            <Action label="Approve and pay worker" busy={busy} loading={actions.busy === busyKey('approveWork')} onClick={() => void actions.approve(id)} />
            {!reviewOver && (
              <Action label="Reject and reopen" busy={busy} loading={actions.busy === busyKey('rejectWork')} onClick={() => void actions.reject(id)} ghost />
            )}
          </>
        )}
        {bounty.status === STATUS.Submitted && isWorker && (
          <Action
            label={reviewOver ? 'Collect reward' : 'Waiting for poster review'}
            busy={busy}
            disabled={!reviewOver}
            loading={actions.busy === busyKey('claimAfterReviewWindow')}
            onClick={() => void actions.collect(id)}
          />
        )}
      </div>
    </article>
  )
}

type ActionProps = {
  label: string
  onClick: () => void
  busy: boolean
  loading: boolean
  disabled?: boolean
  ghost?: boolean
}

function Action({ label, onClick, busy, loading, disabled, ghost }: ActionProps) {
  return (
    <button
      onClick={onClick}
      disabled={busy || disabled}
      className="flex min-h-11 w-full items-center justify-center gap-2 rounded-2xl text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-40"
      style={
        ghost
          ? { background: 'var(--surface-strong)', border: '1px solid var(--border)', color: 'var(--ink)' }
          : { background: 'var(--accent)', color: '#fff' }
      }
    >
      {loading ? (
        <>
          <Loader2 className="size-4 animate-spin" /> Confirming...
        </>
      ) : (
        label
      )}
    </button>
  )
}
