const { v4: uuidv4 } = require('uuid');
const logger = require('winston');

/**
 * Live Activity Token 관리 서비스
 * 실제 운영환경에서는 데이터베이스(MongoDB, PostgreSQL 등)를 사용해야 함
 */
class LiveActivityService {
  constructor() {
    // 메모리 기반 저장소 (데모용 - 실제로는 DB 사용)
    this.pushToStartTokens = new Map(); // deviceId -> token info
    this.activityTokens = new Map(); // activityId -> token info
    this.apnsTokens = new Map(); // deviceId -> token info
    // 학년반 구분 없이 전체 관리
  }

  /**
   * Push-to-Start 토큰 등록 (학년/반 정보 포함)
   */
  async registerPushToStartToken(tokenData) {
    const { token, deviceId, bundleId, timestamp, grade, classNumber } = tokenData;
    
    const tokenInfo = {
      id: uuidv4(),
      token,
      deviceId,
      bundleId,
      grade: grade || null,           // 🚨 학년 정보 추가
      classNumber: classNumber || null, // 🚨 반 정보 추가
      registeredAt: new Date(timestamp * 1000),
      lastUpdated: new Date(),
      type: 'push_to_start'
    };

    this.pushToStartTokens.set(deviceId, tokenInfo);

    logger.info('Push-to-start token registered with class info', {
      deviceId,
      grade,
      classNumber,
      tokenId: tokenInfo.id
    });

    return {
      tokenId: tokenInfo.id,
      grade,
      classNumber,
      registeredAt: tokenInfo.registeredAt
    };
  }

  /**
   * Activity 토큰 등록 (학년/반 정보 포함)
   */
  async registerActivityToken(tokenData) {
    const { token, activityId, deviceId, bundleId, timestamp, grade, classNumber } = tokenData;
    
    const tokenInfo = {
      id: uuidv4(),
      token,
      activityId,
      deviceId,
      bundleId,
      grade: grade || null,           // 🚨 학년 정보 추가
      classNumber: classNumber || null, // 🚨 반 정보 추가
      registeredAt: new Date(timestamp * 1000),
      lastUpdated: new Date(),
      type: 'activity_token'
    };

    this.activityTokens.set(activityId, tokenInfo);

    logger.info('Activity token registered with class info', {
      activityId,
      deviceId,
      grade,
      classNumber,
      tokenId: tokenInfo.id
    });

    return {
      tokenId: tokenInfo.id,
      activityId,
      grade,
      classNumber,
      registeredAt: tokenInfo.registeredAt
    };
  }

  /**
   * APNs 토큰 등록
   */
  async registerAPNsToken(tokenData) {
    const { token, deviceId, bundleId, timestamp } = tokenData;
    
    const tokenInfo = {
      id: uuidv4(),
      token,
      deviceId,
      bundleId,
      registeredAt: new Date(timestamp * 1000),
      lastUpdated: new Date(),
      type: 'apns_token'
    };

    this.apnsTokens.set(deviceId, tokenInfo);

    logger.info('APNs token registered', {
      deviceId,
      tokenId: tokenInfo.id
    });

    return {
      tokenId: tokenInfo.id,
      registeredAt: tokenInfo.registeredAt
    };
  }

  /**
   * 모든 Push-to-Start 토큰들 조회 (전체 학교)
   */
  async getAllPushToStartTokens() {
    return Array.from(this.pushToStartTokens.values());
  }

  /**
   * 모든 토큰 조회 (전체 학교)
   */
  async getAllTokens() {
    const pushToStartTokens = await this.getAllPushToStartTokens();
    const activityTokens = Array.from(this.activityTokens.values());

    return {
      pushToStartTokens,
      activityTokens,
      totalDevices: pushToStartTokens.length
    };
  }

  /**
   * 서비스 통계 조회
   */
  async getStats() {
    const totalPushToStartTokens = this.pushToStartTokens.size;
    const totalActivityTokens = this.activityTokens.size;
    const totalAPNsTokens = this.apnsTokens.size;
    
    // 전체 학교 통계
    const schoolStats = {
      totalRegisteredDevices: totalPushToStartTokens,
      totalActiveActivities: totalActivityTokens
    };

    // 최근 등록 시간
    const recentRegistrations = Array.from(this.pushToStartTokens.values())
      .sort((a, b) => b.registeredAt - a.registeredAt)
      .slice(0, 10);

    return {
      totalPushToStartTokens,
      totalActivityTokens,
      totalAPNsTokens,
      schoolStats,
      recentRegistrations: recentRegistrations.map(token => ({
        deviceId: token.deviceId,
        grade: token.grade,
        classNumber: token.classNumber,
        registeredAt: token.registeredAt
      })),
      lastUpdated: new Date()
    };
  }

  /**
   * 토큰 정리 (만료된 토큰 제거)
   */
  async cleanupExpiredTokens() {
    const now = new Date();
    const expirationTime = 30 * 24 * 60 * 60 * 1000; // 30일

    let cleanedCount = 0;

    // Push-to-Start 토큰 정리
    for (const [deviceId, tokenInfo] of this.pushToStartTokens.entries()) {
      if (now - tokenInfo.lastUpdated > expirationTime) {
        this.pushToStartTokens.delete(deviceId);
        
        // 반별 구독에서도 제거
        const classKey = `${tokenInfo.grade}-${tokenInfo.classNumber}`;
        if (this.classSubscriptions.has(classKey)) {
          this.classSubscriptions.get(classKey).delete(deviceId);
        }
        
        cleanedCount++;
      }
    }

    // Activity 토큰 정리
    for (const [activityId, tokenInfo] of this.activityTokens.entries()) {
      if (now - tokenInfo.lastUpdated > expirationTime) {
        this.activityTokens.delete(activityId);
        cleanedCount++;
      }
    }

    logger.info(`Cleaned up ${cleanedCount} expired tokens`);
    return cleanedCount;
  }

  /**
   * 디바이스의 모든 토큰 제거
   */
  async removeDeviceTokens(deviceId) {
    let removed = false;

    // Push-to-Start 토큰 제거
    if (this.pushToStartTokens.has(deviceId)) {
      this.pushToStartTokens.delete(deviceId);
      removed = true;
    }

    // APNs 토큰 제거
    if (this.apnsTokens.has(deviceId)) {
      this.apnsTokens.delete(deviceId);
      removed = true;
    }

    // 해당 디바이스의 Activity 토큰들 제거
    for (const [activityId, tokenInfo] of this.activityTokens.entries()) {
      if (tokenInfo.deviceId === deviceId) {
        this.activityTokens.delete(activityId);
        removed = true;
      }
    }

    if (removed) {
      logger.info(`Removed all tokens for device: ${deviceId}`);
    }

    return removed;
  }
}

module.exports = new LiveActivityService();