import { View, Text, Button } from "react-native";
import { useRouter } from "expo-router";

export default function TestScreen() {
  const router = useRouter();

  return (
    <View className="">
      <Text className="text-white text-lg font-bold">Test Screen</Text>
      <Button title="Ir para Perfil" onPress={() => router.push("/HomeScreen")} />
    </View>
  );
}
