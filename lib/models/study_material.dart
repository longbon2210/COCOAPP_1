class StudyMaterial {
  final String id;
  final String title;
  final String courseName;
  final String fileType; // PDF, DOCX, ZIP
  final String fileSize;
  final String authorName;
  final String university;
  final int downloadCount;
  final int likesCount;
  final double rating;
  final String description;
  final DateTime uploadDate;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.courseName,
    required this.fileType,
    required this.fileSize,
    required this.authorName,
    required this.university,
    required this.downloadCount,
    required this.likesCount,
    required this.rating,
    required this.description,
    required this.uploadDate,
  });

  static List<StudyMaterial> getSampleMaterials() {
    return [];
  }
}
