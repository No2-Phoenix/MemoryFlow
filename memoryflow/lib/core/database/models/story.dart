class Story {
  int id;
  String title;
  String? subtitle;
  String? dateLabel;
  String? location;
  String? caption;
  DateTime createdAt;
  DateTime updatedAt;
  List<Photo> photos;
  String? ambientMusicPath;
  int? dominantColor;
  double? latitude;
  double? longitude;
  List<String> lines;
  List<int> palette;
  String? coverImagePath;
  double coverBlurSigma;
  String? cameraModel;
  String? textMode;
  bool showDate;
  bool showLocation;
  bool showAmbient;
  bool isUserCreated;

  Story({
    this.id = 0,
    required this.title,
    this.subtitle,
    this.dateLabel,
    this.location,
    this.caption,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Photo>? photos,
    this.ambientMusicPath,
    this.dominantColor,
    this.latitude,
    this.longitude,
    List<String>? lines,
    List<int>? palette,
    this.coverImagePath,
    this.coverBlurSigma = 2.0,
    this.cameraModel,
    this.textMode,
    this.showDate = true,
    this.showLocation = true,
    this.showAmbient = true,
    this.isUserCreated = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       photos = photos ?? [],
       lines = lines ?? [],
       palette = palette ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'dateLabel': dateLabel,
    'location': location,
    'caption': caption,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'ambientMusicPath': ambientMusicPath,
    'dominantColor': dominantColor,
    'latitude': latitude,
    'longitude': longitude,
    'lines': lines,
    'palette': palette,
    'coverImagePath': coverImagePath,
    'coverBlurSigma': coverBlurSigma,
    'cameraModel': cameraModel,
    'textMode': textMode,
    'showDate': showDate,
    'showLocation': showLocation,
    'showAmbient': showAmbient,
    'isUserCreated': isUserCreated,
  };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    subtitle: json['subtitle'],
    dateLabel: json['dateLabel'],
    location: json['location'],
    caption: json['caption'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    photos:
        (json['photos'] as List<dynamic>?)
            ?.map((p) => Photo.fromJson(p))
            .toList() ??
        [],
    ambientMusicPath: json['ambientMusicPath'],
    dominantColor: json['dominantColor'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    lines: (json['lines'] as List<dynamic>?)?.map((line) => '$line').toList(),
    palette: (json['palette'] as List<dynamic>?)
        ?.map((color) => color as int)
        .toList(),
    coverImagePath: json['coverImagePath'],
    coverBlurSigma: (json['coverBlurSigma'] as num?)?.toDouble() ?? 2.0,
    cameraModel: json['cameraModel'],
    textMode: json['textMode'],
    showDate: json['showDate'] as bool? ?? true,
    showLocation: json['showLocation'] as bool? ?? true,
    showAmbient: json['showAmbient'] as bool? ?? true,
    isUserCreated: json['isUserCreated'] ?? false,
  );
}

class Photo {
  int id;
  int? storyId;
  String localPath;
  String? storyText;
  DateTime? takenAt;
  double? latitude;
  double? longitude;
  String? locationName;
  DateTime createdAt;

  Photo({
    this.id = 0,
    this.storyId,
    required this.localPath,
    this.storyText,
    this.takenAt,
    this.latitude,
    this.longitude,
    this.locationName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'storyId': storyId,
    'localPath': localPath,
    'storyText': storyText,
    'takenAt': takenAt?.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'] ?? 0,
    storyId: json['storyId'],
    localPath: json['localPath'] ?? '',
    storyText: json['storyText'],
    takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt']) : null,
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    locationName: json['locationName'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
