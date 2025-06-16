const express = require('express');
const router = express.Router();
const Joi = require('joi');
const LiveActivityService = require('../services/LiveActivityService');
const APNsService = require('../services/APNsService');
const logger = require('winston');

// 토큰 등록 스키마
const tokenRegistrationSchema = Joi.object({
  type: Joi.string().valid('push_to_start', 'activity_token', 'apns_token').required(),
  token: Joi.string().required(),
  activityId: Joi.string().when('type', { is: 'activity_token', then: Joi.required() }),
  grade: Joi.number().integer().min(1).max(3),
  classNumber: Joi.number().integer().min(1).max(11),
  bundleId: Joi.string().required(),
  deviceId: Joi.string().required(),
  timestamp: Joi.number().required()
});

// Live Activity 제어 스키마 (전체 학교용)
const liveActivityControlSchema = Joi.object({
  action: Joi.string().valid('start', 'update', 'end').required(),
  data: Joi.object().optional()
});

/**
 * Push-to-Start 토큰 등록
 * POST /api/live-activity/push-to-start
 */
router.post('/push-to-start', async (req, res, next) => {
  try {
    const { error, value } = tokenRegistrationSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details 
      });
    }

    const result = await LiveActivityService.registerPushToStartToken(value);
    
    logger.info('Push-to-start token registered', {
      deviceId: value.deviceId,
      grade: value.grade,
      classNumber: value.classNumber
    });

    res.status(200).json({
      success: true,
      message: 'Push-to-start token registered successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Activity 토큰 등록
 * POST /api/live-activity/activity-token
 */
router.post('/activity-token', async (req, res, next) => {
  try {
    const { error, value } = tokenRegistrationSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details 
      });
    }

    const result = await LiveActivityService.registerActivityToken(value);
    
    logger.info('Activity token registered', {
      activityId: value.activityId,
      deviceId: value.deviceId,
      grade: value.grade,
      classNumber: value.classNumber
    });

    res.status(200).json({
      success: true,
      message: 'Activity token registered successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
});

/**
 * APNs 토큰 등록
 * POST /api/live-activity/apns-token
 */
router.post('/apns-token', async (req, res, next) => {
  try {
    const { error, value } = tokenRegistrationSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details 
      });
    }

    const result = await LiveActivityService.registerAPNsToken(value);
    
    logger.info('APNs token registered', {
      deviceId: value.deviceId
    });

    res.status(200).json({
      success: true,
      message: 'APNs token registered successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Live Activity 시작
 * POST /api/live-activity/start
 */
router.post('/start', async (req, res, next) => {
  try {
    const { error, value } = liveActivityControlSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details 
      });
    }

    const result = await APNsService.startLiveActivity(value.data);
    
    logger.info('Live Activity start requested for entire school');

    res.status(200).json({
      success: true,
      message: 'Live Activity start request sent',
      data: result
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Live Activity 업데이트 (기존 로직 기반 새로고침)
 * POST /api/live-activity/update
 * 🚨 중요: APNs payload에 content-state 없음! 앱에서 기존 로직으로 새로고침
 */
router.post('/update', async (req, res, next) => {
  try {
    const { error, value } = liveActivityControlSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details 
      });
    }

    const result = await APNsService.updateLiveActivity(value.data);
    
    logger.info('Live Activity update requested for entire school - using existing logic refresh');

    res.status(200).json({
      success: true,
      message: 'Live Activity update request sent (existing logic refresh)',
      data: result
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Live Activity 종료
 * POST /api/live-activity/end
 */
router.post('/end', async (req, res, next) => {
  try {
    const { error, value } = liveActivityControlSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details 
      });
    }

    const result = await APNsService.endLiveActivity(value.data);
    
    logger.info('Live Activity end requested for entire school');

    res.status(200).json({
      success: true,
      message: 'Live Activity end request sent',
      data: result
    });
  } catch (error) {
    next(error);
  }
});

/**
 * 등록된 토큰 조회 (전체 학교)
 * GET /api/live-activity/tokens
 */
router.get('/tokens', async (req, res, next) => {
  try {
    const tokens = await LiveActivityService.getAllTokens();

    res.status(200).json({
      success: true,
      data: tokens
    });
  } catch (error) {
    next(error);
  }
});

/**
 * 토큰 통계
 * GET /api/live-activity/stats
 */
router.get('/stats', async (req, res, next) => {
  try {
    const stats = await LiveActivityService.getStats();

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;