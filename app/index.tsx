import { View, Text, Button } from "react-native";
import { useRouter } from "expo-router";
import "../global.css"

export default function HomeScreen() {
  const router = useRouter();

  return (
    <View >
      <Text>Home Screen</Text>
      <Button title="Ir para Perfil" onPress={() => router.push("/TestScreen")} />
    </View>
  );
}
