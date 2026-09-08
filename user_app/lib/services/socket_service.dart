import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/config.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  IO.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _historyController = StreamController<List<dynamic>>.broadcast();
  final _rideAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _fareIncreasedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionSuccessController = StreamController<Map<String, dynamic>>.broadcast();
  final _roadmapUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  String? _pendingRideId;
  final Set<String> _registeredRooms = {};

  IO.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected == true;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<dynamic>> get historyStream => _historyController.stream;
  Stream<Map<String, dynamic>> get rideAcceptedStream => _rideAcceptedController.stream;
  Stream<Map<String, dynamic>> get rideStatusStream => _rideStatusController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get fareIncreasedStream => _fareIncreasedController.stream;
  Stream<Map<String, dynamic>> get connectionSuccessStream => _connectionSuccessController.stream;
  Stream<Map<String, dynamic>> get roadmapUpdatedStream => _roadmapUpdatedController.stream;

  void connect(String userId, {String? name, List<String> additionalUserIds = const []}) {
    final roomIds = <String>{
      if (userId.isNotEmpty) userId,
      ...additionalUserIds.where((id) => id.isNotEmpty),
    };

    if (_socket != null) {
      if (_socket!.connected) {
        _registerRooms(roomIds, name: name);
        _flushPendingRideJoin();
      } else {
        _socket!.connect();
      }
      return;
    }

    final apiBase = AppConfig.apiBaseUrl;
    String baseUrl = apiBase;
    if (apiBase.endsWith('/api')) {
      baseUrl = apiBase.substring(0, apiBase.length - 4);
    } else if (apiBase.endsWith('/api/')) {
      baseUrl = apiBase.substring(0, apiBase.length - 5);
    }

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _attachSocketListeners(roomIds, name: name);
    _socket?.connect();
  }

  void _attachSocketListeners(Set<String> roomIds, {String? name}) {
    _socket?.onConnect((_) {
      print("User Socket Connected");
      _registerRooms(roomIds, name: name);
      _flushPendingRideJoin();
    });

    _socket?.on("connection_success", (data) {
      print("User Socket Connection Success: $data");
      _connectionSuccessController.add(
        data is Map ? Map<String, dynamic>.from(data) : {'data': data},
      );
    });

    _socket?.on("ride_accepted", (data) {
      print("Ride Accepted Received: $data");
      if (data is Map) {
        _rideAcceptedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("ride_status_update", (data) {
      print("Ride Status Update Received: $data");
      if (data is Map) {
        _rideStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("driver_location_update", (data) {
      if (data is Map) {
        _driverLocationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("receive_message", (data) {
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("chat_history", (data) {
      _historyController.add(List<dynamic>.from(data));
    });

    _socket?.on("fare_increased", (data) {
      print("Fare Increased: $data");
      if (data is Map) {
        _fareIncreasedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("roadmap_updated", (data) {
      print("Roadmap Updated Received: $data");
      if (data is Map) {
        _roadmapUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.onDisconnect((_) => print("User Socket Disconnected"));
  }

  void _registerRooms(Set<String> roomIds, {String? name}) {
    for (final roomId in roomIds) {
      if (_registeredRooms.contains(roomId)) continue;
      _socket?.emit("register", {"userId": roomId, "name": name ?? "User"});
      _registeredRooms.add(roomId);
      print("User Socket registered room: $roomId");
    }
  }

  void registerAdditionalRoom(String userId, {String? name}) {
    if (userId.isEmpty) return;
    if (_socket?.connected == true) {
      _registerRooms({userId}, name: name);
    } else {
      connect(userId, name: name);
    }
  }

  void joinRide(String rideId) {
    if (rideId.isEmpty) return;
    _pendingRideId = rideId;
    _flushPendingRideJoin();
  }

  void _flushPendingRideJoin() {
    final rideId = _pendingRideId;
    if (rideId == null || rideId.isEmpty || _socket?.connected != true) return;
    _socket?.emit("join_ride", rideId);
    print("Joined ride room: $rideId");
    _pendingRideId = null;
  }

  void sendMessage(String senderId, String receiverId, String message,
      {String senderRole = 'user', String? senderName}) {
    _socket?.emit("send_message", {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "senderRole": senderRole,
      "senderName": senderName
    });
  }

  void fetchHistory(String userId1, String userId2) {
    _socket?.emit("fetch_history", {
      "userId1": userId1,
      "userId2": userId2
    });
  }

  void dispose() {
    _socket?.dispose();
    _messageController.close();
    _rideAcceptedController.close();
    _rideStatusController.close();
    _driverLocationController.close();
    _roadmapUpdatedController.close();
  }
}
