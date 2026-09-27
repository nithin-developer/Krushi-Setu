import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/app/models/blog_model.dart';

class BlogService {
  Future<List<BlogModel>> fetchBlogs({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('${AppConstants.baseUrl}/blogs').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List blogsJson = data['blogs'] ?? [];
        return blogsJson.map((j) => BlogModel.fromJson(j)).toList();
      } else {
        throw Exception('Failed to load blogs (Status ${response.statusCode})');
      }
    } catch (e) {
      // Fallback / Mock items if server connection is offline during dev
      return _getFallbackBlogs();
    }
  }

  Future<BlogModel?> fetchBlogById(String blogId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/blogs/$blogId');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BlogModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  List<BlogModel> _getFallbackBlogs() {
    final now = DateTime.now();
    return [
      BlogModel(
        id: 'adv-1',
        title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
        slug: 'pm-kisan-scheme',
        summary: 'Direct income support of ₹6,000 per year in three equal installments to all landholding farmer families.',
        content: 'Under PM-KISAN, financial assistance of ₹6,000/year is transferred directly into Aadhaar-seeded bank accounts of beneficiary farmers. Ensure farmers have completed e-KYC and updated land records in the Krushi Setu Digital Twin.',
        coverImage: 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=800&q=80',
        category: 'scheme',
        categoryLabel: 'Govt Scheme',
        tags: ['PM-KISAN', 'Subsidy', 'Income Support'],
        targetCrops: ['All Crops'],
        author: 'Ministry of Agriculture & Farmers Welfare',
        status: 'published',
        viewsCount: 1240,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      BlogModel(
        id: 'adv-2',
        title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        slug: 'pmfby-crop-insurance',
        summary: 'Comprehensive crop insurance coverage against non-preventable natural risks from pre-sowing to post-harvest.',
        content: 'Covers financial loss suffered due to natural calamities like drought, flood, pests, and diseases. Farmers pay a nominal premium: 2% for Kharif crops, 1.5% for Rabi crops, and 5% for commercial/horticultural crops.',
        coverImage: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=800&q=80',
        category: 'scheme',
        categoryLabel: 'Crop Insurance',
        tags: ['Insurance', 'Risk Relief'],
        targetCrops: ['Paddy', 'Wheat', 'Cotton'],
        author: 'Government of India',
        status: 'published',
        viewsCount: 980,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      BlogModel(
        id: 'adv-3',
        title: 'Kharif Paddy: Blast & Stem Borer Management',
        slug: 'paddy-blast-management',
        summary: 'High humidity and cloudy weather increase blast disease incidence in early-tillering paddy.',
        content: 'Monitor for spindle-shaped lesions on leaves with brown margins. Spray Tricyclazole 75% WP @ 0.6g/L or Isoprothiolane 40% EC @ 1.5ml/L of water. For stem borer, set up pheromone traps @ 5/acre.',
        coverImage: 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=800&q=80',
        category: 'pest',
        categoryLabel: 'Pest Alert',
        tags: ['Paddy', 'Disease Control', 'Blast'],
        targetCrops: ['Paddy (Rice)'],
        author: 'ICAR - Indian Agricultural Research Institute',
        status: 'published',
        viewsCount: 1560,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
