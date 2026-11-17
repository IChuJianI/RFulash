import { uiMaterial } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import {
  RuffleEngine,
  SCALE_EXACT_FIT,
  SCALE_NO_BORDER,
  SCALE_NO_SCALE,
  SCALE_SHOW_ALL
} from '../bridge/RuffleNapi';
import { GLOW_CLEAR, GLOW_HINTS, GLOW_LABELS, GLOW_SOFT, GLOW_STANDARD, normalizeGlowLevel } from '../common/Glow';
import { ACCENT_COLORS, ACCENT_LABELS, DEFAULT_ACCENT } from '../common/ThemePalette';
import { LANG_SYSTEM, normalizeLanguageIndex } from '../common/Language';

type VoidCallback = () => void;
type ValueCallback = (value: boolean) => void;
type IndexCallback = (index: number) => void;

const KEY_ESCAPE = 2070;
const OPTIONS_QUALITY = 0;
const OPTIONS_SCALE = 1;
const OPTIONS_THEME = 2;
const OPTIONS_LANGUAGE = 3;

export const SETTINGS_PAGE_MAIN = 'main';
export const SETTINGS_PAGE_PLAY = 'play';
export const SETTINGS_PAGE_SOUND = 'sound';
export const SETTINGS_PAGE_PICTURE = 'picture';
export const SETTINGS_PAGE_DISPLAY = 'display';
export const SETTINGS_PAGE_APPEARANCE = 'appearance';
export const SETTINGS_PAGE_THEME = 'theme';
export const SETTINGS_PAGE_GLOW = 'glow';
export const SETTINGS_PAGE_LANGUAGE = 'language';

/** Half-modal settings panel; the system sheet owns the title and close. */
@Component
export struct PlayerMenu {
  @Link visible: boolean;
  @Link page: string;
  @Link volume: number;
  @Link qualityIndex: number;
  @Link scaleMode: number;
  @Link scaleForced: boolean;
  @Link letterbox: boolean;
  @Link playing: boolean;
  @Link fullscreen: boolean;
  @Link hasMovie: boolean;
  @Prop colorModeIndex: number = 0;
  @Prop themeIndex: number = 0;
  @Prop glowLevel: number = GLOW_STANDARD;
  @Prop languageIndex: number = LANG_SYSTEM;
  @Prop showAbout: boolean = true;
  @StorageLink('accentColor') accentColor: string = DEFAULT_ACCENT;
  onReload: VoidCallback = () => {};
  onTogglePlaying: VoidCallback = () => {};
  onStep: VoidCallback = () => {};
  onFullscreen: VoidCallback = () => {};
  onPickTheme: (index: number) => void = () => {};
  onPickAccent: (index: number) => void = () => {};
  onPickGlow: (level: number) => void = () => {};
  onPickLanguage: (index: number) => void = () => {};
  onAbout: VoidCallback = () => {};

  private scaleLabels: Resource[] = [
    $r('app.string.scale_fit_window'),
    $r('app.string.scale_exact_fit'),
    $r('app.string.scale_fill_crop'),
    $r('app.string.scale_original')
  ];
  private scaleValues: number[] = [SCALE_SHOW_ALL, SCALE_EXACT_FIT, SCALE_NO_BORDER, SCALE_NO_SCALE];
  private qualityLabels: Resource[] = [
    $r('app.string.quality_low'),
    $r('app.string.quality_medium'),
    $r('app.string.quality_high'),
    $r('app.string.quality_best')
  ];
  private qualityValues: number[] = [0, 1, 2, 3];
  private themeLabels: Resource[] = [
    $r('app.string.theme_follow_system'),
    $r('app.string.theme_light'),
    $r('app.string.theme_dark')
  ];
  private languageLabels: Resource[] = [
    $r('app.string.language_system'),
    $r('app.string.language_zh'),
    $r('app.string.language_zh_hant'),
    $r('app.string.language_ru'),
    $r('app.string.language_en'),
    $r('app.string.language_ja'),
    $r('app.string.language_ko')
  ];

