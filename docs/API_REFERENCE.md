# API Reference

KKYORI Cloud Functions API 완전 참조 가이드

## 🎯 Base URLs

- **Production**: `https://{function-name}-444846167409.asia-northeast3.run.app`
- **Region**: `asia-northeast3` (Seoul)
- **Project**: `kkyori-voca`

## 📋 Available APIs

### 1. HealthCheck API

#### Endpoint

```
GET https://healthcheck-go-444846167409.asia-northeast3.run.app
```

#### Description

서비스 상태 및 가동시간을 확인합니다.

#### Request

- **Method**: `GET`
- **Headers**: 없음 필요
- **Body**: 없음

#### Response

```json
{
  "status": "healthy",
  "timestamp": "2025-07-20T00:23:08Z",
  "service": "kkyori-voca-api",
  "version": "1.0.0",
  "region": "asia-northeast3",
  "uptime": "2h15m30s"
}
```

#### Response Fields

| Field       | Type   | Description                              |
| ----------- | ------ | ---------------------------------------- |
| `status`    | string | 서비스 상태 ("healthy" 또는 "unhealthy") |
| `timestamp` | string | 응답 생성 시간 (ISO 8601)                |
| `service`   | string | 서비스 이름                              |
| `version`   | string | 서비스 버전                              |
| `region`    | string | 배포 지역                                |
| `uptime`    | string | 서비스 가동시간                          |

#### Status Codes

- `200`: 서비스 정상
- `500`: 서비스 오류

#### cURL Example

```bash
curl -X GET https://healthcheck-go-444846167409.asia-northeast3.run.app
```

---

### 2. Whisper 음성 분석 API

#### Endpoint

```
POST https://whisper-transcribe-go-444846167409.asia-northeast3.run.app
```

#### Description

음성 파일을 텍스트로 변환하고 타임스탬프 정보를 제공합니다.

#### Request

- **Method**: `POST`
- **Headers**:
  - `Content-Type: audio/mp4` (또는 지원되는 오디오 타입)
- **Body**: 바이너리 오디오 데이터

#### Supported Audio Formats

- `audio/mp4` (.m4a)
- `audio/mpeg` (.mp3)
- `audio/wav` (.wav)
- `audio/flac` (.flac)

#### File Size Limits

- **최대 크기**: 25MB
- **최대 길이**: 약 25분 (비트레이트에 따라)

#### Response (Success)

```json
{
  "success": true,
  "transcription": {
    "text": "Hello, how are you today?",
    "language": "en",
    "duration": 3.2,
    "words": [],
    "segments": [
      {
        "id": 0,
        "text": "Hello, how are you today?",
        "start": 0.0,
        "end": 3.2
      }
    ]
  },
  "timestamp": "2025-07-20T00:23:08Z"
}
```

#### Response (Error)

```json
{
  "success": false,
  "error": "Error description",
  "details": "Detailed error information",
  "timestamp": "2025-07-20T00:23:08Z"
}
```

#### Response Fields (Success)

| Field                    | Type    | Description                      |
| ------------------------ | ------- | -------------------------------- |
| `success`                | boolean | 요청 성공 여부                   |
| `transcription`          | object  | 전사 결과 객체                   |
| `transcription.text`     | string  | 전사된 텍스트                    |
| `transcription.language` | string  | 감지된 언어 코드                 |
| `transcription.duration` | number  | 오디오 길이 (초)                 |
| `transcription.words`    | array   | 단어별 타임스탬프 (현재 빈 배열) |
| `transcription.segments` | array   | 세그먼트별 타임스탬프            |
| `timestamp`              | string  | 응답 생성 시간                   |

#### Segment Object

| Field   | Type   | Description     |
| ------- | ------ | --------------- |
| `id`    | number | 세그먼트 ID     |
| `text`  | string | 세그먼트 텍스트 |
| `start` | number | 시작 시간 (초)  |
| `end`   | number | 종료 시간 (초)  |

#### Status Codes

- `200`: 전사 성공
- `400`: 잘못된 요청 (파일 형식, 크기 등)
- `500`: 서버 오류
- `503`: 서비스 일시 불가

#### cURL Example

```bash
curl -X POST https://whisper-transcribe-go-444846167409.asia-northeast3.run.app \
  -H "Content-Type: audio/mp4" \
  --data-binary @your-audio-file.m4a
```

#### Python Example

```python
import requests

url = "https://whisper-transcribe-go-444846167409.asia-northeast3.run.app"
headers = {"Content-Type": "audio/mp4"}

with open("audio.m4a", "rb") as f:
    response = requests.post(url, headers=headers, data=f)

if response.status_code == 200:
    result = response.json()
    if result["success"]:
        print("Transcription:", result["transcription"]["text"])
    else:
        print("Error:", result["error"])
```

#### JavaScript Example

```javascript
const audioFile = document.getElementById("audioInput").files[0];

fetch("https://whisper-transcribe-go-444846167409.asia-northeast3.run.app", {
  method: "POST",
  headers: {
    "Content-Type": "audio/mp4",
  },
  body: audioFile,
})
  .then((response) => response.json())
  .then((data) => {
    if (data.success) {
      console.log("Transcription:", data.transcription.text);
    } else {
      console.error("Error:", data.error);
    }
  });
```

## 🚨 Error Handling

### Common Error Codes

#### 400 Bad Request

```json
{
  "success": false,
  "error": "Invalid audio format",
  "details": "Supported formats: mp4, mp3, wav, flac",
  "timestamp": "2025-07-20T00:23:08Z"
}
```

#### 413 Payload Too Large

```json
{
  "success": false,
  "error": "File too large",
  "details": "Maximum file size is 25MB",
  "timestamp": "2025-07-20T00:23:08Z"
}
```

#### 500 Internal Server Error

```json
{
  "success": false,
  "error": "OpenAI API error",
  "details": "Transcription service temporarily unavailable",
  "timestamp": "2025-07-20T00:23:08Z"
}
```

### Rate Limits

- **Whisper API**: 10개 동시 요청
- **HealthCheck API**: 100개 동시 요청
- **타임아웃**: Whisper 300초, HealthCheck 30초

## 🔐 Authentication

현재 모든 API는 공개 액세스입니다. 인증이 필요하지 않습니다.

## 📊 Monitoring

### Health Check URL

API 상태를 모니터링하려면 HealthCheck 엔드포인트를 주기적으로 호출하세요:

```bash
curl -s https://healthcheck-go-444846167409.asia-northeast3.run.app | jq '.status'
```

### Response Time Guidelines

- **HealthCheck**: < 200ms
- **Whisper**: 10-60초 (파일 크기에 따라)

## 🔄 API Versioning

현재 API 버전: `v1` (경로에 버전 없음)

향후 버전 업데이트 시:

- `v2` API: `/v2/` 경로 추가 예정
- 기존 API: 최소 6개월 하위 호환성 유지

## 📞 Support

- **문제 신고**: [GitHub Issues](https://github.com/your-org/kkyori-cloud-functions/issues)
- **API 상태**: [Status Page](https://status.kkyori.com) (예정)
- **문의**: api-support@kkyori.com
