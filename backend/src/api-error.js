// Autoria de Lucas Soares Gonçalves RA 25009467
export class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}
