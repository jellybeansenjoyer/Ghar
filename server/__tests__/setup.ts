// Set environment variables before any module imports
process.env.PORT = '3001';
process.env.NODE_ENV = 'test';
process.env.APP_URL = 'http://localhost:3001';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/testdb';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-123';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-key-for-testing-456';
process.env.TWILIO_ACCOUNT_SID = '';
process.env.TWILIO_AUTH_TOKEN = '';
process.env.TWILIO_PHONE_NUMBER = '';
process.env.GOOGLE_CLIENT_ID = 'test-google-client-id';
process.env.CLOUDINARY_CLOUD_NAME = '';
process.env.CLOUDINARY_API_KEY = '';
process.env.CLOUDINARY_API_SECRET = '';
process.env.ONESIGNAL_APP_ID = '';
process.env.ONESIGNAL_REST_API_KEY = '';
