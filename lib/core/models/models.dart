class User {
  final String id;
  final String displayId;
  final String? contactHint;
  User({required this.id, required this.displayId, this.contactHint});
  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'] ?? '', displayId: j['displayId'] ?? '', contactHint: j['contactHint']);
}

class GovOfficial {
  final String id;
  final String username;
  final String fullName;
  final String agency;
  final String role;
  GovOfficial({required this.id, required this.username, required this.fullName, required this.agency, required this.role});
  factory GovOfficial.fromJson(Map<String, dynamic> j) => GovOfficial(
    id: j['id'] ?? '', username: j['username'] ?? '',
    fullName: j['full_name'] ?? j['fullName'] ?? '',
    agency: j['agency'] ?? '', role: j['role'] ?? 'analyst',
  );
  bool get isAdmin => role == 'admin';
}

class Report {
  final String id;
  final String title;
  final String content;
  final String status;
  final String priority;
  final String? categoryName;
  final String? categoryColor;
  final String? locationProvince;
  final String? locationCity;
  final String? locationDetail;
  final String? authorDisplayId;
  final int viewCount;
  final int supportCount;
  final int commentCount;
  final DateTime createdAt;

  Report({
    required this.id, required this.title, required this.content,
    required this.status, required this.priority,
    this.categoryName, this.categoryColor,
    this.locationProvince, this.locationCity, this.locationDetail,
    this.authorDisplayId,
    required this.viewCount, required this.supportCount, required this.commentCount,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    content: j['content'] ?? '',
    status: j['status'] ?? 'pending',
    priority: j['priority'] ?? 'normal',
    categoryName: j['category_name'],
    categoryColor: j['category_color'],
    locationProvince: j['location_province'],
    locationCity: j['location_city'],
    locationDetail: j['location_detail'],
    authorDisplayId: j['author_display_id'],
    viewCount: j['view_count'] ?? 0,
    supportCount: int.tryParse(j['support_count']?.toString() ?? '0') ?? 0,
    commentCount: int.tryParse(j['comment_count']?.toString() ?? '0') ?? 0,
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Menunggu';
      case 'verified': return 'Terverifikasi';
      case 'investigating': return 'Ditindaklanjuti';
      case 'resolved': return 'Selesai';
      case 'rejected': return 'Ditolak';
      default: return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'critical': return 'Kritis';
      case 'high': return 'Tinggi';
      case 'normal': return 'Normal';
      case 'low': return 'Rendah';
      default: return priority;
    }
  }
}

class ReportMedia {
  final String id;
  final String fileUrl;
  ReportMedia({required this.id, required this.fileUrl});
  factory ReportMedia.fromJson(Map<String, dynamic> j) =>
      ReportMedia(id: j['id'] ?? '', fileUrl: j['file_url'] ?? '');
  String get fullUrl {
    if (fileUrl.startsWith('http')) return fileUrl;
    return 'https://suararakyat.duckdns.org' + fileUrl;
  }
}

class Comment {
  final String id;
  final String content;
  final String? authorDisplayId;
  final bool isOfficial;
  final DateTime createdAt;
  Comment({required this.id, required this.content, this.authorDisplayId, required this.isOfficial, required this.createdAt});
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
    id: j['id'] ?? '', content: j['content'] ?? '',
    authorDisplayId: j['author_display_id'],
    isOfficial: j['is_official'] == true,
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String color;
  Category({required this.id, required this.name, required this.slug, required this.color});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'] ?? 0, name: j['name'] ?? '', slug: j['slug'] ?? '', color: j['color'] ?? '#1D9BF0');
}
