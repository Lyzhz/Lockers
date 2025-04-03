import React from "react";
import { View, Text, StyleSheet } from "react-native";
import { useData } from "../src/context/DataContext"; // Ajuste o caminho conforme necessário

export default function TesteScreen() {
  const { data, loading } = useData();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>🚀 Status: {loading ? "Carregando..." : "Pronto!"}</Text>
      <Text style={styles.dataText}>📦 Dados: {JSON.stringify(data, null, 2)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    padding: 20,
    backgroundColor: "#f2f2f2",
  },
  title: {
    fontSize: 20,
    fontWeight: "bold",
    marginBottom: 10,
  },
  dataText: {
    fontSize: 16,
    textAlign: "center",
  },
});
