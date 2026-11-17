export const ACCENT_LABELS: Resource[] = [
  $r('app.string.accent_orange'),
  $r('app.string.accent_blue'),
  $r('app.string.accent_purple'),
  $r('app.string.accent_red'),
  $r('app.string.accent_teal')
];
export const ACCENT_COLORS: string[] = ['#ED6F21', '#0A59F7', '#7E3FF2', '#E84026', '#00A5A5'];
export const DEFAULT_ACCENT = '#ED6F21';
export const DEFAULT_ACCENT_BG = '#26ED6F21';

export function accentColorFor(index: number): string {
  return ACCENT_COLORS[index >= 0 && index < ACCENT_COLORS.length ? index : 0];
}

export function accentBgFor(index: number): string {
  return '#26' + accentColorFor(index).substring(1);
}
