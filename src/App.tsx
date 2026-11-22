import { useRoute } from '@/hooks/useRoute'
import BoardApp from '@/BoardApp'
import Landing from '@/pages/Landing'

export default function App() {
  const route = useRoute()
  return route === 'app' ? <BoardApp /> : <Landing />
}
