import { uiMaterial } from '@kit.ArkUI';

export const GLOW_SOFT: number = 0;
export const GLOW_STANDARD: number = 1;
export const GLOW_CLEAR: number = 2;

export const GLOW_LABELS: Resource[] = [
  $r('app.string.glow_soft'),
  $r('app.string.glow_standard'),
  $r('app.string.glow_clear')
];
export const GLOW_HINTS: Resource[] = [
  $r('app.string.glow_hint_soft'),
  $r('app.string.glow_hint_standard'),
  $r('app.string.glow_hint_clear')
];

export function normalizeGlowLevel(level: number): number {
  return level === GLOW_SOFT || level === GLOW_CLEAR ? level : GLOW_STANDARD;
}

/** 悬浮底栏与半模态共用：柔和更厚、通透更薄，标准档对应官方底部悬浮的 THIN。 */
export function glowMaterialStyle(level: number): uiMaterial.ImmersiveStyle {
  if (level === GLOW_SOFT) {
    return uiMaterial.ImmersiveStyle.THICK;
  }
  if (level === GLOW_CLEAR) {
    return uiMaterial.ImmersiveStyle.ULTRA_THIN;
  }
  return uiMaterial.ImmersiveStyle.THIN;
}
