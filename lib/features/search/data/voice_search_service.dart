import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice search states
enum VoiceSearchState {
  idle,
  initializing,
  listening,
  processing,
  error,
  permissionDenied,
}

/// Service for handling voice search functionality.
class VoiceSearchService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  VoiceSearchState _state = VoiceSearchState.idle;
  String _lastWords = '';
  String _errorMessage = '';
  bool _isAvailable = false;
  double _soundLevel = 0.0;
  List<LocaleName> _locales = [];
  String _currentLocale = '';

  VoiceSearchState get state => _state;
  String get lastWords => _lastWords;
  String get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceSearchState.listening;
  double get soundLevel => _soundLevel;
  List<LocaleName> get locales => _locales;
  String get currentLocale => _currentLocale;

  bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initialize the speech recognition service.
  Future<bool> initialize() async {
    if (_isAvailable) return true;

    _setState(VoiceSearchState.initializing);

    try {
      if (_isMobilePlatform) {
        final permissionStatus = await Permission.microphone.status;

        if (permissionStatus.isDenied) {
          final result = await Permission.microphone.request();
          if (!result.isGranted) {
            _setState(VoiceSearchState.permissionDenied);
            _errorMessage =
                'Microphone permission is required for voice search';
            return false;
          }
        } else if (permissionStatus.isPermanentlyDenied) {
          _setState(VoiceSearchState.permissionDenied);
          _errorMessage = 'Please enable microphone permission in settings';
          return false;
        }
      }

      _isAvailable = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );

      if (_isAvailable) {
        _locales = await _speech.locales();
        final systemLocale = await _speech.systemLocale();
        _currentLocale = systemLocale?.localeId ?? 'en_US';
        _setState(VoiceSearchState.idle);
      } else {
        _setState(VoiceSearchState.error);
        _errorMessage = 'Speech recognition not available on this device';
      }

      return _isAvailable;
    } catch (e) {
      _setState(VoiceSearchState.error);
      _errorMessage = 'Failed to initialize speech recognition: $e';
      return false;
    }
  }

  /// Start listening for voice input.
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    _lastWords = '';
    _setState(VoiceSearchState.listening);

    await _speech.listen(
      onResult: (result) => _onResult(result, onResult, onPartialResult),
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      localeId: _currentLocale,
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _speech.stop();
    _setState(VoiceSearchState.idle);
    _soundLevel = 0.0;
  }

  /// Cancel listening without processing results.
  Future<void> cancelListening() async {
    await _speech.cancel();
    _lastWords = '';
    _soundLevel = 0.0;
    _setState(VoiceSearchState.idle);
  }

  void _onResult(
    SpeechRecognitionResult result,
    Function(String)? onResult,
    Function(String)? onPartialResult,
  ) {
    _lastWords = result.recognizedWords;

    if (result.finalResult) {
      _setState(VoiceSearchState.idle);
      _soundLevel = 0.0;
      onResult?.call(_lastWords);
    } else {
      onPartialResult?.call(_lastWords);
    }

    notifyListeners();
  }

  void _onError(SpeechRecognitionError error) {
    _setState(VoiceSearchState.error);
    _errorMessage = _getErrorMessage(error.errorMsg);
    _soundLevel = 0.0;
    notifyListeners();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceSearchState.listening) {
        _setState(VoiceSearchState.idle);
        _soundLevel = 0.0;
      }
    }
  }

  String _getErrorMessage(String error) {
    switch (error) {
      case 'error_speech_timeout':
        return 'No speech detected. Please try again.';
      case 'error_no_match':
        return 'Could not recognize speech. Please try again.';
      case 'error_audio':
        return 'Audio recording error. Please try again.';
      case 'error_network':
        return 'Network error. Please check your connection.';
      case 'error_permission':
        return 'Microphone permission denied.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  void _setState(VoiceSearchState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Set the locale for speech recognition.
  void setLocale(String localeId) {
    if (_locales.any((l) => l.localeId == localeId)) {
      _currentLocale = localeId;
      notifyListeners();
    }
  }

  /// Open app settings for permission.
  Future<void> openSettings() async {
    await openAppSettings();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
