const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const logger = require('winston');
const http2 = require('http2');
const url = require('url');
const LiveActivityService = require('./LiveActivityService');

// Native Node.js HTTP/2 사용

/**
 * Modern Apple Push Notification Service using native Node.js fetch
 * iOS 18+ Live Activity 원격 제어를 위한 최신 APNs 통신
 * node-apn deprecated 이슈 해결을 위해 native 구현
 */
class APNsService {
  constructor() {
    this.authKey = null;
    this.keyId = process.env.APNS_KEY_ID;
    this.teamId = process.env.APNS_TEAM_ID;
    this.isProduction = process.env.NODE_ENV === 'production';
    
    // Docker 환경에서는 직접 APNs 접근 대신 프록시 사용 고려
    this.apnsUrl = this.isProduction 
      ? 'https://api.push.apple.com'
      : 'https://api.sandbox.push.apple.com';
    
    console.log(`🌐 [APNs] Environment: ${this.isProduction ? 'Production' : 'Sandbox'}`);
    console.log(`🌐 [APNs] Target URL: ${this.apnsUrl}`);
    
    this.initializeAPNs();
  }

  /**
   * APNs 초기화 - JWT 인증키 로드
   */
  initializeAPNs() {
    try {
      const keyPath = process.env.APNS_AUTH_KEY_PATH || path.join(__dirname, '../config/AuthKey.p8');
      
      if (!fs.existsSync(keyPath)) {
        logger.warn('APNs auth key file not found, APNs features disabled', { keyPath });
        return;
      }

      this.authKey = fs.readFileSync(keyPath, 'utf8');
      
      if (!this.keyId || !this.teamId) {
        logger.error('APNs credentials missing in environment variables');
        return;
      }

      logger.info('APNs service initialized successfully', {
        production: this.isProduction,
        keyId: this.keyId,
        teamId: this.teamId,
        apnsUrl: this.apnsUrl
      });
      
    } catch (error) {
      logger.error('Failed to initialize APNs service', { error: error.message });
    }
  }

