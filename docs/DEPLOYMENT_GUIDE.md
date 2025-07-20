# Go Cloud Functions 배포 가이드

이 문서는 kkyori_mobile 프로젝트의 Go Cloud Functions 배포 방법을 설명합니다.

## 📋 **배포된 함수 목록**

### 1. **HealthCheck 함수**

- **URL**: `https://healthcheck-go-444846167409.asia-northeast3.run.app`
- **기능**: 서비스 상태 확인, 가동시간 모니터링
- **메모리**: 256MiB
- **타임아웃**: 30초

### 2. **Whisper 함수 (타임스탬프 지원)**

- **URL**: `https://whisper-transcribe-go-444846167409.asia-northeast3.run.app`
- **기능**: OpenAI Whisper API를 사용한 음성 → 텍스트 변환 (기본 타임스탬프 지원)
- **메모리**: 1GiB
- **타임아웃**: 300초 (5분)
- **환경변수**: `OPENAI_API_KEY` 필요

## 🚀 **배포 방법**

### 사전 준비

1. Google Cloud CLI 설치 및 인증
2. 프로젝트 설정: `gcloud config set project kkyori-voca`
3. OpenAI API 키 환경변수 설정

### HealthCheck 함수 배포

```bash
cd functions/healthcheck-go
./deploy.sh
```

### Whisper 함수 배포

```bash
# OpenAI API 키 설정
export OPENAI_API_KEY='your-api-key-here'

cd functions/whisper-go
./deploy.sh
```

## 🔧 **기술 세부사항**

### Go Cloud Functions 구조

- **런타임**: Go 1.23.0
- **프레임워크**: Cloud Functions Framework for Go v1.8.1
- **배포 방식**: Cloud Run Functions (`gcloud run deploy`)
- **네트워킹**: 공용 액세스 허용

### 타임스탬프 지원 현황

- **현재 버전**: 기본 세그먼트 타임스탬프 지원
- **단어별 타임스탬프**: Go 라이브러리 제한으로 현재 미지원
- **세그먼트 타임스탬프**: 전체 텍스트에 대한 기본 세그먼트 제공
- **향후 계획**: Go OpenAI 라이브러리 업데이트 시 완전한 타임스탬프 지원 예정

### 응답 형식

```json
{
  "success": true,
  "transcription": {
    "text": "전사된 텍스트",
    "language": "en",
    "duration": 10.5,
    "words": [], // 현재 빈 배열 (라이브러리 제한)
    "segments": [
      {
        "id": 0,
        "text": "전사된 텍스트",
        "start": 0.0,
        "end": 10.5
      }
    ]
  },
  "timestamp": "2025-07-20T00:23:08Z"
}
```

## 📱 **Flutter 앱 연동**

### API 사용 우선순위

1. **기본 분석**: Go Cloud Functions (whisper-transcribe-go)
2. **타임스탬프 포함 분석**: Go Cloud Functions (동일한 API 사용)
3. **백업**: Legacy Firebase Functions (V2)

### 사용 예시

```dart
// 기본 음성 분석 (Go API)
final result = await VoiceAnalysisService.analyzeVoice(
  audioFilePath: audioPath,
);

// 타임스탬프 포함 분석 (Go API)
final resultWithTimestamps = await VoiceAnalysisService.analyzeVoiceV2(
  audioFilePath: audioPath,
  includeWordTimestamps: true,
);

// 헬스체크
final isHealthy = await VoiceAnalysisService.checkHealthStatus();
```

## 🔍 **테스트 방법**

### HealthCheck 함수 테스트

```bash
curl https://healthcheck-go-444846167409.asia-northeast3.run.app
```

### Whisper 함수 테스트

```bash
curl -X POST https://whisper-transcribe-go-444846167409.asia-northeast3.run.app \
  -H "Content-Type: audio/mp4" \
  --data-binary @your-audio-file.m4a
```

## 🚨 **문제 해결**

### 자주 발생하는 오류

#### 1. 빌드 오류

```
ERROR: build step failed
```

**해결책**:

- `go.mod` 파일 확인
- 의존성 업데이트: `go mod tidy`
- Go 버전 확인 (1.23.0 권장)

#### 2. API 키 오류

```
❌ Error: OPENAI_API_KEY environment variable is not set
```

**해결책**:

```bash
export OPENAI_API_KEY='your-api-key-here'
```

#### 3. 배포 권한 오류

```
ERROR: (gcloud.run.deploy) Permission denied
```

**해결책**:

- Google Cloud 프로젝트 권한 확인
- 올바른 프로젝트 설정: `gcloud config set project kkyori-voca`

### 로그 확인

```bash
# 빌드 로그 확인
gcloud logging read "resource.type=build" --limit=10 --project=kkyori-voca

# 함수 실행 로그 확인
gcloud logging read "resource.type=cloud_run_revision" --limit=10 --project=kkyori-voca
```

## 📈 **성능 및 비용**

### 예상 비용 (월간)

- **HealthCheck**: ~$1-5 (낮은 사용량)
- **Whisper**: ~$20-50 (중간 사용량, OpenAI API 비용 별도)

### 성능 특징

- **HealthCheck**: ~100ms 응답 시간
- **Whisper**: ~10-60초 (파일 크기에 따라)
- **동시 처리**: HealthCheck 100개, Whisper 10개 인스턴스

## 🔄 **업데이트 히스토리**

### 2025-07-20

- ✅ Go Cloud Functions 첫 배포 완료
- ✅ 타임스탬프 기본 지원 추가
- ✅ Flutter 앱 Go API 연동 완료
- ⏳ 단어별 타임스탬프: Go 라이브러리 제한으로 대기 중

### 향후 계획

- [ ] 단어별 타임스탬프 완전 지원 (라이브러리 업데이트 대기)
- [ ] 다국어 지원 확장
- [ ] 오디오 전처리 기능 추가
- [ ] 실시간 스트리밍 전사 지원
