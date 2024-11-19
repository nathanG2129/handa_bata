import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T value) {
    return Stream.value(value).concatWith([this]);
  }
}

extension StreamConcatWith<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> other) {
    return Stream.eventTransformed(
      this,
      (sink) => _ConcatStreamSink(sink, other.iterator),
    );
  }
}

class _ConcatStreamSink<T> implements EventSink<T> {
  final EventSink<T> _sink;
  // ignore: unused_field
  final Iterator<Stream<T>> _streams;
  bool _isListening = true;

  _ConcatStreamSink(this._sink, this._streams);

  @override
  void add(T event) {
    if (_isListening) _sink.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_isListening) _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _isListening = false;
    _sink.close();
  }
}

class AdminSession {
  static final AdminSession _instance = AdminSession._internal();
  factory AdminSession() => _instance;

  static const Duration sessionTimeout = Duration(hours: 1);
  static const String _lastActivityKey = 'admin_last_activity';
  
  DateTime? _lastActivity;
  Timer? _sessionTimer;

  StreamController<bool>? _sessionController;
  
  StreamController<bool> get _controller {
    if (_sessionController == null || _sessionController!.isClosed) {
      print('🔄 Creating new session controller (getter)');
      _sessionController = StreamController<bool>.broadcast();
    }
    return _sessionController!;
  }

  Stream<bool> get sessionState {
    if (_lastActivity != null) {
      // If we have an active session, emit the current state immediately
      return _controller.stream.startWith(true);
    }
    return _controller.stream;
  }

  AdminSession._internal() {
    _initializeSession();
  }

  void _initializeSession() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSession()
    );
  }

  Future<void> startSession() async {
    try {
      print('\n🔄 STARTING ADMIN SESSION');
      
      // Create a new controller first
      print('🔄 Creating new session controller');
      _sessionController?.close();
      _sessionController = StreamController<bool>.broadcast();
      
      print('🔄 Setting up session data');
      _lastActivity = DateTime.now();
      
      print('💾 Saving session data to SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
      
      print('⏰ Initializing session timer');
      _initializeSession();
      
      // Emit the state directly without waiting
      print('🔄 Emitting initial session state');
      _controller.add(true);
      
      print('✅ Admin session started successfully\n');
    } catch (e) {
      print('❌ Error starting session: $e');
      _controller.add(false);
      rethrow;
    }
  }

  Future<void> endSession() async {
    _lastActivity = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
    
    _controller.add(false);
    _sessionTimer?.cancel();
  }

  Future<bool> isSessionValid() async {
    print('\n🔍 CHECKING SESSION VALIDITY');
    
    if (_lastActivity == null) {
      print('🔄 No last activity, checking SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);
      
      if (lastActivityStr == null) {
        print('❌ No stored last activity found');
        return false;
      }
      _lastActivity = DateTime.parse(lastActivityStr);
      print('✅ Loaded last activity: $_lastActivity');
    }

    final isValid = _lastActivity != null &&
        DateTime.now().difference(_lastActivity!) < sessionTimeout;
    
    print(isValid 
      ? '✅ Session is valid' 
      : '❌ Session has expired');

    if (!isValid) {
      print('🔄 Ending expired session');
      await endSession();
    }

    return isValid;
  }

  Future<void> updateActivity() async {
    _lastActivity = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
  }

  void _checkSession() async {
    try {
      final valid = await isSessionValid();
      if (!_controller.isClosed) {
        _controller.add(valid);
      }
    } catch (e) {
      print('❌ Error checking session: $e');
      if (!_controller.isClosed) {
        _controller.add(false);
      }
    }
  }

  void dispose() {
    _sessionTimer?.cancel();
    _sessionController?.close();
    _sessionController = null;
  }
} 