class ImportBatch {
  final int id;
  final String fileName;
  final String? profileName;
  final String importedAt;
  final int recordCount;

  const ImportBatch({
    required this.id,
    required this.fileName,
    this.profileName,
    required this.importedAt,
    required this.recordCount,
  });

  factory ImportBatch.fromMap(Map<String, dynamic> m) => ImportBatch(
        id: m['id'] as int,
        fileName: m['file_name'] as String,
        profileName: m['profile_name'] as String?,
        importedAt: m['imported_at'] as String,
        recordCount: m['record_count'] as int,
      );
}
