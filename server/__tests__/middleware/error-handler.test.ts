import { Request, Response, NextFunction } from 'express';
import { ZodError, ZodIssue } from 'zod';
import { errorHandler } from '../../src/middleware/error-handler';

function createMockRes(): Response {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}

describe('Error Handler Middleware', () => {
  const req = {} as Request;
  const next = jest.fn() as NextFunction;

  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should handle ZodError with 400 status', () => {
    const res = createMockRes();
    const zodIssues: ZodIssue[] = [
      { code: 'too_small', minimum: 1, type: 'string', inclusive: true, exact: false, message: 'Required', path: ['name'] },
    ];
    const error = new ZodError(zodIssues);

    errorHandler(error, req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        message: 'Validation error',
        errors: expect.arrayContaining([
          expect.objectContaining({ field: 'name' }),
        ]),
      })
    );
  });

  it('should handle generic errors with 500 status', () => {
    const res = createMockRes();
    const error = new Error('Something broke');

    errorHandler(error, req, res, next);

    expect(res.status).toHaveBeenCalledWith(500);
  });

  it('should handle errors with custom statusCode', () => {
    const res = createMockRes();
    const error: any = new Error('Not Found');
    error.statusCode = 404;

    errorHandler(error, req, res, next);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  it('should hide error message in production mode', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    const res = createMockRes();
    const error = new Error('Sensitive info');

    errorHandler(error, req, res, next);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'Internal Server Error' })
    );

    process.env.NODE_ENV = originalEnv;
  });

  it('should show error message in development mode', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    const res = createMockRes();
    const error = new Error('Debug info here');

    errorHandler(error, req, res, next);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'Debug info here' })
    );

    process.env.NODE_ENV = originalEnv;
  });
});
