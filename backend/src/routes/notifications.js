const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notificationsController');
const { authenticateToken } = require('../middleware/auth');
const { uuidParamValidation } = require('../middleware/validator');

router.use(authenticateToken);

router.get('/', notificationsController.getNotifications);
router.patch('/:id/read', uuidParamValidation, notificationsController.markAsRead);
router.delete('/:id', uuidParamValidation, notificationsController.deleteNotification);

module.exports = router;
