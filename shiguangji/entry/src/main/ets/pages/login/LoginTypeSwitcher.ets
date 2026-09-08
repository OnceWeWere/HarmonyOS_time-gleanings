// 引入统一主题颜色。
import { AppTheme } from '../theme/AppTheme'

// 声明这是一个 V2 组件。
@ComponentV2
// LoginTypeSwitcher 是登录方式切换条，负责在“手机”和“邮箱”之间切换。
export struct LoginTypeSwitcher {
  // loginType 由父组件传入，0 表示手机，1 表示邮箱。
  @Param @Require loginType: number
  // onChange 是回调事件，子组件点击后通知父组件修改 loginType。
  @Event onChange: (value: number) => void = (value: number) => {}

  // build 是当前组件的 UI。
  build() {
    // Stack 用来把背景、滑块、文字按钮叠在一起。
    Stack({ alignContent: Alignment.Start }) {
      // 第一层：整个切换条的浅色背景。
      Row() {}
      // 背景宽度铺满切换条。
      .width('100%')
      // 背景高度固定为 44。
      .height(44)
      // 背景使用主色的浅色版本。
      .backgroundColor(AppTheme.primarySoft)
      // 圆角让切换条更柔和。
      .borderRadius(12)

      // 第二层：白色滑块，表示当前选中的登录方式。
      Row() {}
      // 滑块宽度为一半，因为一共有两个选项。
      .width('50%')
      // 滑块高度和背景一样。
      .height(44)
      // 滑块使用白色背景。
      .backgroundColor(AppTheme.surface)
      // 滑块圆角和外层一致。
      .borderRadius(12)
      // 滑块阴影，让选中状态更明显。
      .shadow({
        // 阴影颜色。
        color: AppTheme.shadow,
        // 阴影模糊半径。
        radius: 6,
        // 阴影水平偏移。
        offsetX: 0,
        // 阴影垂直偏移。
        offsetY: 2
      })
      // loginType 为 0 时滑块在左边，为 1 时移动到右边。
      .translate({ x: this.loginType === 0 ? '0%' : '100%' })

      // 第三层：真正可以点击的“手机 / 邮箱”文字。
      Row() {
        // 手机选项点击区域。
        Column() {
          // 手机选项文字。
          Text('手机')
            // 文字字号。
            .fontSize(15)
            // 选中时用主文字色，未选中时用次级文字色。
            .fontColor(this.loginType === 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
            // 选中时加粗，未选中时正常字重。
            .fontWeight(this.loginType === 0 ? FontWeight.Bold : FontWeight.Normal)
        }
        // 手机选项占一半空间。
        .layoutWeight(1)
        // 点击区域高度铺满切换条。
        .height('100%')
        // 文字垂直居中。
        .justifyContent(FlexAlign.Center)
        // 点击手机选项时执行。
        .onClick(() => {
          // 如果当前不是手机模式，才需要切换。
          if (this.loginType !== 0) {
            // animateTo 让切换过程有动画。
            animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
              // 通知父组件切换到手机模式。
              this.onChange(0)
            })
          }
        })

        // 邮箱选项点击区域。
        Column() {
          // 邮箱选项文字。
          Text('邮箱')
            // 文字字号。
            .fontSize(15)
            // 选中时用主文字色，未选中时用次级文字色。
            .fontColor(this.loginType === 1 ? AppTheme.textPrimary : AppTheme.textSecondary)
            // 选中时加粗，未选中时正常字重。
            .fontWeight(this.loginType === 1 ? FontWeight.Bold : FontWeight.Normal)
        }
        // 邮箱选项占一半空间。
        .layoutWeight(1)
        // 点击区域高度铺满切换条。
        .height('100%')
        // 文字垂直居中。
        .justifyContent(FlexAlign.Center)
        // 点击邮箱选项时执行。
        .onClick(() => {
          // 如果当前不是邮箱模式，才需要切换。
          if (this.loginType !== 1) {
            // animateTo 让切换过程有动画。
            animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
              // 通知父组件切换到邮箱模式。
              this.onChange(1)
            })
          }
        })
      }
      // 文字层宽度铺满切换条。
      .width('100%')
      // 文字层高度固定为 44。
      .height(44)
    }
    // 整个切换条占父容器 80% 宽度。
    .width('80%')
    // 整个切换条高度固定为 44。
    .height(44)
    // 顶部留白，让切换条和标题区域拉开距离。
    .margin({ top: 36 })
  }
}
