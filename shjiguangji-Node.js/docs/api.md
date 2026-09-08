# 拾光记 API 文档

基础地址：

```text
http://localhost:3000
```

## 启动方式

1. 安装依赖：

```bash
npm install
```

2. 复制环境变量：

```bash
copy .env.example .env
```

3. 修改 `.env` 中的 MySQL 账号、密码和数据库名。

4. 执行 `schema.sql` 创建数据库和表。

5. 启动服务：

```bash
npm run dev
```

## 通用返回格式

```json
{
  "code": 0,
  "message": "成功信息",
  "data": {}
}
```

## 健康检查

### GET `/api/health`

检查服务和数据库是否正常。

成功响应：

```json
{
  "code": 0,
  "message": "ok",
  "database": "connected"
}
```

## 用户注册

### POST `/api/users/register`

账号密码不加密，方便初学阶段学习。

请求体：

```json
{
  "phone": "13800138000",
  "email": "test@example.com",
  "password": "123456"
}
```

说明：

- `phone` 和 `email` 至少传一个
- `password` 必填

成功响应：

```json
{
  "code": 0,
  "message": "注册成功",
  "data": {
    "id": 1,
    "phone": "13800138000",
    "email": "test@example.com"
  }
}
```

## 用户登录

### POST `/api/users/login`

请求体：

```json
{
  "account": "13800138000",
  "password": "123456"
}
```

说明：

- `account` 可以是手机号，也可以是邮箱
- `password` 是明文密码
- 如果 `account` 是邮箱，并且这个邮箱还没有注册，接口会自动创建账号并登录
- 如果邮箱已经存在，但密码不一致，接口返回登录失败

成功响应：

```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "id": 1,
    "phone": "13800138000",
    "email": "test@example.com",
    "created_at": "2026-06-23T12:00:00.000Z"
  }
}
```

## 上传图片

### POST `/api/uploads/images`

前端把本地图片转成 base64 后上传，后端会保存到 `uploads/images`，并返回可以直接渲染的图片 URL。

请求体：

```json
{
  "fileName": "photo.jpg",
  "imageBase64": "/9j/4AAQSkZJRgABAQ..."
}
```

成功响应：

```json
{
  "code": 0,
  "message": "上传成功",
  "data": {
    "path": "/uploads/images/1710000000000-12345.jpg",
    "url": "http://localhost:3000/uploads/images/1710000000000-12345.jpg"
  }
}
```

说明：

- 数据库建议保存 `path`
- 前端显示图片时再拼接当前 `BASE_URL`

## 获取日记列表

### GET `/api/journals?userId=1`

说明：

- `userId` 必填
- 只返回当前用户自己的日记

成功响应：

```json
{
  "code": 0,
  "message": "查询成功",
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "title": "今天的日记",
      "content": "今天很开心",
      "image": null,
      "journal_date": "2026.06.23",
      "journal_time": "20:30",
      "created_at": "2026-06-23T12:00:00.000Z",
      "updated_at": "2026-06-23T12:00:00.000Z"
    }
  ]
}
```

## 获取日记详情

### GET `/api/journals/:id?userId=1`

示例：

```text
GET /api/journals/1
```

## 创建日记

### POST `/api/journals`

请求体：

```json
{
  "userId": 1,
  "title": "今天的日记",
  "content": "今天很开心",
  "image": "/uploads/images/1710000000000-12345.jpg",
  "journalDate": "2026.06.23",
  "journalTime": "20:30"
}
```

成功响应：

```json
{
  "code": 0,
  "message": "创建成功",
  "data": {
    "id": 1
  }
}
```

## 更新日记

### PUT `/api/journals/:id`

请求体：

```json
{
  "userId": 1,
  "title": "修改后的标题",
  "content": "修改后的内容",
  "image": null,
  "journalDate": "2026.06.23",
  "journalTime": "21:00"
}
```

## 删除日记

### DELETE `/api/journals/:id?userId=1`

成功响应：

```json
{
  "code": 0,
  "message": "删除成功"
}
```
