/**
 * Adaptive layout values following the HarmonyOS window size classes:
 * compact (<600vp), medium (600-840vp) and expanded (>=840vp), with an extra
 * >=1080vp tier for the PC panel layout.
 */
export class LayoutSpec {
  static readonly BREAKPOINT_MD: number = 600;
  static readonly BREAKPOINT_LG: number = 840;
  static readonly BREAKPOINT_XL: number = 1080;

  static readonly SIDEBAR_WIDTH: number = 280;
  static readonly PANEL_WIDTH: number = 320;

  // HdsNavigation MINI title bar; the stage is padded down by this height
  // because the immersive title bar floats over its content.
  static readonly TITLE_BAR_HEIGHT: number = 56;
  static readonly TITLE_BAR_HEIGHT_2IN1: number = 48;
  static readonly TAB_BAR_HEIGHT: number = 56;
  static readonly TAB_BAR_WIDTH_SMALL: number = 220;
  static readonly TAB_BAR_WIDTH_MEDIUM: number = 240;
  static readonly TAB_BAR_WIDTH_LARGE: number = 260;
  static readonly TAB_BAR_SIDE_MARGIN: number = 16;
  static readonly TAB_BAR_BOTTOM_GAP: number = 16;

  static readonly TOUCH_TARGET: number = 44;
}
