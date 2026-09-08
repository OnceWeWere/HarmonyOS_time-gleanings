// 引入 HarmonyOS 的网络请求模块。
import { http } from '@kit.NetworkKit'
// 引入文件读写模块，用来读取本地图片。
import { fileIo } from '@kit.CoreFileKit'
// 引入工具模块，用来把图片字节转成 base64。
import { util } from '@kit.ArkTS'
// 引入日记数据模型，用来把后端数据转换成前端对象。
import { JournalItem } from '../model/JournalModel'

// BASE_URL 是后端服务器地址，前端所有接口都会拼接这个地址。
const BASE_URL = 'http://10.34.11.28:3000' // 本机以太网
// const BASE_URL = 'http://10.34.11.88:3000' // 本机wifi

// ApiResult 描述后端统一返回格式。
interface ApiResult {
  // code 为 0 通常表示成功，非 0 表示失败。
  code: number
  // message 是后端返回的提示信息。
  message: string
  // data 是后端返回的数据，可能是对象，也可能是对象数组。
  data?: Object | Object[]
}

// LoginBody 描述登录接口需要提交的数据。
interface LoginBody {
  // account 可以是手机号，也可以是邮箱。
  account: string
  // password 是用户输入的密码。
  password: string
}

// RegisterBody 描述注册接口需要提交的数据。
interface RegisterBody {
  // phone 是手机号注册时使用的字段，可选。
  phone?: string
  // email 是邮箱注册时使用的字段，可选。
  email?: string
  // password 是用户密码。
  password: string
}

// JournalBody 描述新建和编辑日记时提交给后端的数据。
interface JournalBody {
  // userId 表示当前登录用户的 id。
  userId: number
  // title 是日记标题。
  title: string
  // content 是日记正文内容。
  content: string
  // image 是图片地址，保存到数据库时通常是 /uploads/... 这种路径。
  image?: string
  // journalDate 是日记日期。
  journalDate: string
  // journalTime 是日记时间。
  journalTime: string
}

// UploadImageBody 描述上传图片接口需要提交的数据。
interface UploadImageBody {
  // fileName 是图片文件名。
  fileName: string
  // imageBase64 是图片转成 base64 后的字符串。
  imageBase64: string
}

// ServerUser 描述后端返回的用户对象。
interface ServerUser {
  // id 是数据库里的用户 id。
  id: number
  // phone 是用户手机号，可选。
  phone?: string
  // email 是用户邮箱，可选。
  email?: string
}

// ServerJournal 描述后端返回的日记对象。
interface ServerJournal {
  // id 是数据库里的日记 id。
  id: number
  // user_id 是这篇日记所属用户的 id。
  user_id?: number
  // title 是日记标题。
  title: string
  // content 是日记正文。
  content?: string
  // image 是后端保存的图片路径。
  image?: string
  // journal_date 是后端返回的日记日期。
  journal_date?: string
  // journal_time 是后端返回的日记时间。
  journal_time?: string
}

// UserSession 用来保存当前登录用户的信息。
export class UserSession {
  // currentUserId 保存当前登录用户 id，后续查询日记时会用到。
  static currentUserId: number = 0
}

// ApiService 统一管理前端调用后端接口的代码。
export class ApiService {
  // login 用来登录；邮箱登录不存在时，后端会按你的规则自动注册。
  static async login(account: string, password: string): Promise<boolean> {
    // 组装登录请求体。
    let body: LoginBody = {
      // 把外面传进来的账号放到 account。
      account: account,
      // 把外面传进来的密码放到 password。
      password: password
    }
    // 调用登录接口。
    let result = await ApiService.request('/api/users/login', http.RequestMethod.POST, body)
    // 如果后端返回失败，或者没有用户数据，就认为登录失败。
    if (result.code !== 0 || !result.data) {
      // 返回 false 表示登录失败。
      return false
    }
    // 把后端返回的数据当作用户对象。
    let user = result.data as ServerUser
    // 保存当前用户 id，后面查日记、增删改日记都要用。
    UserSession.currentUserId = user.id
    // 返回 true 表示登录成功。
    return true
  }

  // register 用来注册手机号或邮箱账号。
  static async register(phone: string, email: string, password: string): Promise<boolean> {
    // 组装注册请求体。
    let body: RegisterBody = {
      // 如果 phone 有内容就传手机号，否则传 undefined。
      phone: phone.length > 0 ? phone : undefined,
      // 如果 email 有内容就传邮箱，否则传 undefined。
      email: email.length > 0 ? email : undefined,
      // 传入用户密码。
      password: password
    }
    // 调用注册接口。
    let result = await ApiService.request('/api/users/register', http.RequestMethod.POST, body)
    // 如果后端返回失败，或者没有用户数据，就认为注册失败。
    if (result.code !== 0 || !result.data) {
      // 返回 false 表示注册失败。
      return false
    }
    // 把后端返回的数据当作用户对象。
    let user = result.data as ServerUser
    // 注册成功后，也保存当前用户 id。
    UserSession.currentUserId = user.id
    // 返回 true 表示注册成功。
    return true
  }

