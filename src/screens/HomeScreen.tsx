import { View, Text, Button } from 'react-native';
import { HomeScreenNavigationProp } from '../navigation/types'; // Importa os tipos
import { useNavigation } from '@react-navigation/native';

export default function HomeScreen() {
  const navigation = useNavigation<HomeScreenNavigationProp>();

  return (
    <View>
      <Text>Home Screen</Text>
      <Button title="Ir para Perfil" onPress={() => navigation.navigate('Profile')} />
    </View>
  );
}
