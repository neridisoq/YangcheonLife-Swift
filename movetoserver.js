const admin = require('firebase-admin');
const cron = require('node-cron');

// Firebase Admin SDK 초기화
const serviceAccount = require('./yangcheonlife-firebase-adminsdk-uu2g2-2c41d27ffc.json'); // 서비스 계정 키 파일

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('🔥 Firebase Admin SDK 초기화 완료');

// Live Activity 시작 메시지 전송
async function startLiveActivity() {
  try {
    const message = {
      topic: 'ios_liveactivity',
      data: {
        type: 'start_live_activity'
      },
      notification: {
        title: '시간표 Live Activity 시작',
        body: '학교 시간이 시작되었습니다. Live Activity가 활성화됩니다.'
      },
      apns: {
        payload: {
          aps: {
            'mutable-content' : 1,
            'content-available': 1,
            sound: 'default'
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Live Activity 시작 메시지 전송 성공:', response);
  } catch (error) {
    console.error('❌ Live Activity 시작 메시지 전송 실패:', error);
  }
}

// Live Activity 종료 메시지 전송
async function stopLiveActivity() {
  try {
    const message = {
      topic: 'ios_liveactivity',
      data: {
        type: 'stop_live_activity'
      },
      notification: {
        title: '시간표 Live Activity 종료',
        body: '학교 시간이 종료되었습니다. Live Activity가 비활성화됩니다.'
      },
      apns: {
        payload: {
          aps: {
            'content-available': 1,
            sound: 'default'
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Live Activity 종료 메시지 전송 성공:', response);
  } catch (error) {
    console.error('❌ Live Activity 종료 메시지 전송 실패:', error);
  }
}

// Wake Live Activity 메시지 전송 (10분마다)
async function wakeLiveActivity() {
  try {
    const message = {
      topic: 'wake',
      data: {
        type: 'wake_live_activity'
      },
      apns: {
        payload: {
          aps: {
            'content-available': 1
          }
        }
      },
      android: {
        priority: 'high',
        data: {
          type: 'wake_live_activity'
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('⏰ Live Activity 깨우기 메시지 전송 성공:', response);
  } catch (error) {
    console.error('❌ Live Activity 깨우기 메시지 전송 실패:', error);
  }
}

// 스케줄러 설정
console.log('📅 Live Activity 스케줄러 시작');

// 매일 오전 8시에 Live Activity 시작 (월-금)
cron.schedule('0 8 * * 1-5', () => {
  const now = new Date();
  console.log(`🌅 [${now.toLocaleString('ko-KR')}] Live Activity 시작 스케줄 실행`);
  startLiveActivity();
}, {
  timezone: "Asia/Seoul"
});

// 매일 오후 4시 30분에 Live Activity 종료 (월-금)
cron.schedule('30 16 * * 1-5', () => {
  const now = new Date();
  console.log(`🌆 [${now.toLocaleString('ko-KR')}] Live Activity 종료 스케줄 실행`);
  stopLiveActivity();
}, {
  timezone: "Asia/Seoul"
});

// 학교 시간 중 10분마다 Live Activity 깨우기 (월-금, 8:00-16:30)
cron.schedule('*/10 8-16 * * 1-5', () => {
  const now = new Date();
  const hour = now.getHours();
  const minute = now.getMinutes();
  
  // 16시 30분 이후는 제외 (16시 30분에는 종료 메시지가 보내짐)
  if (hour === 16 && minute > 30) {
    return;
  }
  
  console.log(`⏰ [${now.toLocaleString('ko-KR')}] Live Activity 깨우기 스케줄 실행`);
  wakeLiveActivity();
}, {
  timezone: "Asia/Seoul"
});

// 수동 실행을 위한 Express 서버 (선택사항)
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// 수동 Live Activity 시작
app.post('/start-live-activity', async (req, res) => {
  try {
    await startLiveActivity();
    res.json({ success: true, message: 'Live Activity 시작 메시지 전송됨' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 수동 Live Activity 종료
app.post('/stop-live-activity', async (req, res) => {
  try {
    await stopLiveActivity();
    res.json({ success: true, message: 'Live Activity 종료 메시지 전송됨' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 수동 Live Activity 깨우기
app.post('/wake-live-activity', async (req, res) => {
  try {
    await wakeLiveActivity();
    res.json({ success: true, message: 'Live Activity 깨우기 메시지 전송됨' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 상태 확인
app.get('/health', (req, res) => {
  res.json({ 
    status: 'running', 
    timestamp: new Date().toLocaleString('ko-KR'),
    timezone: 'Asia/Seoul',
    schedules: [
      'Live Activity 시작: 매일 오전 8:00 (월-금)',
      'Live Activity 종료: 매일 오후 4:30 (월-금)', 
      'Live Activity 깨우기: 10분마다 (월-금, 8:00-16:30)'
    ]
  });
});

// 현재 스케줄 상태 확인
app.get('/schedule-status', (req, res) => {
  const now = new Date();
  const hour = now.getHours();
  const minute = now.getMinutes();
  const day = now.getDay(); // 0=일요일, 1=월요일...
  
  const isWeekday = day >= 1 && day <= 5;
  const isSchoolTime = hour >= 8 && (hour < 16 || (hour === 16 && minute <= 30));
  
  res.json({
    currentTime: now.toLocaleString('ko-KR'),
    isWeekday: isWeekday,
    isSchoolTime: isSchoolTime,
    shouldWakeBeActive: isWeekday && isSchoolTime,
    nextWakeSchedule: isWeekday && isSchoolTime ? '10분 이내' : '다음 학교 시간'
  });
});

app.listen(port, () => {
  console.log(`🚀 서버가 포트 ${port}에서 실행 중`);
  console.log(`📋 상태 확인: http://localhost:${port}/health`);
  console.log(`📊 스케줄 상태: http://localhost:${port}/schedule-status`);
  console.log(`🟢 수동 시작: POST http://localhost:${port}/start-live-activity`);
  console.log(`🔴 수동 종료: POST http://localhost:${port}/stop-live-activity`);
  console.log(`⏰ 수동 깨우기: POST http://localhost:${port}/wake-live-activity`);
});

// 프로세스 종료 시 정리
process.on('SIGINT', () => {
  console.log('\n📋 Live Activity 스케줄러 종료');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n📋 Live Activity 스케줄러 종료');
  process.exit(0);
});

console.log('⏰ 스케줄 설정 완료:');
console.log('   - 시작: 매일 오전 8:00 (월-금)');
console.log('   - 종료: 매일 오후 4:30 (월-금)');
console.log('   - 깨우기: 10분마다 (월-금, 8:00-16:30)');
console.log('   - 시간대: Asia/Seoul');