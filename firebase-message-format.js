// Firebase Cloud Messaging 올바른 메시지 형식
// Notification Service Extension이 작동하려면 이 형식을 사용해야 합니다.

// 1. Live Activity 시작 메시지
const startLiveActivityMessage = {
  topic: 'ios_liveactivity',
  notification: {
    title: '시간표 Live Activity 시작',
    body: '학교 시간이 시작되었습니다. Live Activity가 활성화됩니다.'
  },
  data: {
    type: 'start_live_activity'
  },
  apns: {
    headers: {
      'apns-push-type': 'alert',
      'apns-priority': '10'
    },
    payload: {
      aps: {
        alert: {
          title: '시간표 Live Activity 시작',
          body: '학교 시간이 시작되었습니다. Live Activity가 활성화됩니다.'
        },
        'mutable-content': 1,        // ⭐ 핵심: Service Extension 활성화
        'content-available': 1,      // ⭐ 핵심: 백그라운드 처리 활성화
        sound: 'default'
      }
    }
  }
};

// 2. Live Activity 종료 메시지
const stopLiveActivityMessage = {
  topic: 'ios_liveactivity',
  notification: {
    title: '시간표 Live Activity 종료',
    body: '학교 시간이 종료되었습니다. Live Activity가 비활성화됩니다.'
  },
  data: {
    type: 'stop_live_activity'
  },
  apns: {
    headers: {
      'apns-push-type': 'alert',
      'apns-priority': '10'
    },
    payload: {
      aps: {
        alert: {
          title: '시간표 Live Activity 종료',
          body: '학교 시간이 종료되었습니다. Live Activity가 비활성화됩니다.'
        },
        'mutable-content': 1,        // ⭐ 핵심: Service Extension 활성화
        'content-available': 1,      // ⭐ 핵심: 백그라운드 처리 활성화
        sound: 'default'
      }
    }
  }
};

// 3. Docker Firebase 스케줄러에서 사용할 업데이트된 함수들
async function startLiveActivity() {
  try {
    const response = await admin.messaging().send(startLiveActivityMessage);
    console.log('✅ Live Activity 시작 메시지 전송 성공:', response);
    return response;
  } catch (error) {
    console.error('❌ Live Activity 시작 메시지 전송 실패:', error);
    throw error;
  }
}

async function stopLiveActivity() {
  try {
    const response = await admin.messaging().send(stopLiveActivityMessage);
    console.log('✅ Live Activity 종료 메시지 전송 성공:', response);
    return response;
  } catch (error) {
    console.error('❌ Live Activity 종료 메시지 전송 실패:', error);
    throw error;
  }
}

// 4. 핵심 차이점 설명:
/*
기존 방식 (앱이 포그라운드일 때만 작동):
- data 필드만 사용
- mutable-content 없음
- Service Extension 호출되지 않음

새로운 방식 (백그라운드/종료 상태에서도 작동):
- notification + data 필드 모두 사용  
- mutable-content: 1 ⭐ 핵심
- content-available: 1 ⭐ 핵심  
- Service Extension이 호출됨
- Extension에서 Live Activity 시작 가능
*/

module.exports = {
  startLiveActivity,
  stopLiveActivity,
  startLiveActivityMessage,
  stopLiveActivityMessage
};