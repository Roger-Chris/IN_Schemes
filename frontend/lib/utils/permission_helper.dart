import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Requests default system permissions for Location and Microphone using native dialogs.
Future<void> requestDefaultPermissions() async {
  // 1. Request location permission
  try {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('Error requesting location permission: $e');
  }

  // 2. Request microphone permission
  try {
    final speech = stt.SpeechToText();
    final hasPermission = await speech.hasPermission;
    if (!hasPermission) {
      await speech.initialize();
    }
  } catch (e) {
    debugPrint('Error requesting microphone permission: $e');
  }
}
