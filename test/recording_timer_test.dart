import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dual_recorder/widgets/recording_timer.dart';
import 'package:dual_recorder/theme/ocean_colors.dart';

void main() {
  group('RecordingTimer Widget Tests', () {
    testWidgets('RecordingTimer displays duration correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingTimer(
              duration: const Duration(hours: 1, minutes: 2, seconds: 30),
              isRecording: true,
            ),
          ),
        ),
      );

      expect(find.text('01:02:30'), findsOneWidget);
    });

    testWidgets('RecordingTimer displays red indicator when recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingTimer(
              duration: const Duration(seconds: 10),
              isRecording: true,
            ),
          ),
        ),
      );

      // Find the red circle indicator
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == OceanColors.error,
        ),
        findsOneWidget,
      );
    });

    testWidgets('RecordingTimer hides indicator when not recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingTimer(
              duration: const Duration(seconds: 5),
              isRecording: false,
            ),
          ),
        ),
      );

      // When not recording, the red indicator should not be displayed
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == OceanColors.error,
        ),
        findsNothing,
      );
    });

    testWidgets('RecordingTimer formats zero duration correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingTimer(
              duration: const Duration(seconds: 0),
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.text('00:00:00'), findsOneWidget);
    });

    testWidgets('RecordingTimer displays custom color',
        (WidgetTester tester) async {
      const customColor = Color(0xFF00FF00);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingTimer(
              duration: const Duration(seconds: 15),
              isRecording: false,
              color: customColor,
            ),
          ),
        ),
      );

      expect(find.text('00:00:15'), findsOneWidget);
    });
  });
}
