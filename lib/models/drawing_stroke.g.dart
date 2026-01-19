// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_stroke.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawingPointAdapter extends TypeAdapter<DrawingPoint> {
  @override
  final int typeId = 3;

  @override
  DrawingPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingPoint(
      x: fields[0] as double,
      y: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DrawingPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DrawingStrokeAdapter extends TypeAdapter<DrawingStroke> {
  @override
  final int typeId = 4;

  @override
  DrawingStroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingStroke(
      points: (fields[0] as List).cast<DrawingPoint>(),
      colorValue: fields[1] as int,
      strokeWidth: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DrawingStroke obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.points)
      ..writeByte(1)
      ..write(obj.colorValue)
      ..writeByte(2)
      ..write(obj.strokeWidth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingStrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
