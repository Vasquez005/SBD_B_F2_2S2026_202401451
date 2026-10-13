// Error con código HTTP, para validaciones propias del API (400, 404, ...).
class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

module.exports = { HttpError };