import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../config/app_config.dart';
import '../storage/secure_storage.dart';

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  String? _familyId;

  SocketService._();

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  io.Socket? get socket => _socket;
  bool get isConnected => _isConnected;

  void connect() {
    if (_socket != null) {
      if (!_isConnected) {
        _socket!.connect();
      }
      return;
    }

    _socket = io.io(
      AppConfig.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(999999)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      developer.log('Socket connected', name: 'Socket');
      // Auto-rejoin family room after reconnect so realtime keeps working.
      if (_familyId != null) {
        joinFamilyRoom(_familyId!);
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      developer.log('Socket disconnected', name: 'Socket');
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      developer.log('Socket reconnected', name: 'Socket');
      if (_familyId != null) {
        joinFamilyRoom(_familyId!);
      }
    });

    _socket!.onError((error) {
      developer.log('Socket error: $error', name: 'Socket');
    });
  }

  Future<void> joinFamilyRoom(String familyId) async {
    _familyId = familyId;
    final token = await SecureStorageService.getAccessToken();
    if (token != null && _socket != null) {
      _socket!.emit('join:family', {
        'familyId': familyId,
        'token': token,
      });
      developer.log('Joined family room: $familyId', name: 'Socket');
    }
  }

  void onVisitorNew(Function(Map<String, dynamic>) callback) {
    _socket?.off('visitor:new');
    _socket?.on('visitor:new', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onVisitorResponded(Function(Map<String, dynamic>) callback) {
    _socket?.off('visitor:responded');
    _socket?.on('visitor:responded', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onVisitorExpired(Function(Map<String, dynamic>) callback) {
    _socket?.off('visitor:expired');
    _socket?.on('visitor:expired', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onChatMessage(Function(Map<String, dynamic>) callback) {
    _socket?.off('chat:message');
    _socket?.on('chat:message', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
