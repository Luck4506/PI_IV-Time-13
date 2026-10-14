part of '../../telas_professor.dart';

class ClassInfo {
  const ClassInfo(this.name, this.students, this.average);
  final String name;
  final int students;
  final int average;
  static const samples = [
    ClassInfo('3º A', 31, 68),
    ClassInfo('3º B', 29, 73),
    ClassInfo('2º A', 32, 77),
  ];
}
