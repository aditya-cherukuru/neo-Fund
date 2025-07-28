const express = require('express');
const { auth } = require('../middleware/auth');
const {
  createForecast,
  getForecasts,
  deleteForecast
} = require('../controllers/forecastController');

const router = express.Router();

router.post('/', auth, createForecast);
router.get('/', auth, getForecasts);
router.delete('/:id', auth, deleteForecast);

module.exports = router; 