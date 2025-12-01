/**
 * Standardized API response helpers
 */

const successResponse = (res, data = null, message = null, statusCode = 200) => {
  const response = { success: true };
  if (data !== null) response.data = data;
  if (message) response.message = message;
  return res.status(statusCode).json(response);
};

const errorResponse = (res, message, statusCode = 400, code = null) => {
  const response = {
    success: false,
    error: { message }
  };
  if (code) response.error.code = code;
  return res.status(statusCode).json(response);
};

const paginatedResponse = (res, data, pagination, message = null) => {
  const response = {
    success: true,
    data,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: Math.ceil(pagination.total / pagination.limit)
    }
  };
  if (message) response.message = message;
  return res.status(200).json(response);
};

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse
};
