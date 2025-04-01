import { GluestackUIProvider } from '@gluestack-ui/themed';
import { theme } from './src/theme/theme';
import AppNavigator from './src/navigation/AppNavigator';

export default function App() {
  return (
    <GluestackUIProvider config={theme}>
      <AppNavigator />
    </GluestackUIProvider>
  );
}
