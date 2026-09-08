import lottie from '@ohos/lottie'
import { LoginTypeSwitcher } from './LoginTypeSwitcher.ets'
import { LoginFormArea } from './LoginFormArea.ets'
import { GlobalState } from '../../entryability/EntryAbility'
import { AppStorageV2, router } from '@kit.ArkUI'
import { ApiService } from '../api/ApiService'
import { AppTheme } from '../theme/AppTheme'
import { UiUtil } from '../utils/UiUtil'

@Entry
@ComponentV2
struct Login {
  @Local phone: string = ''
  @Local password: string = ''
  @Local isAgree: boolean = false
  @Local animName: string = 'login_bg'
  @Local loginType: number = 0 // 0=手机, 1=邮箱

  // 用来配置CanvasRenderingContext2D对象的参数，包括是否开启抗锯齿，true表明开启抗锯齿。
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  // 用来创建CanvasRenderingContext2D对象，通过在canvas中调用CanvasRenderingContext2D对象来绘制。
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!

  // 手机模式：0=登录, 1=注册, 2=忘记密码
  @Local phoneMode: number = 0
  @Local phoneCode: string = ''

  // 邮箱登录字段
  @Local email: string = ''

  // 倒计时
  @Local countdown: number = 0
  private timerId: number = -1

