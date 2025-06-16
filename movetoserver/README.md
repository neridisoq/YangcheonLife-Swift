# YangcheonLife iOS 18+ Live Activity Server

양천생활 iOS 18+ Live Activity 원격 제어를 위한 Node.js 네이티브 서버입니다.

## 특징

- **iOS 18+ 전용**: Apple의 최신 Live Activity 원격 시작/중지/업데이트 기능 지원
- **네이티브 APNs**: Firebase 없이 순수 Apple Push Notification 서비스 사용
- **토큰 관리**: Push-to-Start, Activity Token, APNs Token 통합 관리
- **실시간 제어**: 서버에서 원격으로 Live Activity 생명주기 완전 제어
- **고성능**: Express.js 기반 RESTful API, 압축/보안 미들웨어 포함

## 요구사항

- Node.js 18.0.0 이상
- Apple Developer Account (APNs 인증서)
- iOS 18.0 이상 대상 앱

## 설치

```bash
cd movetoserver
npm install
```

## 설정

1. `.env` 파일 생성:
```bash
cp .env.example .env
```

2. APNs 인증 설정:
   - Apple Developer에서 AuthKey.p8 파일 다운로드
   - `config/` 폴더에 저장
   - `.env`에서 `APNS_KEY_ID`, `APNS_TEAM_ID` 설정

3. 환경변수 설정:
```env
NODE_ENV=development
PORT=3000
APNS_AUTH_KEY_PATH=./config/AuthKey.p8
APNS_KEY_ID=YOUR_KEY_ID
APNS_TEAM_ID=YOUR_TEAM_ID
BUNDLE_ID=com.helgisnw.yangcheonlife
```

## 실행

```bash
# 개발모드
npm run dev

# 프로덕션
npm start
```

## API 엔드포인트

### 토큰 등록

#### Push-to-Start 토큰 등록
```http
POST /api/live-activity/push-to-start
Content-Type: application/json

{
  "type": "push_to_start",
  "token": "device_push_to_start_token",
  "grade": 3,
  "classNumber": 1,
  "bundleId": "com.helgisnw.yangcheonlife",
  "deviceId": "unique_device_id",
  "timestamp": 1703123456
}
```

#### Activity 토큰 등록
```http
POST /api/live-activity/activity-token
Content-Type: application/json

{
  "type": "activity_token",
  "token": "activity_push_token",
  "activityId": "activity_uuid",
  "grade": 3,
  "classNumber": 1,
  "bundleId": "com.helgisnw.yangcheonlife",
  "deviceId": "unique_device_id",
  "timestamp": 1703123456
}
```

### Live Activity 제어 (전체 학교 동시 적용)

#### 원격 시작 (전체 학교)
```http
POST /api/live-activity/start
Content-Type: application/json

{
  "action": "start",
  "data": {
    "currentStatus": "inClass",
    "currentClass": {
      "period": 1,
      "subject": "1교시 시작",
      "startTime": "08:20",
      "endTime": "09:10"
    },
    "alertTitle": "수업 시작",
    "alertBody": "1교시가 시작되었습니다."
  }
}
```

#### 원격 업데이트 (전체 학교)
```http
POST /api/live-activity/update
Content-Type: application/json

{
  "action": "update",
  "data": {
    "currentStatus": "breakTime",
    "alert": {
      "title": "쉬는시간",
      "body": "다음 교시까지 10분 남았습니다."
    }
  }
}
```

#### 원격 종료 (전체 학교)
```http
POST /api/live-activity/end
Content-Type: application/json

{
  "action": "end",
  "data": {
    "dismissalDate": 1703127056,
    "alertTitle": "하교 시간",
    "alertBody": "오늘 수업이 모두 끝났습니다."
  }
}
```

### 조회 API

#### 전체 토큰 조회
```http
GET /api/live-activity/tokens
```

#### 서버 통계
```http
GET /api/live-activity/stats
```

#### 헬스체크
```http
GET /health
```

## 아키텍처

```
전체 학교 iOS 디바이스들 (iOS 18+)
    ↓ (토큰 등록)
Node.js Server
    ↓ (전체 학교 동시 APNs 요청)
Apple Push Notification Service
    ↓ (모든 디바이스 Live Activity 동시 제어)
전체 학교 Live Activity 동시 실행
```

### 토큰 플로우

1. **Push-to-Start Token**: 앱에서 `pushToStartTokenUpdates`로 받은 토큰 등록 (학년반 정보 포함하지만 서버에서는 전체 관리)
2. **Activity Token**: Live Activity 생성시 `pushTokenUpdates`로 받은 토큰 등록
3. **APNs Token**: 일반 디바이스 토큰 등록 (필요시)

### Live Activity 제어 플로우 (전체 학교 동시)

1. **원격 시작**: 모든 Push-to-Start 토큰으로 APNs 동시 전송 → 전체 학교 Live Activity 동시 생성
2. **원격 업데이트**: 모든 Activity 토큰으로 APNs 동시 전송 → 전체 학교 Live Activity 동시 업데이트
3. **원격 종료**: 모든 Activity 토큰으로 APNs 동시 전송 → 전체 학교 Live Activity 동시 종료

## 배포

### 개발환경
```bash
npm run dev
```

### 프로덕션 환경
```bash
# PM2 사용 권장
npm install -g pm2
pm2 start ecosystem.config.js
```

### Docker (선택사항)
```bash
docker build -t yangcheonlife-server .
docker run -p 3000:3000 yangcheonlife-server
```

## 보안

- Helmet.js: 보안 헤더 설정
- CORS: 허용된 오리진만 접근
- 입력 검증: Joi 스키마 검증
- 로깅: Winston으로 모든 요청/에러 로그

## 모니터링

### 로그 파일
- `logs/combined.log`: 모든 로그
- `logs/error.log`: 에러 로그만

### 메트릭
- 등록된 토큰 수
- 반별 디바이스 수
- APNs 전송 성공/실패율
- API 응답시간

## 주의사항

1. **APNs 인증서**: AuthKey.p8 파일은 Git에 커밋하지 마세요
2. **토큰 저장**: 현재는 메모리 저장, 실제 운영시 데이터베이스 사용 필요
3. **스케일링**: 여러 서버 인스턴스 실행시 토큰 동기화 고려
4. **에러 처리**: APNs 실패시 재시도 로직 구현 권장

## 문제해결

### APNs 연결 실패
- AuthKey.p8 파일 경로 확인
- Key ID, Team ID 정확성 확인
- 네트워크 방화벽 설정 확인

### 토큰 등록 실패
- 요청 JSON 스키마 확인
- Bundle ID 일치 확인
- iOS 18+ 디바이스 사용 확인

## 라이센스

MIT License