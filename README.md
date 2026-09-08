# 拾光记 · ShiGuangJi

> 拾起时光，记录美好 —— 基于 HarmonyOS (ArkTS) + Node.js + MySQL 的日记应用课程设计

一款运行在 HarmonyOS 手机端的日记类应用，支持手机号/邮箱双通道登录注册、富文本写日记、相册选图配图、时间轴浏览与增删改查。客户端使用 ArkUI 声明式开发范式与 V2 状态管理体系，后端为 Express + MySQL 的 RESTful 服务，图片以 Base64 上传后由服务端落盘并静态托管。

---

## 目录

- [效果演示](#效果演示)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [接口文档](#接口文档)
- [数据库设计](#数据库设计)
- [架构与实现要点](#架构与实现要点)
- [已知限制](#已知限制)
- [课设资料](#课设资料)

---

## 效果演示

| 资料 | 位置 |
| --- | --- |
| 运行效果视频 | [效果视频.mp4](效果视频.mp4) |
| 系统结构图 | [docx/结构图.png](docx/结构图.png) |
| 课程设计报告 | [docx/拾光记_报告.docx](docx/拾光记_报告.docx) |
| 答辩演示文稿 | [docx/拾光记_演示.pptx](docx/拾光记_演示.pptx) |

---

## 技术栈

### 客户端（HarmonyOS）

| 项目 | 说明 |
| --- | --- |
| 开发语言 | ArkTS |
| UI 框架 | ArkUI 声明式开发范式 |
| 状态管理 | V2 状态管理：`@ComponentV2` / `@ObservedV2` / `@Trace` / `@Local` / `@Provider` + `AppStorageV2` |
| 页面路由 | `router`（登录页 → 首页）+ `Navigation` / `NavPathStack`（首页内多级页面） |
| 编译 SDK | HarmonyOS 6.1.0(23)，`compatibleSdkVersion` 与 `targetSdkVersion` 均为 6.1.0(23) |
| 设备类型 | phone |
| 三方依赖 | `@ohos/lottie ^2.0.31`（登录页动画背景） |
| 测试依赖 | `@ohos/hypium 1.0.25`、`@ohos/hamock 1.0.0` |
| 应用权限 | `ohos.permission.INTERNET` |
| 包名 | `com.shiguangji.diary`，版本 `1.0.0` (versionCode 1000000) |

### 服务端（Node.js）

| 项目 | 说明 |
| --- | --- |
| 运行时 | Node.js（CommonJS 模块） |
| Web 框架 | `express ^4.21.2` |
| 数据库 | MySQL，驱动 `mysql2 ^3.11.5`（Promise 连接池） |
| 跨域 | `cors ^2.8.5` |
| 配置管理 | `dotenv ^16.4.7` |
| 热重载 | `nodemon ^3.1.9`（开发模式） |

---

## 项目结构

```text
me-课设/
├── shiguangji/                          # HarmonyOS 客户端工程（DevEco Studio）
│   ├── AppScope/                        # 应用级配置与资源（app.json5、应用名、图标）
│   ├── entry/                           # 主模块 entry
│   │   └── src/main/
│   │       ├── module.json5             # 模块配置、权限声明、Ability 注册
│   │       ├── ets/
│   │       │   ├── entryability/
│   │       │   │   └── EntryAbility.ets # 应用入口：加载首页、沉浸式全屏、安全区避让
│   │       │   ├── entrybackupability/
│   │       │   │   └── EntryBackupAbility.ets  # 备份扩展能力
│   │       │   └── pages/
│   │       │       ├── login/
│   │       │       │   ├── login.ets            # 登录页（Lottie 动画背景 + 表单容器）
│   │       │       │   ├── LoginTypeSwitcher.ets # 手机/邮箱切换条（带滑块动画）
│   │       │       │   └── LoginFormArea.ets     # 登录/注册/忘记密码表单区
│   │       │       ├── journal/
│   │       │       │   ├── JournalIndex.ets  # 首页：顶部日期栏 + 时间轴 + 悬浮写日记按钮
│   │       │       │   ├── JournalList.ets   # 时间轴列表组件
│   │       │       │   ├── JournalNew.ets    # 新建日记：RichEditor + 相册选图
│   │       │       │   ├── JournalDetail.ets # 日记详情：查看 + 删除
│   │       │       │   └── JournalEdit.ets   # 编辑日记
│   │       │       ├── model/
│   │       │       │   └── JournalModel.ets  # JournalItem 数据类 + JournalStore 数据仓库
│   │       │       ├── api/
│   │       │       │   └── ApiService.ets    # 网络请求统一封装（含图片 Base64 上传）
│   │       │       ├── theme/
│   │       │       │   └── AppTheme.ets      # 全局色板常量
│   │       │       └── utils/
│   │       │           └── UiUtil.ets        # Toast 等 UI 工具
│   │       └── resources/
│   │           ├── base/                  # 默认资源（图片、字符串、颜色、页面路由表）
│   │           ├── dark/                  # 深色模式颜色资源
│   │           └── rawfile/               # 日记默认背景图、lottie/login_bg.json
│   ├── build-profile.json5                # 工程构建配置（SDK 版本、签名、模块）
│   ├── oh-package.json5                   # 工程依赖
│   └── hvigor/                            # Hvigor 构建配置
│
├── shjiguangji-Node.js/node.js/           # 服务端
│   ├── src/
│   │   ├── index.js                       # Express 入口：全部路由定义
│   │   └── db.js                          # MySQL 连接池
│   ├── uploads/images/                    # 上传图片落盘目录（启动时自动创建）
│   ├── schema.sql                         # 建库建表脚本
│   ├── .env.example                       # 环境变量样例
│   ├── .env                               # 本地环境变量（含数据库口令，勿外传）
│   └── package.json
│
├── docx/                                  # 课设文档：结构图、报告、演示 PPT
└── 效果视频.mp4                            # 应用运行效果录屏
```

---

## 功能特性

### 登录与账号

- **双通道登录**：手机号与邮箱两种登录方式，顶部切换条带滑块动画过渡。
- **手机号三种表单模式**：登录、注册、忘记密码；注册与找回密码模式下显示验证码输入框与「获取验证码」倒计时按钮。
- **邮箱免注册登录**：使用邮箱登录时，若账号不存在，服务端会自动创建该邮箱账号并直接登录成功（返回「邮箱注册并登录成功」）。
- **协议勾选**：需勾选用户协议后方可提交。
- **Lottie 动画背景**：登录页以 Canvas 承载 `rawfile/lottie/login_bg.json` 循环动画，页面销毁时释放动画资源与倒计时定时器。

### 日记管理

- **时间轴首页**：顶部背景图叠加当前日期（日 + 月），下方为竖向时间轴日记列表，右下角悬浮「写日记」按钮。
- **富文本编辑**：新建与编辑页基于 `RichEditor` + `RichEditorController`，支持聚焦控制与内容提取。
- **相册配图**：通过 `photoAccessHelper.PhotoViewPicker` 拉起系统相册（限定图片类型），选中后经 `addImageSpan` 插入编辑器。
- **图片上传**：本地图片以只读方式打开 → 读入 `ArrayBuffer` → `util.Base64Helper` 编码为 Base64 → POST 到服务端；服务端解码落盘并返回可访问路径。
- **默认标题**：未填写标题时，自动以「日期 + 时间」生成默认标题。
- **详情与删除**：详情页展示标题、日期时间、正文与配图；删除时先请求服务端删除，成功后再移除本地列表项并返回首页，失败则 Toast 提示。
- **编辑保留时间**：编辑页当前不修改日记的原有日期与时间字段。

### 界面与体验

- **沉浸式全屏**：`setWindowLayoutFullScreen(true)` 开启全屏布局，并通过 `getWindowAvoidArea` 读取状态栏与导航条高度，写入全局状态供各页面避让。
- **统一色板**：`AppTheme` 集中管理颜色 —— 自然绿主色 `#52796F`、珊瑚强调色 `#E86F51`、页面底色 `#F4F7F3`，配合 `resources/dark` 提供深色模式颜色资源。
- **轻量反馈**：`UiUtil.toast` 基于 `promptAction.showToast` 统一处理操作结果提示。
- **列表刷新机制**：`JournalStore` 维护 `journalVersion` 版本号，配合 `ForEach` 的 key 强制列表在增删改后稳定重渲染。

---

## 快速开始

### 一、环境准备

- DevEco Studio（支持 HarmonyOS 6.1.0(23) SDK）
- Node.js（建议 18 及以上）
- MySQL 5.7 / 8.0
- HarmonyOS 真机或手机模拟器

### 二、启动服务端

```bash
cd shjiguangji-Node.js/node.js

# 1. 安装依赖
npm install

# 2. 初始化数据库（创建 shiguangji 库与 users / journals 两张表）
mysql -u root -p < schema.sql

# 3. 配置环境变量
#    复制 .env.example 为 .env，按本机实际情况修改数据库账号口令
cp .env.example .env

# 4. 启动服务
npm start          # 生产方式启动
npm run dev        # 开发方式启动（nodemon 热重载）
```

启动成功后控制台输出：

```text
拾光记服务已启动：http://0.0.0.0:3000
本机访问：http://localhost:3000
```

验证服务与数据库连通性：

```bash
curl http://localhost:3000/api/health
# 期望返回：{"code":0,"message":"ok","database":"connected"}
```

`.env` 可配置项：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PORT` | `3000` | 服务监听端口 |
| `DB_HOST` | `127.0.0.1` | 数据库地址 |
| `DB_PORT` | `3306` | 数据库端口 |
| `DB_USER` | `root` | 数据库用户名 |
| `DB_PASSWORD` | — | 数据库口令 |
| `DB_NAME` | `shiguangji` | 数据库名 |

> 服务监听 `0.0.0.0`，因此手机与电脑处于同一局域网时可直接通过电脑内网 IP 访问。

### 三、运行客户端

1. 用 DevEco Studio 打开 `shiguangji` 目录，等待 Hvigor 同步与 `oh_modules` 依赖安装完成。
2. **修改后端地址**：打开 `shiguangji/entry/src/main/ets/pages/api/ApiService.ets`，将第 11 行的 `BASE_URL` 改为你自己电脑的局域网 IP：

   ```typescript
   const BASE_URL = 'http://你的电脑IP:3000'
   ```

   > 文件内已保留以太网与 Wi-Fi 两个地址的注释示例，按当前联网方式选用对应网卡 IP。使用模拟器时不能填 `localhost`，需填电脑真实内网 IP。
3. 在 DevEco Studio 中配置签名（`build-profile.json5` 的 `signingConfigs` 默认为空，需通过 `File > Project Structure > Signing Configs` 自动生成调试签名）。
4. 连接真机或启动模拟器，运行 `entry` 模块。应用入口页为 `pages/login/login`。

---

## 接口文档

所有接口统一返回结构：

```json
{
  "code": 0,
  "message": "提示信息",
  "data": {}
}
```

`code = 0` 表示成功，非 0（400 / 401 / 404 / 500）表示失败。请求与响应体均为 `application/json`，请求体大小上限 20 MB。

### 用户

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/api/users/register` | 注册账号 |
| `POST` | `/api/users/login` | 登录（邮箱账号不存在时自动注册并登录） |

**注册** `POST /api/users/register`

请求体：`phone` 与 `email` 至少传一个，`password` 必填。

```json
{ "phone": "13800000000", "email": "user@example.com", "password": "123456" }
```

成功返回：

```json
{ "code": 0, "message": "注册成功", "data": { "id": 1, "phone": "13800000000", "email": "user@example.com" } }
```

**登录** `POST /api/users/login`

`account` 可为手机号或邮箱（含 `@` 即判定为邮箱）。

```json
{ "account": "user@example.com", "password": "123456" }
```

成功返回：

```json
{ "code": 0, "message": "登录成功", "data": { "id": 1, "phone": null, "email": "user@example.com", "created_at": "2026-09-08T10:00:00.000Z" } }
```

失败返回 `401`：手机号不存在或口令错误 → 「账号或密码错误」；邮箱已存在但口令错误 → 「邮箱或密码错误」；邮箱不存在 → 自动创建账号并返回 `code: 0`「邮箱注册并登录成功」。

### 日记

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/api/journals?userId={id}` | 查询该用户全部日记，按 `created_at` 倒序 |
| `GET` | `/api/journals/{id}?userId={id}` | 查询单篇日记详情 |
| `POST` | `/api/journals` | 新建日记 |
| `PUT` | `/api/journals/{id}` | 更新日记 |
| `DELETE` | `/api/journals/{id}?userId={id}` | 删除日记 |

**新建 / 更新** 请求体（`userId` 与 `title` 必填）：

```json
{
  "userId": 1,
  "title": "开学第一天",
  "content": "今天天气很好……",
  "image": "/uploads/images/1757300000000-12345.jpg",
  "journalDate": "2026-09-08",
  "journalTime": "10:30"
}
```

新建成功返回 `{ "code": 0, "message": "创建成功", "data": { "id": 12 } }`；更新成功返回 `{ "code": 0, "message": "更新成功" }`。

> 查询、更新、删除均校验 `user_id`，只能操作属于当前用户的日记；目标不存在时返回 `404`「日记不存在」。

### 图片上传

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/api/uploads/images` | 上传 Base64 图片 |

请求体：

```json
{ "fileName": "cover.jpg", "imageBase64": "iVBORw0KGgoAAAANSUhEUg..." }
```

成功返回：

```json
{
  "code": 0,
  "message": "上传成功",
  "data": {
    "path": "/uploads/images/1757300000000-12345.jpg",
    "url": "http://localhost:3000/uploads/images/1757300000000-12345.jpg"
  }
}
```

处理规则：自动剥离 `data:image/...;base64,` 前缀；按 `fileName` 后缀识别扩展名，仅接受 `.jpg` `.jpeg` `.png` `.webp` `.gif`，否则回退为 `.jpg`；文件名以「时间戳-随机数」重命名后写入 `uploads/images/`。该目录由服务端在启动时自动创建，并通过 `/uploads` 路由静态托管。

### 服务状态

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/` | 返回服务名与文档入口 |
| `GET` | `/api/health` | 健康检查，执行 `SELECT 1` 验证数据库连通性 |

---

## 数据库设计

数据库 `shiguangji`，字符集 `utf8mb4`，排序规则 `utf8mb4_unicode_ci`。建表脚本见 [shjiguangji-Node.js/node.js/schema.sql](shjiguangji-Node.js/node.js/schema.sql)。

### users — 用户表

| 字段 | 类型 | 约束 | 说明 |
| --- | --- | --- | --- |
| `id` | INT | 主键，自增 | 用户 ID |
| `phone` | VARCHAR(20) | 唯一 | 手机号 |
| `email` | VARCHAR(100) | 唯一 | 邮箱 |
| `password` | VARCHAR(100) | 非空 | 登录口令 |
| `created_at` | TIMESTAMP | 默认当前时间 | 注册时间 |

### journals — 日记表

| 字段 | 类型 | 约束 | 说明 |
| --- | --- | --- | --- |
| `id` | INT | 主键，自增 | 日记 ID |
| `user_id` | INT | 外键 → `users.id`，`ON DELETE SET NULL` | 所属用户 |
| `title` | VARCHAR(100) | 非空 | 标题 |
| `content` | TEXT | — | 正文（RichEditor 提取的纯文本） |
| `image` | VARCHAR(500) | — | 图片相对路径，如 `/uploads/images/xxx.jpg` |
| `journal_date` | VARCHAR(20) | — | 日记日期 |
| `journal_time` | VARCHAR(20) | — | 日记时间 |
| `created_at` | TIMESTAMP | 默认当前时间 | 创建时间 |
| `updated_at` | TIMESTAMP | 默认当前时间，更新时自动刷新 | 修改时间 |

---

## 架构与实现要点

### 分层结构

```text
┌─────────────────────── HarmonyOS 客户端 ───────────────────────┐
│  pages/         视图层：login、JournalIndex/List/New/Detail/Edit │
│  model/         数据层：JournalItem(@ObservedV2) + JournalStore   │
│  api/           服务层：ApiService —— 统一 HTTP 封装与字段映射     │
│  theme/ utils/  基础设施：色板常量、Toast 工具                     │
└───────────────────────────────┬────────────────────────────────┘
                          HTTP / JSON
┌───────────────────────────────┴────────────────────────────────┐
│  src/index.js   路由层：用户、日记、上传、健康检查                 │
│  src/db.js      数据层：mysql2 Promise 连接池（上限 10 连接）      │
│  uploads/       文件层：图片落盘 + express.static 静态托管         │
└───────────────────────────────┬────────────────────────────────┘
                                │
                          MySQL shiguangji
```

### 关键实现

- **前后端字段映射**：数据库使用下划线命名（`user_id`、`journal_date`），前端使用驼峰命名。`ApiService` 内的 `ServerJournal` / `JournalBody` 接口与 `toJournalBody`、`getJournals` 承担双向转换，页面层只面向 `JournalItem` 编程。
- **图片地址双向转换**：`toDisplayImageUrl` 将库中相对路径拼接 `BASE_URL` 供 `Image` 组件显示；`toServerImagePath` 反向剥离 `BASE_URL`，确保数据库只存相对路径，服务端迁移 IP 后历史数据仍可复用。已是完整外链的图片地址则原样保留。
- **会话状态**：`UserSession.currentUserId` 静态保存当前登录用户 ID，登录/注册成功后写入，后续日记接口全部以此为查询条件，实现数据按用户隔离。
- **状态管理**：`JournalIndex` 作为 `@Entry` 组件，通过 `@Provider('pageStack')` 与 `@Provider('journalStore')` 向 `Navigation` 子页面下发路由栈与数据仓库，子页面直接注入使用，避免逐层传参。
- **请求资源管理**：`ApiService.request` 与 `readImageAsBase64` 均使用 `try / finally` 确保 HTTP 请求对象 `destroy()`、文件句柄 `closeSync()` 一定执行；连接与读取超时均设为 20 秒。
- **SQL 注入防护**：服务端所有查询均使用 `?` 占位符参数化传入，不拼接用户输入。

---

## 已知限制

以下为课程设计范围内的简化处理，非生产级实现，记录在此便于后续改进：

1. **口令明文存储**：`users.password` 直接保存原文并在登录时明文比对，未做 bcrypt 等加盐哈希。
2. **无鉴权令牌**：接口未引入 JWT / Session，`userId` 由客户端传入，仅做归属校验，不校验调用方身份。
3. **验证码为前端模拟**：手机号注册与找回密码流程中的验证码有输入框与倒计时 UI，但未接入短信服务，服务端不校验验证码。
4. **后端地址硬编码**：`BASE_URL` 写死在 `ApiService.ets` 中，更换网络环境需手动改代码并重新编译。
5. **富文本降级为纯文本**：`RichEditor` 中插入的图片与样式在保存时仅提取纯文本写入 `content`，单篇日记只在 `image` 字段保留一张配图路径。
6. **列表无分页**：`GET /api/journals` 一次返回该用户全部日记，数据量大时缺少分页与懒加载。
7. **无软删除**：删除为物理删除，日记不可恢复；`user_id` 外键为 `ON DELETE SET NULL`，用户删除后其日记会变成无归属数据。
8. **编辑页不改时间**：编辑日记时保留原有 `journal_date` 与 `journal_time`，不支持修改日记的日期时间。

---

## 课设资料

| 文件 | 说明 |
| --- | --- |
| [docx/拾光记_报告.docx](docx/拾光记_报告.docx) | 课程设计报告 |
| [docx/拾光记_演示.pptx](docx/拾光记_演示.pptx) | 答辩演示文稿 |
| [docx/结构图.png](docx/结构图.png) | 系统结构图 |
| [效果视频.mp4](效果视频.mp4) | 应用运行效果录屏 |

---

## 许可与说明

本项目为课程设计作业，仅用于学习与教学演示。服务端 `package.json` 中声明的 license 为 ISC。
