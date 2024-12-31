class Goal {
  String name;
  int? count;
  double? value;

  Goal({required this.name, this.count, this.value});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'count': count,
      'value': value,
    };
  }
}
