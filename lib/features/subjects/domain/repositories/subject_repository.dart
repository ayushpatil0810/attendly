import '../entities/subject.dart';

abstract interface class SubjectRepository {
  Stream<List<Subject>> watchSubjectsForSemester(int semesterId);
  Future<List<Subject>> getSubjectsForSemester(int semesterId);
  Future<Subject?> getSubjectById(int id);
  Future<int> createSubject({
    required int semesterId,
    required String name,
    bool lectureEnabled = true,
    bool labEnabled = false,
    int sortOrder = 0,
  });
  Future<void> updateSubject(Subject subject);
  Future<void> deleteSubject(int id);
}
