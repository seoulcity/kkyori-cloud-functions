#!/bin/bash

# 로컬 테스트 스크립트

set -e

# 사용법 출력
show_usage() {
    echo "Usage: $0 <function-name> [port]"
    echo ""
    echo "Available functions:"
    echo "  whisper      - Whisper transcription function"
    echo "  healthcheck  - Health check function"
    echo ""
    echo "Examples:"
    echo "  $0 whisper 8080"
    echo "  $0 healthcheck 8081"
    echo ""
}

# 인수 확인
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

FUNCTION_NAME=$1
PORT=${2:-8080}

# 함수별 디렉토리 매핑
case $FUNCTION_NAME in
    "whisper")
        FUNCTION_DIR="whisper-go"
        ;;
    "healthcheck")
        FUNCTION_DIR="healthcheck-go"
        ;;
    *)
        echo "❌ Unknown function: $FUNCTION_NAME"
        show_usage
        exit 1
        ;;
esac

echo "🧪 Starting local test for $FUNCTION_NAME..."
echo "📍 Directory: $FUNCTION_DIR"
echo "📍 Port: $PORT"
echo ""

# 함수 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ ! -d "$PROJECT_ROOT/functions/$FUNCTION_DIR" ]; then
    echo "❌ Directory functions/$FUNCTION_DIR not found"
    exit 1
fi

cd "$PROJECT_ROOT/functions/$FUNCTION_DIR"

# 환경변수 설정
export PORT=$PORT
export FUNCTIONS_FRAMEWORK_TARGET=$(grep -o 'functions.HTTP("[^"]*"' main.go | cut -d'"' -f2)

# Whisper 함수의 경우 OpenAI API 키 필요
if [ "$FUNCTION_NAME" = "whisper" ]; then
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "❌ Error: OPENAI_API_KEY environment variable is required for whisper function"
        echo "Please set your OpenAI API key:"
        echo "export OPENAI_API_KEY='your-api-key-here'"
        exit 1
    fi
    echo "✅ OpenAI API key found"
fi

# 의존성 설치
echo "📦 Installing dependencies..."
go mod tidy

# 로컬 서버 실행
echo "🚀 Starting local server..."
echo "🌐 Server will be available at: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

go run main.go 