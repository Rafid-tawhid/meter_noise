import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WaveGraph extends StatelessWidget {
  final List<double> values; // Replace this with your actual data

  WaveGraph(this.values);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(300, 150), // Set the size of your wave graph
      painter: WaveGraphPainter(values),
    );
  }
}
class WaveGraphPainter extends CustomPainter {
  final List<double> values;
  final Paint wavePaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  WaveGraphPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final height = size.height;

    // Start drawing the wave from the left side of the widget
    path.moveTo(0, height * values[0]);

    for (int i = 1; i < values.length; i++) {
      // Calculate the x-coordinate for the current point
      final x = size.width * i / (values.length - 1);
      // Calculate the y-coordinate for the current point
      final y = height * values[i];
      // Draw a line to the current point
      path.lineTo(x, y);
    }

    // Draw the path
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
