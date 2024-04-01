import 'dart:convert';

class CallerInfo {
  String? id;
  String? name;
  CallerInfo({
    this.id,
    this.name,
  });

  @override
  bool operator ==(covariant CallerInfo other) {
    if (identical(this, other)) return true;

    return other.name == name && other.id == id;
  }

  @override
  int get hashCode => name.hashCode ^ id.hashCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  factory CallerInfo.fromMap(Map<String, dynamic> map) {
    return CallerInfo(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CallerInfo.fromJson(String source) => CallerInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}
