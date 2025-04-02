import { View, Text, Button } from "react-native";
import { useRouter } from "expo-router";

export default function HomeScreen() {
  const router = useRouter();

  return (
    <View className="bg-red-500">
      <Text className="p-5">Home Screen</Text>
      <Button title="Ir para Perfil" onPress={() => router.push("/TestScreen")} />
    </View>
  );
}
