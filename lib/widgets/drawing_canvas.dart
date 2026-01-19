import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:soul_note/models/drawing_stroke.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawingStroke> initialStrokes;
  final Function(List<DrawingStroke>) onStrokesChanged;

  const DrawingCanvas({
    super.key,
    required this.initialStrokes,
    required this.onStrokesChanged,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late List<DrawingStroke> strokes;
  Color selectedColor = Colors.white;
  double selectedWidth = 5.0;

  final List<Color> palette = [
    Colors.white,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    const Color(0xFF6366F1), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    strokes = List.from(widget.initialStrokes);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      strokes.add(DrawingStroke(
        points: [DrawingPoint(x: details.localPosition.dx, y: details.localPosition.dy)],
        colorValue: selectedColor.toARGB32(),
        strokeWidth: selectedWidth,
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      strokes.last.points.add(DrawingPoint(x: details.localPosition.dx, y: details.localPosition.dy));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onStrokesChanged(strokes);
  }

  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
      widget.onStrokesChanged(strokes);
    }
  }

  void _clear() {
    setState(() {
      strokes.clear();
    });
    widget.onStrokesChanged(strokes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🎨 TOOLBAR
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Colors Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: palette.map((color) => GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (selectedColor == color)
                            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Brush Size & Actions
              Row(
                children: [
                  const Icon(Icons.brush, color: Colors.white54, size: 18),
                  Expanded(
                    child: Slider(
                      value: selectedWidth,
                      min: 1,
                      max: 20,
                      activeColor: selectedColor,
                      onChanged: (val) => setState(() => selectedWidth = val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, color: Colors.white),
                    onPressed: _undo,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    onPressed: _clear,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 🖌️ CANVAS
        Expanded(
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xFF151B2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: StrokePainter(strokes: strokes),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  StrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Use perfect_freehand for smooth artistic strokes
      final outlinePoints = getStroke(
        stroke.points.map((p) => Point(p.x, p.y)).toList(),
        options: StrokeOptions(
          size: stroke.strokeWidth,
          thinning: 0.5,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      final path = Path();
      if (outlinePoints.isNotEmpty) {
        path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
        for (var i = 1; i < outlinePoints.length; i++) {
          path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}
