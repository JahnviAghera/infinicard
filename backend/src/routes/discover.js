const express = require('express');
const router = express.Router();
const discoverController = require('../controllers/discoverController');
const { authenticateToken } = require('../middleware/auth');

// All routes require authentication
router.use(authenticateToken);

// Discover routes
router.get('/professionals', discoverController.getProfessionals);
router.post('/connections/request', discoverController.sendConnectionRequest);
router.get('/connections', discoverController.getConnections);
router.patch('/connections/:id/accept', discoverController.acceptConnection);
router.patch('/connections/:id/reject', discoverController.rejectConnection);
router.get('/locations', discoverController.getLocations);
router.get('/fields', discoverController.getFields);

module.exports = router;
