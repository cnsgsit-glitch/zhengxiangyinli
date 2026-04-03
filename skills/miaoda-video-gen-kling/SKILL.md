# SKILL.md - 可灵AI (Kling AI) 视频生成

使用快手可灵AI生成视频。支持文生视频、图生视频。

## 触发词
生成视频、AI视频、视频生成、可灵、kling

## 使用前提
1. 拥有可灵AI账号
2. 在开发者平台获取 Access Key + Secret Key：https://app.klingai.com/cn/dev/api-key
3. 账号有足够的资源包（新用户有初始credits）

## 认证方式

可灵AI API 使用 JWT 认证，流程：
1. AccessKey + SecretKey → 用 HS256 算法生成 JWT Token
2. Header 里放 `Authorization: Bearer <JWT Token>`

### JWT Token 生成示例 (Python)
```python
import jwt
import time

ak = "你的AccessKey"
sk = "你的SecretKey"

headers = {"alg": "HS256", "typ": "JWT"}
payload = {
    "iss": ak,
    "exp": int(time.time()) + 1800,  # 30分钟有效
    "nbf": int(time.time()) - 5
}

token = jwt.encode(payload, sk, headers=headers)
# 使用: Authorization: Bearer <token>
```

## API 域名
- 中国区服务器：`https://api-beijing.klingai.com`

## 使用方法

### 生成视频
告诉我：
- 视频内容描述（prompt，英文效果更好）
- 时长（5秒/10秒/15秒）
- 宽高比（横屏16:9/竖屏9:16）

## API调用示例

### 查询账户余额
```bash
curl -X GET "https://api-beijing.klingai.com/account/costs?start_time=1704067200000&end_time=1735689600000" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json"
```

### 文生视频
```bash
curl -X POST "https://api-beijing.klingai.com/v1/videos/generations" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kling-v1-5",
    "prompt": "A professional Chinese business consultant in glasses speaking to camera",
    "duration": 5,
    "aspect_ratio": "16:9"
  }'
```

### 图生视频
```bash
curl -X POST "https://api-beijing.klingai.com/v1/images/generations" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kling-v1-5",
    "prompt": "The person starts walking",
    "image_url": "https://example.com/image.jpg"
  }'
```

## 参数说明

### 文生视频
| 参数 | 说明 | 必填 | 默认值 |
|------|------|------|--------|
| model | 模型版本 | 否 | kling-v1-5 |
| prompt | 视频描述（英文效果更好） | 是 | - |
| duration | 时长（5/10/15秒） | 否 | 5 |
| aspect_ratio | 宽高比 (16:9, 9:16) | 否 | 16:9 |
| mode | 生成模式 | 否 | standard |

### 图生视频
| 参数 | 说明 | 必填 | 默认值 |
|------|------|------|--------|
| model | 模型版本 | 否 | kling-v1-5 |
| prompt | 动作描述 | 是 | - |
| image_url | 参考图URL | 是 | - |
| duration | 时长 | 否 | 5 |

## 错误码
- `0`: 成功
- `1000/1001/1002`: 认证失败
- `1102`: 余额不足
- `1103`: 无权限

## 注意事项
1. 视频生成需要等待（异步），通常30秒-2分钟
2. 英文prompt效果通常优于中文
3. 生成的视频可在官网下载和使用
4. 视频生成费用：约 0.9-1.2 credits/秒
