import { Button as GluestackButton, ButtonText } from '@gluestack-ui/themed';

type ButtonProps = {
  title: string;
  onPress: () => void;
};

export default function Button({ title, onPress }: ButtonProps) {
  return (
    <GluestackButton onPress={onPress}>
      <ButtonText>{title}</ButtonText>
    </GluestackButton>
  );
}
