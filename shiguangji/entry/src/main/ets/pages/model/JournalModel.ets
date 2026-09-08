// @ObservedV2 表示这个类的对象可以被 V2 状态管理系统观察。
@ObservedV2
// JournalItem 表示“一条日记”的数据结构。
export class JournalItem {
  // @Trace 表示这个字段变化后，使用它的 UI 可以自动刷新。
  @Trace
  // id 是日记的唯一编号，后端数据库里的 id 会转成字符串放在这里。
  id: string = ''

  @Trace title: string = ''

  @Trace date: string = '' // 日记日期

  @Trace
  time: string = '' // 日记时间

  @Trace
  // summary 是日记正文内容，目前项目里用它保存 RichEditor 提取出来的纯文本。
  summary: string = ''

  @Trace
  // image 是日记图片，可以是本地资源，也可以是后端返回的网络图片地址。
  image?: ResourceStr

  // constructor 是构造函数，用来创建一条新的 JournalItem。
  constructor(id: string = '', title: string = '', date: string = '', time: string = '', summary: string = '', image?: ResourceStr) {
    this.id = id
    this.title = title
    this.date = date
    this.time = time
    this.summary = summary
    this.image = image
  }
}


@ObservedV2
// JournalStore 是日记数据仓库，负责保存列表、当前选中的日记，以及增删改查方法。
export class JournalStore {
  // @Trace 表示当前选中的日记 id 变化后，详情页可以重新读取对应数据。
  @Trace
  // activeJournalId 保存“当前正在查看或编辑”的日记 id。
  activeJournalId: string = ''

  // @Trace 表示日记列表变化后，首页时间轴列表可以自动刷新。
  @Trace
  // journalList 保存当前登录用户的所有日记。
  journalList: JournalItem[] = []

  // @Trace 表示版本号变化后，可以强制列表重新渲染。
  @Trace
  // journalVersion 是列表刷新标记，用在 JournalList 的 ForEach key 里。
  journalVersion: number = 0

  // setJournalList 用后端返回的新列表，整体替换当前本地列表。
  setJournalList(list: JournalItem[]): void {
    // 把传进来的日记数组保存到仓库。
    this.journalList = list
    // 如果当前有选中的日记，并且新列表里已经找不到它了，就清空选中状态。
    if (this.activeJournalId.length > 0 && !this.findJournalById(this.activeJournalId)) {
      // 清空当前选中的日记 id，避免详情页继续显示不存在的数据。
      this.activeJournalId = ''
    }
    // 列表变化后，让版本号加一，通知列表重新渲染。
    this.refreshJournalVersion()
  }

  // addJournal 用来把一条新日记添加到列表最上方。
  addJournal(item: JournalItem): void {
    // 使用数组字面量 [...] 创建一个全新的数组对象,新日记放在数组最前面，这样首页时间轴会先显示最新内容。
    this.journalList = [item, ...this.journalList]

    // 新增后刷新版本号，让列表立刻显示新数据。
    this.refreshJournalVersion()
  }

  // updateJournal 用来更新列表里已经存在的一条日记。
  updateJournal(item: JournalItem): void {
    // hasUpdated 用来记录这次是否真的找到了并更新了某条日记。
    let hasUpdated = false
    // 遍历当前列表，逐条寻找 id 相同的日记。
    this.journalList.forEach((journal: JournalItem) => {
      // 如果列表里的日记 id 和传进来的日记 id 一样，说明找到了要更新的那条。
      if (journal.id === item.id) {
        // 更新标题。
        journal.title = item.title
        // 更新日期。
        journal.date = item.date
        // 更新时间。
        journal.time = item.time
        // 更新正文摘要。
        journal.summary = item.summary
        // 更新图片地址。
        journal.image = item.image
        // 标记已经成功更新过数据。
        hasUpdated = true
      }
    })
    // 如果真的更新了某条日记，就刷新数组引用和版本号。
    if (hasUpdated) {
      // 重新生成一个数组引用，帮助 UI 更稳定地感知列表发生了变化。
      this.journalList = [...this.journalList]
      // 更新后刷新版本号，让首页列表重新渲染。
      this.refreshJournalVersion()
    }
  }

  // removeJournal 用来根据 id 删除一条日记。
  removeJournal(id: string): void {
    // filter 会返回一个新数组，只保留 id 不等于目标 id 的日记。
    this.journalList = this.journalList.filter((item: JournalItem) => item.id !== id)
    // 如果删掉的正好是当前选中的日记，就清空选中状态。
    if (this.activeJournalId === id) {
      // 清空当前选中的日记 id，避免详情页继续读取已删除数据。
      this.activeJournalId = ''
    }
    // 删除后刷新版本号，让首页列表立刻移除这条数据。
    this.refreshJournalVersion()
  }

  // findJournalById 用来通过 id 查找一条日记。
  findJournalById(id: string): JournalItem | undefined {
    // find 会返回第一条 id 相同的日记；如果找不到，就返回 undefined。
    return this.journalList.find((item: JournalItem) => item.id === id)
  }

  // setActiveJournal 用来记录当前点击的是哪一条日记。
  setActiveJournal(id: string): void {
    // 把传进来的 id 保存成当前选中的日记 id。
    this.activeJournalId = id
  }

  // getActiveJournal 用来获取当前选中的完整日记对象。
  getActiveJournal(): JournalItem | undefined {
    // 通过 activeJournalId 去列表里查找对应的日记。
    return this.findJournalById(this.activeJournalId)
  }

  // refreshJournalVersion 是仓库内部使用的方法，外部页面不需要直接调用。
  private refreshJournalVersion(): void {
    // 每次列表有变化，版本号加一，ForEach 的 key 也会跟着变化。
    this.journalVersion++
  }
}
