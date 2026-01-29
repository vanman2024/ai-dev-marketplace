// Responsive dimension utilities
import { Dimensions, PixelRatio } from 'react-native';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');
const BASE_WIDTH = 393; // iPhone 14 Pro

// Width percentage
export function wp(widthPercent: number): number {
  return PixelRatio.roundToNearestPixel((SCREEN_WIDTH * widthPercent) / 100);
}

// Height percentage
export function hp(heightPercent: number): number {
  return PixelRatio.roundToNearestPixel((SCREEN_HEIGHT * heightPercent) / 100);
}

// Moderate scale for fonts
export function moderateScale(size: number, factor = 0.5): number {
  const scale = SCREEN_WIDTH / BASE_WIDTH;
  return size + (scale - 1) * size * factor;
}

// Device detection
export const isSmallDevice = SCREEN_WIDTH < 375;
export const isLargeDevice = SCREEN_WIDTH >= 428;
export const isTablet = SCREEN_WIDTH >= 768;
