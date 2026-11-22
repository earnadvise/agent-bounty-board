import { Hero } from '@/components/landing/Hero'
import { LiveStats } from '@/components/landing/LiveStats'
import { HowItWorks } from '@/components/landing/HowItWorks'
import { AgentIdSection } from '@/components/landing/AgentIdSection'
import { AgentFlow } from '@/components/landing/AgentFlow'
import { Trust } from '@/components/landing/Trust'
import { FinalCta, Footer } from '@/components/landing/Footer'

export default function Landing() {
  return (
    <div className="min-h-dvh">
      <Hero />
      <LiveStats />
      <HowItWorks />
      <AgentIdSection />
      <AgentFlow />
      <Trust />
      <FinalCta />
      <Footer />
    </div>
  )
}
