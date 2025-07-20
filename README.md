# KKYORI Cloud Functions

🎯 **KKYORI Voice Practice App의 백엔드 Cloud Functions**

이 저장소는 KKYORI 영어 발음 연습 앱의 백엔드 서비스를 담당하는 Google Cloud Functions들을 관리합니다.

## 🏗️ **아키텍처**

```
KKYORI Cloud Functions
├── functions/
│   ├── whisper-go/              # 음성 분석 API (OpenAI Whisper)
│   ├── healthcheck-go/          # 서비스 상태 확인 API
│   └── shared/                  # 공통 설정
├── scripts/                     # 배포 및 유틸리티 스크립트
├── docs/                        # 문서
└── .github/workflows/           # CI/CD 파이프라인
```

## 🚀 **배포된 서비스**

### 1. **Whisper 음성 분석 API**

- **URL**: `https://whisper-transcribe-go-444846167409.asia-northeast3.run.app`
- **기능**: 음성 파일을 텍스트로 변환 (타임스탬프 포함)
- **기술**: Go + OpenAI Whisper API
- **메모리**: 1GiB | **타임아웃**: 300초

### 2. **HealthCheck API**

- **URL**: `https://healthcheck-go-444846167409.asia-northeast3.run.app`
- **기능**: 서비스 상태 및 가동시간 모니터링
- **기술**: Go + Cloud Functions Framework
- **메모리**: 256MiB | **타임아웃**: 30초

## 📱 **클라이언트 연동**

### Flutter 앱에서 사용하는 방법:

```dart
// 음성 분석
final result = await VoiceAnalysisService.analyzeVoice(
  audioFilePath: audioPath,
  language: 'en',
);

// 헬스체크
final isHealthy = await VoiceAnalysisService.checkHealthStatus();
```

### REST API 직접 호출:

```bash
# 헬스체크
curl https://healthcheck-go-444846167409.asia-northeast3.run.app

# 음성 분석 (바이너리 파일 업로드)
curl -X POST https://whisper-transcribe-go-444846167409.asia-northeast3.run.app \
  -H "Content-Type: audio/mp4" \
  --data-binary @your-audio.m4a
```

## 🛠️ **개발 환경 설정**

### 1. 사전 요구사항

```bash
# Go 설치 (1.23.0+)
go version

# Google Cloud CLI 설치 및 인증
gcloud auth login
gcloud config set project kkyori-voca
```

### 2. 환경 변수 설정

```bash
# OpenAI API 키 설정 (Whisper 함수용)
export OPENAI_API_KEY='your-openai-api-key'

# Google Cloud 설정
export GOOGLE_CLOUD_PROJECT='kkyori-voca'
export GOOGLE_CLOUD_REGION='asia-northeast3'
```

### 3. 로컬 테스트

```bash
# Whisper 함수 로컬 실행
./scripts/local-test.sh whisper 8080

# HealthCheck 함수 로컬 실행
./scripts/local-test.sh healthcheck 8081
```

## 🚀 **배포**

### 개별 함수 배포

```bash
# Whisper 함수 배포
cd functions/whisper-go
./deploy.sh

# HealthCheck 함수 배포
cd functions/healthcheck-go
./deploy.sh
```

### 전체 함수 일괄 배포

```bash
./scripts/deploy-all.sh
```

## 📊 **모니터링 & 로그**

```bash
# 실행 로그 확인
gcloud logging read "resource.type=cloud_run_revision" --limit=10

# 빌드 로그 확인
gcloud logging read "resource.type=build" --limit=10
```

## 🧪 **테스트**

```bash
# 통합 테스트 실행
cd tests
./run-integration-tests.sh

# API 응답 확인
curl -s https://healthcheck-go-444846167409.asia-northeast3.run.app | jq
```

## 📈 **성능 & 비용**

| 함수        | 응답시간 | 월 예상비용 | 동시처리       |
| ----------- | -------- | ----------- | -------------- |
| Whisper     | 10-60초  | $20-50      | 10개 인스턴스  |
| HealthCheck | ~100ms   | $1-5        | 100개 인스턴스 |

## 🔧 **기술 스택**

- **런타임**: Go 1.23.0
- **프레임워크**: Google Cloud Functions Framework
- **배포**: Cloud Run Functions (`gcloud run deploy`)
- **외부 API**: OpenAI Whisper API
- **모니터링**: Google Cloud Logging

## 📚 **문서**

- [📖 배포 가이드](docs/DEPLOYMENT_GUIDE.md)
- [🔧 API 참조](docs/API_REFERENCE.md)
- [❗ 문제 해결](docs/TROUBLESHOOTING.md)

## 🤝 **기여하기**

1. **Fork** 이 저장소
2. **브랜치 생성**: `git checkout -b feature/new-function`
3. **변경사항 커밋**: `git commit -m 'Add new function'`
4. **브랜치 푸시**: `git push origin feature/new-function`
5. **Pull Request 생성**

## 📞 **지원**

- **이슈 리포트**: [GitHub Issues](https://github.com/your-org/kkyori-cloud-functions/issues)
- **문의**: 프로젝트 담당자에게 연락

## 📄 **라이선스**

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

**🎯 KKYORI** - AI 기반 영어 발음 연습의 혁신
