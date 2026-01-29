// Safe area wrapper component
import { ViewStyle } from 'react-native';
import {
    SafeAreaView,
    useSafeAreaInsets,
} from 'react-native-safe-area-context';

interface SafeViewProps {
  children: React.ReactNode;
  edges?: ('top' | 'bottom' | 'left' | 'right')[];
  style?: ViewStyle;
}

export function SafeView({ children, edges, style }: SafeViewProps) {
  return (
    <SafeAreaView style={[{ flex: 1 }, style]} edges={edges}>
      {children}
    </SafeAreaView>
  );
}

export function useSafeArea() {
  const insets = useSafeAreaInsets();
  return {
    top: insets.top,
    bottom: insets.bottom,
    paddingTop: Math.max(insets.top, 16),
    paddingBottom: Math.max(insets.bottom, 16),
  };
}
