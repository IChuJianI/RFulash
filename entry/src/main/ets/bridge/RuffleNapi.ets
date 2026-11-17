import {
  nativeDialogResult,
  nativeExtractThumbnail,
  nativeFocus,
  nativeHasMovie,
  nativeHttpResult,
  nativeInit,
  nativeIsPlaying,
  nativeKey,
  nativeLastError,
  nativeLoadSwf,
  nativeLoadUrl,
  nativeMovieHeight,
  nativeMovieWidth,
  nativePollEvent,
  nativeReady,
  nativeReload,
  nativeRequestThumbnail,
  nativeSetFullscreen,
  nativeSetLetterbox,
  nativeSetPlaying,
  nativeSetQuality,
  nativeSetScaleMode,
  nativeSetVolume,
  nativeShutdown,
  nativeStep,
  nativeSurfaceReady,
  nativeSurfaceSize,
  nativeTextInput,
  nativeTogglePlaying,
  nativeWheel
} from 'libentry.so';

export const KEY_DOWN: number = 0;
export const KEY_UP: number = 1;

export const CURSOR_ARROW: number = 0;
export const CURSOR_HAND: number = 1;
export const CURSOR_IBEAM: number = 2;
export const CURSOR_GRAB: number = 3;

export const SCALE_EXACT_FIT: number = 0;
export const SCALE_NO_BORDER: number = 1;
export const SCALE_NO_SCALE: number = 2;
export const SCALE_SHOW_ALL: number = 3;

/**
 * Pointer input (touch on tablets/PC touch screens, mouse on 2in1) is delivered
 * by the XComponent's native callbacks, not through this bridge, so every
 * pointer event reaches the engine exactly once. Keyboard still crosses NAPI
 * because ArkUI owns key focus.
 */
export class RuffleEngine {
  static init(filesDir: string): boolean {
    return nativeInit(filesDir) === 0;
  }

  static isReady(): boolean {
    return nativeReady() === 1;
  }

  /**
   * The native engine only lives between surface creation and destruction;
   * loading or driving it outside that window is rejected.
   */
  static hasSurface(): boolean {
    return nativeSurfaceReady() === 1;
  }

  static hasMovie(): boolean {
    return nativeHasMovie() === 1;
  }

  static isPlaying(): boolean {
    return nativeIsPlaying() === 1;
  }

  static movieWidth(): number {
    return nativeMovieWidth();
  }

  static movieHeight(): number {
    return nativeMovieHeight();
  }

  static lastError(): string {
    return nativeLastError();
  }

  /** Pops one `name\tpayload` request queued by the player, or ''. */
  static pollEvent(): string {
    return nativePollEvent();
  }

  static textInput(text: string): number {
    return nativeTextInput(text);
  }

  static setFullscreen(isFull: boolean): number {
    return nativeSetFullscreen(isFull ? 1 : 0);
  }

  /** Answers a queued file-picker request; '' means canceled. */
  static dialogResult(id: number, paths: string): number {
    return nativeDialogResult(id, paths);
  }

  /** Answers a queued POST request; `status` 0 reports a network error. */
  static httpResult(id: number, status: number, contentType: string, body: string): number {
    return nativeHttpResult(id, status, contentType, body);
  }

  /** Reports the XComponent size in pixels so the player can scale the stage. */
  static surfaceSize(width: number, height: number): number {
    return nativeSurfaceSize(Math.round(width), Math.round(height));
  }

  static loadSwf(path: string): number {
    return nativeLoadSwf(path);
  }

  /** Streams a root movie over HTTP(S); relative assets resolve against it. */
  static loadUrl(url: string): number {
    return nativeLoadUrl(url);
  }

  static setPlaying(playing: boolean): number {
    return nativeSetPlaying(playing ? 1 : 0);
  }

  static togglePlaying(): number {
    return nativeTogglePlaying();
  }

  /** `delta` is the vertical axis value in vp; positive scrolls up. */
  static wheel(delta: number): number {
    return nativeWheel(delta);
  }

  static focus(focused: boolean): number {
    return nativeFocus(focused ? 1 : 0);
  }

  static setVolume(volume: number): number {
    return nativeSetVolume(volume);
  }

  static setQuality(index: number): number {
    return nativeSetQuality(index);
  }

  static setScaleMode(mode: number, forced: boolean): number {
    return nativeSetScaleMode(mode, forced ? 1 : 0);
  }

  static setLetterbox(enabled: boolean): number {
    return nativeSetLetterbox(enabled ? 1 : 0);
  }

  /** Advances a single frame while suspended. */
  static step(): number {
    return nativeStep();
  }

  static reload(): number {
    return nativeReload();
  }

  /**
   * Asks the engine to read back a scaled frame of the current movie on its
   * next render. The RGBA data arrives as a `thumb_png\t<name>\t<w>\t<h>\t<base64>`
   * event, keyed by the same `name`.
   */
  static requestThumbnail(name: string): number {
    return nativeRequestThumbnail(name);
  }

  /**
   * Scans a SWF file on disk for the largest embedded bitmap (JPEG or
   * lossless) and queues it as a `thumb_png\t<name>\t<w>\t<h>\t<base64>`
   * event; `thumb_failed\t<name>` when the file has no usable image. Runs on
   * a worker thread inside the engine, so a big file never blocks playback.
   */
  static extractThumbnail(name: string, path: string): number {
    return nativeExtractThumbnail(name, path);
  }

  static key(action: number, keyCode: number): number {
    return nativeKey(action, keyCode);
  }

  static shutdown(): number {
    return nativeShutdown();
  }
}
