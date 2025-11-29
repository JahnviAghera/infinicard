const express = require('express');
const router = express.Router();
const contactsController = require('../controllers/contactsController');
const { authenticateToken } = require('../middleware/auth');
const {
  createContactValidation,
  updateContactValidation,
  uuidParamValidation,
  searchValidation,
} = require('../middleware/validator');

// All routes require authentication
router.use(authenticateToken);

// Contact routes
router.get('/', contactsController.getAllContacts);
router.get('/search', searchValidation, contactsController.searchContacts);
router.get('/:id', uuidParamValidation, contactsController.getContactById);
router.post('/', createContactValidation, contactsController.createContact);
router.put('/:id', updateContactValidation, contactsController.updateContact);
router.delete('/:id', uuidParamValidation, contactsController.deleteContact);
router.patch('/:id/favorite', uuidParamValidation, contactsController.toggleFavorite);

module.exports = router;