  aboutToDisappear(): void {
    lottie.destroy(this.animName)
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // ========== Lottie 动画背景 ==========
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor(AppTheme.pageBg)
        .onReady(() => {
          lottie.loadAnimation({ // 将动画加载到内存
            container: this.context,
            renderer: 'canvas',
            loop: true,
            autoplay: true,
            name: this.animName,
            path: 'rawfile/lottie/login_bg.json'
          })
        })

      // ========== 内容层 ==========
      Column({ space: 0 }) {
        Column({ space: 12 }) {
          Stack({ alignContent: Alignment.Center }) {
            Column({ space: 12 }) {
              Text('拾光记')
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.textPrimary)
                .letterSpacing(8)

              Text('拾起时光，记录美好')
                .fontSize(13)
                .fontColor(AppTheme.textSecondary)
                .letterSpacing(2)
            }
          }
          .height(180)
          .width('100%')
        }
        .margin({ top: 0 })
        .padding({top:15})



        // 切换条区域
        LoginTypeSwitcher({
          loginType: this.loginType,
          onChange: (value: number) => {
            this.loginType = value
            // 切换登录方式时重置手机端状态
            this.phoneMode = 0
            this.phoneCode = ''
          },
        })

        // 登录表单 + 链接行 + 登录按钮
        LoginFormArea({
          phone: this.phone!!, // 语法糖 !! = 同时传 phone 和 $phone 回调
          password: this.password!!,
          email: this.email!!,
          phoneCode: this.phoneCode!!,
          loginType: this.loginType,
          phoneMode: this.phoneMode,
          countdown: this.countdown,
          canSubmit: this.canSubmit,
          onPhoneModeChange: (value: number) => {
            this.phoneMode = value
            this.phoneCode = ''
          },
          onSendCode: () => {
            this.startCountdown()
          },
          onSubmit: () => {
            this.handleSubmit()
          },
        })
          .padding({ left: 28, right: 28 })
          .margin({ top: 24 })

        Blank()

        // 其他登录方式 + 协议
        Column({ space: 24 }) {
          // 其他登录方式
          Column({ space: 16 }) {
            Row() {
              Line().width(60).height(1).backgroundColor(AppTheme.border).layoutWeight(1)
              Text('其它登录方式').fontSize(12).fontColor(AppTheme.textTertiary).margin({ left: 12, right: 12 })
              Line().width(60).height(1).backgroundColor(AppTheme.border).layoutWeight(1)
            }
            .width('100%')

            Row() {
              this.buildSocialBtn($r('app.media.login_qq'), 'QQ')
              this.buildSocialBtn($r('app.media.login_wx'), '微信')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 60, right: 60 })
          }

          // 协议
          Row({ space: 6 }) {
            /*this.xxx 和 $$this.xxx 在 V2 系统组件上的语义完全不一样。
            this.isAgree    取值：把当前状态「快照」传给组件，组件拿到的是一个普通值
            $$this.isAgree  绑定：把状态变量「活引用」传给组件，组件能反向写回*/
            Toggle({ type: ToggleType.Checkbox, isOn: $$this.isAgree })
              .selectedColor(AppTheme.accent)
              .width(16)
              .height(16)

            Text() {
              Span('我已阅读并同意').fontSize(12).fontColor(AppTheme.textSecondary)
              Span('用户条款').fontSize(12).fontColor(AppTheme.accent)
              Span('及').fontSize(12).fontColor(AppTheme.textSecondary)
              Span('隐私政策').fontSize(12).fontColor(AppTheme.accent)
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          // .margin({ top: 8, bottom: 32 })
        }
        .width('100%')
        .padding({ left: 28, right: 28 })
        .margin({ top: 28 })
      }
      .width('100%')
      .height('100%')
      .padding({
        top: this.getUIContext().px2vp(this.globalState.topRectHeight),
        bottom:this.getUIContext().px2vp(this.globalState.bottomRectHeight)
      })
    }
    .width('100%')
    .height('100%')
  }

  get canSubmit(): boolean {
    if (!this.isAgree) {
      return false
    }

    if (this.loginType === 0) {
      if (this.phoneMode === 0) { // 手机d登录
        return this.phone.length >= 11 && this.password.length >= 6
      } else if (this.phoneMode === 1) { //
        return this.phone.length >= 11 && this.phoneCode.length >= 4 && this.password.length >= 6
      } else {
        return this.phone.length >= 11 && this.phoneCode.length >= 4 && this.password.length >= 6
      }
    } else {
      // 邮箱登录
      return this.email.length >= 6 && this.password.length >= 6
    }
  }

  startCountdown() {
    if (this.countdown > 0) {
      return
    }
    this.countdown = 60
    this.timerId = setInterval(() => {
      this.countdown--
      if (this.countdown <= 0) {
        clearInterval(this.timerId)
        this.timerId = -1
      }
    }, 1000)
  }

  async handleSubmit() {
    if (!this.canSubmit) {
      UiUtil.toast('请先填写完整信息并勾选协议')
      return
    }

    if (this.loginType === 1) {
      await this.submitAccountAction(() => ApiService.login(this.email, this.password), '账号或密码错误')
      return
    }

    if (this.phoneMode === 1) {
      await this.submitAccountAction(() => ApiService.register(this.phone, '', this.password), '注册失败')
      return
    }

    if (this.phoneMode === 2) {
      UiUtil.toast('重置密码接口暂未实现')
      return
    }

    await this.submitAccountAction(() => ApiService.login(this.phone, this.password), '账号或密码错误')
  }

  private async submitAccountAction(action: () => Promise<boolean>, failMessage: string): Promise<void> {
    try {
      let success = await action()
      if (success) {
        this.goJournalPage()
      } else {
        UiUtil.toast(failMessage)
      }
    } catch (error) {
      UiUtil.toast(`请求失败: ${JSON.stringify(error)}`)
    }
  }

  private goJournalPage(): void {
    UiUtil.toast('登录成功')
    try {
      router.replaceUrl({ url: 'pages/journal/JournalIndex' })
    } catch (error) {
      UiUtil.toast(`跳转失败: ${JSON.stringify(error)}`)
    }
  }

  // ========== 社交登录按钮 ==========
  @Builder
  buildSocialBtn(icon: Resource, name: string) {
    Column({ space: 8 }) {
      Image(icon)
        .width(26)
        .height(26)
        .objectFit(ImageFit.Contain)

      Text(name)
        .fontSize(12)
        .fontColor(AppTheme.textSecondary)
    }
  }
}
