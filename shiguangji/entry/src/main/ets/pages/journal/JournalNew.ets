// 引入 ArkUI 里用到的应用状态、键盘避让模式、窗口对象。
import { AppStorageV2, KeyboardAvoidMode, window } from '@kit.ArkUI'
// 引入系统相册选择器，用来从本地选择图片。
import { photoAccessHelper } from '@kit.MediaLibraryKit'
// 引入全局状态，用来读取顶部安全区、底部安全区高度。
import { GlobalState } from '../../entryability/EntryAbility'
// 引入日记数据模型和日记列表仓库。
import { JournalItem, JournalStore } from '../model/JournalModel'
// 引入接口服务，用来把新日记保存到后端。
import { ApiService } from '../api/ApiService'
import { AppTheme } from '../theme/AppTheme'
import { UiUtil } from '../utils/UiUtil'


@ComponentV2
// 导出新建日记页面组件，外部路由可以使用 JournalNew() 打开它。
export struct JournalNew {
  // 标题输入框绑定的数据，用户输入标题时会更新它。
  @Local title: string = ''
  // 从 AppStorageV2 中连接全局状态，如果没有就创建一个新的 GlobalState。
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // 从父级 Navigation 中消费 pageStack，用它来返回上一页。
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 从父级页面消费 journalStore，用它把新日记添加到列表里。
  @Consumer('journalStore') journalStore: JournalStore = new JournalStore()
  // 记录键盘是否弹出，用来控制底部安全区 padding。
  @Local private isKeyboardVisible: boolean = false

  // RichEditor 的控制器，用来操作富文本编辑器，例如插入图片、读取内容、清空内容。
  private richEditorController: RichEditorController = new RichEditorController()

  // 撤回历史列表，默认放一个空字符串，代表最开始什么都没有写。
  private undoList: string[] = ['']
  // 恢复历史列表，点击撤回后，被撤回的内容会临时放到这里。
  private redoList: string[] = []
  // 是否正在通过代码恢复内容，避免恢复时触发 onDidChange 又重复记录历史。
  private isRestoring: boolean = false
  // 当前窗口对象，用来监听键盘高度变化。
  private mainWindow?: window.Window
  // 进入页面之前的键盘避让模式，离开页面时要恢复回去。
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET
  // 键盘高度变化回调，height 大于 0 说明键盘弹出来了。
  private keyboardHeightChangeCallback: Callback<number> = (height: number): void => {
    // 更新键盘显示状态，页面底部 padding 会跟着重新计算。
    this.isKeyboardVisible = height > 0
  }

  aboutToAppear(): void {
    // 先保存原来的键盘避让模式，方便离开页面时恢复。
    this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
    // 设置为 RESIZE，让键盘弹出时页面内容区域跟着缩小，底部工具栏能顶到键盘上方。
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
    // 获取当前页面所在的上下文。
    let hostContext = this.getUIContext().getHostContext()
    // 如果上下文不存在，后面的窗口监听就不能继续做。
    if (!hostContext) {
      // 直接结束初始化，避免空对象报错。
      return
    }
    // 通过上下文拿到当前应用最后一个窗口。
    window.getLastWindow(hostContext).then((windowClass: window.Window) => {
      // 保存窗口对象，离开页面时要用它取消监听。
      this.mainWindow = windowClass
      // 监听键盘高度变化。
      this.mainWindow.on('keyboardHeightChange', this.keyboardHeightChangeCallback)
    }).catch(() => {
      // 获取窗口失败时不做处理，页面主体功能仍然可以使用。
    })
  }

