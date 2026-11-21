import { useMemo } from 'react'

type Props = {
  address: string
  size?: number
}

/** Deterministic identicon: the same address always draws the same agent mark. */
export function AgentAvatar({ address, size = 40 }: Props) {
  const { cells, fg, bg } = useMemo(() => {
    const hex = address.toLowerCase().replace(/^0x/, '').padEnd(40, '0')
    const byte = (i: number) => parseInt(hex.slice(i * 2, i * 2 + 2), 16)
    const hue = Math.round((byte(0) / 255) * 360)
    const grid: boolean[] = []
    for (let row = 0; row < 5; row++) {
      for (let col = 0; col < 5; col++) {
        const mirrored = col < 3 ? col : 4 - col
        grid.push(byte(1 + row * 3 + mirrored) % 2 === 0)
      }
    }
    return {
      cells: grid,
      fg: `hsl(${hue} 55% 38%)`,
      bg: `hsl(${hue} 60% 94%)`,
    }
  }, [address])

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 5 5"
      role="img"
      aria-label="Agent avatar"
      className="shrink-0 rounded-xl"
      style={{ background: bg }}
    >
      {cells.map((on, i) =>
        on ? <rect key={i} x={i % 5} y={Math.floor(i / 5)} width={1} height={1} fill={fg} /> : null,
      )}
    </svg>
  )
}
