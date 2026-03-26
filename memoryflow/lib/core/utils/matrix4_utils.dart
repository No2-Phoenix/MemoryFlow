import 'package:flutter/material.dart';
import 'dart:math' as math;

class Matrix4Utils {
  static Matrix4 createTiltTransform({
    required double tiltX,
    required double tiltY,
    double perspective = 0.001,
  }) {
    final matrix = Matrix4.identity()..setEntry(3, 2, perspective);

    matrix.rotateX(tiltY * math.pi / 180);
    matrix.rotateY(tiltX * math.pi / 180);

    return matrix;
  }

  static Matrix4 createCardTilt({
    required Offset focalPoint,
    required Size cardSize,
    double maxTilt = 15.0,
  }) {
    final center = Offset(cardSize.width / 2, cardSize.height / 2);
    final offset = focalPoint - center;

    final tiltX = (offset.dy / center.dy) * maxTilt;
    final tiltY = -(offset.dx / center.dx) * maxTilt;

    return createTiltTransform(tiltX: tiltX, tiltY: tiltY);
  }

  static Matrix4 createPerspectiveTransform({double perspective = 0.001}) {
    return Matrix4.identity()..setEntry(3, 2, perspective);
  }

  static Matrix4 createRotationTransform({
    double angle = 0,
    String axis = 'y',
  }) {
    final matrix = Matrix4.identity();
    if (axis == 'x') {
      matrix.rotateX(angle);
    } else if (axis == 'y') {
      matrix.rotateY(angle);
    } else {
      matrix.rotateZ(angle);
    }
    return matrix;
  }

  static Matrix4 createScaleTransform({
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    return Matrix4.identity()..scaleByDouble(scaleX, scaleY, 1.0, 1.0);
  }

  static Matrix4 createTranslateTransform({
    double x = 0,
    double y = 0,
    double z = 0,
  }) {
    return Matrix4.identity()..translateByDouble(x, y, z, 1.0);
  }

  static Offset getTransformedPoint(Matrix4 matrix, Offset point) {
    final vector = Vector4(point.dx, point.dy, 0, 1);
    final transformed = matrix.transform4(vector);
    return Offset(transformed.x, transformed.y);
  }
}

class Vector4 {
  final double x, y, z, w;
  Vector4(this.x, this.y, this.z, this.w);
}

extension Matrix4Extension on Matrix4 {
  Vector4 transform4(Vector4 vector) {
    final storage = this.storage;
    return Vector4(
      storage[0] * vector.x +
          storage[4] * vector.y +
          storage[8] * vector.z +
          storage[12] * vector.w,
      storage[1] * vector.x +
          storage[5] * vector.y +
          storage[9] * vector.z +
          storage[13] * vector.w,
      storage[2] * vector.x +
          storage[6] * vector.y +
          storage[10] * vector.z +
          storage[14] * vector.w,
      storage[3] * vector.x +
          storage[7] * vector.y +
          storage[11] * vector.z +
          storage[15] * vector.w,
    );
  }
}
