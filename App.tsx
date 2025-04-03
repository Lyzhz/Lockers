import React, { useEffect, useContext } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import SplashScreen from 'expo-splash-screen'; // Importando SplashScreen
import MainScreen from './app/index'; // Sua tela principal
import { DataProvider, useData } from './src/context/DataContext'; // Seu contexto de dados

const Stack = createStackNavigator();

const MainNavigator = () => {
  const { loading } = useData(); // Obtém o estado de carregamento do contexto

  useEffect(() => {
    // Impede que a splash screen desapareça automaticamente
    SplashScreen.preventAutoHideAsync();

    // Quando o carregamento terminar, esconde a splash screen
    if (!loading) {
      SplashScreen.hideAsync();
    }
  }, [loading]); // O efeito será reexecutado quando 'loading' mudar

  if (loading) {
    return null; // Enquanto o carregamento estiver em andamento, não renderiza nada
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Home" component={MainScreen} />
    </Stack.Navigator>
  );
};

const App = () => {
  return (
    <DataProvider>
      <NavigationContainer>
        <MainNavigator />
      </NavigationContainer>
    </DataProvider>
  );
};

export default App;
