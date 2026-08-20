import 'dart:async';
import 'dart:ui';
import 'package:app/shared/utils/log_utils.dart';

/// A mixin that encapsulates adaptive auto-polling logic for transaction
/// status checks. Each class that uses this mixin gets its own independent
/// timer and counter state.
///
/// The polling cycle starts with fast intervals (2s) for the first 6 attempts,
/// then switches to slow intervals (10s) for subsequent attempts, up to a
/// maximum of [MAX_POLL_COUNT] total attempts.
///
/// Uses a recursive [Timer] pattern (not [Timer.periodic]) so the delay is
/// re-evaluated before each attempt, enabling adaptive intervals.
mixin AutoPollingMixin {
  Timer? _pollingTimer;
  int _pollingCounter = 0;
  bool _isPolling = false;

  /// Maximum number of polling attempts before giving up.
  static const int MAX_POLL_COUNT = 11;

  /// Polling interval in seconds for the first [FAST_INTERVAL_THRESHOLD] attempts.
  static const int FAST_INTERVAL_SECONDS = 2;

  /// Polling interval in seconds after [FAST_INTERVAL_THRESHOLD] attempts.
  static const int SLOW_INTERVAL_SECONDS = 10;

  /// Counter threshold to switch from fast to slow interval.
  static const int FAST_INTERVAL_THRESHOLD = 6;

  /// Log tag for identifying the source controller in logs.
  String get pollingLogTag => runtimeType.toString();

  /// Starts a new polling cycle. Resets counter and timer, then begins scheduling.
  ///
  /// [onPoll] is called each tick and should return `true` to stop polling
  /// (e.g., when the transaction reaches a terminal state), or `false` to
  /// continue polling.
  ///
  /// [onMaxPollReached] is called when the maximum number of polling attempts
  /// is reached without a terminal state. Use this to notify the user.
  void startPolling(
    Future<bool> Function() onPoll, {
    VoidCallback? onMaxPollReached,
  }) {
    LogUtils.debugLog(
        '[$pollingLogTag] startPolling: beginning new polling cycle');
    resetPolling();
    _scheduleNextPoll(onPoll, onMaxPollReached: onMaxPollReached);
  }

  /// Stops the polling timer and clears the reference.
  void stopPolling() {
    LogUtils.debugLog(
        '[$pollingLogTag] stopPolling: cancelling timer (counter=$_pollingCounter)');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Resets counter to zero and stops any active timer.
  void resetPolling() {
    LogUtils.debugLog(
        '[$pollingLogTag] resetPolling: resetting counter=$_pollingCounter to 0');
    stopPolling();
    _pollingCounter = 0;
    _isPolling = false;
  }

  /// Schedules the next poll after the appropriate delay.
  ///
  /// Uses a recursive [Timer] pattern so the interval is re-evaluated
  /// before each attempt, enabling the adaptive fast-to-slow transition.
  void _scheduleNextPoll(
    Future<bool> Function() onPoll, {
    VoidCallback? onMaxPollReached,
  }) {
    _pollingTimer?.cancel();
    final delay = _getPollingDelay();
    LogUtils.debugLog(
        '[$pollingLogTag] _scheduleNextPoll: scheduling poll #${_pollingCounter + 1} in ${delay.inSeconds}s');
    _pollingTimer = Timer(delay, () async {
      if (_pollingCounter >= MAX_POLL_COUNT) {
        LogUtils.debugLog(
            '[$pollingLogTag] max poll count reached ($_pollingCounter/$MAX_POLL_COUNT), stopping');
        stopPolling();
        onMaxPollReached?.call();
        return;
      }
      if (_isPolling) {
        LogUtils.debugLog(
            '[$pollingLogTag] skipping poll #${_pollingCounter + 1}: previous call still in-flight');
        return;
      }

      _isPolling = true;
      try {
        _pollingCounter++;
        LogUtils.debugLog(
            '[$pollingLogTag] executing poll #$_pollingCounter/$MAX_POLL_COUNT');
        final shouldStop = await onPoll();
        LogUtils.debugLog(
            '[$pollingLogTag] poll #$_pollingCounter result: shouldStop=$shouldStop');
        if (shouldStop) {
          LogUtils.debugLog(
              '[$pollingLogTag] callback signalled stop, ending polling');
          stopPolling();
          return;
        }
      } catch (e) {
        LogUtils.debugLog('[$pollingLogTag] poll #$_pollingCounter error: $e');
      } finally {
        _isPolling = false;
      }

      // Schedule next only if not stopped
      if (_pollingTimer != null) {
        _scheduleNextPoll(onPoll, onMaxPollReached: onMaxPollReached);
      } else {
        LogUtils.debugLog(
            '[$pollingLogTag] timer was nulled during poll, not rescheduling');
      }
    });
  }

  /// Returns the delay before the next poll based on current counter.
  ///
  /// Returns [FAST_INTERVAL_SECONDS] (2s) when counter < [FAST_INTERVAL_THRESHOLD] (6),
  /// and [SLOW_INTERVAL_SECONDS] (10s) when counter >= [FAST_INTERVAL_THRESHOLD].
  Duration _getPollingDelay() {
    return Duration(
      seconds: _pollingCounter < FAST_INTERVAL_THRESHOLD
          ? FAST_INTERVAL_SECONDS
          : SLOW_INTERVAL_SECONDS,
    );
  }
}
