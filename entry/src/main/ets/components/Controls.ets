import { common } from '@kit.AbilityKit';
import { RecentMovie } from '../model/Recents';
import { LibraryMovie } from '../model/Library';
import { DEFAULT_ACCENT } from '../common/ThemePalette';

type VoidCallback = () => void;
type RecentCallback = (entry: RecentMovie) => void;
type LibraryCallback = (entry: LibraryMovie) => void;

const KEY_ENTER = 2054;
const KEY_SPACE = 2052;

@Component
export struct RecentRow {
  @Prop entry: RecentMovie = { name: '', source: '', openedAt: 0 };
  @StorageLink('accentColor') private accentColor: string = DEFAULT_ACCENT;
  onOpen: RecentCallback = () => {};
  onDelete: VoidCallback = () => {};
  @State private hovered: boolean = false;
  @State private menuShown: boolean = false;

  private activate(event: KeyEvent): void {
    if (event.type === KeyType.Down && (event.keyCode === KEY_ENTER || event.keyCode === KEY_SPACE)) {
      this.onOpen(this.entry);
    }
  }

  @Builder
  RowContextMenu() {
    Column() {
      Button($r('app.string.ctx_delete'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .role(ButtonRole.ERROR)
        .controlSize(ControlSize.NORMAL)
        .width(140)
        .height(44)
        .onClick(() => this.onDelete())
    }
    .padding(6)
    .backgroundColor($r('app.color.player_surface'))
    .borderRadius(12)
    .shadow({ radius: 16, color: '#33000000', offsetX: 0, offsetY: 4 })
  }

  build() {
    Row() {
      Text(this.entry.name)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text($r('app.string.recent_local'))
        .fontSize(12)
        .fontColor($r('app.color.player_text_tertiary'))
        .margin({ left: 8 })
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.hovered ? $r('app.color.player_fill_hover') : $r('app.color.player_fill'))
    .borderRadius(10)
    .focusable(true)
    .focusOnTouch(false)
    .onHover((isHover: boolean) => {
      this.hovered = isHover;
    })
    .bindContextMenu(this.menuShown, this.RowContextMenu, {
      placement: Placement.BottomLeft,
      onDisappear: () => {
        this.menuShown = false;
      }
    })
    .onMouse((event: MouseEvent) => {
      if (event.button === MouseButton.Right && event.action === MouseAction.Press) {
        this.menuShown = true;
      }
    })
    // Tablets have no right button: long-press opens the same menu.
    .gesture(LongPressGesture().onAction(() => {
      this.menuShown = true;
    }))
    .onClick(() => this.onOpen(this.entry))
    .onKeyEvent((event: KeyEvent) => this.activate(event))
  }
}

/**
 * Folder header of the grouped library listing. A group is a real subfolder of
 * the players directory, so the same menu creates/removes folders there.
 */
@Component
export struct GroupRow {
  @Prop groupName: string = '';
  @Prop count: number = 0;
  @Prop collapsed: boolean = false;
  // The 未分组 bucket is the players root; it can be collapsed but not deleted.
  @Prop rootGroup: boolean = false;
  @StorageLink('accentColor') private accentColor: string = DEFAULT_ACCENT;
  onToggle: VoidCallback = () => {};
  onImport: VoidCallback = () => {};
  onRename: VoidCallback = () => {};
  onDelete: VoidCallback = () => {};
  @State private hovered: boolean = false;
  @State private menuShown: boolean = false;

  private str(res: Resource): string {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      return context.resourceManager.getStringSync(res.id);
    } catch (error) {
      return '';
    }
  }

  private countLabel(): string {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      return context.resourceManager.getStringSync($r('app.string.group_count').id, this.count);
    } catch (error) {
      return '';
    }
  }

  private displayName(): string {
    return this.rootGroup ? this.str($r('app.string.group_default')) : this.groupName;
  }

