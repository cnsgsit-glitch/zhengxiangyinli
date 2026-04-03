#!/bin/bash
# 可灵AI视频生成工具

# 读取参数
PROMPT=""
MODE="standard"
DURATION=5
ASPECT_RATIO="16:9"
IMAGE_URL=""
API_KEY="${Kling_API_KEY:-}"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --prompt)
            PROMPT="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --aspect_ratio)
            ASPECT_RATIO="$2"
            shift 2
            ;;
        --image_url)
            IMAGE_URL="$2"
            shift 2
            ;;
        --api_key)
            API_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# 检查必要参数
if [ -z "$PROMPT" ]; then
    echo "Error: --prompt is required"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "Error: API key not configured. Set Kling_API_KEY environment variable or pass --api_key"
    exit 1
fi

# 构建请求
API_URL="https://api.klingai.com/v1/videos/generations"

# 如果有图片URL，使用图生视频
if [ -n "$IMAGE_URL" ]; then
    REQUEST_BODY=$(cat <<EOF
{
    "image_url": "$IMAGE_URL",
    "mode": "$MODE",
    "duration": $DURATION
}
EOF
)
else
    REQUEST_BODY=$(cat <<EOF
{
    "prompt": "$PROMPT",
    "mode": "$MODE",
    "duration": $DURATION,
    "aspect_ratio": "$ASPECT_RATIO"
}
EOF
)
fi

# 发送请求
echo "提交视频生成任务..."
echo "Prompt: $PROMPT"
echo "Duration: ${DURATION}s, Aspect: $ASPECT_RATIO"

RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$REQUEST_BODY")

# 解析响应
TASK_ID=$(echo "$RESPONSE" | jq -r '.data.task_id // empty')
CODE=$(echo "$RESPONSE" | jq -r '.code // 0')
MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')

if [ "$CODE" != "0" ] && [ -n "$CODE" ]; then
    echo "Error: $MESSAGE"
    exit 1
fi

if [ -z "$TASK_ID" ]; then
    echo "Error: Failed to get task_id"
    echo "Response: $RESPONSE"
    exit 1
fi

echo "任务提交成功！Task ID: $TASK_ID"
echo "等待视频生成..."

# 轮询获取结果
while true; do
    sleep 5
    STATUS_RESPONSE=$(curl -s "https://api.klingai.com/v1/videos/generations/subtasks/$TASK_ID" \
        -H "Authorization: Bearer $API_KEY")
    
    TASK_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.data.task_status // empty')
    VIDEO_URL=$(echo "$STATUS_RESPONSE" | jq -r '.data.url // empty')
    
    echo "Status: $TASK_STATUS"
    
    if [ "$TASK_STATUS" = "completed" ] && [ -n "$VIDEO_URL" ]; then
        echo "✅ 视频生成完成！"
        echo "下载链接: $VIDEO_URL"
        echo "{\"video_url\": \"$VIDEO_URL\", \"task_id\": \"$TASK_ID\"}"
        break
    elif [ "$TASK_STATUS" = "failed" ]; then
        echo "❌ 视频生成失败"
        echo "$STATUS_RESPONSE"
        exit 1
    fi
    
    # 超时保护（最多等待5分钟）
    ELAPSED=$((ELAPSED + 5))
    if [ $ELAPSED -gt 300 ]; then
        echo "超时，任务可能还在处理中，Task ID: $TASK_ID"
        exit 0
    fi
done
