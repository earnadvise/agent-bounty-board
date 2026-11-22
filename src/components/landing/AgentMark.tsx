const PATTERN = [
  [0, 0, 1, 0, 0],
  [0, 1, 1, 1, 0],
  [1, 1, 0, 1, 1],
  [0, 1, 1, 1, 0],
  [1, 0, 1, 0, 1],
]

/** The project mark: a symmetric 5x5 agent glyph. */
export function AgentMark({ size = 36, tile = true }: { size?: number; tile?: boolean }) {
  return (
    <svg width={size} height={size} viewBox="0 0 5 5" role="img" aria-label="Agent Bounty Board mark" className="shrink-0">
      {tile && <rect width="5" height="5" rx="0.9" fill="#122d45" />}
      {PATTERN.flatMap((row, r) =>
        row.map((on, c) =>
          on ? (
            <rect
              key={`${r}-${c}`}
              x={c + 0.08}
              y={r + 0.08}
              width={0.84}
              height={0.84}
              rx={0.16}
              fill={r === 2 && (c === 1 || c === 3) ? '#85b1ed' : '#acc6e9'}
            />
          ) : null,
        ),
      )}
    </svg>
  )
}
