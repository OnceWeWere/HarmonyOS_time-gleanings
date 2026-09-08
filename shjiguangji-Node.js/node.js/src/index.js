const express = require('express')
const cors = require('cors')
const path = require('path')
const fs = require('fs')

require('dotenv').config({
  path: path.resolve(__dirname, '../.env')
})

const pool = require('./db')

const app = express()
const port = Number(process.env.PORT || 3000)
const uploadRoot = path.resolve(__dirname, '../uploads')
const imageUploadDir = path.resolve(uploadRoot, 'images')

app.use(cors())
app.use(express.json({ limit: '20mb' }))
app.use('/uploads', express.static(uploadRoot))

if (!fs.existsSync(imageUploadDir)) {
  fs.mkdirSync(imageUploadDir, { recursive: true })
}

app.get('/', (req, res) => {
  res.json({
    message: '拾光记服务启动成功',
    docs: '/api/health'
  })
})

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1')
    res.json({
      code: 0,
      message: 'ok',
      database: 'connected'
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: 'database error',
      error: error.message
    })
  }
})

app.post('/api/users/register', async (req, res) => {
  const { phone, email, password } = req.body

  if (!password || (!phone && !email)) {
    res.status(400).json({
      code: 400,
      message: 'phone 或 email 至少传一个，password 必填'
    })
    return
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO users (phone, email, password) VALUES (?, ?, ?)',
      [phone || null, email || null, password]
    )

    res.json({
      code: 0,
      message: '注册成功',
      data: {
        id: result.insertId,
        phone: phone || null,
        email: email || null
      }
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '注册失败',
      error: error.message
    })
  }
})

app.post('/api/users/login', async (req, res) => {
  const { account, password } = req.body

  if (!account || !password) {
    res.status(400).json({
      code: 400,
      message: 'account 和 password 必填'
    })
    return
  }

  try {
    const isEmail = account.includes('@')
    const [rows] = await pool.query(
      'SELECT id, phone, email, created_at FROM users WHERE (phone = ? OR email = ?) AND password = ? LIMIT 1',
      [account, account, password]
    )

    if (rows.length === 0) {
      if (isEmail) {
        const [existsRows] = await pool.query(
          'SELECT id FROM users WHERE email = ? LIMIT 1',
          [account]
        )

        if (existsRows.length > 0) {
          res.status(401).json({
            code: 401,
            message: '邮箱或密码错误'
          })
          return
        }

        const [result] = await pool.query(
          'INSERT INTO users (phone, email, password) VALUES (?, ?, ?)',
          [null, account, password]
        )

        res.json({
          code: 0,
          message: '邮箱注册并登录成功',
          data: {
            id: result.insertId,
            phone: null,
            email: account
          }
        })
        return
      }

      res.status(401).json({
        code: 401,
        message: '账号或密码错误'
      })
      return
    }

    res.json({
      code: 0,
      message: '登录成功',
      data: rows[0]
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '登录失败',
      error: error.message
    })
  }
})

app.post('/api/uploads/images', async (req, res) => {
  const { fileName, imageBase64 } = req.body

  if (!imageBase64) {
    res.status(400).json({
      code: 400,
      message: 'imageBase64 必填'
    })
    return
  }

  try {
    const cleanBase64 = imageBase64.includes(',') ? imageBase64.split(',').pop() : imageBase64
    const extFromName = path.extname(fileName || '').toLowerCase()
    const ext = ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(extFromName) ? extFromName : '.jpg'
    const savedName = `${Date.now()}-${Math.round(Math.random() * 100000)}${ext}`
    const savedPath = path.join(imageUploadDir, savedName)

    fs.writeFileSync(savedPath, Buffer.from(cleanBase64, 'base64'))

    res.json({
      code: 0,
      message: '上传成功',
      data: {
        path: `/uploads/images/${savedName}`,
        url: `${req.protocol}://${req.get('host')}/uploads/images/${savedName}`
      }
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '上传失败',
      error: error.message
    })
  }
})

app.get('/api/journals', async (req, res) => {
  const { userId } = req.query

  if (!userId) {
    res.status(400).json({
      code: 400,
      message: 'userId 必填'
    })
    return
  }

  try {
    const [rows] = await pool.query(
      'SELECT id, user_id, title, content, image, journal_date, journal_time, created_at, updated_at FROM journals WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    )

    res.json({
      code: 0,
      message: '查询成功',
      data: rows
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '查询失败',
      error: error.message
    })
  }
})

app.get('/api/journals/:id', async (req, res) => {
  const { userId } = req.query

  if (!userId) {
    res.status(400).json({
      code: 400,
      message: 'userId 必填'
    })
    return
  }

  try {
    const [rows] = await pool.query(
      'SELECT id, user_id, title, content, image, journal_date, journal_time, created_at, updated_at FROM journals WHERE id = ? AND user_id = ? LIMIT 1',
      [req.params.id, userId]
    )

    if (rows.length === 0) {
      res.status(404).json({
        code: 404,
        message: '日记不存在'
      })
      return
    }

    res.json({
      code: 0,
      message: '查询成功',
      data: rows[0]
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '查询失败',
      error: error.message
    })
  }
})

app.post('/api/journals', async (req, res) => {
  const { userId, title, content, image, journalDate, journalTime } = req.body

  if (!userId || !title) {
    res.status(400).json({
      code: 400,
      message: 'userId 和 title 必填'
    })
    return
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO journals (user_id, title, content, image, journal_date, journal_time) VALUES (?, ?, ?, ?, ?, ?)',
      [userId || null, title, content || '', image || null, journalDate || null, journalTime || null]
    )

    res.json({
      code: 0,
      message: '创建成功',
      data: {
        id: result.insertId
      }
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '创建失败',
      error: error.message
    })
  }
})

app.put('/api/journals/:id', async (req, res) => {
  const { userId, title, content, image, journalDate, journalTime } = req.body

  if (!userId || !title) {
    res.status(400).json({
      code: 400,
      message: 'userId 和 title 必填'
    })
    return
  }

  try {
    const [result] = await pool.query(
      'UPDATE journals SET title = ?, content = ?, image = ?, journal_date = ?, journal_time = ? WHERE id = ? AND user_id = ?',
      [title, content || '', image || null, journalDate || null, journalTime || null, req.params.id, userId]
    )

    if (result.affectedRows === 0) {
      res.status(404).json({
        code: 404,
        message: '日记不存在'
      })
      return
    }

    res.json({
      code: 0,
      message: '更新成功'
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '更新失败',
      error: error.message
    })
  }
})

app.delete('/api/journals/:id', async (req, res) => {
  const { userId } = req.query

  if (!userId) {
    res.status(400).json({
      code: 400,
      message: 'userId 必填'
    })
    return
  }

  try {
    const [result] = await pool.query('DELETE FROM journals WHERE id = ? AND user_id = ?', [req.params.id, userId])

    if (result.affectedRows === 0) {
      res.status(404).json({
        code: 404,
        message: '日记不存在'
      })
      return
    }

    res.json({
      code: 0,
      message: '删除成功'
    })
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: '删除失败',
      error: error.message
    })
  }
})

app.listen(port, '0.0.0.0', () => {
  console.log(`拾光记服务已启动：http://0.0.0.0:${port}`)
  console.log(`本机访问：http://localhost:${port}`)
})