  // getJournals 用来获取当前用户的所有日记。
  static async getJournals(): Promise<JournalItem[]> {
    // 调用查询日记接口，并把当前用户 id 放在查询参数里。
    let result = await ApiService.request(`/api/journals?userId=${UserSession.currentUserId}`, http.RequestMethod.GET)
    // 把后端 data 当作日记数组。
    let list = result.data as ServerJournal[]
    // 如果后端没有返回列表，就给前端一个空数组。
    if (!list) {
      // 返回空数组，避免页面遍历时报错。
      return []
    }

    // 把后端字段转换成前端使用的 JournalItem。
    return list.map((item: ServerJournal) => {
      // 每一条后端日记都创建成一个 JournalItem。
      return new JournalItem(
        // 数据库 id 是数字，这里转成字符串，方便前端统一处理。
        `${item.id}`,
        // 日记标题。
        item.title,
        // 日记日期；没有就用空字符串。
        item.journal_date || '',
        // 日记时间；没有就用空字符串。
        item.journal_time || '',
        // 日记正文；没有就用空字符串。
        item.content || '',
        // 图片路径转换成前端 Image 可以显示的完整地址。
        ApiService.toDisplayImageUrl(item.image)
      )
    })
  }

  // createJournal 用来新建一条日记。
  static async createJournal(item: JournalItem): Promise<string> {
    // 把前端 JournalItem 转成后端需要的请求体。
    let body = ApiService.toJournalBody(item)
    // 调用新建日记接口。
    let result = await ApiService.request('/api/journals', http.RequestMethod.POST, body)
    // 如果后端返回失败，或者没有返回数据，就表示新建失败。
    if (result.code !== 0 || !result.data) {
      // 返回空字符串表示保存失败。
      return ''
    }

    // 后端会返回新日记的 id。
    let data = result.data as Record<string, number>
    // 把新 id 转成字符串返回给页面。
    return `${data.id}`
  }

  // updateJournal 用来编辑已有日记。
  static async updateJournal(item: JournalItem): Promise<boolean> {
    // 把前端 JournalItem 转成后端需要的请求体。
    let body = ApiService.toJournalBody(item)
    // 调用编辑日记接口，路径里带上要编辑的日记 id。
    let result = await ApiService.request(`/api/journals/${item.id}`, http.RequestMethod.PUT, body)
    // code 为 0 表示编辑成功。
    return result.code === 0
  }

  // toJournalBody 用来把前端日记对象转换成后端接口需要的格式。
  private static toJournalBody(item: JournalItem): JournalBody {
    // 返回后端需要的日记请求体。
    return {
      // 当前登录用户 id。
      userId: UserSession.currentUserId,
      // 日记标题。
      title: item.title,
      // 日记正文。
      content: item.summary,
      // 图片地址转换成适合保存到数据库的路径。
      image: ApiService.toServerImagePath(item.image),
      // 日记日期。
      journalDate: item.date,
      // 日记时间。
      journalTime: item.time
    }
  }

  // deleteJournal 用来删除一条日记。
  static async deleteJournal(id: string): Promise<boolean> {
    // 调用删除接口，路径里带日记 id，查询参数里带当前用户 id。
    let result = await ApiService.request(`/api/journals/${id}?userId=${UserSession.currentUserId}`, http.RequestMethod.DELETE)
    // code 为 0 表示删除成功。
    return result.code === 0
  }

  // uploadImage 用来把本地图片上传到后端。
  static async uploadImage(image: ResourceStr | undefined): Promise<string> {
    // 如果没有图片，或者图片不是字符串地址，就不上传。
    if (!image || typeof image !== 'string') {
      // 返回空字符串表示没有上传成功的图片地址。
      return ''
    }
    // 如果图片本来就是网络地址，就直接返回，不需要重复上传。
    if (image.startsWith('http://') || image.startsWith('https://')) {
      // 直接返回原图片地址。
      return image
    }

    // 组装上传图片请求体。
    let body: UploadImageBody = {
      // 从图片 uri 里取出文件名。
      fileName: ApiService.getFileName(image),
      // 读取本地图片，并转成 base64。
      imageBase64: ApiService.readImageAsBase64(image)
    }
    // 调用上传图片接口。
    let result = await ApiService.request('/api/uploads/images', http.RequestMethod.POST, body)
    // 如果后端返回失败，或者没有返回数据，就表示上传失败。
    if (result.code !== 0 || !result.data) {
      // 返回空字符串表示上传失败。
      return ''
    }

    // 后端会返回图片路径或完整图片地址。
    let data = result.data as Record<string, string>
    // 优先使用 path，再使用 url，并转换成前端可显示的完整地址。
    return ApiService.toDisplayImageUrl(data.path || data.url) || ''
  }

