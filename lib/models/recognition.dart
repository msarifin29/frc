// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/foundation.dart';

class Recognition {
  final String name;
  final List<double> embedding;
  final double distance;

  Recognition({this.name = '', this.embedding = const [], this.distance = 0.0});

  Recognition copyWith({String? name, List<double>? embedding, double? distance}) {
    return Recognition(
      name: name ?? this.name,
      embedding: embedding ?? this.embedding,
      distance: distance ?? this.distance,
    );
  }

  @override
  String toString() {
    return 'Recognition(name: $name, embedding: $embedding, distance: $distance)';
  }

  @override
  bool operator ==(covariant Recognition other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        listEquals(other.embedding, embedding) &&
        other.distance == distance;
  }

  @override
  int get hashCode {
    return name.hashCode ^ embedding.hashCode ^ distance.hashCode;
  }
}