  private str(res: Resource): string {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      return context.resourceManager.getStringSync(res.id);
    } catch (error) {
      return '';
    }
  }

  private close(): void {
    this.visible = false;
  }

  private currentScaleIndex(): number {
    const index = this.scaleValues.indexOf(this.scaleMode);
    return index < 0 ? 0 : index;
  }

  private currentQualityIndex(): number {
    const index = this.qualityValues.indexOf(this.qualityIndex);
    return index < 0 ? 1 : index;
  }

  private currentThemeIndex(): number {
    return this.colorModeIndex >= 0 && this.colorModeIndex < this.themeLabels.length ? this.colorModeIndex : 0;
  }

  private currentAccentIndex(): number {
    return this.themeIndex >= 0 && this.themeIndex < ACCENT_LABELS.length ? this.themeIndex : 0;
  }

  private currentGlowIndex(): number {
    return normalizeGlowLevel(this.glowLevel);
  }

  private currentLanguageIndex(): number {
    return normalizeLanguageIndex(this.languageIndex);
  }

  private glowNote(): Resource {
    if (uiMaterial.isImmersiveMaterialSupported()) {
      return $r('app.string.glow_note_supported');
    }
    return $r('app.string.glow_note_unsupported');
  }

  private optionsSelected(kind: number): number {
    if (kind === OPTIONS_QUALITY) {
      return this.currentQualityIndex();
    }
    if (kind === OPTIONS_SCALE) {
      return this.currentScaleIndex();
    }
    if (kind === OPTIONS_LANGUAGE) {
      return this.currentLanguageIndex();
    }
    return this.currentThemeIndex();
  }

  private pickScale(index: number): void {
    if (index === this.currentScaleIndex()) {
      return;
    }
    const value = this.scaleValues[index];
    this.scaleMode = value;
    RuffleEngine.setScaleMode(value, this.scaleForced);
  }

  private pickQuality(index: number): void {
    if (index === this.currentQualityIndex()) {
      return;
    }
    const value = this.qualityValues[index];
    this.qualityIndex = value;
    RuffleEngine.setQuality(value);
  }

  private pickTheme(index: number): void {
    if (index === this.colorModeIndex) {
      return;
    }
    this.onPickTheme(index);
  }

  private toggleForced(value: boolean): void {
    this.scaleForced = value;
    RuffleEngine.setScaleMode(this.scaleMode, value);
  }

  private toggleLetterbox(value: boolean): void {
    this.letterbox = value;
    RuffleEngine.setLetterbox(value);
  }

  private changeVolume(value: number): void {
    this.volume = value;
    RuffleEngine.setVolume(value);
  }

  @Builder
  GroupTitle(title: Resource) {
    Text(title)
      .fontSize(12)
      .fontColor($r('app.color.player_text_tertiary'))
      .width('100%')
      .padding({ left: 4 })
      .margin({ top: 4 })
  }

  @Builder
  RowDivider() {
    Divider()
      .color($r('app.color.player_divider'))
      .margin({ left: 16, right: 16 })
  }

  @Builder
  ActionRow(label: Resource, canAct: boolean, action: VoidCallback) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .opacity(canAct ? 1 : 0.4)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      if (canAct) {
        action();
      }
    })
  }

  @Builder
  PlayPauseRow() {
    Row() {
      Text(this.playing ? $r('app.string.menu_pause') : $r('app.string.menu_resume'))
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .opacity(this.hasMovie ? 1 : 0.4)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      if (this.hasMovie) {
        this.onTogglePlaying();
      }
    })
  }

  @Builder
  StepRow() {
    Row() {
      Text($r('app.string.player_step_forward'))
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .opacity(this.hasMovie && !this.playing ? 1 : 0.4)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      if (this.hasMovie && !this.playing) {
        this.onStep();
      }
    })
  }

  @Builder
  NavRow(label: Resource, value: string, action: VoidCallback) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .layoutWeight(1)
      if (value.length > 0) {
        Text(value)
          .fontSize(13)
          .fontColor($r('app.color.player_text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(14)
        .fontColor([$r('app.color.player_text_tertiary')])
        .accessibilityLevel('no')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .hoverEffect(HoverEffect.Highlight)
    .accessibilityText(value.length > 0 ? `${this.str(label)}, ${value}` : this.str(label))
    .onClick(() => action())
  }

  @Builder
  SwitchRow(label: Resource, value: boolean, onChange: ValueCallback) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(this.accentColor)
        .onChange((isOn: boolean) => onChange(isOn))
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  VolumeCard() {
    Column({ space: 2 }) {
      Row() {
        Text($r('app.string.player_master_volume'))
          .fontSize(14)
          .fontColor($r('app.color.player_text'))
        Blank()
        Text(`${Math.round(this.volume * 100)}%`)
          .fontSize(13)
          .fontColor($r('app.color.player_text_tertiary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      Slider({ value: this.volume, min: 0, max: 1, step: 0.01 })
        .width('100%')
        .selectedColor(this.accentColor)
        .showTips(true)
        .padding({ left: 12, right: 12 })
        .onChange((value: number) => this.changeVolume(value))
    }
    .width('100%')
    .padding({ bottom: 8 })
    .backgroundColor($r('app.color.player_fill'))
    .borderRadius(15)
    .clip(true)
  }

  @Builder
  MainPage() {
    Column({ space: 8 }) {
      this.GroupTitle($r('app.string.settings_basic_group'))
      Column() {
        this.NavRow($r('app.string.row_play_settings'), '', () => {
          this.page = SETTINGS_PAGE_PLAY;
        })
        this.RowDivider()
        this.NavRow($r('app.string.row_sound_settings'), `${Math.round(this.volume * 100)}%`, () => {
          this.page = SETTINGS_PAGE_SOUND;
        })
        this.RowDivider()
        this.NavRow($r('app.string.row_picture_settings'), this.str(this.qualityLabels[this.currentQualityIndex()]), () => {
          this.page = SETTINGS_PAGE_PICTURE;
        })
        this.RowDivider()
        this.NavRow($r('app.string.row_display_settings'), this.str(this.scaleLabels[this.currentScaleIndex()]), () => {
          this.page = SETTINGS_PAGE_DISPLAY;
        })
        this.RowDivider()
        this.NavRow($r('app.string.row_language_settings'),
          this.str(this.languageLabels[this.currentLanguageIndex()]), () => {
            this.page = SETTINGS_PAGE_LANGUAGE;
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.player_fill'))
      .borderRadius(15)
      .clip(true)

      this.GroupTitle($r('app.string.settings_look_group'))
      Column() {
        this.NavRow($r('app.string.row_appearance_settings'), this.str(this.themeLabels[this.currentThemeIndex()]), () => {
          this.page = SETTINGS_PAGE_APPEARANCE;
        })
        this.RowDivider()
        this.NavRow($r('app.string.row_glow'), this.str(GLOW_LABELS[this.currentGlowIndex()]), () => {
          this.page = SETTINGS_PAGE_GLOW;
        })
        this.RowDivider()
        this.NavRow($r('app.string.row_theme_settings'), this.str(ACCENT_LABELS[this.currentAccentIndex()]), () => {
          this.page = SETTINGS_PAGE_THEME;
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.player_fill'))
      .borderRadius(15)
      .clip(true)

      if (this.showAbout) {
        this.GroupTitle($r('app.string.about_title'))
        Column() {
          this.NavRow($r('app.string.row_about'), '', () => {
            this.close();
            this.onAbout();
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.player_fill'))
        .borderRadius(15)
        .clip(true)
      }
    }
    .width('100%')
  }

  @Builder
  BackRow() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row({ space: 2 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(16)
          .fontColor([this.accentColor])
          .accessibilityLevel('no')
        Text($r('app.string.player_settings_title'))
          .fontSize(14)
          .fontColor(this.accentColor)
      }
    }
    .height(40)
    .padding({ left: 8, right: 12 })
    .backgroundColor(Color.Transparent)
    .borderRadius(8)
    .hoverEffect(HoverEffect.Highlight)
    .accessibilityText($r('app.string.a11y_back_player_settings'))
    .onClick(() => {
      this.page = SETTINGS_PAGE_MAIN;
    })
  }

  @Builder
  OptionsCard(labels: Resource[], kind: number, onPick: IndexCallback) {
    Column() {
      ForEach(labels, (label: Resource, index: number) => {
        Row() {
          Text(label)
            .fontSize(14)
            .fontColor($r('app.color.player_text'))
            .layoutWeight(1)
          if (this.optionsSelected(kind) === index) {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(18)
              .fontColor([this.accentColor])
              .accessibilityLevel('no')
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .hoverEffect(HoverEffect.Highlight)
        .accessibilityText(label)
        .onClick(() => onPick(index))

        if (index < labels.length - 1) {
          Divider()
            .color($r('app.color.player_divider'))
            .margin({ left: 16, right: 16 })
        }
      }, (label: Resource) => label.id.toString())
    }
    .width('100%')
    .backgroundColor($r('app.color.player_fill'))
    .borderRadius(15)
    .clip(true)
  }

  @Builder
  PlayPage() {
    Column({ space: 8 }) {
      this.BackRow()
      Column() {
        this.PlayPauseRow()
        this.RowDivider()
        this.StepRow()
        this.RowDivider()
        this.ActionRow($r('app.string.player_reload'), this.hasMovie, () => {
          this.close();
          this.onReload();
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.player_fill'))
      .borderRadius(15)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  SoundPage() {
    Column({ space: 8 }) {
      this.BackRow()
      this.VolumeCard()
    }
    .width('100%')
  }

  @Builder
  PicturePage() {
    Column({ space: 8 }) {
      this.BackRow()
      this.OptionsCard(this.qualityLabels, OPTIONS_QUALITY, (index: number) => this.pickQuality(index))
    }
    .width('100%')
  }

  @Builder
  DisplayPage() {
    Column({ space: 8 }) {
      this.BackRow()
      this.OptionsCard(this.scaleLabels, OPTIONS_SCALE, (index: number) => this.pickScale(index))
      Column() {
        this.SwitchRow($r('app.string.player_force_scale'), this.scaleForced, (value: boolean) => this.toggleForced(value))
        this.RowDivider()
        this.SwitchRow($r('app.string.player_letterbox'), this.letterbox, (value: boolean) => this.toggleLetterbox(value))
        this.RowDivider()
        this.ActionRow(this.fullscreen ? $r('app.string.player_exit_fullscreen') : $r('app.string.player_enter_fullscreen'),
          true, () => {
            this.close();
            this.onFullscreen();
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.player_fill'))
      .borderRadius(15)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  AppearancePage() {
    Column({ space: 8 }) {
      this.BackRow()
      this.OptionsCard(this.themeLabels, OPTIONS_THEME, (index: number) => this.pickTheme(index))
    }
    .width('100%')
  }

  @Builder
  AccentCard() {
    Column() {
      ForEach(ACCENT_LABELS, (label: Resource, index: number) => {
        Row({ space: 12 }) {
          Circle({ width: 18, height: 18 })
            .fill(ACCENT_COLORS[index])
          Text(label)
            .fontSize(14)
            .fontColor($r('app.color.player_text'))
            .layoutWeight(1)
          if (this.themeIndex === index) {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(18)
              .fontColor([this.accentColor])
              .accessibilityLevel('no')
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .hoverEffect(HoverEffect.Highlight)
        .accessibilityText(label)
        .onClick(() => this.onPickAccent(index))

        if (index < ACCENT_LABELS.length - 1) {
          Divider()
            .color($r('app.color.player_divider'))
            .margin({ left: 46, right: 16 })
        }
      }, (label: Resource) => label.id.toString())
    }
    .width('100%')
    .backgroundColor($r('app.color.player_fill'))
    .borderRadius(15)
    .clip(true)
  }

  @Builder
  ThemePage() {
    Column({ space: 8 }) {
      this.BackRow()
      this.AccentCard()
    }
    .width('100%')
  }

  @Builder
  GlowRow(level: number) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(GLOW_LABELS[level])
          .fontSize(14)
          .fontColor($r('app.color.player_text'))
          .width('100%')
          .maxLines(1)
        Text(GLOW_HINTS[level])
          .fontSize(12)
          .fontColor($r('app.color.player_text_tertiary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.currentGlowIndex() === level) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(18)
          .fontColor([this.accentColor])
          .accessibilityLevel('no')
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .hoverEffect(HoverEffect.Highlight)
    .accessibilityText(GLOW_LABELS[level])
    .onClick(() => {
      this.onPickGlow(normalizeGlowLevel(level));
    })
  }

  @Builder
  GlowPage() {
    Column({ space: 8 }) {
      this.BackRow()
      Column() {
        this.GlowRow(GLOW_SOFT)
        this.RowDivider()
        this.GlowRow(GLOW_STANDARD)
        this.RowDivider()
        this.GlowRow(GLOW_CLEAR)
      }
      .width('100%')
      .backgroundColor($r('app.color.player_fill'))
      .borderRadius(15)
      .clip(true)

      Text(this.glowNote())
        .fontSize(12)
        .fontColor($r('app.color.player_text_secondary'))
        .width('100%')
        .padding({ left: 4, right: 4, top: 4 })
    }
    .width('100%')
  }

  @Builder
  LanguagePage() {
    Column({ space: 8 }) {
      this.BackRow()
      this.OptionsCard(this.languageLabels, OPTIONS_LANGUAGE, (index: number) => this.onPickLanguage(index))
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 8 }) {
        if (this.page === SETTINGS_PAGE_PLAY) {
          this.PlayPage()
        } else if (this.page === SETTINGS_PAGE_SOUND) {
          this.SoundPage()
        } else if (this.page === SETTINGS_PAGE_PICTURE) {
          this.PicturePage()
        } else if (this.page === SETTINGS_PAGE_DISPLAY) {
          this.DisplayPage()
        } else if (this.page === SETTINGS_PAGE_APPEARANCE) {
          this.AppearancePage()
        } else if (this.page === SETTINGS_PAGE_THEME) {
          this.ThemePage()
        } else if (this.page === SETTINGS_PAGE_GLOW) {
          this.GlowPage()
        } else if (this.page === SETTINGS_PAGE_LANGUAGE) {
          this.LanguagePage()
        } else {
          this.MainPage()
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 16 })
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && event.keyCode === KEY_ESCAPE) {
        if (this.page !== SETTINGS_PAGE_MAIN) {
          this.page = SETTINGS_PAGE_MAIN;
        } else {
          this.close();
        }
      }
    })
  }
}
