// 引入全局状态，主要读取顶部和底部安全区高度。
import { GlobalState } from '../../entryability/EntryAbility'
// 引入日记数据模型和日记数据仓库。
import { JournalItem, JournalStore } from '../model/JournalModel'
// 引入 AppStorageV2，用来连接全局状态。
import { AppStorageV2 } from '@kit.ArkUI'
// 引入系统剪切板，用来实现复制文本。
import pasteboard from '@ohos.pasteboard'
// 引入接口服务，用来删除数据库里的日记。
import { ApiService } from '../api/ApiService'
import { AppTheme } from '../theme/AppTheme'
import { UiUtil } from '../utils/UiUtil'

@ComponentV2
// 导出日记详情页面组件。
export struct JournalDetail {
  // 消费父级提供的 Navigation 路由栈，用来返回上一页。
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 消费父级提供的日记仓库，用来查找当前详情数据。
  @Consumer('journalStore') journalStore: JournalStore = new JournalStore()
  // 连接全局状态，用来处理安全区。
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // 是否显示图片预览层。
  @Local previewVisible: boolean = false
  // 当前正在预览的图片地址。
  @Local previewImage?: ResourceStr = undefined

  // 打开图片预览。
  private openImagePreview(image?: ResourceStr): void {
    if (!image) {
      return
    }
    this.previewImage = image
    this.previewVisible = true
  }

  // 关闭图片预览。
  private closeImagePreview(): void {
    this.previewVisible = false
    this.previewImage = undefined
  }

  // 把当前日记内容复制到系统剪切板。
  private copyJournalText(): void {
    // 先取到当前日记。
    let item = this.journalStore.getActiveJournal()
    // 如果没有日记，就不执行复制。
    if (!item) {
      return
    }
    // 拼出要复制的纯文本。
    let text = `${item.title}\n${item.date} ${item.time}\n${item.summary}`
    try {
      // 创建文本剪切板数据。
      let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
      // 写入系统剪切板。
      pasteboard.getSystemPasteboard().setData(pasteData)
      UiUtil.toast('复制成功')
    } catch (error) {
      // 复制失败时先简单打印，后面可以换成 Toast 提示。
      // console.error(`复制失败: ${JSON.stringify(error)}`)
      UiUtil.toast(`复制失败: ${JSON.stringify(error)}`)
    }
  }

  // 删除当前日记：先删数据库，成功后再删本地列表。
  private async deleteJournal() {
    // 先取到当前日记。
    let item = this.journalStore.getActiveJournal()
    // 如果没有日记，就不继续。
    if (!item) {
      return
    }

    try {
      // 调用后端删除接口。
      let success = await ApiService.deleteJournal(item.id)
      // 后端返回失败时给一个简单提示。
      if (!success) {
        UiUtil.toast('删除失败')
        return
      }
      // 从本地列表中移除这条日记，首页会立刻少一条。
      this.journalStore.removeJournal(item.id)
      UiUtil.toast(`删除成功`)
      // 删除后返回首页。
      this.pageStack.pop()

    } catch (error) {
      // 网络或接口异常时提示用户。
      UiUtil.toast(`删除失败: ${JSON.stringify(error)}`)
    }
  }

  build() {
    NavDestination() {
      // Stack 用来叠放正文和图片预览层。
      Stack({ alignContent: Alignment.TopStart }) {
        // 纵向布局：顶部标题栏 + 内容区域。
        Column() {
          // 自定义顶部标题栏。
          this.TitleBarBuilder()
          // 详情内容区域。
          this.ContentBuilder()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(AppTheme.surface)

        // 点击图片后显示全屏预览层。
        if (this.previewVisible && this.previewImage) {
          this.ImagePreviewBuilder()
        }
      }
    }
    .hideTitleBar(true)
    .padding({
      // 顶部安全区。
      top: this.getUIContext().px2vp(this.globalState.topRectHeight),
      // 底部安全区。
      bottom: this.getUIContext().px2vp(this.globalState.bottomRectHeight)
    })
  }

  // 顶部标题栏。
  @Builder
  TitleBarBuilder() {
    // 横向布局：左侧返回，右侧功能图标。
    Row() {
      // 返回按钮点击区域。
      Column() {
        // 返回箭头图标。
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([AppTheme.textPrimary])
      }
      .width(48)
      .height(56)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // Navigation 路由栈返回。
        this.pageStack.pop()
      })

      // 右侧功能按钮组。
      Row({ space: 20 }) {
        // 复制按钮点击区域。
        Column() {
          SymbolGlyph($r('sys.symbol.checkmark_square_on_square'))
            .fontSize(24)
            .fontColor([AppTheme.textPrimary])
        }
        .width(28)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          // 执行复制。
          this.copyJournalText()
        })

