const express = require('express');
const router = express.Router();
const cardsController = require('../controllers/cardsController');
const { authenticateToken } = require('../middleware/auth');
const {
  createCardValidation,
  updateCardValidation,
  uuidParamValidation,
  searchValidation,
} = require('../middleware/validator');

// All routes require authentication
router.use(authenticateToken);

// Card routes
router.get('/', cardsController.getAllCards);
router.get('/search', searchValidation, cardsController.searchCards);
router.get('/:id', uuidParamValidation, cardsController.getCardById);
router.post('/', createCardValidation, cardsController.createCard);
router.put('/:id', updateCardValidation, cardsController.updateCard);
router.delete('/:id', uuidParamValidation, cardsController.deleteCard);
router.patch('/:id/favorite', uuidParamValidation, cardsController.toggleFavorite);

module.exports = router;
