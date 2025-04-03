// No arquivo onde você tem o DataContext
import { useData } from "../context/DataContext"; // Certifique-se do caminho correto

export const sendLog = async (CodigoEvento: string, DescricaoEvento: string, data: any) => {
  if (!data.WsLogSistema) {
    console.error("❌ Erro: URL do WebService (WsLogSistema) não encontrada.");
    return;
  }

  const requestBody = {
    CodigoEvento,
    Descricao: DescricaoEvento,
    NomeControladora: data.NomeTablet,
    IdSiteControladora: data.IdSite,
    IdControladora: data.IgldDoor,
    token: data.IgToken,
  };

  try {
    console.log("📤 Enviando log para:", data.WsLogSistema);
    console.log("📦 Payload:", requestBody);

    const response = await fetch(data.WsLogSistema, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const responseData = await response.json();
    console.log("✅ Resposta do servidor:", responseData);
  } catch (error) {
    console.error("❌ Erro ao enviar log:", error);
  }
};