  // 页面即将销毁或离开时执行，适合做清理。
  aboutToDisappear(): void {
    // 恢复进入页面之前的键盘避让模式，避免影响别的页面。
    this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode)
    // 如果之前拿到了窗口对象，就取消键盘高度监听。
    if (this.mainWindow) {
      // 取消监听，防止离开页面后还继续触发回调。
      this.mainWindow.off('keyboardHeightChange', this.keyboardHeightChangeCallback)
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部自定义标题栏。
        this.TitleBarBuilder()

        // 中间区域外层，用来放编辑器并设置灰色背景。
        Column() {
          // 编辑器容器，用白色背景承载 RichEditor。
          Column() {
            // 富文本编辑器，controller 让我们可以在代码里控制它。
            RichEditor({ controller: this.richEditorController })
              // 给编辑器设置唯一 id，后面 focusControl 会通过这个 id 聚焦它。
              .id('journalRichEditor')
              .width('100%')
              .height('100%')
              .backgroundColor(Color.Transparent)
              // 允许组件获取焦点。
              .focusable(true)
              // 页面打开后默认尝试获取焦点。
              .defaultFocus(true)
              // 获取焦点时允许弹出键盘。
              .enableKeyboardOnFocus(true)
              // 光标颜色。
              .caretColor(AppTheme.textPrimary)
              // 关闭编辑器自带滚动条。
              .barState(BarState.Off)
              // 编辑器内部留白，让文字不要贴边。
              .padding({ left: 18, right: 18, top: 18, bottom: 18 })
              .onReady(() => {
                // 设置后续输入文字的默认样式。
                this.richEditorController.setTypingStyle({
                  // 默认字号。
                  fontSize: 18,
                  // 默认文字颜色。
                  fontColor: AppTheme.textPrimary,
                  // 默认字重。
                  fontWeight: FontWeight.Regular
                })
                // 主动让编辑器获取焦点，进入页面后可以直接输入正文。
                focusControl.requestFocus('journalRichEditor')
              })
              // 编辑器内容变化后执行，用来记录撤回历史。
              .onDidChange(() => {
                // 保存当前文本状态。
                this.recordTextHistory()
              })
          }
          .width('100%')
          .height('100%')
          .backgroundColor(AppTheme.surface)
        }
        // 中间编辑区域占据除顶部和底部外的剩余空间。
        .layoutWeight(1)
        // 中间区域宽度铺满。
        .width('100%')
        .backgroundColor(AppTheme.pageBg)
        .padding({ left: 0, right: 0, top: 14, bottom: 14 })

        // 底部富文本工具栏。
        this.RichToolbarBuilder()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.surface)
      .padding({
        // 顶部 padding 使用全局状态里的状态栏高度。
        top: this.getUIContext().px2vp(this.globalState.topRectHeight),
        // 键盘弹出时底部不再额外加安全区；键盘没弹出时保留底部安全区。
        bottom: this.isKeyboardVisible ? 0 : this.getUIContext().px2vp(this.globalState.bottomRectHeight)
      })
    }
    .hideTitleBar(true)
  }

  // 自定义顶部标题栏。
  @Builder
  TitleBarBuilder() {
    Row({ space: 12 }) {
      Column() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([AppTheme.textPrimary])
      }
      .width(44)
      .height(52)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.pageStack.pop()
      })

      TextInput({
        placeholder: '可输入标题',
        // 输入框内容绑定到 title。
        text: this.title
      })
        .layoutWeight(1)
        .height(48)
        .fontSize(18)
        // 标题字重。
        .fontWeight(FontWeight.Medium)
        // 输入文字颜色。
        .fontColor(AppTheme.textPrimary)
        // 提示文字颜色。
        .placeholderColor(AppTheme.textTertiary)
        // 输入框背景透明。
        .backgroundColor(Color.Transparent)
        .padding({ left: 0, right: 0 })
        .onChange((value: string) => {
          // 把用户输入的新标题保存到 title。
          this.title = value
        })

      // 保存按钮点击区域。
      Column() {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(24)
          .fontColor([AppTheme.accent])
      }
      .width(44)
      .height(52)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.saveJournal()
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 2, right: 8 })
    .border({
      width: { bottom: 0.5 },
      color: { bottom: AppTheme.border }
    })
  }

  // 底部富文本工具栏。
  @Builder
  RichToolbarBuilder() {
    // 横向布局：撤回、恢复、插入图片。
    Row() {
      Column({ space: 2 }) {
        SymbolGlyph($r('sys.symbol.undo'))
          .fontSize(25)
          .fontColor([AppTheme.textPrimary])
      }
      .width(76)
      .height(58)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 调用撤回方法。
        this.undoEdit()
      })

      // 恢复按钮点击区域。
      Column({ space: 2 }) {
        SymbolGlyph($r('sys.symbol.redo'))
          .fontSize(25)
          .fontColor([AppTheme.textPrimary])
      }
      .width(76)
      .height(58)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 调用恢复方法。
        this.redoEdit()
      })

      // 插入图片按钮点击区域。
      Column({ space: 4 }) {
        // 图片图标。
        SymbolGlyph($r('sys.symbol.picture'))
          // 图标大小。
          .fontSize(25)
          // 图标颜色。
          .fontColor([AppTheme.accent])
      }
      .width(76)
      .height(58)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 调用插入图片方法。
        this.insertImage()
      })
    }
    .width('100%')
    .height(58)
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(AppTheme.surface)
    .border({
      width: { top: 0.5 },
      color: { top: AppTheme.border }
    })
  }

  // 撤回：把当前内容放进 redoList，然后回到 undoList 里的上一份内容。
  private undoEdit() {
    // 如果 undoList 里只有初始空内容，就说明没有可撤回的内容。
    if (this.undoList.length <= 1) {
      // 即使不能撤回，也重新聚焦编辑器，方便用户继续输入。
      focusControl.requestFocus('journalRichEditor')
      return
    }

    // 从 undoList 尾部取出当前内容。
    let currentText = this.undoList.pop()
    // pop 可能返回 undefined，所以这里先判断。
    if (currentText !== undefined) {
      // 把当前内容放进 redoList，之后点恢复可以拿回来。
      this.redoList.push(currentText)
    }

    // undoList 尾部现在变成了上一份内容。
    let previousText = this.undoList[this.undoList.length - 1]
    // 把编辑器内容恢复到上一份内容。
    this.restoreText(previousText)
    // 恢复后重新聚焦编辑器。
    focusControl.requestFocus('journalRichEditor')
  }

  // 恢复：把 redoList 里的内容取回来，再放回 undoList。
  private redoEdit() {
    // 从 redoList 尾部取出刚才撤回掉的内容。
    let nextText = this.redoList.pop()
    // 如果 redoList 没有内容，就说明没有可恢复的内容。
    if (nextText === undefined) {
      // 重新聚焦编辑器，方便用户继续输入。
      focusControl.requestFocus('journalRichEditor')
      // 结束方法。
      return
    }

    // 把恢复出来的内容重新放回 undoList。
    this.undoList.push(nextText)
    // 把编辑器内容恢复为 nextText。
    this.restoreText(nextText)
    // 恢复后重新聚焦编辑器。
    focusControl.requestFocus('journalRichEditor')
  }

  // 插入图片：打开系统图片选择器，用户选中图片后插入到光标位置。
  private insertImage() {
    // 创建图片选择参数。
    let options = new photoAccessHelper.PhotoSelectOptions()
    // 只允许选择图片。
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
    // 只选一张
    options.maxSelectNumber = 1

    // 创建图片选择器。
    let picker = new photoAccessHelper.PhotoViewPicker()
    // 打开系统图片选择器。
    picker.select(options).then((result: photoAccessHelper.PhotoSelectResult) => {
      // 如果用户没有选择图片，就不继续。
      if (result.photoUris.length === 0) {
        return
      }

      // 获取第一张图片的 uri。
      let imageUri = result.photoUris[0]
      // 获取当前光标位置。
      let offset = this.richEditorController.getCaretOffset()
      // 把本地图片 uri 插入到 RichEditor。
      this.richEditorController.addImageSpan(imageUri, {
        // 图片插入的位置。
        offset: offset,
        // 图片样式。
        imageStyle: {
          // 图片显示尺寸。
          size: [128, 128],
          // 图片和文字的垂直对齐方式。
          verticalAlign: ImageSpanAlignment.BOTTOM,
          objectFit: ImageFit.Cover
        }
      })
      // 插入图片后也记录一次历史。
      this.recordTextHistory()
      // 插入后重新聚焦编辑器。
      focusControl.requestFocus('journalRichEditor')
    }).catch(() => {
      // 用户取消选择或系统选择失败时，不做额外处理。
      focusControl.requestFocus('journalRichEditor')
    })
  }

  // 每次内容变化时，保存一份当前文本。和上一份一样就不重复保存。
  private recordTextHistory() {
    // 如果当前是在执行 restoreText，说明是代码恢复内容，不是用户主动输入。
    if (this.isRestoring) {
      // 不记录恢复过程产生的变化。
      return
    }

    // 读取编辑器里的纯文本摘要。
    let currentText = this.getPlainTextSummary()
    // 取出 undoList 中最后一次保存的内容。
    let lastText = this.undoList[this.undoList.length - 1]
    // 如果当前内容和上一次一样，就不用重复保存。
    if (currentText === lastText) {
      // 结束方法。
      return
    }

    // 把当前内容加入撤回历史。
    this.undoList.push(currentText)
    // 用户输入了新内容后，之前的 redo 历史就失效了，所以清空。
    this.redoList = []
  }

  // 恢复内容时采用最容易理解的做法：清空编辑器，再把文本重新放进去。
  private restoreText(text: string) {
    // 标记正在恢复内容，避免触发 onDidChange 后重复记录历史。
    this.isRestoring = true
    // 清空编辑器里的所有 span，包括文字和图片。
    this.richEditorController.deleteSpans()
    // 如果要恢复的文本不是空字符串，就重新添加文本。
    if (text.length > 0) {
      // 把文本添加回 RichEditor。
      this.richEditorController.addTextSpan(text)
      // 把光标移动到文本末尾。
      this.richEditorController.setCaretOffset(text.length)
    }
    // 恢复完成，关闭恢复标记。
    this.isRestoring = false
  }

  // 保存当前日记。
  private async saveJournal() {
    // 获取当前时间，用来生成 id、日期和时间。
    let now = new Date()
    // 去掉标题前后的空格。
    let title = this.title.trim()
    // 从富文本编辑器里提取摘要文本。
    let summary = this.getPlainTextSummary()
    // 从富文本编辑器里提取第一张图片，列表页会用它显示缩略图。
    let image = this.getFirstImage()
    // 创建一条新的日记数据。
    let item: JournalItem = new JournalItem(
      // 用当前时间戳生成唯一 id。
      `journal-${now.getTime()}`,
      // 如果用户输入了标题就用用户标题，否则用日期时间作为默认标题。
      title.length > 0 ? title : this.createDefaultTitle(now),
      // 保存日期。
      this.formatDate(now),
      // 保存时间。
      this.formatTime(now),
      // 保存摘要内容。
      summary,
      // 保存第一张图片。
      image
    )

    try {
      // 如果日记里有图片，先上传到后端，拿到后端返回的图片地址。
      if (image) {
        let imageUrl = await ApiService.uploadImage(image)
        if (imageUrl.length === 0) {
          UiUtil.toast('图片上传失败')
          return
        }
        item.image = imageUrl
      }
      // 先保存到后端数据库。
      let id = await ApiService.createJournal(item)
      // 如果后端保存失败，提示用户。
      if (id.length === 0) {
        UiUtil.toast('保存失败')
        return
      }
      item.id = id
      // 后端保存成功后，再把新日记添加到本地列表里。
      this.journalStore.addJournal(item)
      // 保存完成后返回上一页。
      this.pageStack.pop()
    } catch (error) {
      // 后端没有启动或网络失败时会走到这里。
      UiUtil.toast(`保存失败: ${JSON.stringify(error)}`)
    }
  }

  // 从 RichEditor 中提取纯文本摘要，只保留文字，不把图片写成“[图片]”。
  private getPlainTextSummary(): string {
    // 先准备一个空字符串，用来拼接内容。
    let summary = ''
    // 获取编辑器里的所有 span，文字和图片都会以 span 的形式存在。
    this.richEditorController.getSpans().forEach((span: RichEditorTextSpanResult | RichEditorImageSpanResult) => {
      // 先把当前 span 当作文字 span 尝试读取。
      let textSpan = span as RichEditorTextSpanResult
      // 如果 value 存在，说明这是文字 span。
      if (textSpan.value !== undefined) {
        // 把文字追加到摘要里。
        summary += textSpan.value
        // 当前 span 处理完毕，进入下一个 span。
        return
      }
    })
    // 返回最终拼接好的摘要。
    return summary
  }

  // 从 RichEditor 中取第一张图片，给列表页和详情页显示。
  private getFirstImage(): ResourceStr | undefined {
    // 默认没有图片。
    let image: ResourceStr | undefined = undefined
    // 遍历所有 span，找到第一张图片就保存下来。
    this.richEditorController.getSpans().forEach((span: RichEditorTextSpanResult | RichEditorImageSpanResult) => {
      // 已经找到图片后，不再继续处理后面的图片。
      if (image !== undefined) {
        return
      }
      // 把当前 span 当作图片 span 尝试读取。
      let imageSpan = span as RichEditorImageSpanResult
      // valueResourceStr 存在时，说明这是一张图片。
      if (imageSpan.valueResourceStr !== undefined) {
        image = imageSpan.valueResourceStr
      }
    })
    // 返回第一张图片，没有图片时返回 undefined。
    return image
  }

  // 创建默认标题。
  private createDefaultTitle(date: Date): string {
    // 默认标题格式：日期 + 时间。
    return `${this.formatDate(date)} ${this.formatTime(date)}`
  }

  // 把 Date 格式化成 yyyy.MM.dd。
  private formatDate(date: Date): string {
    // getMonth 从 0 开始，所以月份要加 1。
    return `${date.getFullYear()}.${this.padTime(date.getMonth() + 1)}.${this.padTime(date.getDate())}`
  }

  // 把 Date 格式化成 HH:mm。
  private formatTime(date: Date): string {
    // 小时和分钟都用 padTime 补齐两位。
    return `${this.padTime(date.getHours())}:${this.padTime(date.getMinutes())}`
  }

  // 小于 10 的数字前面补 0。
  private padTime(value: number): string {
    // 例如 5 变成 05，12 保持 12。
    return value < 10 ? `0${value}` : `${value}`
  }
}
