// AppTheme 用来统一保存整个项目的颜色。
export class AppTheme {
  // pageBg 是页面背景色，主要用于首页、列表页等大面积背景。
  static readonly pageBg: string = '#F4F7F3'
  // surface 是卡片、输入框、详情页正文等主要白色区域。
  static readonly surface: string = '#FFFFFF'
  // surfaceMuted 是较浅的辅助背景色，例如登录输入框背景。
  static readonly surfaceMuted: string = '#EEF3EB'
  // surfaceWarm 是偏暖的浅色背景，用来做轻提示或辅助按钮底色。
  static readonly surfaceWarm: string = '#FFF1EC'
  // textPrimary 是最重要的正文颜色，例如标题和主要文字。
  static readonly textPrimary: string = '#1F2522'
  // textSecondary 是次级文字颜色，例如摘要、说明文字。
  static readonly textSecondary: string = '#6E7971'
  // textTertiary 是更弱的文字颜色，例如时间、占位提示。
  static readonly textTertiary: string = '#8A968D'
  // border 是细分割线和输入框边界颜色。
  static readonly border: string = '#E3E8E1'
  // axis 是日记时间轴竖线颜色。
  static readonly axis: string = '#C8D2C7'
  // primary 是主色，偏自然绿色。
  static readonly primary: string = '#52796F'
  // primarySoft 是主色的浅色版本，适合做背景。
  static readonly primarySoft: string = '#DDE8E3'
  // accent 是强调色，适合保存按钮、删除按钮、新建按钮等重点操作。
  static readonly accent: string = '#E86F51'
  // disabled 是不可点击状态的颜色。
  static readonly disabled: string = '#CBD5C9'
  // shadow 是阴影颜色，前两位 22 表示透明度。
  static readonly shadow: string = '#22000000'
}