  /**
   * JWT 토큰 생성 (APNs 인증용)
   */
  generateJWTToken() {
    if (!this.authKey || !this.keyId || !this.teamId) {
      throw new Error('APNs credentials not properly configured');
    }

    const now = Math.floor(Date.now() / 1000);
    
    const payload = {
      iss: this.teamId,
      iat: now,
      exp: now + 3600 // 1시간 후 만료
    };

    return jwt.sign(payload, this.authKey, {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: this.keyId
      }
    });
  }

  /**
   * Live Activity 시작 (전체 학교 동시 시작)
   */
  async startLiveActivity(data = {}) {
    if (!this.isReady()) {
      throw new Error('APNs service not ready');
    }

    try {
      // 전체 학교의 Push-to-Start 토큰들 조회
      const tokens = await LiveActivityService.getAllPushToStartTokens();
      
      if (tokens.length === 0) {
        logger.warn('No push-to-start tokens found for school');
        return { sent: 0, failed: 0 };
      }

      // APNs 페이로드 구성 (애플 공식 표준)
      const payload = this.createStartPayload(data);
      
      const results = await Promise.allSettled(
        tokens.map(tokenInfo => this.sendAPNsNotification(tokenInfo.token, payload, tokenInfo.bundleId))
      );

      const sent = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      logger.info('Live Activity start notifications sent to entire school', {
        sent,
        failed,
        total: tokens.length
      });

      return { sent, failed, total: tokens.length };

    } catch (error) {
      logger.error('Failed to start Live Activity', { error: error.message });
      throw error;
    }
  }

  /**
   * Live Activity 업데이트 (전체 학교 동시 업데이트 - 개별 시간표 데이터 사용)
   */
  async updateLiveActivity(data = {}) {
    if (!this.isReady()) {
      throw new Error('APNs service not ready');
    }

    try {
      // Activity 토큰들 조회 (update는 activity 토큰 사용)
      const { activityTokens } = await LiveActivityService.getAllTokens();
      
      if (activityTokens.length === 0) {
        logger.warn('No activity tokens found for school');
        return { sent: 0, failed: 0 };
      }

      // 🚨 각 토큰별로 개별 시간표 데이터 계산 필요
      const results = await Promise.allSettled(
        activityTokens.map(async (tokenInfo) => {
          // TODO: tokenInfo에서 학년/반 정보 추출 (현재는 저장되지 않음)
          const grade = tokenInfo.grade || null;
          const classNumber = tokenInfo.classNumber || null;
          
          // 개별 시간표 데이터로 페이로드 생성
          const payload = await this.createUpdatePayloadForStudent(grade, classNumber, data);
          
          return this.sendAPNsNotification(tokenInfo.token, payload, tokenInfo.bundleId);
        })
      );

      const sent = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      logger.info('Live Activity update notifications sent to entire school with individual schedule data', {
        sent,
        failed,
        total: activityTokens.length
      });

      return { sent, failed, total: activityTokens.length };

    } catch (error) {
      logger.error('Failed to update Live Activity', { error: error.message });
      throw error;
    }
  }

  /**
   * Live Activity 종료 (전체 학교 동시 종료)
   */
  async endLiveActivity(data = {}) {
    if (!this.isReady()) {
      throw new Error('APNs service not ready');
    }

    try {
      // Activity 토큰들 조회 (end는 activity 토큰 사용)
      const { activityTokens } = await LiveActivityService.getAllTokens();
      
      if (activityTokens.length === 0) {
        logger.warn('No activity tokens found for school');
        return { sent: 0, failed: 0 };
      }

      // APNs 페이로드 구성 (애플 공식 표준)
      const payload = this.createEndPayload(data);
      
      const results = await Promise.allSettled(
        activityTokens.map(tokenInfo => this.sendAPNsNotification(tokenInfo.token, payload, tokenInfo.bundleId))
      );

      const sent = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      logger.info('Live Activity end notifications sent to entire school', {
        sent,
        failed,
        total: activityTokens.length
      });

      return { sent, failed, total: activityTokens.length };

    } catch (error) {
      logger.error('Failed to end Live Activity', { error: error.message });
      throw error;
    }
  }

  /**
   * Live Activity 시작 페이로드 생성 (애플 공식 표준)
   * 🚨 중요: content-state 없음! 앱에서 기존 로직으로 시작하도록 함
   */
  createStartPayload(data) {
    const currentTime = Math.floor(Date.now() / 1000);
    
    return {
      aps: {
        timestamp: currentTime,
        event: 'start',
        'attributes-type': 'ClassActivityAttributes',
        'attributes': {
          schoolId: 'yangcheon'
        },
        // 의도적으로 content-state 제거: 앱에서 기존 로직으로 시작하도록 함
        alert: {
          title: '수업 시작',
          body: '라이브 액티비티가 시작됩니다.',
          sound: 'default'
        },
        // iOS 18+ 전용: 새 토큰 요청
        'input-push-token': 1
      }
    };
  }

  /**
   * Live Activity 업데이트 페이로드 생성 (백그라운드 업데이트용)
   * 🚨 중요: content-state 포함! 백그라운드에서 직접 업데이트하기 위함
   * 🚨 문제: 학년/반 정보가 없어서 개별 시간표 데이터 사용 불가
   */
  createUpdatePayload(data) {
    const currentTime = Math.floor(Date.now() / 1000);
    
    // 🚨 학년/반 정보 없이 일반적인 시간표 데이터 계산 (더미)
    const liveScheduleData = this.calculateCurrentScheduleState();
    
    return {
      aps: {
        timestamp: currentTime,
        event: 'update',
        // 백그라운드 Live Activity 업데이트를 위해 content-state 포함
        'content-state': {
          currentStatus: liveScheduleData.currentStatus,
          currentClass: liveScheduleData.currentClass,
          nextClass: liveScheduleData.nextClass,
          startDate: liveScheduleData.startDate,
          endDate: liveScheduleData.endDate,
          lastUpdated: currentTime
        },
        alert: {
          title: '수업 업데이트',
          body: liveScheduleData.alertMessage || '시간표가 업데이트되었습니다.',
          sound: 'default'
        }
      }
    };
  }
  
  /**
   * 개별 학생용 업데이트 페이로드 생성 (실제 시간표 데이터 사용)
   * 🚨 중요: 학년/반별 실제 시간표 데이터 사용
   */
  async createUpdatePayloadForStudent(grade, classNumber, data) {
    const currentTime = Math.floor(Date.now() / 1000);
    
    // 개별 학생의 실제 시간표 데이터 계산
    const liveScheduleData = await this.calculateCurrentScheduleState(grade, classNumber);
    
    return {
      aps: {
        timestamp: currentTime,
        event: 'update',
        // 개별 학생의 실제 시간표 데이터로 content-state 구성
        'content-state': {
          currentStatus: liveScheduleData.currentStatus,
          currentClass: liveScheduleData.currentClass,
          nextClass: liveScheduleData.nextClass,
          startDate: liveScheduleData.startDate,
          endDate: liveScheduleData.endDate,
          lastUpdated: currentTime
        },
        alert: {
          title: '수업 업데이트',
          body: liveScheduleData.alertMessage || `${grade}학년 ${classNumber}반 시간표가 업데이트되었습니다.`,
          sound: 'default'
        }
      }
    };
  }
  
  /**
   * 현재 시간 기반으로 실시간 시간표 상태 계산
   * 🚨 중요: 서버에서 앱의 기존 로직과 동일한 계산 수행
   * 🚨 문제: 현재는 가짜 데이터! 실제 구현 시 데이터베이스 연동 필요
   */
  async calculateCurrentScheduleState(grade = null, classNumber = null) {
    const now = new Date();
    const koreaTime = new Date(now.getTime() + (9 * 60 * 60 * 1000)); // UTC+9
    
    const hour = koreaTime.getHours();
    const minute = koreaTime.getMinutes();
    const weekday = koreaTime.getDay(); // 0=일요일, 1=월요일, ...
    const weekdayIndex = weekday === 0 ? 6 : weekday - 1; // 월=0, 화=1, ..., 일=6
    
    // 기본 상태
    let currentStatus = 'inClass';
    let currentClass = null;
    let nextClass = null;
    let startDate = Math.floor(now.getTime() / 1000);
    let endDate = Math.floor((now.getTime() + 3600000) / 1000); // 1시간 후
    let alertMessage = '';
    
    // 시간대별 상태 판단 (앱의 TimeUtility 로직과 동일)
    if (hour < 8 || (hour === 8 && minute < 20)) {
      currentStatus = 'beforeSchool';
      alertMessage = '등교 시간입니다.';
    } else if (hour >= 16) {
      currentStatus = 'afterSchool';
      alertMessage = '하교 시간입니다.';
    } else if ((hour === 12 && minute >= 10) || (hour === 13 && minute < 10)) {
      currentStatus = 'lunchTime';
      alertMessage = '점심시간입니다.';
    } else {
      // 수업 중 또는 쉬는시간
      const currentPeriod = this.estimateCurrentPeriod(hour, minute);
      
      if (currentPeriod > 0) {
        currentStatus = 'inClass';
        
        // 🚨 실제 시간표 데이터 조회 필요!
        // TODO: 데이터베이스에서 학년/반별 시간표 조회
        const scheduleData = await this.getScheduleData(grade, classNumber, weekdayIndex);
        const currentSubject = this.findSubjectByPeriod(scheduleData, currentPeriod);
        
        if (currentSubject) {
          currentClass = {
            period: currentPeriod,
            subject: currentSubject.subject,
            classroom: currentSubject.classroom,
            startTime: this.getPeriodStartTime(currentPeriod),
            endTime: this.getPeriodEndTime(currentPeriod)
          };
          
          alertMessage = `${currentPeriod}교시 ${currentSubject.subject} 수업이 진행 중입니다.`;
        } else {
          // 시간표 데이터가 없으면 기본값
          currentClass = {
            period: currentPeriod,
            subject: `${currentPeriod}교시`,
            classroom: '교실',
            startTime: this.getPeriodStartTime(currentPeriod),
            endTime: this.getPeriodEndTime(currentPeriod)
          };
          
          alertMessage = `${currentPeriod}교시 수업이 진행 중입니다.`;
        }
        
        // 다음 교시 정보
        if (currentPeriod < 7) {
          const nextSubject = this.findSubjectByPeriod(scheduleData, currentPeriod + 1);
          if (nextSubject) {
            nextClass = {
              period: currentPeriod + 1,
              subject: nextSubject.subject,
              classroom: nextSubject.classroom,
              startTime: this.getPeriodStartTime(currentPeriod + 1),
              endTime: this.getPeriodEndTime(currentPeriod + 1)
            };
          }
        }
        
        // 현재 교시의 시작/종료 시간 설정
        const periodStart = this.getPeriodStartTimeInSeconds(currentPeriod, koreaTime);
        const periodEnd = this.getPeriodEndTimeInSeconds(currentPeriod, koreaTime);
        
        startDate = Math.floor(periodStart / 1000);
        endDate = Math.floor(periodEnd / 1000);
      } else {
        currentStatus = 'breakTime';
        alertMessage = '쉬는시간입니다.';
      }
    }
    
    // 주말 처리
    if (weekday === 0 || weekday === 6) {
      currentStatus = 'afterSchool';
      currentClass = null;
      nextClass = null;
      alertMessage = '주말입니다.';
    }
    
    return {
      currentStatus,
      currentClass,
      nextClass,
      startDate,
      endDate,
      alertMessage
    };
  }
  
  /**
   * 시간표 데이터 조회 (데이터베이스 연동 필요)
   * 🚨 현재는 더미 구현! 실제로는 데이터베이스에서 조회해야 함
   */
  async getScheduleData(grade, classNumber, weekdayIndex) {
    // TODO: 실제 구현 시 데이터베이스에서 조회
    // const scheduleData = await database.getSchedule(grade, classNumber, weekdayIndex);
    
    console.log(`📚 [APNs] TODO: 데이터베이스에서 시간표 조회 필요 - ${grade}학년 ${classNumber}반 ${weekdayIndex}요일`);
    
    // 현재는 빈 배열 반환 (더미 데이터)
    // 실제로는 comsi.helgisnw.metestfile.json과 같은 형태의 데이터 반환
    return [];
  }
  
  /**
   * 특정 교시의 과목 정보 조회
   */
  findSubjectByPeriod(scheduleData, period) {
    if (!scheduleData || scheduleData.length === 0) {
      return null;
    }
    
    // scheduleData는 해당 요일의 시간표 배열
    const subject = scheduleData.find(item => item.classTime === period || item.period === period);
    
    if (subject) {
      return {
        subject: subject.subject,
        classroom: subject.classroom || '교실',
        teacher: subject.teacher || ''
      };
    }
    
    return null;
  }
  
  /**
   * 현재 교시 추정
   */
  estimateCurrentPeriod(hour, minute) {
    const timeInMinutes = hour * 60 + minute;
    const periods = [
      { start: 8 * 60 + 20, end: 9 * 60 + 10, period: 1 },   // 1교시
      { start: 9 * 60 + 20, end: 10 * 60 + 10, period: 2 },  // 2교시
      { start: 10 * 60 + 20, end: 11 * 60 + 10, period: 3 }, // 3교시
      { start: 11 * 60 + 20, end: 12 * 60 + 10, period: 4 }, // 4교시
      { start: 13 * 60 + 10, end: 14 * 60, period: 5 },      // 5교시
      { start: 14 * 60 + 10, end: 15 * 60, period: 6 },      // 6교시
      { start: 15 * 60 + 10, end: 16 * 60, period: 7 }       // 7교시
    ];
    
    for (const period of periods) {
      if (timeInMinutes >= period.start && timeInMinutes <= period.end) {
        return period.period;
      }
    }
    
    return 0; // 교시 시간이 아님
  }
  
  /**
   * 교시별 시작 시간 반환
   */
  getPeriodStartTime(period) {
    const times = {
      1: '08:20', 2: '09:20', 3: '10:20', 4: '11:20',
      5: '13:10', 6: '14:10', 7: '15:10'
    };
    return times[period] || '00:00';
  }
  
  /**
   * 교시별 종료 시간 반환
   */
  getPeriodEndTime(period) {
    const times = {
      1: '09:10', 2: '10:10', 3: '11:10', 4: '12:10',
      5: '14:00', 6: '15:00', 7: '16:00'
    };
    return times[period] || '00:00';
  }
  
  /**
   * 교시별 시작 시간을 timestamp로 반환
   */
  getPeriodStartTimeInSeconds(period, baseDate) {
    const times = {
      1: { hour: 8, minute: 20 }, 2: { hour: 9, minute: 20 },
      3: { hour: 10, minute: 20 }, 4: { hour: 11, minute: 20 },
      5: { hour: 13, minute: 10 }, 6: { hour: 14, minute: 10 },
      7: { hour: 15, minute: 10 }
    };
    
    const time = times[period];
    if (!time) return baseDate.getTime();
    
    const result = new Date(baseDate);
    result.setHours(time.hour, time.minute, 0, 0);
    return result.getTime();
  }
  
  /**
   * 교시별 종료 시간을 timestamp로 반환
   */
  getPeriodEndTimeInSeconds(period, baseDate) {
    const times = {
      1: { hour: 9, minute: 10 }, 2: { hour: 10, minute: 10 },
      3: { hour: 11, minute: 10 }, 4: { hour: 12, minute: 10 },
      5: { hour: 14, minute: 0 }, 6: { hour: 15, minute: 0 },
      7: { hour: 16, minute: 0 }
    };
    
    const time = times[period];
    if (!time) return baseDate.getTime() + 3600000; // 1시간 후
    
    const result = new Date(baseDate);
    result.setHours(time.hour, time.minute, 0, 0);
    return result.getTime();
  }

  /**
   * Live Activity 종료 페이로드 생성 (애플 공식 표준)
   */
  createEndPayload(data) {
    const currentTime = Math.floor(Date.now() / 1000);
    
    return {
      aps: {
        timestamp: currentTime,
        event: 'end',
        'content-state': {
          currentStatus: 'afterSchool',
          currentClass: null,
          nextClass: null,
          startDate: data.startDate || currentTime,
          endDate: currentTime,
          lastUpdated: currentTime
        },
        // 즉시 해제 또는 4시간 후 해제
        'dismissal-date': data.dismissalDate || currentTime,
        alert: {
          title: data.alertTitle || '수업 종료',
          body: data.alertBody || '라이브 액티비티가 종료되었습니다.',
          sound: 'default'
        }
      }
    };
  }

  /**
   * Native Node.js HTTP/2 APNs 알림 전송
   */
  async sendAPNsNotification(deviceToken, payload, bundleId) {
    return new Promise((resolve, reject) => {
      try {
        const jwtToken = this.generateJWTToken();
        const targetUrl = `${this.apnsUrl}/3/device/${deviceToken}`;
        const parsedUrl = url.parse(targetUrl);
        
        console.log(`📡 [APNs] Sending to: ${targetUrl}`);
        
        // HTTP/2 클라이언트 연결
        const client = http2.connect(this.apnsUrl);
        
        client.on('error', (error) => {
          console.error(`❌ [HTTP/2] Connection error: ${error.message}`);
          client.close();
          reject(error);
        });
        
        const headers = {
          ':method': 'POST',
          ':path': parsedUrl.path,
          'authorization': `Bearer ${jwtToken}`,
          'content-type': 'application/json',
          'apns-topic': `${bundleId}.push-type.liveactivity`,
          'apns-push-type': 'liveactivity',
          'apns-priority': '10',
          'apns-expiration': '0'
        };
        
        console.log(`📡 [APNs] Headers:`, headers);
        console.log(`📡 [APNs] Payload:`, JSON.stringify(payload, null, 2));
        
        const req = client.request(headers);
        
        req.on('response', (headers) => {
          const statusCode = headers[':status'];
          console.log(`📡 [APNs] Response status: ${statusCode}`);
          
          let responseData = '';
          
          req.on('data', (chunk) => {
            responseData += chunk;
          });
          
          req.on('end', () => {
            client.close();
            
            if (statusCode >= 200 && statusCode < 300) {
              console.log(`✅ [APNs] Success: ${statusCode}`);
              if (responseData) {
                console.log(`✅ [APNs] Response:`, responseData);
              }
              resolve({ success: true, status: statusCode });
            } else {
              console.error(`❌ [APNs] Failed: ${statusCode} - ${responseData}`);
              reject(new Error(`APNs send failed: ${statusCode} - ${responseData}`));
            }
          });
        });
        
        req.on('error', (error) => {
          console.error(`❌ [APNs] Request error: ${error.message}`);
          client.close();
          reject(error);
        });
        
        // 요청 본문 전송
        req.write(JSON.stringify(payload));
        req.end();
        
      } catch (error) {
        console.error(`❌ [APNs] Setup error: ${error.message}`);
        reject(error);
      }
    });
  }

  /**
   * APNs Service 상태 확인
   */
  isReady() {
    return this.authKey && this.keyId && this.teamId;
  }

  /**
   * Service 정보 조회
   */
  getServiceInfo() {
    return {
      ready: this.isReady(),
      production: this.isProduction,
      apnsUrl: this.apnsUrl,
      keyId: this.keyId ? this.keyId.substring(0, 4) + '...' : null,
      teamId: this.teamId ? this.teamId.substring(0, 4) + '...' : null
    };
  }
}

module.exports = new APNsService();