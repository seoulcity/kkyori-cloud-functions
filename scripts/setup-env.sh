#!/bin/bash

# KKYORI Cloud Functions 환경 설정 스크립트

set -e

echo "🚀 KKYORI Cloud Functions 환경 설정"
echo "=================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "프로젝트 루트: $PROJECT_ROOT"

# 1. Go 설치 확인
echo ""
log_info "Go 설치 확인 중..."
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | cut -d ' ' -f 3)
    log_success "Go 설치됨: $GO_VERSION"
    
    # Go 버전 확인 (1.23.0 이상)
    REQUIRED_VERSION="1.23"
    CURRENT_VERSION=$(echo $GO_VERSION | sed 's/go//' | cut -d '.' -f 1,2)
    
    if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]]; then
        log_success "Go 버전 요구사항 충족 (>= 1.23.0)"
    else
        log_warning "Go 버전이 낮습니다. 1.23.0 이상 권장"
    fi
else
    log_error "Go가 설치되지 않았습니다"
    log_info "Go 설치: https://golang.org/doc/install"
    exit 1
fi

# 2. Google Cloud CLI 설치 확인
echo ""
log_info "Google Cloud CLI 확인 중..."
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(Google Cloud SDK)" 2>/dev/null || echo "unknown")
    log_success "Google Cloud CLI 설치됨: $GCLOUD_VERSION"
    
    # 로그인 확인
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
        ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        log_success "인증됨: $ACTIVE_ACCOUNT"
    else
        log_warning "Google Cloud에 로그인되지 않았습니다"
        log_info "로그인: gcloud auth login"
    fi
    
    # 프로젝트 설정 확인
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ "$CURRENT_PROJECT" = "kkyori-voca" ]; then
        log_success "프로젝트 설정됨: $CURRENT_PROJECT"
    else
        log_warning "프로젝트가 kkyori-voca로 설정되지 않았습니다 (현재: $CURRENT_PROJECT)"
        log_info "설정: gcloud config set project kkyori-voca"
    fi
else
    log_error "Google Cloud CLI가 설치되지 않았습니다"
    log_info "설치: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# 3. 환경 변수 확인
echo ""
log_info "환경 변수 확인 중..."

# .env 파일 확인
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    log_success ".env 파일 발견"
    source "$ENV_FILE"
else
    log_warning ".env 파일이 없습니다"
    log_info ".env.example을 복사하여 .env를 만드세요"
    
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        read -p "지금 .env.example을 복사하시겠습니까? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
            log_success ".env 파일이 생성되었습니다"
            log_warning "OpenAI API 키를 설정해주세요"
        fi
    fi
fi

# OpenAI API 키 확인
if [ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "your-openai-api-key-here" ]; then
    log_success "OpenAI API 키 설정됨"
else
    log_warning "OpenAI API 키가 설정되지 않았습니다"
    log_info "Whisper 함수를 사용하려면 OPENAI_API_KEY 환경 변수가 필요합니다"
fi

# 4. 의존성 설치
echo ""
log_info "Go 모듈 의존성 확인 중..."

for func_dir in "$PROJECT_ROOT/functions"/*/; do
    if [ -f "$func_dir/go.mod" ]; then
        func_name=$(basename "$func_dir")
        log_info "$func_name 의존성 확인 중..."
        
        cd "$func_dir"
        if go mod download && go mod verify; then
            log_success "$func_name 의존성 준비됨"
        else
            log_error "$func_name 의존성 설치 실패"
        fi
        cd - > /dev/null
    fi
done

# 5. 필수 도구 확인
echo ""
log_info "추가 도구 확인 중..."

# jq 확인 (JSON 파싱용)
if command -v jq &> /dev/null; then
    log_success "jq 설치됨"
else
    log_warning "jq가 설치되지 않았습니다 (JSON 파싱용)"
    log_info "설치: brew install jq (macOS) 또는 apt install jq (Ubuntu)"
fi

# curl 확인
if command -v curl &> /dev/null; then
    log_success "curl 사용 가능"
else
    log_warning "curl이 설치되지 않았습니다"
fi

# 6. 배포 스크립트 실행 권한 확인
echo ""
log_info "배포 스크립트 권한 확인 중..."

DEPLOY_SCRIPTS=(
    "$PROJECT_ROOT/scripts/deploy-all.sh"
    "$PROJECT_ROOT/scripts/local-test.sh"
    "$PROJECT_ROOT/functions/whisper-go/deploy.sh"
    "$PROJECT_ROOT/functions/healthcheck-go/deploy.sh"
)

for script in "${DEPLOY_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            log_success "$(basename "$script") 실행 가능"
        else
            log_warning "$(basename "$script") 실행 권한 없음"
            chmod +x "$script"
            log_success "$(basename "$script") 실행 권한 추가됨"
        fi
    else
        log_warning "$(basename "$script") 파일이 없습니다"
    fi
done

# 7. 설정 요약
echo ""
echo "🎯 설정 요약"
echo "==========="
echo "Go 버전: $(go version | cut -d ' ' -f 3)"
echo "Google Cloud 프로젝트: $(gcloud config get-value project 2>/dev/null || echo '미설정')"
echo "활성 계정: $(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 || echo '미인증')"
echo "OpenAI API 키: $([ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "your-openai-api-key-here" ] && echo '✅ 설정됨' || echo '❌ 미설정')"

# 8. 다음 단계 안내
echo ""
echo "🚀 다음 단계"
echo "==========="
echo "1. 로컬 테스트:"
echo "   ./scripts/local-test.sh whisper 8080"
echo "   ./scripts/local-test.sh healthcheck 8081"
echo ""
echo "2. 개별 함수 배포:"
echo "   cd functions/whisper-go && ./deploy.sh"
echo "   cd functions/healthcheck-go && ./deploy.sh"
echo ""
echo "3. 전체 배포:"
echo "   ./scripts/deploy-all.sh"
echo ""
echo "4. 헬스체크:"
echo "   curl https://healthcheck-go-444846167409.asia-northeast3.run.app"

log_success "환경 설정 완료!" 