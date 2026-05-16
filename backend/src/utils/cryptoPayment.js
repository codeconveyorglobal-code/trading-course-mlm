const axios = require('axios');

const NOWPAYMENTS_BASE_URL = 'https://api.nowpayments.io/v1';

const nowpaymentsAPI = axios.create({
  baseURL: NOWPAYMENTS_BASE_URL,
  headers: {
    'x-api-key': process.env.NOWPAYMENTS_API_KEY,
    'Content-Type': 'application/json',
  },
});

// Create a crypto payment
const createPayment = async ({ priceAmount, priceCurrency = 'USD', payCurrency = 'USDT', orderId, orderDescription, callbackUrl, successUrl, cancelUrl }) => {
  const response = await nowpaymentsAPI.post('/payment', {
    price_amount: priceAmount,
    price_currency: priceCurrency,
    pay_currency: payCurrency,
    ipn_callback_url: callbackUrl || process.env.NOWPAYMENTS_CALLBACK_URL,
    order_id: orderId,
    order_description: orderDescription,
    success_url: successUrl,
    cancel_url: cancelUrl,
  });
  return response.data;
};

// Get available currencies
const getAvailableCurrencies = async () => {
  const response = await nowpaymentsAPI.get('/currencies');
  return response.data;
};

// Get payment status
const getPaymentStatus = async (paymentId) => {
  const response = await nowpaymentsAPI.get(`/payment/${paymentId}`);
  return response.data;
};

// Get minimum payment amount
const getMinimumAmount = async (currencyFrom, currencyTo) => {
  const response = await nowpaymentsAPI.get('/min-amount', {
    params: { currency_from: currencyFrom, currency_to: currencyTo },
  });
  return response.data;
};

// Get estimated price
const getEstimatedPrice = async (amount, currencyFrom, currencyTo) => {
  const response = await nowpaymentsAPI.get('/estimate', {
    params: { amount, currency_from: currencyFrom, currency_to: currencyTo },
  });
  return response.data;
};

// Verify IPN signature
const verifyIPN = (body, hmacHeader) => {
  const crypto = require('crypto');
  const sortedBody = JSON.stringify(sortObject(body));
  const hmac = crypto.createHmac('sha512', process.env.NOWPAYMENTS_IPN_SECRET);
  hmac.update(sortedBody);
  const expectedHmac = hmac.digest('hex');
  return expectedHmac === hmacHeader;
};

const sortObject = (obj) => {
  return Object.keys(obj).sort().reduce((result, key) => {
    result[key] = obj[key] && typeof obj[key] === 'object' ? sortObject(obj[key]) : obj[key];
    return result;
  }, {});
};

// Map NOWPayments status to internal status
const mapPaymentStatus = (nowStatus) => {
  const mapping = {
    waiting: 'pending',
    confirming: 'processing',
    confirmed: 'processing',
    sending: 'processing',
    partially_paid: 'processing',
    finished: 'completed',
    failed: 'failed',
    refunded: 'refunded',
    expired: 'failed',
  };
  return mapping[nowStatus] || 'pending';
};

module.exports = {
  createPayment,
  getAvailableCurrencies,
  getPaymentStatus,
  getMinimumAmount,
  getEstimatedPrice,
  verifyIPN,
  mapPaymentStatus,
};
