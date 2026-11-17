import { abilityAccessCtrl, common, ConfigurationConstant } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { mediaquery, uiMaterial, SymbolGlyphModifier, window } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import { Environment, fileIo, fileUri, picker, WatchEvent, Watcher } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { pointer } from '@kit.InputKit';
import {
  CURSOR_ARROW,
  CURSOR_GRAB,
  CURSOR_HAND,
  CURSOR_IBEAM,
  KEY_DOWN,
  KEY_UP,
  RuffleEngine,
  SCALE_SHOW_ALL
} from '../bridge/RuffleNapi';
import { AboutPanel } from '../components/AboutPanel';
import { LicensesPanel } from '../components/LicensesPanel';
import {
  PlayerMenu,
  SETTINGS_PAGE_APPEARANCE,
  SETTINGS_PAGE_DISPLAY,
  SETTINGS_PAGE_GLOW,
  SETTINGS_PAGE_LANGUAGE,
  SETTINGS_PAGE_MAIN,
  SETTINGS_PAGE_PICTURE,
  SETTINGS_PAGE_PLAY,
  SETTINGS_PAGE_SOUND,
  SETTINGS_PAGE_THEME
} from '../components/PlayerMenu';
import { GroupRow, LibraryRow, RecentRow } from '../components/Controls';
import {
  HdsNavigation,
  HdsNavigationMenuItemOptions,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleBarStyle,
  HdsNavigationTitleMode,
  hdsMaterial,
  TitleSize
} from '@kit.UIDesignKit';
import { LayoutSpec } from '../common/LayoutSpec';
import { GLOW_STANDARD, glowMaterialStyle, normalizeGlowLevel } from '../common/Glow';
import { accentBgFor, accentColorFor, DEFAULT_ACCENT, DEFAULT_ACCENT_BG } from '../common/ThemePalette';
import { applyLanguageNow, LANG_SYSTEM, normalizeLanguageIndex } from '../common/Language';
import { RecentMovie, RecentsStore } from '../model/Recents';
import { LibraryMovie, LibraryStore } from '../model/Library';

const KEY_ESCAPE = 2070;
const KEY_F11 = 2100;
const KEY_BACKSPACE = 2055;
const KEY_ENTER = 2054;
const KEY_SPACE = 2052;
// Inotify mask for the library folder watchers: create/delete/move/modify.
const WATCH_LIBRARY_EVENTS = 0xFFF;
const LIBRARY_SYNC_DEBOUNCE_MS = 400;

const TAB_HOME = 0;
const TAB_PLAYER = 1;
const SIDEBAR_ABOUT_KEY = 100;

const SHEET_LIBRARY = 'library';
const SHEET_RECENTS = 'recents';
const SHEET_WIDTH = 480;
const SHEET_HEIGHT = 560;

const LIB_PAGE_LIST = 'list';
const LIB_PAGE_CREATE = 'create';
const LIB_PAGE_MOVE = 'move';
const LIB_PAGE_RENAME = 'rename';
const GROUP_ROOT_KEY = '\u0000root';

const ABOUT_PAGE_ABOUT = 'about';
const ABOUT_PAGE_LICENSES = 'licenses';

@Entry
@Component
struct Index {
  @State private status: ResourceStr = $r('app.string.status_initializing');
  @State private fileName: string = '';
  @State private playing: boolean = true;
  @State private errorText: string = '';
  // Localized errors keep their resource id so the 100 ms refresh loop can
  // re-resolve the text after an in-app language switch.
  private errorResId: number = 0;
  @State private fullscreen: boolean = false;
  @State private keyboardVisible: boolean = false;
  @State private keyboardText: string = '';
  @State private hasMovie: boolean = false;
  @State private settingsVisible: boolean = false;
  @State private settingsPage: string = SETTINGS_PAGE_MAIN;
  @State private aboutVisible: boolean = false;
  @State private licenseViewerOpen: boolean = false;
  @State private libSheetVisible: boolean = false;
  @State private libSheetKind: string = SHEET_LIBRARY;
  @State private aboutPage: string = ABOUT_PAGE_ABOUT;
  @State private librarySearchOpen: boolean = false;
  @State private librarySearchText: string = '';
  // Library sheet page: the listing, the 新建分组 form or the 移动到分组 picker.
  @State private libSheetPage: string = LIB_PAGE_LIST;
  @State private libraryGroups: string[] = [];
  @State private collapsedGroups: string[] = [];
  @State private groupDraft: string = '';
  @State private renameFromGroup: string = '';
  @State private moveSourcePath: string = '';
  @State private moveFileName: string = '';
  @State private moveFromGroup: string = '';
  @State @Watch('onSettingChanged') private volume: number = 1;
  @State @Watch('onSettingChanged') private qualityIndex: number = 1;
  @State @Watch('onSettingChanged') private scaleMode: number = SCALE_SHOW_ALL;
  @State @Watch('onSettingChanged') private scaleForced: boolean = false;
  @State @Watch('onSettingChanged') private letterbox: boolean = true;
  @State @Watch('onSettingChanged') private colorModeIndex: number = 0;
  @State @Watch('onSettingChanged') private themeIndex: number = 0;
  @State @Watch('onSettingChanged') private glowLevel: number = GLOW_STANDARD;
  @State @Watch('onSettingChanged') private languageIndex: number = LANG_SYSTEM;
  @StorageLink('accentColor') private accentColor: string = DEFAULT_ACCENT;
  @StorageLink('accentBg') private accentBg: string = DEFAULT_ACCENT_BG;
  @State private recents: RecentMovie[] = [];
  @State private library: LibraryMovie[] = [];
  @State private opening: boolean = false;
  @StorageLink('pendingSwfUri') @Watch('onPendingSwfUri') private pendingSwfUri: string = '';

  private pollTimer: number = -1;
  private initialized: boolean = false;
  private keyboardBacking: string = '';
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  private lastSettingsVisible: boolean = false;
  private lastAboutVisible: boolean = false;
  private lastLibSheetVisible: boolean = false;
  private settingsStore: preferences.Preferences | undefined = undefined;
  private recentsStore: RecentsStore | undefined = undefined;
  private libraryStore: LibraryStore | undefined = undefined;
  private libraryWatchers: Watcher[] = [];
  private librarySyncTimer: number = -1;
  private pendingRecent: RecentMovie | undefined = undefined;
  private lastHasMovie: boolean = false;
  private thumbCaptured: boolean = false;
  private thumbDueAt: number = 0;
  // The native engine is created and destroyed together with the XComponent
  // surface, so a load that arrives before the surface exists is rejected
  // before the file is ever read. Such requests wait here instead.
  private pendingLoadSource: string = '';
  private pendingLoadName: string = '';
  private pendingLoadAt: number = 0;
  private pendingLoadAttempts: number = 0;

  private cursorCode: number = CURSOR_ARROW;
  private cursorHidden: boolean = false;
  private cursorApplied: number = -2;
  private hiddenCursor: image.PixelMap | undefined = undefined;
  @State private perfFps: number = 0;

  @State private isWidth600: boolean = false;
  @State private isWidth840: boolean = false;
  @State private compactTab: number = TAB_HOME;
  @State private sidebarHovered: number = -1;
  private is2in1: boolean = deviceInfo.deviceType === '2in1';
  private width600Listener: mediaquery.MediaQueryListener | undefined = undefined;
  private width840Listener: mediaquery.MediaQueryListener | undefined = undefined;

  /**
   * PC keeps the sidebar once the window is wide enough; tablets and narrow
   * PC windows switch to the compact shell with a floating bottom tab bar.
   */
  private isSidebarLayout(): boolean {
    return this.is2in1 && this.isWidth840;
  }

  private initBreakpoints(): void {
    const mediaQuery = this.getUIContext().getMediaQuery();
    const medium = mediaQuery.matchMediaSync(`(width>=${LayoutSpec.BREAKPOINT_MD}vp)`);
    this.isWidth600 = medium.matches;
    this.width600Listener = medium;
    medium.on('change', (result: mediaquery.MediaQueryResult) => {
      this.isWidth600 = result.matches;
    });
    const large = mediaQuery.matchMediaSync(`(width>=${LayoutSpec.BREAKPOINT_LG}vp)`);
    this.isWidth840 = large.matches;
    this.width840Listener = large;
    large.on('change', (result: mediaquery.MediaQueryResult) => {
      this.isWidth840 = result.matches;
    });
  }

  private releaseBreakpoints(): void {
    if (this.width600Listener !== undefined) {
      this.width600Listener.off('change');
      this.width600Listener = undefined;
    }
    if (this.width840Listener !== undefined) {
      this.width840Listener.off('change');
      this.width840Listener = undefined;
    }
  }

  /** Compact tabs only switch between the home page and the movie now. */
  private selectCompactTab(index: number): void {
    const tab = index === TAB_HOME ? TAB_HOME : TAB_PLAYER;
    this.compactTab = tab;
    if (tab === TAB_HOME) {
      this.librarySearchOpen = false;
      this.librarySearchText = '';
      return;
    }
    this.requestFocus('ruffleFocus');
  }

  aboutToAppear(): void {
    this.initBreakpoints();
    const context = this.getUIContext().getHostContext();
    if (context) {
      this.initialized = RuffleEngine.init(context.filesDir);
      if (!this.initialized) {
        this.setError($r('app.string.error_engine_init'));
      }
      this.recentsStore = new RecentsStore(context.filesDir);
      this.recents = this.recentsStore.load();
      this.libraryStore = new LibraryStore(context.filesDir);
      this.library = this.libraryStore.load();
      try {
        this.settingsStore = preferences.getPreferencesSync(context, { name: 'player_settings' });
      } catch (error) {
        const err = error as BusinessError;
        console.error(`open settings store failed: ${err.message}`);
      }
      this.loadSettings();
      this.syncLibraryFromFolder();
      this.refreshLibraryWatchers();
      this.applyAccentTheme();
      this.applyColorMode();
      this.applyPlayerSettings();
    }
    this.pollTimer = setInterval(() => this.refreshStatus(), 100);
    if (this.pendingSwfUri.length > 0) {
      this.onPendingSwfUri('pendingSwfUri');
    }
  }

  aboutToDisappear(): void {
    this.releaseBreakpoints();
    this.stopLibraryWatchers();
    if (this.librarySyncTimer >= 0) {
      clearTimeout(this.librarySyncTimer);
      this.librarySyncTimer = -1;
    }
    if (this.pollTimer >= 0) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
    // The shell swaps remount the XComponent on breakpoint crossings, so the
    // engine's lifetime belongs to the page, not to one surface instance.
    RuffleEngine.shutdown();
  }

  onPageShow(): void {
    this.requestFocus('ruffleFocus');
    // 用户在文件管理器里增删了 players 文件夹的文件后，回到应用时刷新。
    this.syncLibraryFromFolder();
  }

  onPageHide(): void {
    RuffleEngine.focus(false);
  }

  // System back (tablet gesture/navigation bar) peels the topmost layer
  // instead of dropping the player.
  onBackPress(): boolean {
    if (this.keyboardVisible) {
      this.setKeyboardVisible(false);
      return true;
    }
    if (this.libSheetVisible) {
      this.libSheetVisible = false;
      return true;
    }
    if (this.settingsVisible) {
      this.settingsVisible = false;
      return true;
    }
    if (this.aboutVisible) {
      this.aboutVisible = false;
      return true;
    }
    if (this.fullscreen) {
      this.applyFullscreen(false, true);
      return true;
    }
    if (this.compactTab !== TAB_PLAYER) {
      this.selectCompactTab(TAB_PLAYER);
      return true;
    }
    return false;
  }

