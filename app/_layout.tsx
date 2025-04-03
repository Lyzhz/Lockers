import { useState, useEffect } from "react";
import { Stack } from "expo-router";
import SplashScreen from "../app/SplashScreen";

export default function Layout() {
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    setTimeout(() => {
      setIsLoading(false);
    }, 2000);
  }, []);

  if (isLoading) return <SplashScreen />;

  return <Stack screenOptions={{ headerShown: false }} />;
}