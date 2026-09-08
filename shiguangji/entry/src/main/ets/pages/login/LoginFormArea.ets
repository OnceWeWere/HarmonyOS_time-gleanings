// ====================== LoginFormArea（可滑动表单 + 链接 + 登录按钮） ======================
// 调用方：LoginFormArea({ phone: this.phone!!, password: this.password!!, ... })
import { AppTheme } from '../theme/AppTheme'

@ComponentV2
export struct LoginFormArea {
  // ===== 入参：双向输入（V2 用 @Param + @Event $xxx + 父组件 !! 语法糖） =====
  @Param @Require phone: string
  @Param @Require password: string
  @Param @Require email: string
  @Param @Require phoneCode: string
  @Event $phone: (val: string) => void = (val: string) => {}
  @Event $password: (val: string) => void = (val: string) => {}
  @Event $email: (val: string) => void = (val: string) => {}
  @Event $phoneCode: (val: string) => void = (val: string) => {}

  // ===== 入参：父→子单向（父组件决定，子组件不能改） =====
  @Param @Require loginType: number
  @Param @Require phoneMode: number
  @Param @Require countdown: number
  @Param @Require canSubmit: boolean

  // ===== 业务事件（向上抛） =====
  @Event onPhoneModeChange: (value: number) => void = (value: number) => {}
  @Event onSendCode: () => void = () => {}
//   ┌─────────────────────────────────────────────────────────────┐
//   │  箭头函数写法：                                              │
//   │  onSendCode: () => void = () => {}                          │
//   │               ─────────   ──────                             │
//   │                  类型        值                               │
//   │                                                             │
//   ├─────────────────────────────────────────────────────────────┤
//   │  function 等价写法：                                         │
//   │  onSendCode: OnSendCodeHandler = function() {}              │
//   │               ───────────────   ────────────                 │
//   │                    类型              值                      │
//   │                                                             │
//   │  其中：                                                      │
//   │  interface OnSendCodeHandler {                               │
//   │    (): void                                                  │
//   │  }                                                           │
// │                                                             │
// └─────────────────────────────────────────────────────────────┘
  @Event onSubmit: () => void = () => {}


  get codeBtnText(): string {
    if (this.countdown > 0) {
      return `${this.countdown}s 后重试`
    }
    return '获取验证码'
  }

  // ===== 按钮文案（仅依赖本组件入参，父组件不需要） =====
  get submitBtnText(): string {
    if (this.loginType === 1) {
      return '登录 / 注册'
    }
    if (this.phoneMode === 0) {
      return '登录'
    } else if (this.phoneMode === 1) {
      return '注册'
    } else {
      return '重置密码'
    }
  }

