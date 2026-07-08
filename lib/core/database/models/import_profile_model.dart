class ImportProfile {
  final int? id;
  final String name;          // "Intesa Sanpaolo", "N26", "Revolut"
  final String fileType;      // "xlsx" | "csv"
  final int dataStartRow;     // 0-indexed prima riga dati
  final int dateColIndex;
  final int descColIndex;
  final int amountColIndex;
  final int catColIndex;      // -1 se assente
  final String dateType;      // "serial" (Excel) | "string"
  final String dateFormat;    // solo per dateType=string: "dd/MM/yyyy"
  final String decimalSep;    // "." | ","
  final bool negativeIsExpense;
  final String csvDelimiter;  // "," | ";" | "\t"
  final String encoding;      // "utf-8" | "latin1"
  final String createdAt;

  const ImportProfile({
    this.id,
    required this.name,
    required this.fileType,
    required this.dataStartRow,
    required this.dateColIndex,
    required this.descColIndex,
    required this.amountColIndex,
    this.catColIndex = -1,
    this.dateType = 'string',
    this.dateFormat = 'dd/MM/yyyy',
    this.decimalSep = '.',
    this.negativeIsExpense = true,
    this.csvDelimiter = ';',
    this.encoding = 'utf-8',
    required this.createdAt,
  });

  ImportProfile copyWith({
    int? id, String? name, String? fileType, int? dataStartRow,
    int? dateColIndex, int? descColIndex, int? amountColIndex, int? catColIndex,
    String? dateType, String? dateFormat, String? decimalSep,
    bool? negativeIsExpense, String? csvDelimiter, String? encoding, String? createdAt,
  }) => ImportProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    fileType: fileType ?? this.fileType,
    dataStartRow: dataStartRow ?? this.dataStartRow,
    dateColIndex: dateColIndex ?? this.dateColIndex,
    descColIndex: descColIndex ?? this.descColIndex,
    amountColIndex: amountColIndex ?? this.amountColIndex,
    catColIndex: catColIndex ?? this.catColIndex,
    dateType: dateType ?? this.dateType,
    dateFormat: dateFormat ?? this.dateFormat,
    decimalSep: decimalSep ?? this.decimalSep,
    negativeIsExpense: negativeIsExpense ?? this.negativeIsExpense,
    csvDelimiter: csvDelimiter ?? this.csvDelimiter,
    encoding: encoding ?? this.encoding,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'file_type': fileType,
    'data_start_row': dataStartRow,
    'date_col': dateColIndex,
    'desc_col': descColIndex,
    'amount_col': amountColIndex,
    'cat_col': catColIndex,
    'date_type': dateType,
    'date_format': dateFormat,
    'decimal_sep': decimalSep,
    'negative_is_expense': negativeIsExpense ? 1 : 0,
    'csv_delimiter': csvDelimiter,
    'encoding': encoding,
    'created_at': createdAt,
  };

  factory ImportProfile.fromMap(Map<String, dynamic> m) => ImportProfile(
    id: m['id'] as int?,
    name: m['name'] as String,
    fileType: m['file_type'] as String,
    dataStartRow: m['data_start_row'] as int,
    dateColIndex: m['date_col'] as int,
    descColIndex: m['desc_col'] as int,
    amountColIndex: m['amount_col'] as int,
    catColIndex: (m['cat_col'] as int?) ?? -1,
    dateType: (m['date_type'] as String?) ?? 'string',
    dateFormat: (m['date_format'] as String?) ?? 'dd/MM/yyyy',
    decimalSep: (m['decimal_sep'] as String?) ?? '.',
    negativeIsExpense: ((m['negative_is_expense'] as int?) ?? 1) == 1,
    csvDelimiter: (m['csv_delimiter'] as String?) ?? ';',
    encoding: (m['encoding'] as String?) ?? 'utf-8',
    createdAt: m['created_at'] as String,
  );

  // Profilo predefinito per Intesa Sanpaolo (compatibilità con vecchio parser)
  static ImportProfile get intesaSanpaolo => ImportProfile(
    name: 'Intesa Sanpaolo',
    fileType: 'xlsx',
    dataStartRow: 17,
    dateColIndex: 0,
    descColIndex: 2,
    amountColIndex: 7,
    catColIndex: 5,
    dateType: 'serial',
    dateFormat: 'dd/MM/yyyy',
    decimalSep: '.',
    negativeIsExpense: true,
    csvDelimiter: ';',
    encoding: 'utf-8',
    createdAt: DateTime.now().toIso8601String(),
  );
}
