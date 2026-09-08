// 引入 AppStorageV2，用来读取全局状态。
import { AppStorageV2 } from '@kit.ArkUI'
// 引入全局状态，主要用到顶部和底部安全区高度。
import { GlobalState } from '../../entryability/EntryAbility'
// 引入日记列表组件。
import { JournalList } from './JournalList.ets'
// 引入日记详情页组件。
import { JournalDetail } from './JournalDetail.ets'
// 引入新建日记页组件。
import { JournalNew } from './JournalNew.ets'
// 引入编辑日记页组件。
import { JournalEdit } from './JournalEdit.ets'
// 引入日记数据仓库。
import { JournalStore } from '../model/JournalModel'
// 引入接口服务，用来从后端读取日记列表。
import { ApiService } from '../api/ApiService'
import { AppTheme } from '../theme/AppTheme'

@Entry
@ComponentV2
// 日记首页组件。
struct JournalIndex {
  // 从 AppStorageV2 连接全局状态，用来拿安全区高度。
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // 创建并向子组件提供 Navigation 路由栈。
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 创建并向子组件提供日记数据仓库。
  @Provider('journalStore') journalStore: JournalStore = new JournalStore()

  @Local private time:Date = new Date();

  // 页面出现时加载后端日记列表。
  aboutToAppear(): void {
    // 调用后端接口，成功后替换本地 journalList。
    ApiService.getJournals().then((list) => {
      // 使用后端数据；没有数据时就是空列表。
      this.journalStore.setJournalList(list)
    }).catch((error: Error) => {
      // 后端没启动时打印错误。
      console.error(`加载日记列表失败: ${error.message}`)
    })
  }

  // Navigation 的路由表，根据页面名称渲染对应页面组件。
  @Builder
  PagesMap(name: string) {
    if (name === 'JournalNew') {
      // 新建日记页面。
      JournalNew()
    } else if (name === 'JournalDetail') {
      // 日记详情页面。
      JournalDetail()
    } else if (name === 'JournalEdit') {
      // 日记编辑页面。
      JournalEdit()
    }
  }

  build() {
    Navigation(this.pageStack) {
      Stack({ alignContent: Alignment.TopStart }) {
        // 首页主体内容。
        this.PageBuilder()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.pageBg)
      // 右下角悬浮写日记按钮。
      .overlay( // 组件上叠加其他内容
        // 悬浮按钮内容。
        this.WriteButtonBuilder(),
        // 按钮贴右下角对齐。
        { align: Alignment.BottomEnd }
      )
    }
    .hideTitleBar(true)
    // 绑定路由表
    .navDestination(this.PagesMap)
  }

  // 首页主体布局。
  @Builder
  PageBuilder() {
    // 外层 Stack 用来叠放顶部图片和下面列表。
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        // 顶部背景图
        Image($rawfile('Default_Journal_Background.jpg'))
          .width('100%')
          // 图片高度固定为 160。
          .height(160)
          // 图片裁剪填充，保证铺满顶部区域。
          .objectFit(ImageFit.Cover)

        // 图片上方的日期和功能按钮层。
        Column() {
          Row() {
            // 左侧日期区域。
            Row({ space: 6 }) {
              Row() {
                Text(this.time.getDate().toString().padStart(2,'0'))
                  .fontSize(25)
                  .fontColor(AppTheme.surface)
                  .fontWeight(FontWeight.Regular)
              }

              Row({ space: 0 }) {
                Text(`${this.time.getMonth().toString().padStart(2,'0')}月`)
                  .fontSize(14)
                  .fontColor(AppTheme.surface)
                  .fontWeight(FontWeight.Medium)
                  .baselineOffset(3)
              }
            }
            .alignItems(VerticalAlign.Bottom)

            // 右侧功能按钮组。
            Row({ space: 20 }) {
              SymbolGlyph($r('sys.symbol.square_grid_2x2'))
                .fontSize(20)
                .fontColor([AppTheme.surface])
                .opacity(0.9)

              SymbolGlyph($r('sys.symbol.envelope'))
                .fontSize(20)
                .fontColor([AppTheme.surface])
                .opacity(0.9)

              SymbolGlyph($r('sys.symbol.list_bullet'))
                .fontSize(22)
                .fontColor([AppTheme.surface])
                .opacity(0.9)
            }
          }
          .height(32)
          .width('92%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .height('100%')
        .padding({ top: this.getUIContext().px2vp(this.globalState.topRectHeight) + 12 })

        // 顶部图片底部的白色渐变，用来衔接下面的列表。
        Column()
          // 渐变层宽度铺满。
          .width('100%')
          // 渐变层高度。
          .height(32)
          // 从透明过渡到白色。
          .linearGradient({
            // 180 度表示从上到下。
            angle: 180,
            // 顶部透明，底部白色。
            colors: [['#00000000', 0.0], [AppTheme.pageBg, 1.0]]
          })
          // 放在顶部图底部附近。
          .position({ x: 0, y: 128 })
      }
      // 顶部区域宽度铺满。
      .width('100%')
      // 顶部区域高度。
      .height(160)
      // 顶部区域固定在页面最上方。
      .position({ x: 0, y: 0 })

      // 列表区域。
      Column() {
        // 日记时间轴列表。
        JournalList()
          // 列表占据剩余空间。
          .layoutWeight(1)

        Blank() // 空白占位

        // 底部提示文案区域
        Row() {
          Text('— 记录，每一份精彩的回忆 —')
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(11)
            .fontColor(AppTheme.textTertiary)
            .letterSpacing(2)
        }
        .width('100%')
        .padding({ top: 7 })
      }
      .width('100%')
      .height('100%')
      // 顶部留出 160，避开图片区域；底部结合安全区调整。
      .padding({ top: 160, bottom: this.getUIContext().px2vp(this.globalState.bottomRectHeight) - 13 })
    }
  }

  // 右下角新建日记按钮。
  @Builder
  WriteButtonBuilder() {
    Column() {
      // 写日记图标。
      SymbolGlyph($r('sys.symbol.doc_plaintext_and_pencil_fill'))
        .fontSize(28)
        .fontColor([AppTheme.surface])
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(AppTheme.accent)
    // 按钮阴影。
    .shadow({
      // 阴影颜色。
      color: AppTheme.shadow,
      // 阴影模糊半径。
      radius: 14,
      // 阴影水平偏移。
      offsetX: 0,
      // 阴影垂直偏移。
      offsetY: 4
    })
    // 按钮距离右边和底部的间距。
    .margin({ right: 30, bottom: 70})
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.pageStack.pushPath({ name: 'JournalNew' })
    })
  }
}