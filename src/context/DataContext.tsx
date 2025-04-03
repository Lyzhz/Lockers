import React, { createContext, useState, useEffect, ReactNode, useContext } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";

// Definição dos tipos

export type StoredDataType = { [key: string]: string };

type DataContextType = {
  data: StoredDataType;
  loading: boolean;
  setData: React.Dispatch<React.SetStateAction<StoredDataType>>;
  sendLog: (CodigoEvento: string, DescricaoEvento: string) => Promise<void>; // Adiciona sendLog ao contexto
};

const DataContext = createContext<DataContextType | undefined>(undefined);

type DataProviderProps = { children: ReactNode };

export const DataProvider: React.FC<DataProviderProps> = ({ children }) => {
  const [data, setData] = useState<StoredDataType>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      console.log("🔍 Carregando dados do AsyncStorage...");
      const keys = [
        "NomeTablet", "NivelAcesso", "IdPorta", "IdSite", "DeviceId", "NomeNivelAcesso",
        "PatrimonioTablet", "QdePortas", "NomeToken", "WsValidaDados", "WsNivelAcesso",
        "WsEventosSistema", "WsLocacao", "WsLogSistema", "WsArmazenaPessoas", "MacTerminal",
        "idDevice", "TipodeLocação", "TipodeLeitura", "ArmazenaPessoas"
      ];

      const storedData: StoredDataType = {};
      for (const key of keys) {
        const value = await AsyncStorage.getItem(key);
        storedData[key] = value || "*";
      }

      console.log("✅ Dados carregados:", storedData);

      setData(storedData);
      setLoading(false);
    };

    loadData();
  }, []);

  // Função para enviar log
  const sendLog = async (CodigoEvento: string, DescricaoEvento: string) => {
    if (!data.WsLogSistema) {
      console.error("⚠️ URL do serviço de log não definida!");
      return;
    }

    const requestBody = {
      CodigoEvento,
      Descricao: DescricaoEvento,
      NomeControladora: data.NomeTablet,
      IdSiteControladora: data.IdSite,
      IdControladora: data.IdPorta, // Corrigido o nome da chave que estava "IgldDoor"
      token: data.NomeToken, // Corrigido o nome da chave que estava "IgToken"
    };

    try {
      console.log("📤 Enviando log...", requestBody);

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

  return (
    <DataContext.Provider value={{ data, loading, setData, sendLog }}>
      {children}
    </DataContext.Provider>
  );
};

// Hook customizado para facilitar o uso do contexto
export const useData = (): DataContextType => {
  const context = useContext(DataContext);
  if (!context) {
    throw new Error("useData deve ser usado dentro de um DataProvider");
  }
  return context;
};

export default DataContext;
