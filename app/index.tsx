import React, { useRef, useEffect } from "react";
import { View, Text, Image, StyleSheet, Animated, Pressable, Easing } from "react-native";
import { useRouter } from "expo-router";

export default function HomeScreen() {
  const router = useRouter();
  const buttonTitles = ["SCA", "Refectory", "Lockers", "Collect Data", "Facial"];

  // Animações dos botões
  const animations = buttonTitles.map(() => ({
    fade: useRef(new Animated.Value(0)).current,
    slide: useRef(new Animated.Value(50)).current, // Começa mais baixo
    scale: useRef(new Animated.Value(1)).current, // Para efeito de clique
  }));

  useEffect(() => {
    // Animação dos botões em cascata
    animations.forEach((anim, index) => {
      setTimeout(() => {
        Animated.parallel([
          Animated.timing(anim.slide, {
            toValue: 0,
            duration: 1200,
            easing: Easing.out(Easing.exp),
            useNativeDriver: true,
          }),
          Animated.timing(anim.fade, {
            toValue: 1,
            duration: 800,
            useNativeDriver: true,
          }),
        ]).start();
      }, index * 200);
    });
  }, []);

  // Função para efeito de clique
  const handlePressIn = (index: number) => {
    Animated.spring(animations[index].scale, {
      toValue: 0.9,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = (index: number) => {
    Animated.spring(animations[index].scale, {
      toValue: 1,
      useNativeDriver: true,
    }).start();
  };

  // Função chamada ao pressionar a imagem por 2 segundos
  const handleLongPress = () => {
    router.push("/ConfigScreen"); // Redireciona para a ConfigScreen após 2 segundos
  };

  return (
    <View style={styles.container}>
      {/* Conteúdo principal (imagem + texto) */}
      <View style={styles.content}>
        <Pressable onLongPress={handleLongPress} delayLongPress={2000}>
          <Image
            source={require("../src/components/ui/images/image1.png")}
            style={styles.image}
          />
        </Pressable>
        <View style={styles.textContainer}>
          <Text style={styles.text}>GSP - HOME</Text>
        </View>
      </View>

      {/* Botões com animação individual */}
      <View style={styles.buttonsContainer}>
        {buttonTitles.map((title, index) => (
          <Pressable
            key={index}
            onPressIn={() => handlePressIn(index)}
            onPressOut={() => handlePressOut(index)}
            onPress={() => console.log(`${title} clicado`)}
          >
            <Animated.View
              style={[
                styles.button,
                {
                  opacity: animations[index].fade,
                  transform: [
                    { translateY: animations[index].slide },
                    { scale: animations[index].scale },
                  ],
                },
              ]}
            >
              <Text style={styles.buttonText}>{title}</Text>
            </Animated.View>
          </Pressable>
        ))}
      </View>

      {/* Área vazia com borda ocupando o restante da tela */}
      <View style={styles.emptySpace} />

      {/* Rodapé fixo no final da tela */}
      <View style={styles.footer}>
        <Text style={styles.footerText}>
          GSP - Gestão de Segurança Patrimonial - Todos os direitos reservados©.
        </Text>
      </View>
    </View>
  );
}

// Estilos
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "space-between",
    paddingVertical: 20,
    backgroundColor: "#fff",
  },
  content: {
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 2,
    borderColor: "#FFF",
    borderRadius: 10,
    padding: 10,
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: "#f2f5f7",
  },
  image: {
    width: 60,
    height: 60,
    borderRadius: 10,
    marginLeft: 10,
  },
  textContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  text: {
    fontSize: 25,
    fontWeight: "bold",
    color: "#333",
  },
  buttonsContainer: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: 20,
    gap: 10,
  },
  button: {
    width: 140,
    height: 85,
    backgroundColor: "#007BFF",
    paddingVertical: 15,
    borderRadius: 8,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#333",
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.5,
    shadowRadius: 6,
    elevation: 8,
  },
  buttonText: {
    color: "#FFF",
    fontWeight: "bold",
    fontSize: 19,
  },
  emptySpace: {
    flex: 1,
    borderWidth: 2,
    borderColor: "#FFF",
    borderRadius: 10,
    margin: 20,
    backgroundColor: "#f2f5f7",
  },
  footer: {
    alignItems: "center",
    paddingVertical: 10,
    borderTopWidth: 2,
    borderColor: "#FFF",
    backgroundColor: "#222",
  },
  footerText: {
    fontSize: 16,
    fontWeight: "bold",
    color: "#FFF",
  },
});
