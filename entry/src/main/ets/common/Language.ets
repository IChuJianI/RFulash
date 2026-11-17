import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { i18n } from '@kit.LocalizationKit';

export const LANG_SYSTEM = 0;
export const LANG_ZH_HANS = 1;
export const LANG_ZH_HANT = 2;
export const LANG_RU = 3;
export const LANG_EN = 4;
export const LANG_JA = 5;
export const LANG_KO = 6;

const SETTINGS_STORE = 'player_settings';
const LANGUAGE_KEY = 'languageIndex';

export function normalizeLanguageIndex(value: number): number {
  const index = Math.floor(value);
  if (index >= LANG_SYSTEM && index <= LANG_KO) {
    return index;
  }
  return LANG_SYSTEM;
}

/** Current device language, resolved down to the tags this app ships. */
export function resolveSystemTag(): string {
  try {
    const language = i18n.System.getSystemLanguage();
    if (language.length === 0) {
      return 'default';
    }
    if (language.startsWith('zh')) {
      let traditional = language.indexOf('Hant') >= 0 || language.indexOf('hant') >= 0 ||
        language.indexOf('TW') >= 0 || language.indexOf('HK') >= 0 || language.indexOf('MO') >= 0;
      if (!traditional) {
        const region = i18n.System.getSystemRegion();
        traditional = region === 'TW' || region === 'HK' || region === 'MO';
      }
      return traditional ? 'zh-Hant' : 'zh-Hans';
    }
    if (language.startsWith('ru')) {
      return 'ru-RU';
    }
    if (language.startsWith('ja')) {
      return 'ja-JP';
    }
    if (language.startsWith('ko')) {
      return 'ko-KR';
    }
    if (language.startsWith('en')) {
      return 'en-US';
    }
    return language;
  } catch (error) {
    return 'default';
  }
}

function concreteTag(index: number): string {
  if (index === LANG_ZH_HANS) {
    return 'zh-Hans';
  }
  if (index === LANG_ZH_HANT) {
    return 'zh-Hant';
  }
  if (index === LANG_RU) {
    return 'ru-RU';
  }
  if (index === LANG_EN) {
    return 'en-US';
  }
  if (index === LANG_JA) {
    return 'ja-JP';
  }
  if (index === LANG_KO) {
    return 'ko-KR';
  }
  return 'default';
}

/** Follow-system keeps the app preference at "same as system"; it only takes effect on cold start. */
export function preferredTagAtLaunch(index: number): string {
  if (normalizeLanguageIndex(index) === LANG_SYSTEM) {
    return 'default';
  }
  return concreteTag(normalizeLanguageIndex(index));
}

/** Tag for an immediate runtime switch; follow-system resolves the device language itself. */
export function runtimeTag(index: number): string {
  if (normalizeLanguageIndex(index) === LANG_SYSTEM) {
    const resolved = resolveSystemTag();
    return resolved === 'default' ? 'en-US' : resolved;
  }
  return concreteTag(normalizeLanguageIndex(index));
}

export function loadLanguageIndex(context: common.Context): number {
  try {
    const options: preferences.Options = { name: SETTINGS_STORE };
    const store = preferences.getPreferencesSync(context, options);
    const value = store.getSync(LANGUAGE_KEY, LANG_SYSTEM);
    if (typeof value === 'number') {
      return normalizeLanguageIndex(value);
    }
  } catch (error) {
  }
  return LANG_SYSTEM;
}

/** Cold start: decide which resource set loadContent should use. */
export function applyLanguageAtLaunch(index: number): void {
  try {
    i18n.System.setAppPreferredLanguage(preferredTagAtLaunch(index));
  } catch (error) {
  }
}

/** Runtime switch: re-resolves $r resources immediately, no restart. */
export function applyLanguageNow(context: common.Context, index: number): void {
  try {
    context.getApplicationContext().setLanguage(runtimeTag(index));
  } catch (error) {
  }
}

export function sameLanguage(current: string, resolved: string): boolean {
  const left = current.toLowerCase();
  const right = resolved.toLowerCase();
  if (right === 'zh-hans' || right === 'zh-hant') {
    return left === right;
  }
  return left.substring(0, 2) === right.substring(0, 2);
}