  // ====================== 手机表单 ======================
  @Builder
  PhoneFormBuilder() {
    Column({ space: 18 }) {
      // 手机号输入
      Row({ space: 12 }) {
        Image($r('app.media.login_user'))
          .width(22)
          .height(22)
          .fillColor(AppTheme.primary)

        TextInput({ placeholder: '输入手机号码', text: this.phone })
          .maxLength(11)
          .type(InputType.PhoneNumber)
          .placeholderColor(AppTheme.textTertiary)
          .fontSize(15)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.$phone(value)
          })
      }
      .width('100%')
      .height(58)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppTheme.surfaceMuted)
      .borderRadius(14)


      // 验证码(注册/忘记密码 显示)
      if (this.phoneMode !== 0) {
        Row({ space: 12 }) {
          Row({ space: 12 }) {
            Image($r('app.media.login_PhoneCode'))
              .width(22)
              .height(22)
              .fillColor(AppTheme.primary)

            TextInput({ placeholder: '验证码', text: this.phoneCode })
              .type(InputType.Number)
              .maxLength(4)
              .placeholderColor(AppTheme.textTertiary)
              .fontSize(15)
              .height(50)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => {
                this.$phoneCode(value)
              })
          }
          .layoutWeight(1)
          .height(58)
          .padding({ left: 16, right: 8 })
          .backgroundColor(AppTheme.surfaceMuted)
          .borderRadius(14)

          Button(this.codeBtnText)
            .fontSize(13)
            .fontColor(this.countdown > 0 ? AppTheme.textTertiary : AppTheme.accent)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(AppTheme.surfaceWarm)
            .borderRadius(10)
            .height(42)
            .width(112)
            .enabled(this.countdown === 0)
            .onClick(() => {
              this.onSendCode()
            })
        }
        .width('100%')
      }

      // 密码输入
      Row({ space: 12 }) {
        Image($r('app.media.login_password'))
          .width(22)
          .height(22)
          .fillColor(AppTheme.primary)

        TextInput({
          placeholder: this.phoneMode === 2 ? '请输入新密码' : '请输入密码',
          text: this.password,
        })
          .type(InputType.Password)
          .maxLength(6)
          .placeholderColor(AppTheme.textTertiary)
          .fontSize(15)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.$password(value)
          })
      }
      .width('100%')
      .height(58)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppTheme.surfaceMuted)
      .borderRadius(14)
    }
    .width('100%')
  }

  // ====================== 邮箱登录表单 ======================
  @Builder
  EmailLoginFormBuilder() {
    Column({ space: 18 }) {
      // 邮箱输入
      Row({ space: 12 }) {
        Image($r('app.media.login_user'))
          .width(22)
          .height(22)
          .fillColor(AppTheme.primary)

        TextInput({ placeholder: '输入邮箱', text: this.email })
          .type(InputType.Email)
          .placeholderColor(AppTheme.textTertiary)
          .fontSize(15)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.$email(value)
          })
      }
      .width('100%')
      .height(58)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppTheme.surfaceMuted)
      .borderRadius(14)

      // 密码输入
      Row({ space: 12 }) {
        Image($r('app.media.login_password'))
          .width(22)
          .height(22)
          .fillColor(AppTheme.primary)

        TextInput({ placeholder: '请输入密码', text: this.password })
          .placeholderColor(AppTheme.textTertiary)
          .fontSize(15)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .type(InputType.Password)
          .onChange((value: string) => {
            this.$password(value)
          })
      }
      .width('100%')
      .height(58)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppTheme.surfaceMuted)
      .borderRadius(14)
    }
    .width('100%')
  }

  // ====================== 手机模式链接行 ======================
  @Builder
  PhoneModeLinksBuilder() {
    Row() {
      Text('注册账号')
        .fontSize(13)
        .fontColor(this.phoneMode === 1 ? AppTheme.accent : AppTheme.textSecondary)
        .fontWeight(this.phoneMode === 1 ? FontWeight.Medium : FontWeight.Normal)
        .onClick(() => {
          if (this.phoneMode !== 1) {
            this.onPhoneModeChange(1)
          }
        })

      Text('忘记密码')
        .fontSize(13)
        .fontColor(this.phoneMode === 2 ? AppTheme.accent : AppTheme.textSecondary)
        .fontWeight(this.phoneMode === 2 ? FontWeight.Medium : FontWeight.Normal)
        .margin({ left: 24 })
        .onClick(() => {
          if (this.phoneMode !== 2) {
            this.onPhoneModeChange(2)
          }
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  // ====================== 子片段：登录按钮 ======================
  @Builder
  LoginSubmitButtonBuilder() {
    Button(this.submitBtnText, { type: ButtonType.Capsule })
      .width('100%')
      .height(52)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.canSubmit ? AppTheme.surface : AppTheme.textTertiary)
      .backgroundColor(this.canSubmit ? AppTheme.accent : AppTheme.disabled)
      .onClick(() => {
        this.onSubmit()
      })
  }

  build() {
    Column({ space: 24 }) {
      // 可滑动登录表单
      Stack({ alignContent: Alignment.Start }) {
        // 默认手机表单
        Column({ space: 12 }) {
          this.PhoneFormBuilder()
        }
        .width('100%')
        .translate({ x: this.loginType === 0 ? '0%' : '-100%' })
        .visibility(this.loginType === 0 ? Visibility.Visible : Visibility.Hidden)
        .animation({ duration: 280, curve: Curve.EaseOut })

        // 邮箱登录表单
        Column({ space: 12 }) {
          this.EmailLoginFormBuilder()
        }
        .width('100%')
        .translate({ x: this.loginType === 1 ? '0%' : '100%' })
        .visibility(this.loginType === 1 ? Visibility.Visible : Visibility.Hidden)
        .animation({ duration: 280, curve: Curve.EaseOut })
      }
      .width('100%')
      .clip(true)

      // 链接行 + 登录按钮
      Column({ space: 24 }) {
        // 手机模式才显示「注册账号 / 忘记密码」链接
        if (this.loginType === 0) {
          this.PhoneModeLinksBuilder()
        }

        // 登录按钮
        this.LoginSubmitButtonBuilder()
      }
      .width('100%')
    }
    .width('100%')
  }
}