        // 编辑按钮点击区域。
        Column() {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(24)
            .fontColor([AppTheme.textPrimary])
        }
        .width(28)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          // 使用 Navigation 路由栈进入编辑页。
          this.pageStack.pushPath({ name: 'JournalEdit' })
        })

        Column() {
          // 删除图标。
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(24)
            .fontColor([AppTheme.accent])
        }
        .width(28)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          // 点击删除当前日记。
          this.deleteJournal()
        })
      }
      // 图标组高度。
      .height(56)
    }
    // 标题栏宽度铺满。
    .width('100%')
    // 标题栏高度。
    .height(56)
    // 标题栏底部分割线。
    .border({
      // 只设置底部边框宽度。
      width: { bottom: 0.5 },
      // 只设置底部边框颜色。
      color: { bottom: AppTheme.border }
    })
    // 右侧留白。
    .padding({ right: 15 })
    // 左右两端分布。
    .justifyContent(FlexAlign.SpaceBetween)
  }

  // 图片预览层：点击遮罩或右上角按钮都可以关闭。
  @Builder
  ImagePreviewBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#CC000000')
        .onClick(() => {
          this.closeImagePreview()
        })

      if (this.previewImage) {
        Image(this.previewImage)
          .width('88%')
          .height('72%')
          .objectFit(ImageFit.Contain)
      }

      Row() {
        Blank()

        Column() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(22)
            .fontColor([AppTheme.surface])
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.closeImagePreview()
        })
      }
      .width('100%')
      .padding({
        top: this.getUIContext().px2vp(this.globalState.topRectHeight) + 8,
        left: 16,
        right: 16
      })
      .position({ x: 0, y: 0 })
    }
    .width('100%')
    .height('100%')
  }

  // 详情内容区域。
  @Builder
  ContentBuilder() {
    // 内容纵向排列，元素之间间距 14。
    Column({ space: 14 }) {
      // 如果能找到当前日记，就展示日记内容。
      if (this.journalStore.getActiveJournal()) {
        // 渲染当前日记的具体内容。
        this.JournalContentBuilder(this.journalStore.getActiveJournal()!)
      // 如果没有找到当前日记，就显示兜底提示。
      } else {
        // 兜底提示文本。
        Text('没有找到这篇日记')
          // 提示字号。
          .fontSize(16)
          // 提示颜色。
          .fontColor(AppTheme.textTertiary)
      }
    }
    // 内容区域宽度铺满。
    .width('100%')
    // 内容区域占据标题栏下面的剩余空间。
    .layoutWeight(1)
    // 内容左对齐。
    .alignItems(HorizontalAlign.Start)
    // 内容区域内边距。
    .padding({ left: 22, right: 22, top: 22 })
  }

  // 当前日记内容，单独拆出来后就不用在 UI 里反复查询当前日记。
  @Builder
  JournalContentBuilder(item: JournalItem) {
    Column({ space: 14 }) {
      // 日记标题。
      Text(item.title)
        // 标题宽度铺满。
        .width('100%')
        // 标题字号。
        .fontSize(22)
        // 标题字重。
        .fontWeight(FontWeight.Medium)
        // 标题颜色。
        .fontColor(AppTheme.textPrimary)

      // 日期时间行。
      Row({ space: 8 }) {
        // 日记日期。
        Text(item.date)
          // 日期字号。
          .fontSize(13)
          // 日期颜色。
          .fontColor(AppTheme.textTertiary)

        // 日记时间。
        Text(item.time)
          // 时间字号。
          .fontSize(13)
          // 时间颜色。
          .fontColor(AppTheme.textTertiary)
      }
      // 日期时间行宽度铺满。
      .width('100%')

      // 如果有摘要内容，就显示正文摘要。
      if (item.summary) {
        // 摘要正文。
        Text(item.summary)
          // 正文宽度铺满。
          .width('100%')
          // 正文字号。
          .fontSize(16)
          // 正文颜色。
          .fontColor(AppTheme.textSecondary)
          // 正文行高。
          .lineHeight(27)
      }

      // 如果有图片，就显示图片。
      if (item.image) {
        // 日记图片。
        Image(item.image)
          // 图片宽度。
          .width(120)
          // 图片高度。
          .height(120)
          // 图片裁剪填充。
          .objectFit(ImageFit.Cover)
          // 图片圆角。
          .borderRadius(6)
          // 点击图片打开预览层。
          .onClick(() => {
            this.openImagePreview(item.image)
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
