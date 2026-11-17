import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import { applyLanguageAtLaunch, LANG_SYSTEM, loadLanguageIndex, resolveSystemTag, sameLanguage } from '../common/Language';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // Must run before loadContent so the first frame already uses the chosen language.
    applyLanguageAtLaunch(loadLanguageIndex(this.context));
    this.handleIncomingWant(want);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.handleIncomingWant(want);
  }

  /**
   * Files opened from another app (file association, share sheet) arrive as a
   * Want URI. The page consumes it through AppStorage, so a warm launch
   * replaces the current movie just like a cold start.
   */
  private handleIncomingWant(want: Want): void {
    const uri = want.uri;
    if (!uri || uri.length === 0) {
      return;
    }
    if (want.action === 'ohos.want.action.home') {
      return;
    }
    hilog.info(DOMAIN, 'testTag', 'incoming uri: %{public}s', uri);
    AppStorage.setOrCreate('pendingSwfUri', uri);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      if (deviceInfo.deviceType !== '2in1') {
        // Tablets have no title bar; setWindowTitle only applies to the PC decor.
        return;
      }
      try {
        // The 2in1 title bar text should match the app name instead of the ability label.
        windowStage.getMainWindowSync().setWindowTitle('RFulash')
          .catch((error: BusinessError) => {
            hilog.error(DOMAIN, 'testTag', 'Failed to set window title. Cause: %{public}s', error.message);
          });
      } catch (error) {
        hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', (error as BusinessError).message);
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Following the system language means the device language may have changed
    // while the app was in the background.
    this.followSystemLanguage();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  private followSystemLanguage(): void {
    if (loadLanguageIndex(this.context) !== LANG_SYSTEM) {
      return;
    }
    try {
      const resolved = resolveSystemTag();
      if (resolved === 'default' || sameLanguage(i18n.System.getAppPreferredLanguage(), resolved)) {
        return;
      }
      i18n.System.setAppPreferredLanguage(resolved);
      this.context.getApplicationContext().setLanguage(resolved);
    } catch (error) {
      hilog.warn(DOMAIN, 'testTag', 'Failed to follow the system language');
    }
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}