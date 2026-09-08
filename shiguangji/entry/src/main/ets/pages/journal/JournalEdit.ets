// 引入 AppStorageV2，用来读取全局状态。
import { AppStorageV2 } from '@kit.ArkUI'
// 引入全局状态，主要用来获取顶部和底部安全区高度。
import { GlobalState } from '../../entryability/EntryAbility'
// 引入日记数据模型和日记仓库。
import { JournalItem, JournalStore } from '../model/JournalModel'
// 引入接口服务，用来把编辑后的日记保存到后端。
import { ApiService } from '../api/ApiService'
// 引入统一主题颜色。
import { AppTheme } from '../theme/AppTheme'
// 引入 Toast 工具类。
import { UiUtil } from '../utils/UiUtil'

// 声明这是一个 V2 组件。
@ComponentV2
// JournalEdit 是日记编辑页。
export struct JournalEdit {
  // 消费父组件提供的 Navigation 路由栈，用来返回上一页。
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 消费父组件提供的日记仓库，用来读取和更新当前日记。
  @Consumer('journalStore') journalStore: JournalStore = new JournalStore()
  // 连接全局状态，用来处理状态栏和底部安全区。
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // title 保存编辑页标题输入框的内容。
  @Local title: string = ''
  // summary 保存编辑页正文输入框的内容。
  @Local summary: string = ''

  // aboutToAppear 会在页面显示前执行，适合初始化页面数据。
  aboutToAppear(): void {
    // 从仓库里取出当前正在编辑的日记。
    let item = this.journalStore.getActiveJournal()
    // 如果没有取到日记，就直接结束，避免空对象报错。
    if (!item) {
      // 结束当前方法。
      return
    }
    // 把旧标题填入标题输入框。
    this.title = item.title
    // 把旧正文填入正文输入框。
    this.summary = item.summary
  }

  // build 是编辑页的主 UI。
  build() {
    // NavDestination 表示这是 Navigation 路由里的一个目标页面。
    NavDestination() {
      // Column 纵向排列标题栏和内容区域。
      Column() {
        // 渲染顶部标题栏。
        this.TitleBarBuilder()
        // 渲染中间编辑内容。
        this.ContentBuilder()
      }
      // 页面宽度铺满。
      .width('100%')
      // 页面高度铺满。
      .height('100%')
      // 页面背景使用白色。
      .backgroundColor(AppTheme.surface)
      // 给系统状态栏和底部安全区留出空间。
      .padding({
        // 顶部安全区高度从全局状态读取，并从 px 转成 vp。
        top: this.getUIContext().px2vp(this.globalState.topRectHeight),
        // 底部安全区高度从全局状态读取，并从 px 转成 vp。
        bottom: this.getUIContext().px2vp(this.globalState.bottomRectHeight)
      })
    }
    // 隐藏系统默认标题栏，因为这里使用自定义标题栏。
    .hideTitleBar(true)
  }

  // TitleBarBuilder 用来绘制顶部标题栏。
  @Builder
  TitleBarBuilder() {
    // Row 横向排列返回按钮、标题、保存按钮。
    Row({ space: 12 }) {
      // 返回按钮点击区域。
      Column() {
        // 系统返回箭头图标。
        SymbolGlyph($r('sys.symbol.chevron_left'))
          // 图标字号。
          .fontSize(24)
          // 图标颜色。
          .fontColor([AppTheme.textPrimary])
      }
      // 返回按钮点击区域宽度。
      .width(44)
      // 返回按钮点击区域高度。
      .height(56)
      // 让返回图标垂直居中。
      .justifyContent(FlexAlign.Center)
      // 点击返回按钮时执行。
      .onClick(() => {
        // 返回上一页。
        this.pageStack.pop()
      })

      // 标题栏中间文字。
      Text('编辑')
        // 占据左右按钮之间的剩余空间。
        .layoutWeight(1)
        // 标题字号。
        .fontSize(18)
        // 标题字重。
        .fontWeight(FontWeight.Medium)
        // 标题颜色。
        .fontColor(AppTheme.textPrimary)

      // 保存按钮点击区域。
      Column() {
        // 系统确认图标。
        SymbolGlyph($r('sys.symbol.checkmark'))
          // 图标字号。
          .fontSize(24)
          // 图标颜色使用强调色。
          .fontColor([AppTheme.accent])
      }
      // 保存按钮点击区域宽度。
      .width(44)
      // 保存按钮点击区域高度。
      .height(56)
      // 让保存图标垂直居中。
      .justifyContent(FlexAlign.Center)
      // 点击保存按钮时执行。
      .onClick(() => {
        // 保存编辑后的日记。
        this.saveEdit()
      })
    }
    // 标题栏宽度铺满。
    .width('100%')
    // 标题栏高度固定为 56。
    .height(56)
    // 标题栏左右留白。
    .padding({ left: 2, right: 8 })
    // 标题栏底部细分割线。
    .border({
      // 只设置底部边框宽度。
      width: { bottom: 0.5 },
      // 只设置底部边框颜色。
      color: { bottom: AppTheme.border }
    })
  }

