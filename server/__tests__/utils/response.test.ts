import { sendSuccess, sendError } from '../../src/utils/response';
import { Response } from 'express';

function createMockResponse(): Response {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}

describe('Response Utils', () => {
  describe('sendSuccess', () => {
    it('should send a success response with defaults', () => {
      const res = createMockResponse();
      sendSuccess(res, { id: '1' });

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Success',
        data: { id: '1' },
      });
    });

    it('should send a success response with custom message and status', () => {
      const res = createMockResponse();
      sendSuccess(res, { count: 5 }, 'Items fetched', 201);

      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Items fetched',
        data: { count: 5 },
      });
    });

    it('should handle null data', () => {
      const res = createMockResponse();
      sendSuccess(res, null, 'Done');

      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Done',
        data: null,
      });
    });
  });

  describe('sendError', () => {
    it('should send an error response with defaults', () => {
      const res = createMockResponse();
      sendError(res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Internal Server Error',
        errors: undefined,
      });
    });

    it('should send an error response with custom message and status', () => {
      const res = createMockResponse();
      sendError(res, 'Not Found', 404);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Not Found',
        errors: undefined,
      });
    });

    it('should include validation errors', () => {
      const res = createMockResponse();
      const errors = [{ field: 'name', message: 'required' }];
      sendError(res, 'Validation error', 400, errors);

      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Validation error',
        errors,
      });
    });
  });
});
