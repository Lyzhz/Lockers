import { GluestackUIProvider } from '@gluestack-ui/themed';
import { theme } from './src/theme/theme';
import "./global.css"

export default function App() {
  return (
    <GluestackUIProvider config={theme}> 
    </GluestackUIProvider>
  );
}
