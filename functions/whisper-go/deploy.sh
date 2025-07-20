#!/bin/bash

# Whisper 함수 배포 스크립트 (Cloud Run Functions)

set -e

echo "🚀 Deploying Whisper Transcription Function (Cloud Run)..."

# config.env 파일 로드
if [ -f "../shared/config.env" ]; then
    echo "📋 Loading configuration from config.env..."
    source ../shared/config.env
fi

# 환경변수 확인
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY environment variable is not set"
    echo "Please set your OpenAI API key:"
    echo "export OPENAI_API_KEY='your-api-key-here'"
    exit 1
else
    echo "✅ OPENAI_API_KEY is configured"
fi

# 프로젝트 설정
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-"kkyori-voca"}
REGION=${GOOGLE_CLOUD_REGION:-"asia-northeast3"}
FUNCTION_NAME="whisper-transcribe-go"

echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Function Name: $FUNCTION_NAME"

# 함수 배포 (Cloud Run Functions 방식)
echo "🔨 Deploying function with Cloud Run..."
gcloud run deploy $FUNCTION_NAME \
    --source . \
    --function TranscribeAudio \
    --base-image go123 \
    --region=$REGION \
    --allow-unauthenticated \
    --memory=1Gi \
    --timeout=300s \
    --max-instances=10 \
    --set-env-vars="OPENAI_API_KEY=$OPENAI_API_KEY" \
    --project=$PROJECT_ID

echo "✅ Deployment completed!"
echo "🌐 Function URL: https://$FUNCTION_NAME-$PROJECT_ID-$REGION.run.app"
echo ""
echo "🧪 Test the function:"
echo "curl -X POST https://$FUNCTION_NAME-$PROJECT_ID-$REGION.run.app \\"
echo "  -H \"Content-Type: audio/mp4\" \\"
echo "  --data-binary @your-audio-file.m4a" 