  private refreshStatus(): void {
    if (this.errorResId !== 0) {
      const localized = this.strById(this.errorResId);
      if (localized.length > 0) {
        this.errorText = localized;
      }
    }
    this.syncSurfaceSize();
    this.drainEvents();
    this.retryPendingLoad();
    if (this.lastSettingsVisible && !this.settingsVisible) {
      this.requestFocus('ruffleFocus');
    }
    this.lastSettingsVisible = this.settingsVisible;
    if (this.lastAboutVisible && !this.aboutVisible) {
      this.requestFocus('ruffleFocus');
    }
    this.lastAboutVisible = this.aboutVisible;
    if (this.lastLibSheetVisible && !this.libSheetVisible) {
      this.requestFocus('ruffleFocus');
    }
    this.lastLibSheetVisible = this.libSheetVisible;
    if (!RuffleEngine.isReady()) {
      this.status = $r('app.string.status_initializing');
      return;
    }
    const error = RuffleEngine.lastError();
    if (error.length > 0) {
      this.setErrorText(error);
      this.status = $r('app.string.status_load_failed');
      this.opening = false;
      this.pendingRecent = undefined;
      return;
    }
    this.hasMovie = RuffleEngine.hasMovie();
    if (this.hasMovie && !this.lastHasMovie) {
      this.thumbCaptured = false;
      this.thumbDueAt = Date.now() + 600;
    }
    this.lastHasMovie = this.hasMovie;
    if (!this.hasMovie) {
      if (this.opening) {
        this.status = $r('app.string.status_loading');
      } else if (this.errorText.length > 0) {
        this.status = $r('app.string.status_load_failed');
      } else {
        this.status = $r('app.string.status_ready');
      }
      return;
    }
    this.opening = false;
    this.commitPendingRecent();
    if (!this.thumbCaptured && this.thumbDueAt > 0 && Date.now() >= this.thumbDueAt) {
      this.thumbCaptured = true;
      this.captureThumbnail();
    }
    this.playing = RuffleEngine.isPlaying();
    // The frame rate lives on the stage corner, not in the toolbar.
    this.status = '';
  }

  /** Keeps re-issuing the queued load until a surface exists to accept it. */
  private retryPendingLoad(): void {
    if (this.pendingLoadSource.length === 0) {
      return;
    }
    if (RuffleEngine.hasMovie()) {
      this.pendingLoadSource = '';
      this.pendingLoadAttempts = 0;
      return;
    }
    if (Date.now() - this.pendingLoadAt < 300) {
      return;
    }
    this.attemptLoad();
  }

  /**
   * Issues a load and keeps it queued while there is no surface to run it on.
   * Once a surface exists a rejection is real, so the file error is shown.
   */
  private attemptLoad(): void {
    if (this.pendingLoadSource.length === 0) {
      return;
    }
    const result = RuffleEngine.loadSwf(this.pendingLoadSource);
    this.pendingLoadAt = Date.now();
    if (result === 0) {
      this.pendingRecent = {
        name: this.pendingLoadName,
        source: this.pendingLoadSource,
        openedAt: Date.now()
      };
      this.pendingLoadSource = '';
      this.pendingLoadAttempts = 0;
      return;
    }
    this.pendingLoadAttempts += 1;
    const refused = $r('app.string.error_refused_file');
    if (RuffleEngine.hasSurface() || this.pendingLoadAttempts >= 40) {
      this.pendingLoadSource = '';
      this.pendingLoadAttempts = 0;
      this.opening = false;
      this.setError(refused);
      return;
    }
    this.opening = true;
    this.clearError();
    this.status = $r('app.string.status_initializing');
  }

