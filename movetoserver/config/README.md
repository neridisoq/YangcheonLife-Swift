# APNs 인증 설정

이 폴더에 Apple Push Notification 서비스 인증에 필요한 파일들을 저장합니다.

## 필요한 파일

### AuthKey.p8
Apple Developer에서 생성한 APNs 인증 키 파일입니다.

#### 생성 방법:
1. [Apple Developer Console](https://developer.apple.com/account) 접속
2. **Certificates, Identifiers & Profiles** 선택
3. **Keys** 섹션에서 새 키 생성
4. **Apple Push Notifications service (APNs)** 체크
5. 키 생성 후 AuthKey_[KeyID].p8 파일 다운로드
6. 이 폴더에 `AuthKey.p8`로 이름 변경하여 저장

#### 주의사항:
- **이 파일은 절대 Git에 커밋하지 마세요!**
- `.gitignore`에 `*.p8` 추가 권장
- 파일 권한: `chmod 600 AuthKey.p8`

## 환경변수 설정

`.env` 파일에 다음 정보를 설정하세요:

```env
APNS_AUTH_KEY_PATH=./config/AuthKey.p8
APNS_KEY_ID=ABC1234567
APNS_TEAM_ID=DEF8901234
```

### 정보 확인 방법:
- **Key ID**: Apple Developer에서 키 생성시 표시되는 10자리 문자열
- **Team ID**: Apple Developer Account 정보에서 확인 가능한 10자리 문자열

## 보안 권장사항

1. **파일 권한**: 
   ```bash
   chmod 600 AuthKey.p8
   ```

2. **환경 분리**:
   - 개발/프로덕션 환경별로 다른 키 사용
   - 키 순환(rotation) 주기적 실행

3. **백업**:
   - 안전한 위치에 키 파일 백업
   - Apple Developer에서 재다운로드 불가능

## 문제해결

### 인증 실패시 확인사항:
- [ ] AuthKey.p8 파일이 올바른 위치에 있는가?
- [ ] Key ID가 정확한가?
- [ ] Team ID가 정확한가?
- [ ] 파일 권한이 올바른가?
- [ ] Bundle ID가 Apple Developer에 등록되어 있는가?