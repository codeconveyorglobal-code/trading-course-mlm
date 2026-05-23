const axios = require('axios');

const NOWPAYMENTS_BASE_URL = 'https://api.nowpayments.io/v1';

// Resolve API key: DB setting takes priority over env var
const getApiKey = async () => {
  try {
    const AppSettings = require('../models/AppSettings');
    const settings = await AppSettings.findOne({ singleton: true });
    if (settings && settings.nowpaymentsApiKey && settings.nowpaymentsApiKey.trim()) {
      return settings.nowpaymentsApiKey.trim();
    }
  } catch (_) {}
  return process.env.NOWPAYMENTS_API_KEY || '';
};

const getIpnSecret = async () => {
  try {
    const AppSettings = require('../models/AppSettings');
    const settings = await AppSettings.findOne({ singleton: true });
    if (settings && settings.nowpaymentsIpnSecret && settings.nowpaymentsIpnSecret.trim()) {
      return settings.nowpaymentsIpnSecret.trim();
    }
  } catch (_) {}
  return process.env.NOWPAYMENTS_IPN_SECRET || '';
};

const getCallbackUrl = async () => {
  try {
    const AppSettings = require('../models/AppSettings');
    const settings = await AppSettings.findOne({ singleton: true });
    if (settings && settings.nowpaymentsCallbackUrl && settings.nowpaymentsCallbackUrl.trim()) {
      return settings.nowpaymentsCallbackUrl.trim();
    }
  } catch (_) {}
  return process.env.NOWPAYMENTS_CALLBACK_URL || '';
};

// Build axios instance dynamically per-request
const nowpaymentsCall = async (method, path, data = null, params = null) => {
  const apiKey = await getApiKey();
  const instance = axios.create({
    baseURL: NOWPAYMENTS_BASE_URL,
    headers: { 'x-api-key': apiKey, 'Content-Type': 'application/json' },
  });
  const config = { method, url: path };
  if (data) config.data = data;
  if (params) config.params = params;
  const response = await instance(config);
  return response.data;
};

// Create a crypto payment
const createPayment = async ({ priceAmount, priceCurrency = 'USD', payCurrency = 'USDT', orderId, orderDescription, callbackUrl, successUrl, cancelUrl }) => {
  const resolvedCallback = callbackUrl || await getCallbackUrl();
  return nowpaymentsCall('post', '/payment', {
    price_amount: priceAmount,
    price_currency: priceCurrency,
    pay_currency: payCurrency,
    ipn_callback_url: resolvedCallback,
    order_id: orderId,
    order_description: orderDescription,
    success_url: successUrl,
    cancel_url: cancelUrl,
  });
};

// Get available currencies
const getAvailableCurrencies = async () => nowpaymentsCall('get', '/currencies');

// Get payment status
const getPaymentStatus = async (paymentId) => nowpaymentsCall('get', `/payment/${paymentId}`);

// Get minimum payment amount
const getMinimumAmount = async (currencyFrom, currencyTo) =>
  nowpaymentsCall('get', '/min-amount', null, { currency_from: currencyFrom, currency_to: currencyTo });

// Get estimated price
const getEstimatedPrice = async (amount, currencyFrom, currencyTo) =>
  nowpaymentsCall('get', '/estimate', null, { amount, currency_from: currencyFrom, currency_to: currencyTo });

// Verify IPN signature
const verifyIPN = async (body, hmacHeader) => {
  const crypto = require('crypto');
  const secret = await getIpnSecret();
  const sortedBody = JSON.stringify(sortObject(body));
  const hmac = crypto.createHmac('sha512', secret);
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
  getApiKey,
};
