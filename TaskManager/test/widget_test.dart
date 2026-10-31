
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter khởi tạo giao diện thành công', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Task Manager'),
        ),
      ),
    );

    expect(find.text('Task Manager'), findsOneWidget);
  });
}
