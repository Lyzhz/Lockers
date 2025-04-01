import { NativeStackNavigationProp } from '@react-navigation/native-stack';

// Defina as telas disponíveis na navegação
export type RootStackParamList = {
  Home: undefined;
  Profile: undefined;
};

// Defina o tipo para o navigation prop
export type HomeScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'Home'>;
