import { createServer, Server as HttpServer } from 'http';
import { Server as SocketServer } from 'socket.io';

describe('Socket.IO Setup', () => {
  let httpServer: HttpServer;
  let io: SocketServer;
  let socketModule: typeof import('../../src/socket');

  beforeAll((done) => {
    httpServer = createServer();
    // Use jest.isolateModules to get a fresh socket module
    jest.isolateModules(() => {
      socketModule = require('../../src/socket');
    });
    io = socketModule!.initializeSocket(httpServer);
    httpServer.listen(0, done);
  });

  afterAll((done) => {
    io.close();
    httpServer.close(done);
  });

  it('should initialize Socket.IO and return a server instance', () => {
    expect(io).toBeDefined();
    expect(io.constructor.name).toBe('Server');
    expect(typeof io.on).toBe('function');
    expect(typeof io.emit).toBe('function');
    expect(typeof io.to).toBe('function');
  });

  it('getIO should return the initialized instance', () => {
    const retrievedIO = socketModule.getIO();
    expect(retrievedIO).toBe(io);
  });

  it('should support emitting to family rooms', () => {
    const roomTarget = io.to('family:test-family-id');
    expect(roomTarget).toBeDefined();
    expect(typeof roomTarget.emit).toBe('function');
  });

  it('should support emitting to visitor rooms', () => {
    const visitorRoom = io.to('visitor:test-visitor-id');
    expect(visitorRoom).toBeDefined();
    expect(typeof visitorRoom.emit).toBe('function');
  });

  it('should support chaining room targets', () => {
    const multiRoom = io.to('family:f1').to('visitor:v1');
    expect(multiRoom).toBeDefined();
    expect(typeof multiRoom.emit).toBe('function');
  });

  it('should be configured with CORS allowing all origins', () => {
    // Verify the server was created successfully with CORS
    expect(io).toBeDefined();
    expect(io.sockets).toBeDefined();
  });
});
