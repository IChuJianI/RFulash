import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import { DEFAULT_ACCENT } from '../common/ThemePalette';

const APP_NAME = 'RFulash';
const PACKAGE_NAME = 'com.52wfun.rfulash';
const CONTACT_EMAIL = '3093376617@qq.com';
const WEBSITE = 'www.52wfun.com';

function installedVersionName(): string {
  try {
    const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    return info.versionName;
  } catch (error) {
    return '';
  }
}

const APP_VERSION = installedVersionName();

/** Half-modal about panel; the system sheet owns the title and close. */
@Component
export struct AboutPanel {
  onOpenLicenses: () => void = (): void => {};
  @StorageLink('accentColor') private accentColor: string = DEFAULT_ACCENT;

  private copyText(text: string): void {
    const context = this.getUIContext();
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data)
      .then(() => {
        context.getPromptAction().showToast({ message: $r('app.string.toast_copied'), duration: 1200 });
      })
      .catch((error: BusinessError) => {
        console.error(`copy to clipboard failed: ${error.message}`);
        context.getPromptAction().showToast({ message: $r('app.string.toast_copy_failed'), duration: 1200 });
      });
  }

  @Builder
  BrandCard() {
    Row({ space: 14 }) {
      Image($r('app.media.startIcon'))
        .width(48)
        .height(48)
        .borderRadius(14)
        .clip(true)
      Column({ space: 3 }) {
        Text(APP_NAME)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.player_text'))
          .maxLines(1)
        Text($r('app.string.app_tagline'))
          .fontSize(12)
          .fontColor($r('app.color.player_text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(96)
    .padding({ left: 16, right: 16 })
    .borderRadius(15)
    .backgroundColor($r('app.color.player_fill'))
    .accessibilityGroup(true)
  }

  @Builder
  InfoCard(label: Resource, value: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.player_text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.player_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: 60 })
    .padding({ left: 16, right: 12, top: 10, bottom: 10 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(15)
    .backgroundColor($r('app.color.player_fill'))
    .accessibilityGroup(true)
  }

  @Builder
  CopyCard(label: Resource, value: string, action: () => void) {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Column({ space: 2 }) {
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.player_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(value)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: 60 })
    .padding({ left: 16, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.player_fill'))
    .borderRadius(15)
    .hoverEffect(HoverEffect.Highlight)
    .accessibilityGroup(true)
    .onClick(() => action())
  }

  @Builder
  LicensesCard() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row() {
        Text($r('app.string.about_licenses'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.player_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('app.color.player_text_secondary')])
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: 60 })
    .padding({ left: 16, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.player_fill'))
    .borderRadius(15)
    .hoverEffect(HoverEffect.Highlight)
    .accessibilityGroup(true)
    .onClick(() => {
      this.onOpenLicenses();
    })
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        this.BrandCard()

        Row({ space: 8 }) {
          this.InfoCard($r('app.string.about_version'), APP_VERSION)
          this.InfoCard($r('app.string.about_developer'), '李晨')
        }
        .width('100%')

        Row({ space: 8 }) {
          this.InfoCard($r('app.string.about_package'), PACKAGE_NAME)
          this.CopyCard($r('app.string.about_website'), WEBSITE, () => this.copyText(WEBSITE))
        }
        .width('100%')

        Row({ space: 8 }) {
          this.CopyCard($r('app.string.about_email'), CONTACT_EMAIL, () => this.copyText(CONTACT_EMAIL))
          this.LicensesCard()
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }
}
