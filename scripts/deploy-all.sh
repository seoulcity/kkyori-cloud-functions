#!/bin/bash

# 모든 Cloud Functions 배포 스크립트

set -e

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 공통 설정 로드
if [ -f "functions/shared/config.env" ]; then
    echo "📋 Loading configuration..."
    export $(grep -v '^#' functions/shared/config.env | xargs)
else
    echo "❌ Error: functions/shared/config.env not found"
    exit 1
fi

echo "🚀 Deploying All Cloud Functions..."
echo "📍 Project: $GOOGLE_CLOUD_PROJECT"
echo "📍 Region: $GOOGLE_CLOUD_REGION"
echo ""

# 함수 배포 순서 (healthcheck -> whisper)
FUNCTIONS=("healthcheck-go" "whisper-go")
DEPLOYED_FUNCTIONS=()
FAILED_FUNCTIONS=()

for FUNCTION_DIR in "${FUNCTIONS[@]}"; do
    echo "================================================"
    echo "🔨 Deploying $FUNCTION_DIR..."
    echo "================================================"
    
    if [ -d "functions/$FUNCTION_DIR" ]; then
        cd "functions/$FUNCTION_DIR"
        
        # 배포 실행
        if ./deploy.sh; then
            echo "✅ $FUNCTION_DIR deployment successful"
            DEPLOYED_FUNCTIONS+=("$FUNCTION_DIR")
        else
            echo "❌ $FUNCTION_DIR deployment failed"
            FAILED_FUNCTIONS+=("$FUNCTION_DIR")
        fi
        
        cd "$PROJECT_ROOT"
        echo ""
    else
        echo "❌ Directory functions/$FUNCTION_DIR not found"
        FAILED_FUNCTIONS+=("$FUNCTION_DIR")
    fi
done

# 배포 결과 요약
echo "================================================"
echo "📊 Deployment Summary"
echo "================================================"

if [ ${#DEPLOYED_FUNCTIONS[@]} -gt 0 ]; then
    echo "✅ Successfully deployed functions:"
    for func in "${DEPLOYED_FUNCTIONS[@]}"; do
        echo "  • $func"
    done
    echo ""
fi

if [ ${#FAILED_FUNCTIONS[@]} -gt 0 ]; then
    echo "❌ Failed to deploy functions:"
    for func in "${FAILED_FUNCTIONS[@]}"; do
        echo "  • $func"
    done
    echo ""
    exit 1
fi

echo "🎉 All functions deployed successfully!"
echo ""
echo "🌐 Function URLs:"
echo "  • HealthCheck: https://$GOOGLE_CLOUD_REGION-$GOOGLE_CLOUD_PROJECT.cloudfunctions.net/$HEALTHCHECK_FUNCTION_NAME"
echo "  • Whisper: https://$GOOGLE_CLOUD_REGION-$GOOGLE_CLOUD_PROJECT.cloudfunctions.net/$WHISPER_FUNCTION_NAME" 