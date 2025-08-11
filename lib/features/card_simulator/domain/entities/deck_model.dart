import 'dart:convert';

class DeckModel {
  final String name;
  final List<String> imagePaths; // absolute file paths

  const DeckModel({required this.name, required this.imagePaths});

  Map<String, dynamic> toJson() => {
        'name': name,
        'imagePaths': imagePaths,
      };

  factory DeckModel.fromJson(Map<String, dynamic> json) => DeckModel(
        name: json['name'] as String,
        imagePaths: (json['imagePaths'] as List).map((e) => e as String).toList(),
      );

  String encode() => jsonEncode(toJson());
  factory DeckModel.decode(String s) => DeckModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}


