import { View, Text } from 'react-native';

type CardProps = {
  title: string;
  content: string;
};

export default function Card({ title, content }: CardProps) {
  return (
    <View style={{ padding: 10, margin: 10, backgroundColor: '#f8f9fa', borderRadius: 10 }}>
      <Text style={{ fontWeight: 'bold', fontSize: 16 }}>{title}</Text>
      <Text>{content}</Text>
    </View>
  );
}
