// 引入单条日记数据模型和日记数据仓库。
import { JournalItem, JournalStore } from '../model/JournalModel'
import { AppTheme } from '../theme/AppTheme'

@ComponentV2
export struct JournalList {
  // 使用父级提供的 Navigation 路由栈，用来跳转详情页。
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 使用父级提供的日记仓库，用来读取 journalList 数据。
  @Consumer('journalStore') journalStore: JournalStore = new JournalStore()
  // 时间轴最底部的起点项，只显示圆点和标题，不显示内容。
  private startItem: JournalItem = new JournalItem('journal-start', '写下每一天的潮起潮落')

  build() {
    // List 是可滚动列表容器，用来承载所有时间轴节点。
    List() {
      // 遍历 journalStore 中的日记列表，每条日记生成一个时间轴分组。
      ForEach(this.journalStore.journalList, (item: JournalItem, index: number) => {
        // ListItemGroup 用 header 放圆点和标题，body 放日期、时间、摘要、图片。ps:header 分组头部，也就是时间轴圆点和标题。
        ListItemGroup({ header: this.TimeLineHeadBuilder(item, false) }) {
          ListItem() {
            this.ListRowBuilder(item) // 渲染一条日记的内容行。
          }
          // 左侧留 5，让竖线和 header 里的圆点对齐。
          .margin({ left: 5 })
          // 最后一条日记底部 padding 稍大一点，和起点之间有距离。
          .padding({ top: 10, bottom: index === this.journalStore.journalList.length - 1 ? 10 : 8 })
          // 用左边框模拟时间轴竖线。
          .border({
            // 只设置左边框宽度。
            width: { left: 1 },
            // 只设置左边框颜色。
            color: { left: AppTheme.axis }
          })
        }
        // 分组整体左侧微调，让圆点和竖线保持在同一轴线上。
        .padding({ left: 1 })
        // 每条日记分组之间留 12 的间距。
        .margin({ bottom: 12 })
        // 点击整条分组时进入详情页。
        .onClick(() => {
          // 先把当前点击的日记 id 存到仓库里，详情页会用它查数据。
          this.journalStore.setActiveJournal(item.id)
          // 使用 Navigation 路由栈跳转到 JournalDetail 页面。
          this.pageStack.pushPath({ name: 'JournalDetail' })
        })
      // ForEach 的 key，用日记 id 保证每条数据都有稳定标识。
      }, (item: JournalItem) => `${item.id}-${this.journalStore.journalVersion}`)
      /*在 HarmonyOS ArkUI 中，ForEach 的 key 参数是用于性能优化和数据正确渲染的重要机制。
      核心作用
      1. 唯一标识数据项
      key 为 ForEach 循环中的每个数据项提供一个稳定的唯一标识，让框架能区分"这是哪条数据"。
      2. 决定数据变化时的更新策略
      当数据源（this.journalStore.journalList）发生变化时，ArkUI 会根据 key 来判断：不用重新渲染，只更新变化的部分*/




      // 时间轴起始记录，永远在列表最底部。
      ListItemGroup({ header: this.TimeLineHeadBuilder(this.startItem, true) }) {}
      .padding({ left: 1 })
      .margin({ bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.pageBg)
    // 列表整体内边距，给时间轴留出左右空间。
    .padding({
      top: 18,
      left: 18,
      right: 22
    })
    // 滚动到边界时使用弹性效果。
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .alignListItem(ListItemAlign.Start)
  }

  // 时间轴头部：圆点 + 标题。
  @Builder
  TimeLineHeadBuilder(item: JournalItem, isStart: boolean) {
    // 横向布局，左边圆点，右边标题。
    Row({ space: 16 }) {
      // 时间轴圆点。
      Circle()
        .width(isStart ? 12 : 10)
        .height(isStart ? 12 : 10)
        // 填充透明，只保留描边效果。
        .fill(isStart ? AppTheme.pageBg : Color.Transparent)
        // 圆点描边宽度。
        .strokeWidth(isStart ? 1.6 : 2)
        // 起点圆点颜色更浅，普通日记圆点稍深。
        .stroke(isStart ? AppTheme.textTertiary : AppTheme.primary)

      // 日记标题。
      Text(item.title)
        // 标题占据右侧剩余空间。
        .layoutWeight(1)
        // 起点标题略小，普通标题略大。
        .fontSize(isStart ? 16 : 18)
        // 标题使用中等字重。
        .fontWeight(isStart ? FontWeight.Regular : FontWeight.Medium)
        // 起点和普通标题使用不同颜色。
        .fontColor(isStart ? AppTheme.textSecondary : AppTheme.textPrimary)
        // 控制标题行高。
        .lineHeight(isStart ? 23 : 25)
        // 标题最多显示两行。
        .maxLines(2)
        // 超出两行时显示省略号。
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .letterSpacing(2)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    // 起点底部留更多空白，普通日记头部底部留少一点。
    .padding({ bottom: isStart ? 30 : 4 })
    // 起点文字稍微降低透明度，看起来像时间轴的温柔提示。
    .opacity(isStart ? 0.92 : 1)
  }

  // 日记内容区域：日期时间、摘要、图片。
  @Builder
  ListRowBuilder(item: JournalItem) {
    // 外层横向布局，主要是为了后续给内容区域做左边距。
    Row() {
      // 内容纵向排列。
      Column({ space: 10 }) {
        // 日期和时间横向放在同一行。
        Row({ space: 8 }) {
          // 日记日期。
          Text(item.date)
            // 日期字号。
            .fontSize(13)
            // 日期字重。
            .fontWeight(FontWeight.Regular)
            // 日期颜色。
            .fontColor(AppTheme.textTertiary)

          // 日记时间。
          Text(item.time)
            // 时间字号。
            .fontSize(13)
            // 时间字重。
            .fontWeight(FontWeight.Regular)
            // 时间颜色。
            .fontColor(AppTheme.textTertiary)
        }
        // 日期时间行宽度铺满。
        .width('100%')

        // 如果有摘要内容，就显示摘要。
        if (item.summary) {
          // 摘要文本。
          Text(item.summary)
            // 摘要宽度铺满。
            .width('100%')
            // 摘要字号。
            .fontSize(15)
            // 摘要字重。
            .fontWeight(FontWeight.Regular)
            // 摘要颜色。
            .fontColor(AppTheme.textSecondary)
            // 摘要行高。
            .lineHeight(25)
            // 摘要最多显示五行。
            .maxLines(5)
            // 超出时显示省略号。
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 如果有图片，就显示图片缩略图。
        if (item.image) {
          // 日记图片。
          Image(item.image)
            // 图片宽度。
            .width(88)
            // 图片高度。
            .height(88)
            // 图片按容器裁剪填充。
            .objectFit(ImageFit.Cover)
            // 开启裁剪，这样圆角才会生效。
            .clip(true)
            // 图片圆角。
            .borderRadius(5)
            // 图片上方留一点距离。
            .margin({ top: 4 })
        }
      }
      // 内容列占据剩余空间。
      .layoutWeight(1)
      // 内容列左侧留白，让它对齐到标题下面。
      .margin({ left: 23 })
      // 内容左对齐。
      .alignItems(HorizontalAlign.Start)
    }
    // 内容行宽度铺满。
    .width('100%')
    // 内容行底部留白，让时间轴节点之间不拥挤。
    .padding({ bottom: 22 })
  }
}
