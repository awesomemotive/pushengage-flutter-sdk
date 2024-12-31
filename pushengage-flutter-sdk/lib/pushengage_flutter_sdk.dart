import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pushengage_flutter_sdk/helper/logger.dart';
import 'package:pushengage_flutter_sdk/model/DynamicSegment.dart';
import 'package:pushengage_flutter_sdk/model/goal.dart';
import 'package:pushengage_flutter_sdk/model/trigger_alert.dart';
import 'package:pushengage_flutter_sdk/model/trigger_campaign.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';

class PushEngage {
  static const MethodChannel _channel = MethodChannel('PushEngage');
  static Stream<Map<String, dynamic>>? _deepLinkStream;
  static const _sdkVersion = "0.0.1";

  /// A static getter that returns a stream of deep link data.
  ///
  /// This stream emits a map containing deep link data whenever a deep link is
  /// received. The stream is lazily initialized and uses a broadcast stream
  /// controller to allow multiple listeners.
  ///
  /// The stream listens for method calls from the platform channel and emits
  /// the deep link data when the 'onDeepLink' method is called along with additional data.
  ///
  /// Returns:
  ///   A [Stream] of [Map] containing deep link data.
  static Stream<Map<String, dynamic>?> get deepLinkStream {
    if (_deepLinkStream == null) {
      final StreamController<Map<String, dynamic>> controller =
          StreamController<Map<String, dynamic>>.broadcast();

      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDeepLink') {
          final Map<String, dynamic> arguments =
              Map<String, dynamic>.from(call.arguments);
          DebugLogger.log("Data from deeplink: $arguments");
          controller.add(arguments);
        }
      });

      _deepLinkStream = controller.stream;
    }
    return _deepLinkStream!;
  }

  /// Sets the application ID for PushEngage.
  ///
  /// This method sets the application ID.
  ///
  /// [appId] The application ID to be set.
  static Future<void> setAppId(String appId) async {
    try {
      await _channel.invokeMethod('PushEngage#setAppId', {'appId': appId});
      DebugLogger.log('App Id set successfully');
    } on PlatformException catch (e) {
      DebugLogger.log('Failed to set AppId: ${e.message}');
    }
  }

  /// Returns the current version of the SDK.
  ///
  /// This method retrieves the version of the SDK as a string.
  ///
  /// Returns:
  ///   A [String] representing the SDK version.
  static String getSdkVersion() {
    return _sdkVersion;
  }

  /// Android only
  /// Sets the small icon resource for notifications on Android.
  ///
  /// This method is only applicable for Android platforms.
  ///
  /// The [resourceName] parameter should be the name of the drawable resource
  /// to be used as the small icon in notifications.
  ///
  static Future<void> setSmallIconResource(String resourceName) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod(
            'PushEngage#setSmallIconResource', {'resourceName': resourceName});
      } on PlatformException catch (e) {
        DebugLogger.log('Failed to set small icon resource: ${e.message}');
      }
    }
  }

  /// Retrieves the device token hash for Android devices.
  ///
  /// This method invokes a platform-specific method to get the device token hash.
  ///
  /// Returns a [Future] that completes with a [PushEngageResult] containing the
  /// device token hash or an error message.
  ///
  /// Returns:
  /// - A [Future] that completes with the device token hash as a [String], or `null` if
  ///   an error occurs or the platform is not Android.
  static Future<PushEngageResult<String?>> getDeviceTokenHash() async {
    if (Platform.isAndroid) {
      try {
        final deviceTokenHash =
            await _channel.invokeMethod('PushEngage#getDeviceTokenHash');
        return PushEngageResult.success(deviceTokenHash);
      } catch (e) {
        return PushEngageResult.failure(e.toString());
      }
    }
    return PushEngageResult.failure('Platform is not Android');
  }

  /// Enables or disables logging for the PushEngage SDK.
  ///
  /// This method allows you to control whether logging is enabled or disabled
  /// for debugging purposes. When logging is enabled, debug information will
  /// be printed to the console.
  ///
  /// The method also communicates the logging preference to the native side
  /// via a method channel.
  ///
  /// - Parameter shouldEnable: A boolean value indicating whether logging
  ///   should be enabled (`true`) or disabled (`false`).
  ///
  static void enableLogging(bool shouldEnable) {
    if (shouldEnable) {
      DebugLogger.enableLogging();
    } else {
      DebugLogger.disableLogging();
    }
    try {
      _channel
          .invokeMethod('PushEngage#enableLogging', {'status': shouldEnable});
    } catch (e) {
      DebugLogger.log('Failed to enable logging: $e');
    }
  }

  /// Update trigger campaign status
  ///
  /// - [status]: The trigger status of type [TriggerStatusType]. If the status
  ///   is [TriggerStatusType.enabled], the notification will be sent.
  ///
  /// Returns a [Future] that completes with a [PushEngageResult] containing
  /// the result of the notification operation. If the operation is successful,
  /// the result will contain a [String] message. If there is an error, the
  /// result will contain the error message.
  static Future<PushEngageResult<String?>> automatedNotification(
      TriggerStatusType status) async {
    try {
      final String result = await _channel.invokeMethod(
          'PushEngage#automatedNotification',
          {'status': status == TriggerStatusType.enabled});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Sends a trigger event for a specific campaign.
  ///
  /// Returns a [PushEngageResult] containing a [String] if the operation
  /// is successful, or an error message if it fails.
  ///
  /// - Parameter [trigger]: The [TriggerCampaign] object containing the
  ///   data for the trigger event.
  ///
  /// - Returns: A [Future] that completes with a [PushEngageResult] containing
  ///   either the result of the trigger event or an error message.
  static Future<PushEngageResult<String?>> sendTriggerEvent(
      TriggerCampaign trigger) async {
    try {
      final String result = await _channel.invokeMethod(
          'PushEngage#sendTriggerEvent', trigger.toMap());
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Sends a goal event.
  ///
  /// It returns a [PushEngageResult] containing the result
  /// as a string. If an error occurs, it logs the error and returns a
  /// [PushEngageResult] containing the error message.
  ///
  /// - Parameter goal: The [Goal] object to be sent.
  /// - Returns: A [Future] that completes with a [PushEngageResult] containing
  ///   either the result string or an error message.
  static Future<PushEngageResult<String?>> sendGoal(Goal goal) async {
    try {
      final String result =
          await _channel.invokeMethod('PushEngage#sendGoal', goal.toMap());
      return PushEngageResult.success(result);
    } catch (e) {
      DebugLogger.log('Unexpected error: $e');
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Adds an alert to be triggered.
  ///
  /// This method sends a request to add a new alert using the provided
  /// [TriggerAlert] object.
  ///
  /// [alert] - The [TriggerAlert] object representing the alert to be added.
  ///
  /// Returns a [Future] that completes with a [PushEngageResult] containing
  /// either a success or an error message.
  static Future<PushEngageResult<String?>> addAlert(TriggerAlert alert) async {
    try {
      final String result =
          await _channel.invokeMethod('PushEngage#addAlert', alert.toMap());
      return PushEngageResult.success(result);
    } catch (e) {
      DebugLogger.log('Unexpected error: $e');
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Retrieves the details of a subscriber based on the provided values.
  ///
  /// The [values] parameter is a list of strings that specify the details to
  /// be retrieved.
  ///
  /// Returns a [Future] that completes with a [PushEngageResult] containing
  /// a map of the subscriber details or an error message.
  ///
  static Future<PushEngageResult<Map<String, dynamic>?>> getSubscriberDetails(
      List<String>? values) async {
    try {
      final String response = await _channel
          .invokeMethod('PushEngage#getSubscriberDetails', {'values': values});
      final Map<String, dynamic> decodedData =
          jsonDecode(response) as Map<String, dynamic>;
      return PushEngageResult.success(decodedData);
    } catch (e) {
      DebugLogger.log('Unexpected error: $e');
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Requests notification permission from the user.
  ///
  /// Returns a [PushEngageResult] containing a boolean value indicating the success
  /// of the permission request.
  ///
  /// If an error occurs during the permission request, it catches the exception
  /// and returns a [PushEngageResult] with a value of `false`.
  static Future<PushEngageResult<bool>> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final bool? isGranted = await _channel
            .invokeMethod<bool>('PushEngage#requestNotificationPermission');
        return isGranted == true
            ? PushEngageResult.success(true)
            : PushEngageResult.success(false);
      } else {
        final _ = await _channel
            .invokeMethod('PushEngage#requestNotificationPermission');
        return PushEngageResult.success(true);
      }
    } catch (e) {
      return PushEngageResult.success(false);
    }
  }

  /// Retrieves the attributes of a subscriber.
  ///
  /// This method invokes the 'PushEngage#getSubscriberAttributes' method
  /// on the platform channel and returns the result.
  ///
  /// Returns a [PushEngageResult] containing a map of subscriber attributes
  /// if the operation is successful, or an error message if it fails.
  ///
  /// Throws an exception if there is an error during the method invocation.
  static Future<PushEngageResult<Map<String, dynamic>>>
      getSubscriberAttributes() async {
    try {
      final res =
          await _channel.invokeMethod('PushEngage#getSubscriberAttributes');
      if (res is Map) {
        return PushEngageResult.success(Map<String, dynamic>.from(res));
      } else {
        return PushEngageResult.failure('Unexpected response');
      }
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Adds subscriber to segments.
  ///
  /// [segments] A list of segment names to be added.
  ///
  /// Returns a [PushEngageResult] containing the result of the operation.
  /// If successful, the result will contain a [String?] value. If an error
  /// occurs, the result will contain the error message.
  ///
  static Future<PushEngageResult<String?>> addSegment(
      List<String> segments) async {
    try {
      final String? result = await _channel
          .invokeMethod('PushEngage#addSegment', {'segments': segments});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Remove Segments for Subscriber.
  ///
  /// [segments] A list of segment names to be removed.
  ///
  /// Returns a [PushEngageResult] containing a [String] which is the result of the operation.
  /// If the operation is successful, the result will be a success with the corresponding message.
  /// If the operation fails, the result will be a failure with the error message.
  static Future<PushEngageResult<String?>> removeSegment(
      List<String> segments) async {
    try {
      final String? result = await _channel
          .invokeMethod('PushEngage#removeSegment', {'segments': segments});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Add subscriber to dynamic segments.
  ///
  /// Returns a [PushEngageResult] containing a [String] if the operation
  /// is successful, or an error message if it fails.
  ///
  /// - Parameters:
  ///   - segments: A list of [DynamicSegment] objects to be added.
  ///
  /// - Returns: A [Future] that completes with a [PushEngageResult] containing
  ///   a [String] if successful, or an error message if it fails.
  static Future<PushEngageResult<String?>> addDynamicSegment(
      List<DynamicSegment> segments) async {
    try {
      List<Map<String, dynamic>> serializedSegments =
          segments.map((segment) => segment.toMap()).toList();

      final String result = await _channel.invokeMethod(
        'PushEngage#addDynamicSegment',
        {'segments': serializedSegments},
      );
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Updates attributes of a subscriber. If an attribute with the specified key already exists, the existing value
  /// will be replaced.
  ///
  /// If the operation is successful, a [PushEngageResult] containing the result
  /// string is returned. If an error occurs, a [PushEngageResult] containing
  /// the error message is returned.
  ///
  /// - Parameters:
  ///   - attributes: A map of attributes to be added for the subscriber.
  ///
  /// - Returns: A [Future] that resolves to a [PushEngageResult] containing
  ///   either the result string or an error message.
  static Future<PushEngageResult<String?>> addSubscriberAttributes(
      Map<String, dynamic> attributes) async {
    try {
      String attributesJsonString = jsonEncode(attributes);

      final String result = await _channel.invokeMethod(
          'PushEngage#addSubscriberAttributes',
          {'attributes': attributesJsonString});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Deletes Subscriber Attributes.
  ///
  /// [attributes] A list of attribute names to be deleted.
  ///
  /// Returns a [PushEngageResult] containing a [String] message indicating
  /// the result of the operation. If the operation is successful, the message
  /// will contain the result string. If the operation fails, the message will
  /// contain the error string.
  ///
  static Future<PushEngageResult<String?>> deleteSubscriberAttributes(
      List<String> attributes) async {
    try {
      final String result = await _channel.invokeMethod(
          'PushEngage#deleteSubscriberAttributes', {'attributes': attributes});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Add a subscriber profile ID.
  /// Use this method to associate a subscriber ID (e.g., the username of the subscriber in the host application) with the SDK.
  /// [profileId]: The profile ID to be added.
  ///
  /// Returns a [Future] that completes with a [PushEngageResult] containing
  /// either the result or the error message.
  static Future<PushEngageResult<String?>> addProfileId(
      String profileId) async {
    try {
      final String result = await _channel
          .invokeMethod('PushEngage#addProfileId', {'profileId': profileId});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }

  /// Sets attributes of a subscriber replacing any previously associated attributes.
  ///
  /// The [attributes] parameter is a map where the keys are attribute names
  /// and the values are the corresponding attribute values.
  ///
  /// Returns a [PushEngageResult] containing a [String] which indicates
  /// the result of the operation. If the operation is successful, the result
  /// will be a success message. If there is an error, the result will be a
  /// failure message containing the error description.
  ///
  static Future<PushEngageResult<String?>> setSubscriberAttributes(
      Map<String, dynamic> attributes) async {
    try {
      String attributesJsonString = jsonEncode(attributes);

      final String result = await _channel.invokeMethod(
          'PushEngage#setSubscriberAttributes',
          {'attributes': attributesJsonString});
      return PushEngageResult.success(result);
    } catch (e) {
      return PushEngageResult.failure(e.toString());
    }
  }
}
