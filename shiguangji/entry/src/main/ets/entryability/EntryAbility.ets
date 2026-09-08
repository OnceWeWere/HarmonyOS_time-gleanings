import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppStorageV2 } from '@kit.ArkUI'

const DOMAIN = 0x0000;

// 定义可观察的数据类
// AppStorageV2 是专为 @ComponentV2 设计的全局状态存储。
@ObservedV2
export class GlobalState {
  @Trace topRectHeight: number = 0
  @Trace bottomRectHeight: number = 0
}


export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/login/login', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      let windowClass: window.Window = windowStage.getMainWindowSync(); // 获取应用主窗口
      let isLayoutFullScreen = true;

      windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(()=>{
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err:BusinessError)=>{
        console.error(`Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
      })

      // 获取布局避让遮挡的区域
      let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; // 此处以导航条避让为例
      let avoidArea = windowClass.getWindowAvoidArea(type);
      let bottomRectHeight = avoidArea.bottomRect.height; // 获取到导航区域的高度
      AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight); // 全局状态存储

      type = window.AvoidAreaType.TYPE_SYSTEM; // 以状态栏避让为例
      avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height; // 获取状态栏区域高度
      AppStorage.setOrCreate('topRectHeight', topRectHeight);
      console.info(`导航区域的高度：${bottomRectHeight} 状态栏区域高度：${topRectHeight}`)

      // 通过 AppStorageV2.connect 方法创建或获取一个应用级别的全局状态对象。
      let globalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
      // 设置值
      globalState.bottomRectHeight = bottomRectHeight
      globalState.topRectHeight = topRectHeight
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