  // ContentBuilder 用来绘制标题输入框和正文输入框。
  @Builder
  ContentBuilder() {
    // Column 纵向排列标题输入框和正文输入框。
    Column({ space: 16 }) {
      // 标题输入框。
      TextInput({
        // 没有标题时显示的占位文字。
        placeholder: '可输入标题',
        // 输入框内容绑定到 title。
        text: this.title
      })
        // 标题输入框宽度铺满。
        .width('100%')
        // 标题输入框高度。
        .height(52)
        // 标题输入字号。
        .fontSize(20)
        // 标题输入字重。
        .fontWeight(FontWeight.Medium)
        // 标题输入文字颜色。
        .fontColor(AppTheme.textPrimary)
        // 占位文字颜色。
        .placeholderColor(AppTheme.textTertiary)
        // 输入框背景透明。
        .backgroundColor(Color.Transparent)
        // 去掉输入框左右默认内边距。
        .padding({ left: 0, right: 0 })
        // 标题变化时执行。
        .onChange((value: string) => {
          // 把最新输入内容保存到 title。
          this.title = value
        })

      // 正文输入框。
      TextArea({
        // 没有正文时显示的占位文字。
        placeholder: '写下这一刻',
        // 输入框内容绑定到 summary。
        text: this.summary
      })
        // 正文输入框宽度铺满。
        .width('100%')
        // 正文输入框占据剩余高度。
        .layoutWeight(1)
        // 正文字号。
        .fontSize(16)
        // 正文颜色。
        .fontColor(AppTheme.textSecondary)
        // 占位文字颜色。
        .placeholderColor(AppTheme.textTertiary)
        // 正文行高。
        .lineHeight(27)
        // 输入框背景透明。
        .backgroundColor(Color.Transparent)
        // 正文输入框内边距。
        .padding({ left: 0, right: 0, top: 8, bottom: 8 })
        // 正文变化时执行。
        .onChange((value: string) => {
          // 把最新输入内容保存到 summary。
          this.summary = value
        })
    }
    // 内容区域宽度铺满。
    .width('100%')
    // 内容区域占据标题栏下面的剩余空间。
    .layoutWeight(1)
    // 内容区域内边距。
    .padding({ left: 22, right: 22, top: 12, bottom: 12 })
  }

  // saveEdit 用来保存编辑后的日记。
  private async saveEdit() {
    // 先从仓库里取出原来的日记。
    let oldItem = this.journalStore.getActiveJournal()
    // 如果原日记不存在，说明页面状态异常，直接返回上一页。
    if (!oldItem) {
      // 返回上一页。
      this.pageStack.pop()
      // 结束保存流程。
      return
    }

    // 去掉标题前后的空格。
    let newTitle = this.title.trim()
    // 创建一条新的 JournalItem，用新内容覆盖旧内容。
    let item = new JournalItem(
      // 保留原来的 id，这样后端知道要更新哪一条数据。
      oldItem.id,
      // 如果新标题不为空，就用新标题；否则继续保留旧标题。
      newTitle.length > 0 ? newTitle : oldItem.title,
      // 编辑页暂时不修改日期，所以保留旧日期。
      oldItem.date,
      // 编辑页暂时不修改时间，所以保留旧时间。
      oldItem.time,
      // 使用当前输入的正文内容。
      this.summary,
      // 编辑页暂时不修改图片，所以保留旧图片。
      oldItem.image
    )
    // try catch 用来处理接口请求失败的情况。
    try {
      // 调用后端接口更新数据库里的日记。
      let success = await ApiService.updateJournal(item)
      // 如果后端返回失败，就提示用户并停止。
      if (!success) {
        // 弹出保存失败提示。
        UiUtil.toast('保存失败')
        // 停止保存流程。
        return
      }
      // 先更新本地仓库，让详情页能马上看到新内容。
      this.journalStore.updateJournal(item)
      // 再尝试从后端重新读取最新列表，保证首页和数据库一致。
      try {
        // 获取当前用户最新的日记列表。
        let latestList = await ApiService.getJournals()
        // 保存当前编辑的日记 id，方便返回详情页时继续显示它。
        this.journalStore.setActiveJournal(item.id)
        // 用后端最新列表替换本地列表。
        this.journalStore.setJournalList(latestList)
      // 如果刷新列表失败，不影响本次保存，因为前面的更新已经成功。
      } catch (refreshError) {
        // 打印刷新失败原因，方便调试。
        console.error(`刷新日记列表失败: ${JSON.stringify(refreshError)}`)
      }
      // 保存成功后返回上一页。
      this.pageStack.pop()
    // 如果更新接口请求失败，就进入 catch。
    } catch (error) {
      // 弹出保存失败提示。
      UiUtil.toast(`保存失败: ${JSON.stringify(error)}`)
    }
  }
}