  // readImageAsBase64 用来读取本地图片文件，并转成 base64 字符串。
  private static readImageAsBase64(imageUri: string): string {
    // 以只读模式打开图片文件。
    let file = fileIo.openSync(imageUri, fileIo.OpenMode.READ_ONLY)
    // try finally 确保读完文件后一定会关闭文件。
    try {
      // 获取文件大小。
      let stat = fileIo.statSync(file.fd)
      // 根据文件大小创建 ArrayBuffer。
      let buffer = new ArrayBuffer(stat.size)
      // 把文件内容读取到 buffer 里。
      fileIo.readSync(file.fd, buffer)
      // 把 ArrayBuffer 转成 Uint8Array，方便 base64 工具处理。
      let bytes = new Uint8Array(buffer)
      // 把图片字节转成 base64 字符串。
      return new util.Base64Helper().encodeToStringSync(bytes)
    // finally 不管成功还是失败都会执行。
    } finally {
      // 关闭文件，避免文件句柄一直占用。
      fileIo.closeSync(file)
    }
  }

  // getFileName 用来从图片 uri 里提取文件名。
  private static getFileName(uri: string): string {
    // 去掉 uri 后面的查询参数。
    let pureUri = uri.split('?')[0]
    // 按 / 分割路径。
    let parts = pureUri.split('/')
    // 取路径最后一段作为文件名。
    let name = parts[parts.length - 1]
    // 如果取到了文件名就返回，否则给一个默认文件名。
    return name && name.length > 0 ? name : 'journal-image.jpg'
  }

  // toDisplayImageUrl 用来把数据库里的图片路径转换成 Image 可以显示的地址。
  private static toDisplayImageUrl(image?: string): string | undefined {
    // 如果没有图片地址，就返回 undefined。
    if (!image) {
      // 返回 undefined 表示没有图片。
      return undefined
    }
    // 如果本身就是完整网络地址，就直接返回。
    if (image.startsWith('http://') || image.startsWith('https://')) {
      // 返回原地址。
      return image
    }
    // 如果是 /uploads/... 这种以 / 开头的路径，就直接拼接 BASE_URL。
    if (image.startsWith('/')) {
      // 返回完整可访问地址。
      return `${BASE_URL}${image}`
    }
    // 如果不是 / 开头，就补一个 / 再拼接。
    return `${BASE_URL}/${image}`
  }

  // toServerImagePath 用来把前端图片地址转换成适合保存到数据库的路径。
  private static toServerImagePath(image?: ResourceStr): string | undefined {
    // 如果没有图片，或者图片不是字符串，就返回 undefined。
    if (!image || typeof image !== 'string') {
      // 返回 undefined 表示不保存图片。
      return undefined
    }
    // 如果是当前服务器的完整图片地址，就去掉 BASE_URL，只保存相对路径。
    if (image.startsWith(BASE_URL)) {
      // 例如 http://.../uploads/a.png 会变成 /uploads/a.png。
      return image.substring(BASE_URL.length)
    }
    // 如果已经是 /uploads/...，说明它已经是后端路径。
    if (image.startsWith('/uploads/')) {
      // 直接返回这个后端路径。
      return image
    }
    // 如果是其它网络图片地址，就保留完整地址。
    if (image.startsWith('http://') || image.startsWith('https://')) {
      // 返回原网络地址。
      return image
    }
    // 其它情况一般是本地 uri，数据库不直接保存它。
    return undefined
  }

  // request 是底层通用请求方法，其它接口方法都会调用它。
  private static async request(path: string, method: http.RequestMethod, data?: Object): Promise<ApiResult> {
    // 创建一个 HTTP 请求对象。
    let request = http.createHttp()
    // try finally 确保请求结束后销毁 request。
    try {
      // 发起 HTTP 请求。
      let response = await request.request(`${BASE_URL}${path}`, {
        // 请求方法，例如 GET、POST、PUT、DELETE。
        method: method,
        // 请求头配置。
        header: {
          // 告诉后端当前请求体是 JSON。
          'Content-Type': 'application/json'
        },
        // 如果有请求体，就转成 JSON 字符串；没有就传 undefined。
        extraData: data ? JSON.stringify(data) : undefined,
        // 希望后端响应按字符串形式返回，方便 JSON.parse。
        expectDataType: http.HttpDataType.STRING,
        // 连接超时时间，单位是毫秒。
        connectTimeout: 20000,
        // 读取超时时间，单位是毫秒。
        readTimeout: 20000
      } as http.HttpRequestOptions)

      // 打印接口状态，方便联调时看请求有没有成功到达后端。
      console.info(`API ${method} ${path} status=${response.responseCode}`)
      // 如果响应结果是字符串，就需要手动转成对象。
      if (typeof response.result === 'string') {
        // 打印后端返回的原始内容，方便调试。
        console.info(`API response: ${response.result}`)
        // 把 JSON 字符串转换成 ApiResult 对象。
        return JSON.parse(response.result) as ApiResult
      }

      // 如果系统已经把响应解析成对象，就直接按 ApiResult 返回。
      return response.result as ApiResult
    // finally 不管请求成功还是失败都会执行。
    } finally {
      // 销毁 HTTP 请求对象，释放资源。
      request.destroy()
    }
  }
}