  @Builder
  GroupContextMenu() {
    Column() {
      Button($r('app.string.ctx_import_to_group'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .fontColor(this.accentColor)
        .controlSize(ControlSize.NORMAL)
        .width(150)
        .height(44)
        .onClick(() => this.onImport())
      if (!this.rootGroup) {
        Button($r('app.string.ctx_rename'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(this.accentColor)
          .controlSize(ControlSize.NORMAL)
          .width(150)
          .height(44)
          .onClick(() => this.onRename())
        Button($r('app.string.ctx_delete_group'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .role(ButtonRole.ERROR)
          .controlSize(ControlSize.NORMAL)
          .width(150)
          .height(44)
          .onClick(() => this.onDelete())
      }
    }
    .padding(6)
    .backgroundColor($r('app.color.player_surface'))
    .borderRadius(12)
    .shadow({ radius: 16, color: '#33000000', offsetX: 0, offsetY: 4 })
  }

  build() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.folder'))
        .fontSize(20)
        .fontColor([$r('app.color.player_text_secondary')])
      Text(this.displayName())
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.player_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text(this.countLabel())
        .fontSize(12)
        .fontColor($r('app.color.player_text_tertiary'))
      SymbolGlyph(this.collapsed ? $r('sys.symbol.chevron_right') : $r('sys.symbol.chevron_down'))
        .fontSize(16)
        .fontColor([$r('app.color.player_text_tertiary')])
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 10 })
    .backgroundColor(this.hovered ? $r('app.color.player_fill_hover') : $r('app.color.player_fill'))
    .borderRadius(10)
    .focusable(true)
    .focusOnTouch(false)
    .accessibilityGroup(true)
    .accessibilityText(this.displayName())
    .onHover((isHover: boolean) => {
      this.hovered = isHover;
    })
    .bindContextMenu(this.menuShown, this.GroupContextMenu, {
      placement: Placement.BottomLeft,
      onDisappear: () => {
        this.menuShown = false;
      }
    })
    .onMouse((event: MouseEvent) => {
      if (event.button === MouseButton.Right && event.action === MouseAction.Press) {
        this.menuShown = true;
      }
    })
    // Tablets have no right button: long-press opens the same menu.
    .gesture(LongPressGesture().onAction(() => {
      this.menuShown = true;
    }))
    .onClick(() => this.onToggle())
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && (event.keyCode === KEY_ENTER || event.keyCode === KEY_SPACE)) {
        this.onToggle();
      }
    })
  }
}

@Component
export struct LibraryRow {
  @Prop entry: LibraryMovie = { name: '', source: '', thumb: '', addedAt: 0, group: '' };
  // Only set in flat search results, where duplicates across groups must be told apart.
  @Prop groupLabel: string = '';
  @StorageLink('accentColor') private accentColor: string = DEFAULT_ACCENT;
  onOpen: LibraryCallback = () => {};
  onRemove: LibraryCallback = () => {};
  onMove: LibraryCallback = () => {};
  @State private hovered: boolean = false;
  @State private menuShown: boolean = false;

  private activate(event: KeyEvent): void {
    if (event.type === KeyType.Down && (event.keyCode === KEY_ENTER || event.keyCode === KEY_SPACE)) {
      this.onOpen(this.entry);
    }
  }

  @Builder
  RowContextMenu() {
    Column() {
      Button($r('app.string.ctx_open'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .fontColor(this.accentColor)
        .controlSize(ControlSize.NORMAL)
        .width(140)
        .height(44)
        .onClick(() => this.onOpen(this.entry))
      Button($r('app.string.ctx_move_to_group'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .fontColor(this.accentColor)
        .controlSize(ControlSize.NORMAL)
        .width(140)
        .height(44)
        .onClick(() => this.onMove(this.entry))
      Button($r('app.string.ctx_remove_from_library'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .role(ButtonRole.ERROR)
        .controlSize(ControlSize.NORMAL)
        .width(140)
        .height(44)
        .onClick(() => this.onRemove(this.entry))
    }
    .padding(6)
    .backgroundColor($r('app.color.player_surface'))
    .borderRadius(12)
    .shadow({ radius: 16, color: '#33000000', offsetX: 0, offsetY: 4 })
  }

  build() {
    Row() {
      Text(this.entry.name)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (this.groupLabel.length > 0) {
        Text(this.groupLabel)
          .fontSize(11)
          .fontColor($r('app.color.player_text_tertiary'))
          .maxLines(1)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.hovered ? $r('app.color.player_fill_hover') : $r('app.color.player_fill'))
    .borderRadius(10)
    .focusable(true)
    .focusOnTouch(false)
    .onHover((isHover: boolean) => {
      this.hovered = isHover;
    })
    .bindContextMenu(this.menuShown, this.RowContextMenu, {
      placement: Placement.BottomLeft,
      onDisappear: () => {
        this.menuShown = false;
      }
    })
    .onMouse((event: MouseEvent) => {
      if (event.button === MouseButton.Right && event.action === MouseAction.Press) {
        this.menuShown = true;
      }
    })
    // Tablets have no right button: long-press opens the same menu.
    .gesture(LongPressGesture().onAction(() => {
      this.menuShown = true;
    }))
    .onClick(() => this.onOpen(this.entry))
    .onKeyEvent((event: KeyEvent) => this.activate(event))
  }
}
