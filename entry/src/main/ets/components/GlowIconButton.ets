import { curves } from '@kit.ArkUI';

/**
 * 40vp chrome button that follows the title-bar light-sensing rule: the
 * pointer is the light source, a white glow falls off with distance across
 * the chip surface, and the chip springs on press.
 */
@Component
export struct GlowIconButton {
  @Prop icon: Resource = $r('sys.symbol.folder');
  @Prop tip: string = '';
  @Prop enabledValue: boolean = true;
  @Prop iconColor: ResourceColor = $r('app.color.player_text');
  onAction: () => void = () => {};
  @State private hovered: boolean = false;
  @State private pressed: boolean = false;
  @State private lightX: number = 20;
  @State private lightY: number = 20;

  private lit(): boolean {
    return this.enabledValue && (this.hovered || this.pressed);
  }

  build() {
    Button({ type: ButtonType.Normal }) {
      Stack({ alignContent: Alignment.Center }) {
        // Material chip plus the moving light field, clipped at the chip edge.
        Stack({ alignContent: Alignment.TopStart }) {
          Circle({ width: 72, height: 72 })
            .fill(Color.Transparent)
            .radialGradient({
              center: ['50%', '50%'],
              radius: 36,
              colors: [
                ['#6BFFFFFF', 0],
                ['#24FFFFFF', 0.5],
                ['#00FFFFFF', 1]
              ]
            })
            .position({ x: this.lightX - 36, y: this.lightY - 36 })
            .opacity(this.pressed ? 1 : 0.78)
            .animation({ duration: 220, curve: curves.springMotion(0.3, 0.6) })
            .hitTestBehavior(HitTestMode.None)
        }
        .width(40)
        .height(40)
        .borderRadius(8)
        .linearGradient({
          angle: 180,
          colors: [['#17FFFFFF', 0], ['#0AFFFFFF', 1]]
        })
        .clip(true)
        .scale({ x: this.lit() ? 1 : 0.92, y: this.lit() ? 1 : 0.92 })
        .animation({ duration: 260, curve: curves.springMotion(0.32, 0.62) })
        .opacity(this.lit() ? 1 : 0)
        .animation({ duration: 160, curve: Curve.EaseOut })

        SymbolGlyph(this.icon)
          .fontSize(22)
          .fontColor([this.iconColor])
      }
      .scale({ x: this.pressed ? 0.94 : 1, y: this.pressed ? 0.94 : 1 })
      .animation({ duration: 240, curve: curves.springMotion(0.3, 0.6) })
    }
    .width(40)
    .height(40)
    .padding(0)
    .borderRadius(8)
    .backgroundColor(Color.Transparent)
    .enabled(this.enabledValue)
    .focusOnTouch(false)
    .accessibilityText(this.tip)
    .bindTips(this.tip, { appearingTime: 400 })
    .onHover((isHover: boolean) => {
      if (!this.enabledValue) {
        return;
      }
      this.hovered = isHover;
      if (!isHover) {
        this.pressed = false;
      }
    })
    .onMouse((event: MouseEvent) => {
      if (!this.enabledValue) {
        return;
      }
      if (event.action === MouseAction.Move) {
        this.lightX = event.x;
        this.lightY = event.y;
      } else if (event.action === MouseAction.Press) {
        this.pressed = true;
      } else if (event.action === MouseAction.Release) {
        this.pressed = false;
      }
    })
    .onTouch((event: TouchEvent) => {
      if (!this.enabledValue) {
        return;
      }
      if (event.type === TouchType.Down) {
        if (event.touches.length > 0) {
          this.lightX = event.touches[0].x;
          this.lightY = event.touches[0].y;
        }
        this.pressed = true;
      } else if (event.type === TouchType.Move) {
        if (event.touches.length > 0) {
          this.lightX = event.touches[0].x;
          this.lightY = event.touches[0].y;
        }
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (this.enabledValue) {
        this.onAction();
      }
    })
  }
}
