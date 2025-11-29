const express = require('express');
const router = express.Router();
const tagsController = require('../controllers/tagsController');
const { authenticateToken } = require('../middleware/auth');
const {
  createTagValidation,
  uuidParamValidation,
} = require('../middleware/validator');

// All routes require authentication
router.use(authenticateToken);

// Tag routes
router.get('/', tagsController.getAllTags);
router.post('/', createTagValidation, tagsController.createTag);
router.put('/:id', uuidParamValidation, tagsController.updateTag);
router.delete('/:id', uuidParamValidation, tagsController.deleteTag);

// Card tag associations
router.post('/cards/:cardId/tags/:tagId', tagsController.addTagToCard);
router.delete('/cards/:cardId/tags/:tagId', tagsController.removeTagFromCard);

// Contact tag associations
router.post('/contacts/:contactId/tags/:tagId', tagsController.addTagToContact);
router.delete('/contacts/:contactId/tags/:tagId', tagsController.removeTagFromContact);

module.exports = router;
