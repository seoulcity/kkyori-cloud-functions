#!/bin/bash

# HealthCheck 함수 배포 스크립트 (Cloud Run Functions)

set -e

echo "🚀 Deploying HealthCheck Function (Cloud Run)..."

# 프로젝트 설정
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-"kkyori-voca"}
REGION=${GOOGLE_CLOUD_REGION:-"asia-northeast3"}
FUNCTION_NAME="healthcheck-go"

echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Function Name: $FUNCTION_NAME"

# 함수 배포 (Cloud Run Functions 방식)
echo "🔨 Deploying function with Cloud Run..."
gcloud run deploy $FUNCTION_NAME \
    --source . \
    --function HealthCheck \
    --base-image go123 \
    --region=$REGION \
    --allow-unauthenticated \
    --memory=256Mi \
    --timeout=30s \
    --max-instances=100 \
    --set-env-vars="SERVICE_VERSION=1.0.0" \
    --project=$PROJECT_ID

echo "✅ Deployment completed!"
echo "🌐 Function URL: https://$FUNCTION_NAME-$PROJECT_ID-$REGION.run.app"
echo ""
echo "🧪 Test the function:"
echo "curl https://$FUNCTION_NAME-$PROJECT_ID-$REGION.run.app" 