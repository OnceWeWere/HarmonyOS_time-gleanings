// 引入 ArkUI 的 promptAction，用来弹出 Toast 提示。
import { promptAction } from '@kit.ArkUI'

// UiUtil 用来放一些页面里常用的小工具方法。
export class UiUtil {
  // toast 用来显示一条短提示文字。
  static toast(message: string): void {
    // try catch 可以避免 Toast 调用失败时影响页面其它逻辑。
    try {
      // showToast 是系统提供的轻提示方法。
      promptAction.showToast({ message: message })
    // 如果 Toast 调用失败，就进入 catch。
    } catch (error) {
      // 把错误打印出来，方便调试时查看原因。
      console.error(`Toast 失败: ${JSON.stringify(error)}`)
    }
  }
}
