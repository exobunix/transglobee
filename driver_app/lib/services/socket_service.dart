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
  final _newRideController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideAssignedController = StreamController<Map<String, dynamic>>.broadcast();
  final _fareUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionSuccessController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentRequestedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatusController = StreamController<Map<String, dynamic>>.broadcast();

  final _statusChangeController = StreamController<Map<String, dynamic>>.broadcast();

  IO.Socket? get socket => _socket;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<dynamic>> get historyStream => _historyController.stream;
  Stream<Map<String, dynamic>> get newRideStream => _newRideController.stream;
  Stream<Map<String, dynamic>> get rideAssignedStream => _rideAssignedController.stream;
  Stream<Map<String, dynamic>> get fareUpdatedStream => _fareUpdatedController.stream;
  Stream<Map<String, dynamic>> get connectionSuccessStream => _connectionSuccessController.stream;
  Stream<Map<String, dynamic>> get paymentRequestedStream => _paymentRequestedController.stream;
  Stream<Map<String, dynamic>> get rideStatusStream => _rideStatusController.stream;
  Stream<Map<String, dynamic>> get rideCancelledStream => _rideCancelledController.stream;
  Stream<Map<String, dynamic>> get statusChangeStream => _statusChangeController.stream;

  void connect(String userId, {String? name}) {
    if (_socket != null) {
      if (!(_socket!.connected)) {
        _socket!.connect();
      } else {
        _socket!.emit("register", {"userId": userId, "name": name ?? "Driver"});
      }
      return;
    }

    final baseUrl = AppConfig.socketBaseUrl; // Socket.io needs root, not /api
    
    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Force websocket transport
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print("Socket Connected Successfully: $userId");
      _socket?.emit("register", {"userId": userId, "name": name ?? "Driver"});
    });

    _socket?.on("connection_success", (data) {
      print("Socket Connection Success Event: $data");
    });

    _socket?.on("receive_message", (data) {
      print("Socket Message Received: $data");
      _messageController.add(data);
    });

    _socket?.on("chat_history", (data) {
      _historyController.add(data);
    });

    _socket?.on("new_ride", (data) {
      print("New Ride Received via Socket: $data");
      _newRideController.add(data);
    });

    _socket?.on("ride_assigned", (data) {
      print("Ride Assigned (Taken by another driver): $data");
      _rideAssignedController.add(Map<String, dynamic>.from(data));
    });
    
    _socket?.on("fare_updated", (data) {
      print("Fare Updated via Socket: $data");
      _fareUpdatedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on("payment_requested", (data) {
       print("Payment Requested via Socket: $data");
       _paymentRequestedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on("ride_status_update", (data) {
      print("Ride Status Update Received via Socket: $data");
      if (data is Map) {
        _rideStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("ride_cancelled", (data) {
      print("Ride Cancelled Received via Socket: $data");
      if (data is Map) {
        _rideCancelledController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on("status_change", (data) {
      print("Status Change Received via Socket: $data");
      if (data is Map) {
        _statusChangeController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.onDisconnect((_) => print("Socket Disconnected"));
  }

  void sendMessage(String senderId, String receiverId, String message, {String senderRole = 'driver', String? senderName}) {
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

  void updateLocation({
    required String rideId,
    required String userId,
    required double latitude,
    required double longitude,
    double? heading,
  }) {
    _socket?.emit("update_location", {
      "rideId": rideId,
      "userId": userId,
      "latitude": latitude,
      "longitude": longitude,
      "heading": heading,
    });
  }

  void joinRide(String rideId) {
    _socket?.emit("join_ride", rideId);
  }

  void updateFare(String rideId, int amount, double newFare) {
    _socket?.emit("update_fare", {
      "rideId": rideId,
      "amount": amount,
      "newFare": newFare
    });
  }

  void dispose() {
    _socket?.dispose();
    _messageController.close();
    _historyController.close();
    _newRideController.close();
    _rideStatusController.close();
    _rideCancelledController.close();
  }
}
