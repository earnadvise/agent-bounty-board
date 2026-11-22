import { motion } from 'framer-motion'
import type { ReactNode } from 'react'

type Props = {
  id: string
  eyebrow: string
  title: string
  lead?: string
  dark?: boolean
  children: ReactNode
}

/** Shared frame for a landing section: eyebrow, headline, optional lead, content. */
export function Section({ id, eyebrow, title, lead, dark, children }: Props) {
  return (
    <section id={id} style={dark ? { background: '#0d1b2f' } : undefined}>
      <motion.div
        className="mx-auto max-w-6xl px-5 py-20 md:py-24"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-80px' }}
        transition={{ duration: 0.5 }}
      >
        <div className="text-xs font-semibold uppercase tracking-[0.1em]" style={{ color: dark ? '#acc6e9' : 'var(--accent-hover)' }}>
          {eyebrow}
        </div>
        <h2
          className="display mt-3 max-w-3xl text-balance text-3xl font-bold md:text-5xl"
          style={{ color: dark ? '#f9faf3' : 'var(--ink)', letterSpacing: '-0.035em' }}
        >
          {title}
        </h2>
        {lead && (
          <p className="mt-4 max-w-2xl text-pretty text-base md:text-lg" style={{ color: dark ? '#cbd5e1' : 'var(--ink-2)' }}>
            {lead}
          </p>
        )}
        <div className="mt-10">{children}</div>
      </motion.div>
    </section>
  )
}