  /**
   * The XComponent surface keeps its creation-time buffer geometry unless it is
   * told otherwise, which leaves the movie rendered at its original pixel size.
   * Report the laid-out size so the player can scale the stage to the window.
   */
  private syncSurfaceSize(): void {
    try {
      const info = this.getUIContext().getComponentUtils().getRectangleById('ruffleSurface');
      const width = Math.round(info.size.width);
      const height = Math.round(info.size.height);
      if (width <= 0 || height <= 0) {
        return;
      }
      if (width === this.surfaceWidth && height === this.surfaceHeight) {
        return;
      }
      this.surfaceWidth = width;
      this.surfaceHeight = height;
      RuffleEngine.surfaceSize(width, height);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`surface size failed: ${err.message}`);
    }
  }

  private drainEvents(): void {
    for (let i = 0; i < 16; i++) {
      const event = RuffleEngine.pollEvent();
      if (event.length === 0) {
        return;
      }
      const tab = event.indexOf('\t');
      const name = tab < 0 ? event : event.substring(0, tab);
      const payload = tab < 0 ? '' : event.substring(tab + 1);
      const parts = event.split('\t');
      switch (name) {
        case 'perf':
          if (parts.length >= 2) {
            this.perfFps = Number(parts[1]);
          }
          break;
        case 'fullscreen':
          this.applyFullscreen(payload === '1', false);
          break;
        case 'keyboard':
          this.setKeyboardVisible(payload === '1');
          break;
        case 'open_file':
          if (parts.length >= 3) {
            this.handleOpenFile(Number(parts[2]), parts[1], false);
          }
          break;
        case 'open_files':
          if (parts.length >= 3) {
            this.handleOpenFile(Number(parts[2]), parts[1], true);
          }
          break;
        case 'save_file':
          if (parts.length >= 3) {
            this.handleSaveFile(Number(parts[2]), parts[1]);
          }
          break;
        case 'cursor':
          this.applyCursor(Number(payload));
          break;
        case 'cursor_visible':
          this.setCursorHidden(payload !== '1');
          break;
        case 'menu':
          this.showSettings();
          break;
        case 'thumb_png':
          if (parts.length >= 5) {
            this.saveThumbnail(parts[1], Number(parts[2]), Number(parts[3]), parts[4]);
          }
          break;
        case 'thumb_failed':
          console.warn(`thumbnail failed for ${payload}`);
          break;
        case 'http_request':
          this.handleHttpRequest(event);
          break;
        case 'quit':
          this.quitApp();
          break;
        case 'load_error':
          this.opening = false;
          this.pendingRecent = undefined;
          this.setErrorText(payload);
          this.status = $r('app.string.status_load_failed');
          break;
        default:
          break;
      }
    }
  }

  /**
   * Networking is disabled. Every engine request is answered with a failure
   * so the Rust navigator does not block waiting for a reply.
   */
  private handleHttpRequest(event: string): void {
    const parts = event.split('\t');
    if (parts.length < 6) {
      return;
    }
    RuffleEngine.httpResult(Number(parts[1]), 0, '', '');
  }

  private quitApp(): void {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return;
    }
    this.showToast($r('app.string.toast_movie_exited'));
    (context as common.UIAbilityContext).terminateSelf().catch((error: BusinessError) => {
      console.error(`terminateSelf failed: ${error.message}`);
    });
  }

  private buildFilters(extensions: string): string[] {
    const suffixes: string[] = [];
    const parts = extensions.split(',');
    for (let i = 0; i < parts.length; i++) {
      const suffix = parts[i].trim();
      if (suffix.startsWith('.')) {
        suffixes.push(suffix);
      }
    }
    if (suffixes.length === 0) {
      return [];
    }
    return [`${this.str($r('app.string.picker_file'))}|${suffixes.join(',')}`];
  }

  private selectedPaths(uris: string[]): string[] {
    const paths: string[] = [];
    for (let i = 0; i < uris.length; i++) {
      try {
        paths.push(new fileUri.FileUri(uris[i]).path);
      } catch (error) {
        const err = error as BusinessError;
        console.error(`cannot resolve ${uris[i]}: ${err.message}`);
      }
    }
    return paths;
  }

  private async handleOpenFile(id: number, extensions: string, multiple: boolean): Promise<void> {
    let paths: string[] = [];
    try {
      const context = this.getUIContext().getHostContext();
      if (context) {
        const options = new picker.DocumentSelectOptions();
        options.maxSelectNumber = multiple ? 10 : 1;
        const filters = this.buildFilters(extensions);
        if (filters.length > 0) {
          options.fileSuffixFilters = filters;
        }
        const uris = await new picker.DocumentViewPicker(context).select(options);
        paths = this.selectedPaths(uris);
      }
    } catch (error) {
      const err = error as BusinessError;
      this.showToast(this.format($r('app.string.toast_select_failed'), err.message));
    } finally {
      RuffleEngine.dialogResult(id, paths.join('\n'));
      this.requestFocus('ruffleFocus');
    }
  }

  private async handleSaveFile(id: number, fileName: string): Promise<void> {
    let paths: string[] = [];
    try {
      const context = this.getUIContext().getHostContext();
      if (context) {
        const options = new picker.DocumentSaveOptions();
        options.newFileNames = [fileName];
        const uris = await new picker.DocumentViewPicker(context).save(options);
        paths = this.selectedPaths(uris);
      }
    } catch (error) {
      const err = error as BusinessError;
      this.showToast(this.format($r('app.string.toast_save_failed'), err.message));
    } finally {
      RuffleEngine.dialogResult(id, paths.join('\n'));
      this.requestFocus('ruffleFocus');
    }
  }

  private async applyFullscreen(enabled: boolean, notifyPlayer: boolean): Promise<void> {
    this.fullscreen = enabled;
    // Fullscreen hides the tab bar, so leave the compact shell on the movie.
    if (enabled && !this.isSidebarLayout()) {
      this.compactTab = TAB_PLAYER;
    }
    // The PC home page has no fullscreen entry; F11 from it lands on the movie.
    if (enabled && this.isSidebarLayout() && this.compactTab === TAB_HOME) {
      this.compactTab = TAB_PLAYER;
    }
    if (!enabled) {
      this.setKeyboardVisible(false);
    }
    if (notifyPlayer) {
      RuffleEngine.setFullscreen(enabled);
    }

    const context = this.getUIContext().getHostContext();
    if (!context) {
      return;
    }
    try {
      const win = await window.getLastWindow(context as common.UIAbilityContext);
      await win.setWindowLayoutFullScreen(enabled);
      if (this.is2in1) {
        try {
          win.setWindowDecorVisible(!enabled);
        } catch (error) {
          const err = error as BusinessError;
          console.error(`decor toggle failed: ${err.message}`);
        }
      } else {
        try {
          // Tablets keep the status/navigation bars; hide them so the movie owns
          // the whole screen and the exit button sits just below the corner.
          await win.setWindowSystemBarEnable(enabled ? [] : ['status', 'navigation']);
        } catch (error) {
          const err = error as BusinessError;
          console.error(`system bar toggle failed: ${err.message}`);
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`fullscreen failed: ${err.message}`);
    }
    this.requestFocus('ruffleFocus');
  }

  private setKeyboardVisible(visible: boolean): void {
    this.keyboardVisible = visible;
    this.keyboardText = '';
    this.keyboardBacking = '';
    if (visible) {
      setTimeout(() => {
        this.requestFocus('ruffleKeyboard');
      }, 80);
    } else {
      setTimeout(() => {
        this.requestFocus('ruffleFocus');
      }, 80);
    }
  }

  private requestFocus(id: string): void {
    try {
      this.getUIContext().getFocusController().requestFocus(id);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`requestFocus(${id}) failed: ${err.message}`);
    }
  }

  private showSettings(): void {
    if (this.settingsVisible) {
      return;
    }
    if (this.keyboardVisible) {
      this.setKeyboardVisible(false);
    }
    this.settingsPage = SETTINGS_PAGE_MAIN;
    this.settingsVisible = true;
  }

  private showAbout(): void {
    if (this.aboutVisible) {
      return;
    }
    if (this.keyboardVisible) {
      this.setKeyboardVisible(false);
    }
    this.aboutPage = ABOUT_PAGE_ABOUT;
    this.licenseViewerOpen = false;
    this.aboutVisible = true;
  }

  /** Opens the centered library/recents sheet, refreshing its data on open. */
  private toggleLibSheet(kind: string): void {
    if (this.libSheetVisible) {
      if (this.libSheetKind === kind) {
        this.libSheetVisible = false;
      }
      return;
    }
    this.libSheetKind = kind;
    this.libSheetPage = LIB_PAGE_LIST;
    this.libSheetVisible = true;
    if (kind === SHEET_LIBRARY) {
      this.syncLibraryFromFolder();
      this.requestThumbnailForCurrent();
    } else {
      this.librarySearchOpen = false;
      this.librarySearchText = '';
    }
  }

  /**
   * Centered half-modal used by the library and recents pages. The library
   * sheet hosts its 新建分组 / 移动到分组 sub-pages: the title follows the page
   * and back press returns to the listing instead of dismissing.
   */
  private sheetGlass(): boolean {
    return uiMaterial.isImmersiveMaterialSupported();
  }

  private sheetBackground(): ResourceColor {
    return this.sheetGlass() ? Color.Transparent : $r('app.color.player_surface');
  }

  private sheetMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({ style: glowMaterialStyle(this.glowLevel) });
  }

  private libSheetOptions(): SheetOptions {
    return {
      preferType: SheetType.CENTER,
      width: SHEET_WIDTH,
      height: SHEET_HEIGHT,
      dragBar: false,
      showClose: true,
      title: { title: this.libSheetTitle() },
      backgroundColor: this.sheetBackground(),
      systemMaterial: this.sheetGlass() ? this.sheetMaterial() : undefined,
      onWillDismiss: (action: DismissSheetAction) => {
        if (action.reason === DismissReason.PRESS_BACK && this.libSheetPage !== LIB_PAGE_LIST) {
          this.libSheetPage = LIB_PAGE_LIST;
          return;
        }
        action.dismiss();
      },
      onDisappear: () => {
        this.librarySearchOpen = false;
        this.librarySearchText = '';
        this.libSheetPage = LIB_PAGE_LIST;
        this.groupDraft = '';
        this.renameFromGroup = '';
        this.moveSourcePath = '';
        this.moveFileName = '';
        this.moveFromGroup = '';
      }
    };
  }

  private libSheetTitle(): ResourceStr {
    if (this.libSheetKind !== SHEET_LIBRARY) {
      return $r('app.string.recents_title');
    }
    if (this.libSheetPage === LIB_PAGE_CREATE) {
      return $r('app.string.lib_new_group');
    }
    if (this.libSheetPage === LIB_PAGE_RENAME) {
      return $r('app.string.ctx_rename');
    }
    if (this.libSheetPage === LIB_PAGE_MOVE) {
      return $r('app.string.ctx_move_to_group');
    }
    return $r('app.string.library_title');
  }

  /**
   * The settings sheet hosts its option sub-pages: the title follows the page
   * and back press returns to the settings root instead of dismissing.
   */
  private settingsSheetOptions(): SheetOptions {
    return {
      preferType: SheetType.CENTER,
      width: SHEET_WIDTH,
      height: SHEET_HEIGHT,
      dragBar: false,
      showClose: true,
      title: { title: this.settingsSheetTitle() },
      backgroundColor: this.sheetBackground(),
      systemMaterial: this.sheetGlass() ? this.sheetMaterial() : undefined,
      onWillDismiss: (action: DismissSheetAction) => {
        if (action.reason === DismissReason.PRESS_BACK && this.settingsPage !== SETTINGS_PAGE_MAIN) {
          this.settingsPage = SETTINGS_PAGE_MAIN;
          return;
        }
        action.dismiss();
      },
      onDisappear: () => {
        this.settingsPage = SETTINGS_PAGE_MAIN;
      }
    };
  }

  private settingsSheetTitle(): ResourceStr {
    if (this.settingsPage === SETTINGS_PAGE_PLAY) {
      return $r('app.string.row_play_settings');
    }
    if (this.settingsPage === SETTINGS_PAGE_SOUND) {
      return $r('app.string.row_sound_settings');
    }
    if (this.settingsPage === SETTINGS_PAGE_PICTURE) {
      return $r('app.string.row_picture_settings');
    }
    if (this.settingsPage === SETTINGS_PAGE_DISPLAY) {
      return $r('app.string.row_display_settings');
    }
    if (this.settingsPage === SETTINGS_PAGE_APPEARANCE) {
      return $r('app.string.row_appearance_settings');
    }
    if (this.settingsPage === SETTINGS_PAGE_THEME) {
      return $r('app.string.row_theme_settings');
    }
    if (this.settingsPage === SETTINGS_PAGE_GLOW) {
      return $r('app.string.row_glow');
    }
    if (this.settingsPage === SETTINGS_PAGE_LANGUAGE) {
      return $r('app.string.language_settings_title');
    }
    return $r('app.string.player_settings_title');
  }

  /**
   * The about sheet also hosts the licenses page: the title follows the page
   * and back press returns to 关于 instead of dismissing the panel.
   */
  private aboutSheetOptions(): SheetOptions {
    return {
      preferType: SheetType.CENTER,
      width: SHEET_WIDTH,
      height: SHEET_HEIGHT,
      dragBar: false,
      showClose: true,
      title: {
        title: this.aboutPage === ABOUT_PAGE_LICENSES
          ? $r('app.string.licenses_list_title')
          : $r('app.string.about_title')
      },
      backgroundColor: this.sheetBackground(),
      systemMaterial: this.sheetGlass() ? this.sheetMaterial() : undefined,
      onWillDismiss: (action: DismissSheetAction) => {
        if (action.reason === DismissReason.PRESS_BACK) {
          if (this.licenseViewerOpen) {
            this.licenseViewerOpen = false;
            return;
          }
          if (this.aboutPage === ABOUT_PAGE_LICENSES) {
            this.aboutPage = ABOUT_PAGE_ABOUT;
            return;
          }
        }
        action.dismiss();
      },
      onDisappear: () => {
        this.aboutPage = ABOUT_PAGE_ABOUT;
        this.licenseViewerOpen = false;
      }
    };
  }

  private onSettingChanged(propName: string): void {
    const store = this.settingsStore;
    if (!store) {
      return;
    }
    try {
      if (propName === 'volume') {
        store.putSync('volume', this.volume);
      } else if (propName === 'qualityIndex') {
        store.putSync('qualityIndex', this.qualityIndex);
      } else if (propName === 'scaleMode') {
        store.putSync('scaleMode', this.scaleMode);
      } else if (propName === 'scaleForced') {
        store.putSync('scaleForced', this.scaleForced);
      } else if (propName === 'letterbox') {
        store.putSync('letterbox', this.letterbox);
      } else if (propName === 'colorModeIndex') {
        store.putSync('colorModeIndex', this.colorModeIndex);
      } else if (propName === 'themeIndex') {
        store.putSync('themeIndex', this.themeIndex);
      } else if (propName === 'glowLevel') {
        store.putSync('glowLevel', this.glowLevel);
      } else if (propName === 'languageIndex') {
        store.putSync('languageIndex', this.languageIndex);
      }
      store.flushSync();
    } catch (error) {
      const err = error as BusinessError;
      console.error(`persist ${propName} failed: ${err.message}`);
    }
  }

  private loadSettings(): void {
    const store = this.settingsStore;
    if (!store) {
      return;
    }
    try {
      this.volume = store.getSync('volume', 1) as number;
      const quality = store.getSync('qualityIndex', 1) as number;
      this.qualityIndex = quality >= 0 && quality <= 3 ? quality : 1;
      this.scaleMode = store.getSync('scaleMode', SCALE_SHOW_ALL) as number;
      this.scaleForced = store.getSync('scaleForced', false) as boolean;
      this.letterbox = store.getSync('letterbox', true) as boolean;
      const theme = store.getSync('colorModeIndex', 0) as number;
      this.colorModeIndex = theme >= 0 && theme <= 2 ? theme : 0;
      const accent = store.getSync('themeIndex', 0) as number;
      this.themeIndex = accent >= 0 && accent <= 4 ? accent : 0;
      this.glowLevel = normalizeGlowLevel(store.getSync('glowLevel', GLOW_STANDARD) as number);
      this.languageIndex = normalizeLanguageIndex(store.getSync('languageIndex', LANG_SYSTEM) as number);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`load settings failed: ${err.message}`);
    }
  }

  private applyAccentTheme(): void {
    this.accentColor = accentColorFor(this.themeIndex);
    this.accentBg = accentBgFor(this.themeIndex);
  }

  private pickAccent(index: number): void {
    if (index === this.themeIndex) {
      return;
    }
    this.themeIndex = index;
    this.applyAccentTheme();
  }

  private applyColorMode(): void {
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) {
        return;
      }
      const mode = this.colorModeIndex === 1
        ? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
        : (this.colorModeIndex === 2
          ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          : ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      context.getApplicationContext().setColorMode(mode);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`apply color mode failed: ${err.message}`);
    }
  }

  private applyPlayerSettings(): void {
    if (!this.initialized) {
      return;
    }
    RuffleEngine.setVolume(this.volume);
    RuffleEngine.setQuality(this.qualityIndex);
    RuffleEngine.setScaleMode(this.scaleMode, this.scaleForced);
    RuffleEngine.setLetterbox(this.letterbox);
  }

  private strById(id: number, ...args: (string | number)[]): string {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      return context.resourceManager.getStringSync(id, ...args);
    } catch (error) {
      return '';
    }
  }

  private str(res: Resource): string {
    return this.strById(res.id);
  }

  private format(res: Resource, ...args: (string | number)[]): string {
    return this.strById(res.id, ...args);
  }

  private setError(res: Resource): void {
    this.errorResId = res.id;
    this.errorText = this.strById(res.id);
  }

  private setErrorText(text: string): void {
    this.errorResId = 0;
    this.errorText = text;
  }

  private clearError(): void {
    this.errorResId = 0;
    this.errorText = '';
  }

  private onPickLanguage(index: number): void {
    const next = normalizeLanguageIndex(index);
    // Re-picking 跟随系统 after a device language change re-resolves it.
    this.languageIndex = next;
    const context = this.getUIContext().getHostContext();
    if (context) {
      applyLanguageNow(context, next);
    }
    this.refreshStatus();
  }

  private handleAxis(event: AxisEvent): void {
    if (event.action !== AxisAction.UPDATE) {
      return;
    }
    const delta = event.getVerticalAxisValue();
    if (delta !== 0) {
      RuffleEngine.wheel(delta);
    }
  }

  private applyCursor(code: number): void {
    this.cursorCode = code;
    this.syncCursor();
  }

  private setCursorHidden(hidden: boolean): void {
    this.cursorHidden = hidden;
    this.syncCursor();
  }

  private syncCursor(): void {
    try {
      const controller = this.getUIContext().getCursorController();
      if (this.cursorHidden) {
        if (this.cursorApplied === -1) {
          return;
        }
        const pixel = this.ensureHiddenCursor();
        if (pixel) {
          controller.setCustomCursor(pixel);
          this.cursorApplied = -1;
        }
        return;
      }
      if (this.cursorApplied === this.cursorCode) {
        return;
      }
      this.cursorApplied = this.cursorCode;
      switch (this.cursorCode) {
        case CURSOR_HAND:
          controller.setCursor(pointer.PointerStyle.HAND_POINTING);
          break;
        case CURSOR_IBEAM:
          controller.setCursor(pointer.PointerStyle.TEXT_CURSOR);
          break;
        case CURSOR_GRAB:
          controller.setCursor(pointer.PointerStyle.HAND_GRABBING);
          break;
        default:
          controller.setCursor(pointer.PointerStyle.DEFAULT);
          break;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`cursor update failed: ${err.message}`);
    }
  }

  /** A 1x1 transparent cursor stands in for Mouse.hide(). */
  private ensureHiddenCursor(): image.PixelMap | undefined {
    if (this.hiddenCursor) {
      return this.hiddenCursor;
    }
    try {
      const options: image.InitializationOptions = {
        size: { width: 1, height: 1 },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: false
      };
      this.hiddenCursor = image.createPixelMapSync(new ArrayBuffer(4), options);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`hidden cursor failed: ${err.message}`);
    }
    return this.hiddenCursor;
  }

  private stepFrame(): void {
    RuffleEngine.step();
  }

  private reloadMovie(): void {
    this.clearError();
    this.status = $r('app.string.status_reloading');
    RuffleEngine.reload();
  }

  private onKeyboardText(value: string): void {
    const previous = this.keyboardBacking;
    if (value.length > previous.length) {
      RuffleEngine.textInput(value.substring(previous.length));
    } else if (value.length < previous.length) {
      const removed = previous.length - value.length;
      for (let i = 0; i < removed; i++) {
        RuffleEngine.key(KEY_DOWN, KEY_BACKSPACE);
        RuffleEngine.key(KEY_UP, KEY_BACKSPACE);
      }
    }
    this.keyboardBacking = value;
    this.keyboardText = value;
  }

  private isSpecialKey(keyCode: number): boolean {
    if (keyCode >= 2012 && keyCode <= 2016) {
      return true;
    }
    if (keyCode >= 2068 && keyCode <= 2071) {
      return true;
    }
    if (keyCode >= 2081 && keyCode <= 2083) {
      return true;
    }
    if (keyCode >= 2090 && keyCode <= 2101) {
      return true;
    }
    return keyCode === 2016 || keyCode === 2049 || keyCode === 2052;
  }

  private handleKeyboardOverlayKey(event: KeyEvent): void {
    if (event.type !== KeyType.Down) {
      return;
    }
    if (event.keyCode === KEY_ESCAPE) {
      this.setKeyboardVisible(false);
      return;
    }
    if (this.isSpecialKey(event.keyCode)) {
      RuffleEngine.key(KEY_DOWN, event.keyCode);
      RuffleEngine.key(KEY_UP, event.keyCode);
    }
  }

  private handleKey(event: KeyEvent): void {
    const isDown = event.type === KeyType.Down;
    const action = isDown ? KEY_DOWN : KEY_UP;

    // The text overlay owns the keyboard while it is shown: printable input
    // arrives through onChange and special keys through its own handler.
    if (this.keyboardVisible) {
      return;
    }

    // The settings card is modal: the movie must not see keystrokes while it
    // is open, and Escape closes it.
    if (this.settingsVisible) {
      if (isDown && event.keyCode === KEY_ESCAPE) {
        if (this.settingsPage !== SETTINGS_PAGE_MAIN) {
          this.settingsPage = SETTINGS_PAGE_MAIN;
        } else {
          this.settingsVisible = false;
        }
      }
      return;
    }

    // The about card behaves the same way.
    if (this.aboutVisible) {
      if (isDown && event.keyCode === KEY_ESCAPE) {
        if (this.licenseViewerOpen) {
          this.licenseViewerOpen = false;
        } else if (this.aboutPage === ABOUT_PAGE_LICENSES) {
          this.aboutPage = ABOUT_PAGE_ABOUT;
        } else {
          this.aboutVisible = false;
        }
      }
      return;
    }

    // The library/recents sheet is modal too.
    if (this.libSheetVisible) {
      if (isDown && event.keyCode === KEY_ESCAPE) {
        this.libSheetVisible = false;
      }
      return;
    }

    if (isDown && event.keyCode === KEY_F11) {
      this.applyFullscreen(!this.fullscreen, true);
      return;
    }
    if (isDown && event.keyCode === KEY_ESCAPE && this.fullscreen) {
      this.applyFullscreen(false, true);
      return;
    }

    // The home page covers the movie: Escape returns to the player and the
    // movie keeps its keys otherwise.
    if (this.compactTab !== TAB_PLAYER) {
      if (isDown && event.keyCode === KEY_ESCAPE) {
        this.selectCompactTab(TAB_PLAYER);
      }
      return;
    }
    RuffleEngine.key(action, event.keyCode);
  }

  // The focused surface consumes keys itself: otherwise ArkUI's default focus
  // traversal can eat arrows/Space whenever the windowed layout adds buttons.
  private handleSurfaceKey(event: KeyEvent): boolean {
    this.handleKey(event);
    return true;
  }

  private togglePlaying(): void {
    RuffleEngine.togglePlaying();
    this.refreshStatus();
  }

  /**
   * Picker grants die with the process, so the movie is always copied into
   * the app sandbox; storing the raw picked path would make the recents
   * entry unreadable (and unopenable) after a restart. A name-keyed dir
   * also keeps the movie's base path stable across re-imports, which disk
   * SharedObject saves depend on.
   */
  private copyIntoFolder(uri: string, name: string, root: string): string {
    let source = uri;
    try {
      source = new fileUri.FileUri(uri).path;
    } catch (error) {
      // Data-share and document URIs have no filesystem path; fileIo can still
      // stream them with the grant that came with the Want.
      console.info(`keeping URI as source: ${uri}`);
    }
    const safeName = (name === '.' || name === '..') ? this.str($r('app.string.untitled_swf')) : name;
    const dir = `${root}/${safeName}`;
    this.ensureDir(root);
    this.ensureDir(dir);
    const target = `${dir}/${safeName}`;
    if (source !== target) {
      fileIo.copyFileSync(source, target);
      this.copySiblings(source, dir);
    }
    return target;
  }

  private copyIntoImports(uri: string, name: string): string {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      throw new Error(this.str($r('app.string.error_no_context')));
    }
    return this.copyIntoFolder(uri, name, `${context.filesDir}/imports`);
  }

  /** 播放库放在 下载/<包名>：文件管理器只给这个目录显示应用图标和名称。 */
  private libraryRoot(): string {
    let downloadDir = '';
    try {
      downloadDir = Environment.getUserDownloadDir();
    } catch (error) {
      const err = error as BusinessError;
      console.error(`getUserDownloadDir failed: ${err.message}`);
      throw new Error(this.str($r('app.string.error_no_download_dir')));
    }
    return `${downloadDir}/${this.bundleId()}`;
  }

  private bundleId(): string {
    const context = this.getUIContext().getHostContext();
    if (context) {
      return context.applicationInfo.name;
    }
    return 'com.52wfun.rfulash';
  }

  /** 旧版本用 下载/RFulash，升级后把里面的 SWF 搬到包名目录。 */
  private migrateLegacyLibrary(): void {
    let legacyRoot = '';
    try {
      legacyRoot = `${Environment.getUserDownloadDir()}/RFulash`;
    } catch (error) {
      return;
    }
    const legacyPlayers = `${legacyRoot}/players`;
    try {
      if (!fileIo.accessSync(legacyPlayers)) {
        return;
      }
      const playersRoot = `${this.libraryRoot()}/players`;
      this.ensureDir(`${this.libraryRoot()}`);
      this.ensureDir(playersRoot);
      const names = fileIo.listFileSync(legacyPlayers);
      for (let i = 0; i < names.length; i++) {
        const name = names[i];
        if (!name.toLowerCase().endsWith('.swf')) {
          continue;
        }
        const from = `${legacyPlayers}/${name}`;
        const to = `${playersRoot}/${name}`;
        try {
          if (!fileIo.accessSync(to)) {
            fileIo.renameSync(from, to);
          }
        } catch (error) {
          const err = error as BusinessError;
          console.error(`migrate ${name} failed: ${err.message}`);
        }
      }
      try {
        fileIo.rmdirSync(legacyPlayers);
        fileIo.rmdirSync(legacyRoot);
      } catch (error) {
        console.info('legacy library folder not empty, kept');
      }
      if (this.recentsStore) {
        this.recents = this.recentsStore.rewriteSources(`${legacyPlayers}/`, `${playersRoot}/`);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`library migration failed: ${err.message}`);
    }
  }

  /** 播放库文件存放在下载目录 <包名>/players 里；分组就是它下面的子文件夹。 */
  private copyIntoLibrary(uri: string, name: string, group: string): string {
    const playersDir = `${this.libraryRoot()}/players`;
    let source = uri;
    try {
      source = new fileUri.FileUri(uri).path;
    } catch (error) {
      // Data-share and document URIs have no filesystem path; fileIo can still
      // stream them with the grant that came with the Want.
      console.info(`keeping URI as source: ${uri}`);
    }
    const safeName = (name === '.' || name === '..') ? this.str($r('app.string.untitled_swf')) : name;
    this.ensureDir(this.libraryRoot());
    this.ensureDir(playersDir);
    let targetDir = playersDir;
    if (group.length > 0) {
      targetDir = `${playersDir}/${group}`;
      this.ensureDir(targetDir);
    }
    const target = `${targetDir}/${safeName}`;
    if (source !== target) {
      fileIo.copyFileSync(source, target);
    }
    return target;
  }

  /** Real-time search filter for the library panel (matches file and group names). */
  private filteredLibrary(): LibraryMovie[] {
    const query = this.librarySearchText.trim().toLowerCase();
    if (query.length === 0) {
      return this.library;
    }
    const result: LibraryMovie[] = [];
    for (let i = 0; i < this.library.length; i++) {
      const entry = this.library[i];
      if (entry.name.toLowerCase().includes(query) || entry.group.toLowerCase().includes(query)) {
        result.push(entry);
      }
    }
    return result;
  }

  /**
   * The library mirrors Download/<bundleName>/players: top-level SWFs are the
   * 默认 group and every subfolder is a group. A scan rebuilds the list from
   * disk, so files and folders added or deleted in the file manager appear or
   * disappear here (and the library deletes go back to the same folders).
   */
  private syncLibraryFromFolder(): void {
    this.migrateLegacyLibrary();
    if (!this.libraryStore) {
      return;
    }
    try {
      const playersDir = `${this.libraryRoot()}/players`;
      if (!fileIo.accessSync(playersDir)) {
        return;
      }
      const names = fileIo.listFileSync(playersDir);
      const existing = this.library;
      const movies: LibraryMovie[] = [];
      const groups: string[] = [];
      for (let i = 0; i < names.length; i++) {
        const entry = names[i];
        const path = `${playersDir}/${entry}`;
        let isDir = false;
        try {
          isDir = fileIo.statSync(path).isDirectory();
        } catch (error) {
          continue;
        }
        if (isDir) {
          // Every subfolder is a group, even when it holds no SWF yet.
          groups.push(entry);
          if (movies.length >= 60) {
            continue;
          }
          let inner: string[] = [];
          try {
            inner = fileIo.listFileSync(path);
          } catch (error) {
            continue;
          }
          inner.sort();
          for (let j = 0; j < inner.length && movies.length < 60; j++) {
            if (!inner[j].toLowerCase().endsWith('.swf')) {
              continue;
            }
            const innerPath = `${path}/${inner[j]}`;
            try {
              if (!fileIo.statSync(innerPath).isFile()) {
                continue;
              }
            } catch (error) {
              continue;
            }
            movies.push(this.libraryMovieFromEntry(inner[j], innerPath, entry, existing));
          }
        } else if (entry.toLowerCase().endsWith('.swf')) {
          if (movies.length < 60) {
            movies.push(this.libraryMovieFromEntry(entry, path, '', existing));
          }
        }
      }
      groups.sort();
      let groupsChanged = groups.length !== this.libraryGroups.length;
      if (!groupsChanged) {
        for (let i = 0; i < groups.length; i++) {
          if (groups[i] !== this.libraryGroups[i]) {
            groupsChanged = true;
            break;
          }
        }
      }
      if (groupsChanged) {
        this.libraryGroups = groups;
        // The players-root watcher cannot see changes inside group folders,
        // so the watcher set is rebuilt whenever the group list changes.
        if (this.libraryWatchers.length > 0) {
          this.refreshLibraryWatchers();
        }
      }
      movies.sort((a: LibraryMovie, b: LibraryMovie): number => b.addedAt - a.addedAt);
      this.library = movies;
      this.libraryStore.replace(movies);
      // Files that were never rendered (and so have no captured frame) get a
      // thumbnail extracted straight from the SWF's embedded bitmaps instead.
      // The engine deduplicates repeat requests for the same file.
      for (let i = 0; i < movies.length; i++) {
        if (movies[i].thumb.length === 0) {
          RuffleEngine.extractThumbnail(movies[i].name, movies[i].source);
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`library folder sync failed: ${err.message}`);
    }
  }

  private libraryMovieFromEntry(name: string, path: string, group: string, existing: LibraryMovie[]): LibraryMovie {
    let thumb = this.thumbPathFor(name);
    let addedAt = 0;
    for (let j = 0; j < existing.length; j++) {
      if (existing[j].source === path) {
        thumb = existing[j].thumb.length > 0 ? existing[j].thumb : thumb;
        addedAt = existing[j].addedAt;
        break;
      }
    }
    return { name: name, source: path, thumb: thumb, addedAt: addedAt, group: group };
  }

  /** 分组即 players 下的真实子文件夹，名称直接对应目录名。 */
  private groupDir(group: string): string {
    return group.length === 0 ? `${this.libraryRoot()}/players` : `${this.libraryRoot()}/players/${group}`;
  }

  private libraryGroupMovies(group: string): LibraryMovie[] {
    const result: LibraryMovie[] = [];
    for (let i = 0; i < this.library.length; i++) {
      if (this.library[i].group === group) {
        result.push(this.library[i]);
      }
    }
    return result;
  }

  private groupCollapsed(group: string): boolean {
    const key = group.length === 0 ? GROUP_ROOT_KEY : group;
    return this.collapsedGroups.indexOf(key) >= 0;
  }

  private toggleGroup(group: string): void {
    const key = group.length === 0 ? GROUP_ROOT_KEY : group;
    const next: string[] = [];
    let removed = false;
    for (let i = 0; i < this.collapsedGroups.length; i++) {
      if (this.collapsedGroups[i] === key) {
        removed = true;
      } else {
        next.push(this.collapsedGroups[i]);
      }
    }
    if (!removed) {
      next.push(key);
    }
    this.collapsedGroups = next;
  }

  private openCreateGroup(): void {
    this.groupDraft = '';
    this.libSheetPage = LIB_PAGE_CREATE;
  }

  private openRename(group: string): void {
    this.renameFromGroup = group;
    this.groupDraft = group;
    this.libSheetPage = LIB_PAGE_RENAME;
  }

  private isValidGroupName(name: string): boolean {
    if (name.length === 0 || name.length > 30 || name === '.' || name === '..') {
      return false;
    }
    const invalid = '\\/:*?"<>|';
    for (let i = 0; i < invalid.length; i++) {
      if (name.indexOf(invalid.charAt(i)) >= 0) {
        return false;
      }
    }
    return true;
  }

  /** Creates the same-named folder under players; groups are plain folders. */
  private createGroup(): void {
    const name = this.groupDraft.trim();
    if (name.length === 0) {
      this.showToast($r('app.string.toast_group_required'));
      return;
    }
    if (!this.isValidGroupName(name)) {
      this.showToast($r('app.string.toast_group_invalid'));
      return;
    }
    try {
      const playersDir = this.groupDir('');
      this.ensureDir(playersDir);
      const dir = `${playersDir}/${name}`;
      if (fileIo.accessSync(dir)) {
        this.showToast($r('app.string.toast_group_exists'));
        return;
      }
      fileIo.mkdirSync(dir);
    } catch (error) {
      this.showToast(this.format($r('app.string.toast_group_create_failed'), (error as BusinessError).message));
      return;
    }
    this.groupDraft = '';
    this.libSheetPage = LIB_PAGE_LIST;
    this.syncLibraryFromFolder();
    this.showToast(this.format($r('app.string.toast_group_created'), name));
  }

  /** Renames the group folder itself; the SWFs inside keep their locations. */
  private renameGroup(): void {
    const name = this.groupDraft.trim();
    const from = this.renameFromGroup;
    if (name.length === 0) {
      this.showToast($r('app.string.toast_group_required'));
      return;
    }
    if (!this.isValidGroupName(name)) {
      this.showToast($r('app.string.toast_group_invalid'));
      return;
    }
    if (name === from || from.length === 0) {
      this.libSheetPage = LIB_PAGE_LIST;
      return;
    }
    try {
      const playersDir = this.groupDir('');
      this.ensureDir(playersDir);
      const target = `${playersDir}/${name}`;
      if (fileIo.accessSync(target)) {
        this.showToast($r('app.string.toast_group_exists'));
        return;
      }
      fileIo.renameSync(`${playersDir}/${from}`, target);
    } catch (error) {
      this.showToast(this.format($r('app.string.toast_group_rename_failed'), (error as BusinessError).message));
      return;
    }
    this.groupDraft = '';
    this.libSheetPage = LIB_PAGE_LIST;
    this.syncLibraryFromFolder();
    this.showToast(this.format($r('app.string.toast_group_renamed'), name));
  }

  private openMove(entry: LibraryMovie): void {
    this.moveSourcePath = entry.source;
    this.moveFileName = entry.name;
    this.moveFromGroup = entry.group;
    this.libSheetPage = LIB_PAGE_MOVE;
  }

  /** Renames the SWF between players folders, i.e. moves it between groups. */
  private moveEntryTo(group: string): void {
    if (group === this.moveFromGroup) {
      this.libSheetPage = LIB_PAGE_LIST;
      return;
    }
    const source = this.moveSourcePath;
    const name = this.moveFileName;
    if (source.length === 0 || name.length === 0) {
      this.libSheetPage = LIB_PAGE_LIST;
      return;
    }
    try {
      const targetDir = this.groupDir(group);
      this.ensureDir(targetDir);
      const target = `${targetDir}/${name}`;
      if (fileIo.accessSync(target)) {
        this.showToast($r('app.string.toast_move_exists'));
        return;
      }
      try {
        fileIo.renameSync(source, target);
      } catch (error) {
        // 跨设备重命名失败时退回复制后删除。
        fileIo.copyFileSync(source, target);
        fileIo.unlinkSync(source);
      }
      this.libSheetPage = LIB_PAGE_LIST;
      this.syncLibraryFromFolder();
      const movedTo = group.length === 0 ? this.str($r('app.string.group_default')) : group;
      this.showToast(this.format($r('app.string.toast_moved'), movedTo));
    } catch (error) {
      this.showToast(this.format($r('app.string.toast_move_failed'), (error as BusinessError).message));
    }
  }

  /** Destructive: deleting a group removes its folder and the files inside. */
  private removeGroup(group: string): void {
    const count = this.libraryGroupMovies(group).length;
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.dialog_delete_group'),
      message: count > 0
        ? this.format($r('app.string.dialog_delete_group_msg'), group, count)
        : this.format($r('app.string.dialog_delete_empty_group_msg'), group),
      buttons: [
        { text: $r('app.string.action_cancel'), color: this.accentColor },
        { text: $r('app.string.action_delete'), color: $r('app.color.player_error') }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      this.deleteGroup(group);
    }).catch((error: BusinessError) => {
      console.error(`showDialog failed: ${error.message}`);
    });
  }

  private deleteGroup(group: string): void {
    const members = this.libraryGroupMovies(group);
    try {
      fileIo.rmdirSync(this.groupDir(group));
    } catch (error) {
      this.showToast(this.format($r('app.string.toast_group_delete_failed'), (error as BusinessError).message));
      return;
    }
    for (let i = 0; i < members.length; i++) {
      this.deleteThumb(members[i].name);
    }
    this.syncLibraryFromFolder();
    this.showToast($r('app.string.toast_group_deleted'));
  }

  private addLibraryWatcher(path: string): void {
    try {
      const watcher = fileIo.createWatcher(path, WATCH_LIBRARY_EVENTS, (event: WatchEvent) => {
        this.scheduleLibrarySync();
      });
      watcher.start();
      this.libraryWatchers.push(watcher);
    } catch (error) {
      console.info(`watch ${path} unavailable`);
    }
  }

  private refreshLibraryWatchers(): void {
    this.stopLibraryWatchers();
    let playersDir = '';
    try {
      playersDir = `${this.libraryRoot()}/players`;
    } catch (error) {
      return;
    }
    this.addLibraryWatcher(playersDir);
    for (let i = 0; i < this.libraryGroups.length; i++) {
      this.addLibraryWatcher(`${playersDir}/${this.libraryGroups[i]}`);
    }
  }

  private stopLibraryWatchers(): void {
    for (let i = 0; i < this.libraryWatchers.length; i++) {
      try {
        this.libraryWatchers[i].stop();
      } catch (error) {
        console.info('library watcher already stopped');
      }
    }
    this.libraryWatchers = [];
  }

  private scheduleLibrarySync(): void {
    if (this.librarySyncTimer >= 0) {
      clearTimeout(this.librarySyncTimer);
    }
    this.librarySyncTimer = setTimeout(() => {
      this.librarySyncTimer = -1;
      this.syncLibraryFromFolder();
    }, LIBRARY_SYNC_DEBOUNCE_MS);
  }

  private ensureDownloadPermission(): Promise<boolean> {
    return new Promise<boolean>((resolve: (granted: boolean) => void) => {
      const context = this.getUIContext().getHostContext();
      if (!context) {
        resolve(false);
        return;
      }
      const atManager = abilityAccessCtrl.createAtManager();
      atManager.requestPermissionsFromUser(context, ['ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY'])
        .then((data) => {
          resolve(data.authResults.length > 0 && data.authResults[0] === 0);
        })
        .catch((error: BusinessError) => {
          console.error(`requestPermissionsFromUser failed: ${error.message}`);
          resolve(false);
        });
    });
  }

  private importSwf(uri: string, name: string): void {
    if (!this.getUIContext().getHostContext()) {
      this.showToast($r('app.string.error_no_context'));
      return;
    }
    try {
      const target = this.copyIntoImports(uri, name);
      this.requestLoad(name, target);
    } catch (error) {
      const err = error as BusinessError;
      this.opening = false;
      this.setErrorText(this.format($r('app.string.toast_import_failed'), err.message));
      this.showToast(this.errorText);
    }
  }

  /**
   * The engine renders the thumbnail itself (the surface is GPU-rendered and
   * cannot be snapshotted from ArkTS), then delivers it as a `thumb_png`
   * event handled in drainEvents.
   */
  private captureThumbnail(): void {
    const name = (this.fileName === '.' || this.fileName === '..')
      ? this.str($r('app.string.untitled_swf'))
      : this.fileName;
    if (RuffleEngine.requestThumbnail(name) !== 0) {
      console.error('thumbnail request rejected');
    }
  }

  /**
   * Re-captures the open movie's thumbnail when the library panel opens.
   * Always re-requests (not only when the PNG is missing) so thumbnails
   * stored from an early blank frame get overwritten; the engine only ships
   * non-blank frames now.
   */
  private requestThumbnailForCurrent(): void {
    if (!RuffleEngine.hasMovie() || this.fileName.length === 0) {
      return;
    }
    this.captureThumbnail();
  }

  /** Decodes the engine's RGBA readback, packs it as PNG and stores it. */
  private async saveThumbnail(name: string, width: number, height: number, data: string): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (!context || width <= 0 || height <= 0 || data.length === 0) {
      return;
    }
    try {
      const base64 = new util.Base64Helper();
      const rgba = base64.decodeSync(data);
      const options: image.InitializationOptions = {
        size: { width: width, height: height },
        srcPixelFormat: image.PixelMapFormat.RGBA_8888,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.OPAQUE
      };
      const pixelMap = await image.createPixelMap(rgba.buffer, options);
      const packer = image.createImagePacker();
      try {
        const png = await packer.packing(pixelMap, { format: 'image/png', quality: 90 });
        const safeName = (name === '.' || name === '..') ? this.str($r('app.string.untitled_swf')) : name;
        const thumbsDir = `${context.filesDir}/thumbs`;
        this.ensureDir(thumbsDir);
        const target = `${thumbsDir}/${safeName}.png`;
        const file = fileIo.openSync(target,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(file.fd, png);
        } finally {
          fileIo.closeSync(file);
        }
        if (this.libraryStore) {
          this.library = this.libraryStore.setThumb(name, target);
        }
      } finally {
        pixelMap.release();
        packer.release();
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`thumbnail save failed: ${err.message}`);
    }
  }

  private thumbPathFor(name: string): string {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return '';
    }
    const safeName = (name === '.' || name === '..') ? this.str($r('app.string.untitled_swf')) : name;
    const path = `${context.filesDir}/thumbs/${safeName}.png`;
    try {
      return fileIo.accessSync(path) ? path : '';
    } catch (error) {
      return '';
    }
  }

  /** Imports picked SWFs into the library root, or into a group folder. */
  private async importToLibrary(group: string): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      this.showToast($r('app.string.error_no_context'));
      return;
    }
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 50;
    options.fileSuffixFilters = [`${this.str($r('app.string.picker_flash'))}|.swf`];
    try {
      const uris = await new picker.DocumentViewPicker(context).select(options);
      if (uris.length === 0) {
        return;
      }
      if (!await this.ensureDownloadPermission()) {
        this.showToast($r('app.string.toast_import_permission'));
        return;
      }
      let added = 0;
      let failed = 0;
      for (let i = 0; i < uris.length; i++) {
        const name = this.nameFromPath(uris[i]);
        try {
          this.copyIntoLibrary(uris[i], name, group);
          added++;
        } catch (error) {
          const err = error as BusinessError;
          console.error(`import ${name} failed: ${err.message}`);
          failed++;
        }
      }
      this.syncLibraryFromFolder();
      const label = group.length > 0
        ? this.format($r('app.string.group_quoted'), group)
        : this.str($r('app.string.library_title'));
      if (failed === 0) {
        this.showToast(this.format($r('app.string.toast_import_added'), added, label));
      } else if (added === 0) {
        this.showToast(this.format($r('app.string.toast_import_failed_count'), failed));
      } else {
        this.showToast(this.format($r('app.string.toast_import_partial'), added, failed));
      }
    } catch (error) {
      const err = error as BusinessError;
      this.showToast(this.format($r('app.string.toast_import_failed'), err.message));
    }
  }

  /** Destructive: confirm before deleting the entry and its file. */
  private removeFromLibrary(entry: LibraryMovie): void {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.dialog_remove_work'),
      message: this.format($r('app.string.dialog_remove_work_msg'), entry.name),
      buttons: [
        { text: $r('app.string.action_cancel'), color: this.accentColor },
        { text: $r('app.string.action_remove'), color: $r('app.color.player_error') }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      this.deleteLibraryEntry(entry);
    }).catch((error: BusinessError) => {
      console.error(`showDialog failed: ${error.message}`);
    });
  }

  private deleteLibraryEntry(entry: LibraryMovie): void {
    // 播放库就是 players 文件夹的内容：移除条目即删除对应文件。
    let playersRoot = '';
    try {
      playersRoot = `${this.libraryRoot()}/players/`;
    } catch (error) {
      playersRoot = '';
    }
    if (playersRoot.length > 0 && entry.source.startsWith(playersRoot)) {
      try {
        fileIo.unlinkSync(entry.source);
      } catch (error) {
        const err = error as BusinessError;
        console.error(`unlink library file failed: ${err.message}`);
      }
    }
    this.deleteThumb(entry.name);
    if (this.libraryStore) {
      this.library = this.libraryStore.remove(entry.source);
    }
    this.showToast($r('app.string.toast_library_removed'));
  }

  /** Destructive: clearing also deletes every players folder file and group. */
  private clearLibrary(): void {
    if (this.library.length === 0 && this.libraryGroups.length === 0) {
      return;
    }
    const groups = this.libraryGroups;
    const groupText = groups.length > 0
      ? this.format($r('app.string.dialog_groups_suffix'), groups.length)
      : '';
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.dialog_clear_library'),
      message: this.format($r('app.string.dialog_clear_library_msg'), this.library.length, groupText),
      buttons: [
        { text: $r('app.string.action_cancel'), color: this.accentColor },
        { text: $r('app.string.action_clear'), color: $r('app.color.player_error') }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      const entries = this.library;
      let playersRoot = '';
      try {
        playersRoot = `${this.libraryRoot()}/players/`;
      } catch (error) {
        playersRoot = '';
      }
      for (let i = 0; i < entries.length; i++) {
        if (playersRoot.length > 0 && entries[i].source.startsWith(playersRoot)) {
          try {
            fileIo.unlinkSync(entries[i].source);
          } catch (error) {
            const err = error as BusinessError;
            console.error(`unlink library file failed: ${err.message}`);
          }
        }
        this.deleteThumb(entries[i].name);
      }
      for (let i = 0; i < groups.length; i++) {
        try {
          fileIo.rmdirSync(`${playersRoot}${groups[i]}`);
        } catch (error) {
          const err = error as BusinessError;
          console.error(`remove group ${groups[i]} failed: ${err.message}`);
        }
      }
      if (this.libraryStore) {
        this.libraryStore.replace([]);
      }
      this.library = [];
      this.libraryGroups = [];
      this.collapsedGroups = [];
      this.refreshLibraryWatchers();
      this.showToast($r('app.string.toast_library_cleared'));
    }).catch((error: BusinessError) => {
      console.error(`showDialog failed: ${error.message}`);
    });
  }

  private deleteThumb(name: string): void {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      return;
    }
    const safeName = (name === '.' || name === '..') ? this.str($r('app.string.untitled_swf')) : name;
    try {
      fileIo.unlinkSync(`${context.filesDir}/thumbs/${safeName}.png`);
    } catch (error) {
      console.info(`thumb ${safeName} not deleted`);
    }
  }

  private openLibrary(entry: LibraryMovie): void {
    if (!this.canRead(entry.source)) {
      this.showToast($r('app.string.toast_file_missing_import'));
      if (this.libraryStore) {
        this.library = this.libraryStore.remove(entry.source);
      }
      return;
    }
    this.settingsVisible = false;
    this.libSheetVisible = false;
    this.requestLoad(entry.name, entry.source);
  }

  /**
   * Picker grants cover a single file, so a copy only keeps siblings when the
   * source directory happens to be listable (app sandbox or a fully granted
   * directory). Best-effort: failures just mean assets stay unresolved.
   */
  private copySiblings(source: string, targetDir: string): void {
    const slash = source.lastIndexOf('/');
    if (slash <= 0) {
      return;
    }
    const parent = source.substring(0, slash);
    const ownName = source.substring(slash + 1);
    try {
      const names = fileIo.listFileSync(parent);
      if (names.length > 200) {
        return;
      }
      for (let i = 0; i < names.length; i++) {
        const entry = names[i];
        if (entry === ownName) {
          continue;
        }
        try {
          fileIo.copyFileSync(`${parent}/${entry}`, `${targetDir}/${entry}`);
        } catch (error) {
          console.info(`sibling ${entry} not copied`);
        }
      }
    } catch (error) {
      console.info(`siblings of ${source} are not listable`);
    }
  }

  private ensureDir(path: string): void {
    try {
      if (!fileIo.accessSync(path)) {
        fileIo.mkdirSync(path);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`mkdir ${path} failed: ${err.message}`);
    }
  }

  private startLoading(name: string): void {
    this.clearError();
    this.fileName = name;
    this.opening = true;
    this.status = $r('app.string.status_loading');
    this.libSheetVisible = false;
    this.compactTab = TAB_PLAYER;
    this.requestFocus('ruffleFocus');
  }

  /** Opens a local file, waiting for the engine surface when it is not up yet. */
  private requestLoad(name: string, source: string): void {
    this.startLoading(name);
    this.pendingLoadSource = source;
    this.pendingLoadName = name;
    this.pendingLoadAttempts = 0;
    this.pendingLoadAt = 0;
    this.attemptLoad();
  }

  private commitPendingRecent(): void {
    const entry = this.pendingRecent;
    if (!entry) {
      return;
    }
    this.pendingRecent = undefined;
    this.fileName = entry.name;
    if (this.recentsStore) {
      entry.openedAt = Date.now();
      this.recents = this.recentsStore.add(entry);
    }
  }

  private openRecent(entry: RecentMovie): void {
    this.settingsVisible = false;
    this.libSheetVisible = false;
    if (!this.canRead(entry.source)) {
      this.showToast($r('app.string.toast_file_missing_open'));
      if (this.recentsStore) {
        this.recents = this.recentsStore.remove(entry.source);
      }
      return;
    }
    this.requestLoad(entry.name, entry.source);
  }

  /** Destructive: always confirm before dropping a single history entry. */
  private removeRecent(entry: RecentMovie): void {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.dialog_remove_record'),
      message: this.format($r('app.string.dialog_remove_record_msg'), entry.name),
      buttons: [
        { text: $r('app.string.action_cancel'), color: this.accentColor },
        { text: $r('app.string.action_remove'), color: $r('app.color.player_error') }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      if (this.recentsStore) {
        this.recents = this.recentsStore.remove(entry.source);
      }
      this.showToast($r('app.string.toast_recent_removed'));
    }).catch((error: BusinessError) => {
      console.error(`showDialog failed: ${error.message}`);
    });
  }

  /** Destructive: clearing the whole history needs an explicit confirmation. */
  private clearRecents(): void {
    if (this.recents.length === 0) {
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.dialog_clear_recents'),
      message: this.format($r('app.string.dialog_clear_recents_msg'), this.recents.length),
      buttons: [
        { text: $r('app.string.action_cancel'), color: this.accentColor },
        { text: $r('app.string.action_clear'), color: $r('app.color.player_error') }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      if (this.recentsStore) {
        this.recentsStore.clear();
      }
      this.recents = [];
      this.showToast($r('app.string.toast_recents_cleared'));
    }).catch((error: BusinessError) => {
      console.error(`showDialog failed: ${error.message}`);
    });
  }

  /** A local .swf opened from another app arrives as a Want URI. */
  private onPendingSwfUri(_propName: string): void {
    const uri = this.pendingSwfUri;
    if (uri.length === 0) {
      return;
    }
    AppStorage.setOrCreate('pendingSwfUri', '');
    if (uri.startsWith('http://') || uri.startsWith('https://')) {
      return;
    }
    this.settingsVisible = false;
    this.importSwf(uri, this.nameFromPath(uri));
  }

  private nameFromPath(raw: string): string {
    try {
      // URI.getLastSegment returns the percent-decoded last path segment, so a
      // picked document URI yields the real file name instead of %E5... escapes.
      const segment = new fileUri.FileUri(raw).getLastSegment();
      if (segment.length > 0) {
        return segment;
      }
    } catch (error) {
      console.info(`nameFromPath fallback for ${raw}`);
    }
    const slash = raw.lastIndexOf('/');
    let name = slash >= 0 ? raw.substring(slash + 1) : raw;
    const query = name.indexOf('?');
    if (query >= 0) {
      name = name.substring(0, query);
    }
    name = this.decodeName(name);
    return name.length > 0 ? name : this.str($r('app.string.untitled_swf'));
  }

  private decodeName(text: string): string {
    try {
      return decodeURIComponent(text);
    } catch (error) {
      return text;
    }
  }

  private canRead(path: string): boolean {
    try {
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      fileIo.closeSync(file);
      return true;
    } catch (error) {
      return false;
    }
  }

  private async openSwf(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      this.showToast($r('app.string.error_no_context'));
      return;
    }

    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = [`${this.str($r('app.string.picker_flash'))}|.swf`];

    try {
      const uris = await new picker.DocumentViewPicker(context).select(options);
      if (uris.length === 0) {
        return;
      }
      const uri = uris[0];
      const name = this.nameFromPath(uri);
      this.importSwf(uri, name);
    } catch (error) {
      const err = error as BusinessError;
      this.showToast(this.format($r('app.string.toast_select_failed'), err.message));
    }
  }

  private showToast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`showToast failed: ${err.message}`);
    }
  }

  /** Official title-bar actions; the menu is rendered by HdsNavigation. */
  private titleBarMenus(): HdsNavigationMenuItemOptions[] {
    const items: HdsNavigationMenuItemOptions[] = [
      {
        content: {
          icon: $r('sys.symbol.folder'),
          label: $r('app.string.menu_open_swf'),
          action: () => {
            this.openSwf();
          }
        }
      },
      {
        content: {
          icon: $r('sys.symbol.film'),
          label: $r('app.string.menu_library'),
          action: () => {
            this.toggleLibSheet(SHEET_LIBRARY);
          }
        }
      },
      {
        content: {
          icon: $r('sys.symbol.clock'),
          label: $r('app.string.menu_recents'),
          action: () => {
            this.toggleLibSheet(SHEET_RECENTS);
          }
        }
      }
    ];
    if (this.compactTab !== TAB_HOME) {
      items.push({
        content: {
          icon: this.playing ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'),
          label: this.playing ? $r('app.string.menu_pause') : $r('app.string.menu_resume'),
          isEnabled: this.hasMovie,
          action: () => {
            this.togglePlaying();
          }
        }
      });
    }
    items.push({
      content: {
        icon: $r('sys.symbol.gearshape'),
        label: $r('app.string.menu_settings'),
        action: () => {
          this.showSettings();
        }
      }
    });
    if (this.compactTab !== TAB_HOME) {
      items.push({
        content: {
          icon: $r('sys.symbol.arrow_up_left_and_arrow_down_right'),
          label: $r('app.string.menu_fullscreen'),
          action: () => {
            this.applyFullscreen(true, true);
          }
        }
      });
    }
    return items;
  }

  private titleBarOptions(): HdsNavigationTitleBarOptions {
    const isHome: boolean = this.compactTab === TAB_HOME;
    // The immersive bar is transparent and floats over the stage, so it keeps
    // the old toolbar surface as its own background instead of the movie.
    const barStyle: HdsNavigationTitleBarStyle = {
      backgroundStyle: {
        backgroundColor: $r('app.color.player_surface')
      },
      contentStyle: {
        titleStyle: {
          mainTitleColor: $r('app.color.player_text'),
          subTitleColor: $r('app.color.player_text_secondary')
        },
        menuStyle: {
          iconColor: $r('app.color.player_text')
        }
      }
    };
    return {
      style: {
        originalStyle: barStyle,
        scrollEffectStyle: barStyle,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: isHome
            ? $r('app.string.home_title')
            : (this.fileName.length > 0 ? this.fileName : $r('app.string.no_movie')),
          subTitle: isHome ? '' : this.status,
          mainTitleSize: TitleSize.TITLE_S
        },
        menu: {
          maxCount: 6,
          value: this.titleBarMenus()
        }
      }
    };
  }

  @Builder
  EmptyState() {
    Column({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.film'))
        .fontSize(52)
        .fontColor([$r('app.color.player_text_disabled')])
      Text($r('app.string.home_select_hint'))
        .fontSize(15)
        .fontColor($r('app.color.player_text_secondary'))
      Text($r('app.string.home_auto_collect'))
        .fontSize(13)
        .fontColor($r('app.color.player_text_tertiary'))
        .textAlign(TextAlign.Center)
      Button({ type: ButtonType.Normal }) {
        Text($r('app.string.menu_open_swf'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.player_on_accent'))
      }
      .height(LayoutSpec.TOUCH_TARGET)
      .width(132)
      .margin({ top: 6 })
      .backgroundColor(this.accentColor)
      .borderRadius(10)
      .focusOnTouch(false)
      .accessibilityText($r('app.string.a11y_open_swf_file'))
      .onClick(() => this.openSwf())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HomeHero() {
    Column({ space: 12 }) {
      Image($r('app.media.startIcon'))
        .width(80)
        .height(80)
        .borderRadius(22)
        .clip(true)
      Column({ space: 6 }) {
        Text('RFulash')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.player_text'))
        Text($r('app.string.app_tagline'))
          .fontSize(14)
          .fontColor($r('app.color.player_text_secondary'))
      }
      .alignItems(HorizontalAlign.Center)
      Text($r('app.string.home_hero_desc'))
        .fontSize(14)
        .lineHeight(22)
        .fontColor($r('app.color.player_text_secondary'))
        .textAlign(TextAlign.Center)
        .constraintSize({ maxWidth: 520 })
    }
    .width('100%')
    .padding({ top: 24, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HomeStep(step: string, title: ResourceStr, desc: ResourceStr) {
    Row({ space: 12 }) {
      Stack() {
        Text(step)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(this.accentBg)
      .accessibilityLevel('no')

      Column({ space: 3 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.player_text'))
        Text(desc)
          .fontSize(13)
          .lineHeight(18)
          .fontColor($r('app.color.player_text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  HomePage() {
    Scroll() {
      Column() {
        Column({ space: 20 }) {
          this.HomeHero()

          Column({ space: 8 }) {
            Text($r('app.string.home_steps_title'))
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.player_text'))
              .width('100%')

            Column() {
              this.HomeStep('1', $r('app.string.home_step1_title'), $r('app.string.home_step1_desc'))
              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.player_divider'))
                .margin({ left: 56, right: 16 })
              this.HomeStep('2', $r('app.string.home_step2_title'), $r('app.string.home_step2_desc'))
              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.player_divider'))
                .margin({ left: 56, right: 16 })
              this.HomeStep('3', $r('app.string.home_step3_title'), $r('app.string.home_step3_desc'))
            }
            .width('100%')
            .backgroundColor($r('app.color.player_surface'))
            .borderRadius(15)
          }
          .width('100%')

          Column({ space: 12 }) {
            Button({ type: ButtonType.Normal }) {
              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.folder'))
                  .fontSize(20)
                  .fontColor([$r('app.color.player_on_accent')])
                Text($r('app.string.menu_open_swf'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.player_on_accent'))
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor(this.accentColor)
            .borderRadius(10)
            .focusOnTouch(false)
            .accessibilityText($r('app.string.a11y_open_swf_file'))
            .onClick(() => {
              this.openSwf();
            })

            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.checkmark_shield'))
                .fontSize(14)
                .fontColor([$r('app.color.player_text_secondary')])
              Text($r('app.string.home_privacy'))
                .fontSize(12)
                .fontColor($r('app.color.player_text_secondary'))
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxWidth: 720 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 24 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor($r('app.color.player_bg'))
    // Swallow taps that miss the cards so they never reach the movie below.
    .onClick(() => {
    })
  }

  private tabBarStyle(label: ResourceStr, icon: Resource): BottomTabBarStyle {
    const normal = new SymbolGlyphModifier(icon);
    normal.fontColor([$r('app.color.player_text_secondary')]);
    const selected = new SymbolGlyphModifier(icon);
    selected.fontColor([this.accentColor]);
    const symbol: TabBarSymbol = {
      normal: normal,
      selected: selected
    };
    return BottomTabBarStyle.of(symbol, label)
      .labelStyle({
        selectedColor: this.accentColor,
        unselectedColor: $r('app.color.player_text_secondary'),
        maxLines: 1
      });
  }

  private tabBarMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: glowMaterialStyle(this.glowLevel),
      interactive: true,
      lightEffect: { color: this.accentColor }
    });
  }

  private sidebarActiveColor(active: boolean): ResourceColor {
    return active ? this.accentColor : $r('app.color.player_text');
  }

  private sidebarRowBackground(active: boolean, hoverKey: number): ResourceColor {
    if (active) {
      return this.accentBg;
    }
    return this.sidebarHovered === hoverKey ? $r('app.color.player_fill') : Color.Transparent;
  }

  /** XBiGOD-style PC side navigation: brand header, flat rows, bottom about. */
  @Builder
  Sidebar() {
    Column() {
      Row({ space: 10 }) {
        Image($r('app.media.startIcon'))
          .width(38)
          .height(38)
          .borderRadius(11)
          .clip(true)
        Column({ space: 2 }) {
          Text('RFulash')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.player_text'))
            .maxLines(1)
          Text($r('app.string.app_tagline'))
            .fontSize(11)
            .fontColor($r('app.color.player_text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 18 })

      Scroll() {
        Column({ space: 4 }) {
          this.NavRow($r('sys.symbol.house'), $r('app.string.home_title'), TAB_HOME)
          this.NavRow($r('sys.symbol.play_fill'), $r('app.string.tab_play'), TAB_PLAYER)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)

      this.AboutRow()
    }
    .width(LayoutSpec.SIDEBAR_WIDTH)
    .constraintSize({ maxWidth: '40%' })
    .height('100%')
    .padding({ left: 8, right: 8, top: 16, bottom: 14 })
    .backgroundColor($r('app.color.player_surface'))
  }

  @Builder
  NavRow(icon: Resource, label: Resource, tab: number) {
    Row({ space: 12 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.sidebarActiveColor(this.compactTab === tab)])
      Text(label)
        .fontSize(15)
        .fontWeight(this.compactTab === tab ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.sidebarActiveColor(this.compactTab === tab))
        .maxLines(1)
    }
    .width('100%')
    .height(40)
    .padding({ left: 14, right: 14 })
    .borderRadius(8)
    .backgroundColor(this.sidebarRowBackground(this.compactTab === tab, tab))
    .focusable(true)
    .focusOnTouch(false)
    .accessibilityGroup(true)
    .accessibilityText(this.str(label))
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.sidebarHovered = tab;
      } else if (this.sidebarHovered === tab) {
        this.sidebarHovered = -1;
      }
    })
    .onClick(() => {
      this.selectCompactTab(tab);
    })
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && (event.keyCode === KEY_ENTER || event.keyCode === KEY_SPACE)) {
        this.selectCompactTab(tab);
      }
    })
  }

  @Builder
  AboutRow() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.info_circle'))
        .fontSize(22)
        .fontColor([this.sidebarActiveColor(this.aboutVisible)])
      Text($r('app.string.about_title'))
        .fontSize(15)
        .fontWeight(this.aboutVisible ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.sidebarActiveColor(this.aboutVisible))
        .maxLines(1)
    }
    .width('100%')
    .height(40)
    .padding({ left: 14, right: 14 })
    .borderRadius(8)
    .backgroundColor(this.sidebarRowBackground(this.aboutVisible, SIDEBAR_ABOUT_KEY))
    .focusable(true)
    .focusOnTouch(false)
    .accessibilityGroup(true)
    .accessibilityText($r('app.string.about_title'))
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.sidebarHovered = SIDEBAR_ABOUT_KEY;
      } else if (this.sidebarHovered === SIDEBAR_ABOUT_KEY) {
        this.sidebarHovered = -1;
      }
    })
    .onClick(() => this.showAbout())
  }

  /**
   * Half-modal library/recents content. The system sheet supplies the scrim,
   * title and close button, so only the action row and the listing live here.
   */
  @Builder
  LibrarySheet() {
    Column({ space: 10 }) {
      if (this.libSheetKind === SHEET_LIBRARY && this.libSheetPage === LIB_PAGE_CREATE) {
        this.GroupNamePage(false)
      } else if (this.libSheetKind === SHEET_LIBRARY && this.libSheetPage === LIB_PAGE_RENAME) {
        this.GroupNamePage(true)
      } else if (this.libSheetKind === SHEET_LIBRARY && this.libSheetPage === LIB_PAGE_MOVE) {
        this.MoveGroupPage()
      } else {
        Row() {
          Blank()
          if (this.libSheetKind === SHEET_LIBRARY) {
            Button($r('app.string.lib_import'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontColor(this.accentColor)
              .controlSize(ControlSize.SMALL)
              .height(36)
              .focusOnTouch(false)
              .onClick(() => this.importToLibrary(''))
            Button($r('app.string.lib_new_group'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontColor(this.accentColor)
              .controlSize(ControlSize.SMALL)
              .height(36)
              .focusOnTouch(false)
              .onClick(() => this.openCreateGroup())
            Button($r('app.string.lib_search'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontColor(this.accentColor)
              .controlSize(ControlSize.SMALL)
              .height(36)
              .focusOnTouch(false)
              .onClick(() => {
                this.librarySearchOpen = !this.librarySearchOpen;
                if (!this.librarySearchOpen) {
                  this.librarySearchText = '';
                }
              })
            Button($r('app.string.lib_refresh'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontColor(this.accentColor)
              .controlSize(ControlSize.SMALL)
              .height(36)
              .focusOnTouch(false)
              .onClick(() => {
                this.syncLibraryFromFolder();
                this.showToast($r('app.string.toast_library_refreshed'));
              })
            if (this.library.length > 0 || this.libraryGroups.length > 0) {
              Button($r('app.string.lib_clear'))
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .fontColor(this.accentColor)
                .controlSize(ControlSize.SMALL)
                .height(36)
                .focusOnTouch(false)
                .onClick(() => this.clearLibrary())
            }
          } else if (this.recents.length > 0) {
            Button($r('app.string.lib_clear'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontColor(this.accentColor)
              .controlSize(ControlSize.SMALL)
              .height(36)
              .focusOnTouch(false)
              .onClick(() => this.clearRecents())
          }
        }
        .width('100%')

        if (this.libSheetKind === SHEET_LIBRARY) {
          if (this.librarySearchOpen) {
            TextInput({ placeholder: $r('app.string.search_placeholder'), text: this.librarySearchText })
              .placeholderColor($r('app.color.player_text_tertiary'))
              .fontSize(14)
              .fontColor($r('app.color.player_text'))
              .backgroundColor($r('app.color.player_fill'))
              .borderRadius(10)
              .height(40)
              .width('100%')
              .defaultFocus(true)
              .onChange((value: string) => {
                this.librarySearchText = value;
              })
          }
          if (this.librarySearchText.trim().length > 0) {
            // Searching folds the grouping away and shows flat matches.
            if (this.filteredLibrary().length > 0) {
              Scroll() {
                Column({ space: 8 }) {
                  ForEach(this.filteredLibrary(), (entry: LibraryMovie) => {
                    LibraryRow({
                      entry: entry,
                      groupLabel: entry.group,
                      onOpen: (item: LibraryMovie) => this.openLibrary(item),
                      onRemove: (item: LibraryMovie) => this.removeFromLibrary(item),
                      onMove: (item: LibraryMovie) => this.openMove(item)
                    })
                  }, (entry: LibraryMovie) => entry.source)
                }
                .width('100%')
              }
              .scrollBar(BarState.Auto)
              .layoutWeight(1)
              .align(Alignment.Top)
            } else {
              Text($r('app.string.no_match'))
                .fontSize(13)
                .fontColor($r('app.color.player_text_tertiary'))
                .width('100%')
              Blank()
                .layoutWeight(1)
            }
          } else if (this.library.length > 0 || this.libraryGroups.length > 0) {
            Scroll() {
              Column({ space: 8 }) {
                if (this.libraryGroupMovies('').length > 0) {
                  this.GroupSection('', '')
                }
                ForEach(this.libraryGroups, (group: string) => {
                  this.GroupSection(group, group)
                }, (group: string) => `g:${group}`)
              }
              .width('100%')
            }
            .scrollBar(BarState.Auto)
            .layoutWeight(1)
            .align(Alignment.Top)
          } else {
            Text($r('app.string.no_works'))
              .fontSize(13)
              .fontColor($r('app.color.player_text_tertiary'))
              .width('100%')
            Blank()
              .layoutWeight(1)
          }
        } else {
          if (this.recents.length > 0) {
            Scroll() {
              Column({ space: 8 }) {
                ForEach(this.recents, (entry: RecentMovie) => {
                  RecentRow({
                    entry: entry,
                    onOpen: (recent: RecentMovie) => this.openRecent(recent),
                    onDelete: () => this.removeRecent(entry)
                  })
                }, (entry: RecentMovie) => entry.source)
              }
              .width('100%')
            }
            .scrollBar(BarState.Auto)
            .layoutWeight(1)
            .align(Alignment.Top)
          } else {
            Text($r('app.string.no_records'))
              .fontSize(13)
              .fontColor($r('app.color.player_text_tertiary'))
              .width('100%')
            Blank()
              .layoutWeight(1)
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 16 })
  }

  /** One folder header plus its (collapsible) movie rows. */
  @Builder
  GroupSection(group: string, label: string) {
    Column({ space: 8 }) {
      GroupRow({
        groupName: label,
        count: this.libraryGroupMovies(group).length,
        collapsed: this.groupCollapsed(group),
        rootGroup: group.length === 0,
        onToggle: () => this.toggleGroup(group),
        onImport: () => this.importToLibrary(group),
        onRename: () => this.openRename(group),
        onDelete: () => this.removeGroup(group)
      })
      if (!this.groupCollapsed(group) && this.libraryGroupMovies(group).length > 0) {
        Column({ space: 8 }) {
          ForEach(this.libraryGroupMovies(group), (entry: LibraryMovie) => {
            LibraryRow({
              entry: entry,
              onOpen: (item: LibraryMovie) => this.openLibrary(item),
              onRemove: (item: LibraryMovie) => this.removeFromLibrary(item),
              onMove: (item: LibraryMovie) => this.openMove(item)
            })
          }, (entry: LibraryMovie) => entry.source)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  /** 新建/重命名分组 form; both act on the same-named players subfolder. */
  @Builder
  GroupNamePage(isRename: boolean) {
    Column({ space: 12 }) {
      Text(isRename
        ? $r('app.string.group_rename_note')
        : $r('app.string.group_create_note'))
        .fontSize(13)
        .fontColor($r('app.color.player_text_tertiary'))
        .width('100%')
      TextInput({ placeholder: $r('app.string.group_name_placeholder'), text: this.groupDraft })
        .height(44)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .placeholderColor($r('app.color.player_text_tertiary'))
        .backgroundColor($r('app.color.player_fill'))
        .borderRadius(10)
        .width('100%')
        .defaultFocus(true)
        .onChange((value: string) => {
          this.groupDraft = value;
        })
        .onSubmit(() => {
          if (isRename) {
            this.renameGroup();
          } else {
            this.createGroup();
          }
        })
      Row({ space: 12 }) {
        Button($r('app.string.action_cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(this.accentColor)
          .controlSize(ControlSize.SMALL)
          .height(36)
          .focusOnTouch(false)
          .onClick(() => {
            this.libSheetPage = LIB_PAGE_LIST;
          })
        Button({ type: ButtonType.Normal }) {
          Text(isRename ? $r('app.string.action_confirm') : $r('app.string.action_create'))
            .fontSize(14)
            .fontColor($r('app.color.player_on_accent'))
        }
        .height(36)
        .padding({ left: 18, right: 18 })
        .backgroundColor(this.accentColor)
        .borderRadius(10)
        .focusOnTouch(false)
        .onClick(() => {
          if (isRename) {
            this.renameGroup();
          } else {
            this.createGroup();
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  /** 移动到分组 picker: 默认 plus every group, current one check-marked. */
  @Builder
  MoveGroupPage() {
    Column({ space: 10 }) {
      Text(this.format($r('app.string.move_prompt'), this.moveFileName))
        .fontSize(13)
        .fontColor($r('app.color.player_text_secondary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Scroll() {
        Column({ space: 8 }) {
          this.MoveTargetRow('', this.str($r('app.string.group_default')))
          ForEach(this.libraryGroups, (group: string) => {
            this.MoveTargetRow(group, group)
          }, (group: string) => `m:${group}`)
          if (this.libraryGroups.length === 0) {
            Text($r('app.string.move_no_groups'))
              .fontSize(12)
              .fontColor($r('app.color.player_text_tertiary'))
              .width('100%')
          }
        }
        .width('100%')
      }
      .scrollBar(BarState.Auto)
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  MoveTargetRow(group: string, label: string) {
    Row({ space: 10 }) {
      SymbolGlyph($r('sys.symbol.folder'))
        .fontSize(20)
        .fontColor([$r('app.color.player_text_secondary')])
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.player_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (this.moveFromGroup === group) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(18)
          .fontColor([this.accentColor])
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.player_fill'))
    .borderRadius(10)
    .onClick(() => this.moveEntryTo(group))
  }

  /** Settings sheet content; the player settings fill the whole panel. */
  @Builder
  SettingsSheet() {
    PlayerMenu({
      visible: $settingsVisible,
      page: $settingsPage,
      volume: $volume,
      qualityIndex: $qualityIndex,
      scaleMode: $scaleMode,
      scaleForced: $scaleForced,
      letterbox: $letterbox,
      playing: $playing,
      fullscreen: $fullscreen,
      hasMovie: $hasMovie,
      colorModeIndex: this.colorModeIndex,
      themeIndex: this.themeIndex,
      glowLevel: this.glowLevel,
      languageIndex: this.languageIndex,
      showAbout: !this.isSidebarLayout(),
      onPickGlow: (level: number) => {
        this.glowLevel = normalizeGlowLevel(level);
      },
      onPickAccent: (index: number) => this.pickAccent(index),
      onPickLanguage: (index: number) => this.onPickLanguage(index),
      onPickTheme: (index: number) => {
        if (this.colorModeIndex === index) {
          return;
        }
        this.colorModeIndex = index;
        this.applyColorMode();
      },
      onReload: () => this.reloadMovie(),
      onTogglePlaying: () => this.togglePlaying(),
      onStep: () => this.stepFrame(),
      onFullscreen: () => this.applyFullscreen(!this.fullscreen, true),
      onAbout: () => {
        // Sheets swap instead of stacking: close this panel first.
        this.settingsVisible = false;
        this.showAbout();
      }
    })
  }

  /** About sheet content; swaps to the licenses page in the same panel. */
  @Builder
  AboutSheet() {
    if (this.aboutPage === ABOUT_PAGE_LICENSES) {
      LicensesPanel({
        viewerOpen: $licenseViewerOpen,
        onBack: () => {
          this.aboutPage = ABOUT_PAGE_ABOUT;
        }
      })
    } else {
      AboutPanel({
        onOpenLicenses: () => {
          this.aboutPage = ABOUT_PAGE_LICENSES;
        }
      })
    }
  }

  @Builder
  KeyboardOverlay() {
    Column() {
      TextInput({ text: this.keyboardText, placeholder: $r('app.string.keyboard_placeholder') })
        .id('ruffleKeyboard')
        .height(44)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .placeholderColor('#80FFFFFF')
        .backgroundColor('#1A1F27')
        .borderRadius(8)
        .enterKeyType(EnterKeyType.Send)
        .onChange((value: string) => this.onKeyboardText(value))
        .onSubmit(() => {
          RuffleEngine.key(KEY_DOWN, KEY_ENTER);
          RuffleEngine.key(KEY_UP, KEY_ENTER);
        })
        .onKeyEvent((event: KeyEvent) => this.handleKeyboardOverlayKey(event))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#CC0E1116')
    .align(Alignment.Bottom)
  }

  @Builder
  MovieStage() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        XComponent({ id: 'ruffleSurface', type: XComponentType.SURFACE, libraryname: 'entry' })
          .width('100%')
          .height('100%')
          .onAreaChange((_oldValue: Area, _newValue: Area) => this.syncSurfaceSize())
          .onAxisEvent((event: AxisEvent) => this.handleAxis(event))

        if (this.hasMovie && this.errorText.length === 0) {
          Text(`${this.perfFps.toFixed(0)} fps`)
            .fontSize(12)
            .fontColor('#00FF00')
            .textShadow({ radius: 4, color: '#99000000', offsetX: 0, offsetY: 1 })
            .margin({ left: 12, top: 16 })
            .hitTestBehavior(HitTestMode.None)
        }

        if (!this.hasMovie && !this.opening && this.errorText.length === 0 && !this.fullscreen) {
          this.EmptyState()
        }

        if (this.fullscreen) {
          Row() {
            Blank()
            Button($r('app.string.player_exit_fullscreen'))
              .fontSize(13)
              .fontColor('#FFFFFF')
              .height(40)
              .backgroundColor('#99000000')
              .margin({ top: this.is2in1 ? 72 : 16, right: this.is2in1 ? 24 : 16 })
              .focusOnTouch(false)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => this.applyFullscreen(false, true))
          }
          .width('100%')
        }

        if (this.errorText.length > 0) {
          Column() {
            Text(this.errorText)
              .fontSize(13)
              .fontColor('#FF8A80')
              .maxLines(4)
              .textAlign(TextAlign.Center)
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .backgroundColor('#99000000')
              .borderRadius(10)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .hitTestBehavior(HitTestMode.None)
        }

        if (this.keyboardVisible) {
          this.KeyboardOverlay()
        }
      }
      // XComponent cannot hold ArkUI focus, so the surface container owns it.
      .id('ruffleFocus')
      .width('100%')
      .height('100%')
      .focusable(true)
      .defaultFocus(true)
      .focusOnTouch(true)
      .onFocus(() => RuffleEngine.focus(true))
      .onBlur(() => RuffleEngine.focus(false))
      .onKeyEvent((event: KeyEvent) => this.handleSurfaceKey(event))
      .onTouch((event: TouchEvent) => {
        // Pointer use must hand the keyboard back to the movie, in windowed
        // mode too; the text overlay owns focus while it is open.
        if (event.type === TouchType.Down && !this.keyboardVisible) {
          this.requestFocus('ruffleFocus');
        }
      })

      // Home covers the stage but never unmounts it: the engine lives with
      // the XComponent surface, so the movie must stay beneath the page.
      if (!this.fullscreen && this.compactTab === TAB_HOME) {
        this.HomePage()
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * System floating tab bar for tablet and narrow-PC windows. The pages are
   * empty: the library and recents pages float over the stage instead of being
   * TabContent pages, so switching tabs never unmounts the movie. Their
   * entries live in the top-right cluster, so the bar keeps two tabs.
   */
  @Builder
  CompactTabBar() {
    Tabs({ barPosition: BarPosition.End, index: this.compactTab }) {
      TabContent() {
      }
      .tabBar(this.tabBarStyle($r('app.string.home_title'), $r('sys.symbol.house')))

      TabContent() {
      }
      .tabBar(this.tabBarStyle($r('app.string.tab_play'), $r('sys.symbol.play_fill')))
    }
    .width('100%')
    // The pages are empty, so the bar only needs its own strip; keeping the
    // bar out of the stage also keeps taps on it away from the movie.
    .height(LayoutSpec.TAB_BAR_HEIGHT + LayoutSpec.TAB_BAR_BOTTOM_GAP * 2)
    .barMode(BarMode.Fixed)
    .barOverlap(true)
    .scrollable(false)
    .barHeight(LayoutSpec.TAB_BAR_HEIGHT)
    .barFloatingStyle({
      barWidth: {
        smallBarWidth: LayoutSpec.TAB_BAR_WIDTH_SMALL,
        mediumBarWidth: LayoutSpec.TAB_BAR_WIDTH_MEDIUM,
        largeBarWidth: LayoutSpec.TAB_BAR_WIDTH_LARGE
      },
      barSideMargin: LayoutSpec.TAB_BAR_SIDE_MARGIN,
      barBottomMargin: LayoutSpec.TAB_BAR_BOTTOM_GAP,
      systemMaterial: this.tabBarMaterial()
    })
    .animationDuration(200)
    .onChange((index: number) => {
      if (index !== this.compactTab) {
        this.selectCompactTab(index);
      }
    })
  }

  build() {
    Stack() {
      Row() {
        if (!this.fullscreen && this.isSidebarLayout()) {
          this.Sidebar()
        }
        Column() {
          // The stage occupies one fixed slot in the tree for every layout.
          // The engine lives and dies with the XComponent surface, so a
          // breakpoint that rebuilds this node would restart the movie; the
          // sidebar and tab bar may only appear around it.
          HdsNavigation() {
            Row() {
              Column() {
                this.MovieStage()
              }
              .layoutWeight(1)
              .height('100%')
            }
            .layoutWeight(1)
            .width('100%')
            // The bar floats over the content; reserve its strip so the
            // surface and overlays stay below the chrome. The strip keeps the
            // old toolbar surface even if the bar's own style is dropped.
            .backgroundColor($r('app.color.player_surface'))
            .padding({ top: this.fullscreen ? 0 : (this.is2in1 ? LayoutSpec.TITLE_BAR_HEIGHT_2IN1 :
              LayoutSpec.TITLE_BAR_HEIGHT) })
          }
          .titleBar(this.titleBarOptions())
          .titleMode(HdsNavigationTitleMode.MINI)
          .hideBackButton(true)
          .mode(NavigationMode.Stack)
          .hideTitleBar(this.fullscreen, true)
          .width('100%')
          .layoutWeight(1)

          if (!this.fullscreen && !this.isSidebarLayout()) {
            this.CompactTabBar()
          }
        }
        .layoutWeight(1)
        .height('100%')
        .bindSheet($$this.libSheetVisible, this.LibrarySheet, this.libSheetOptions())
      }
      .width('100%')
      .height('100%')
      // Key events bubble here from whichever child holds focus, so the movie
      // keeps receiving keys after the toolbar buttons or the surface are used.
      .onKeyEvent((event: KeyEvent) => this.handleKey(event))
      .bindSheet($$this.settingsVisible, this.SettingsSheet, this.settingsSheetOptions())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.player_bg'))
    .bindSheet($$this.aboutVisible, this.AboutSheet, this.aboutSheetOptions())
  }
}
