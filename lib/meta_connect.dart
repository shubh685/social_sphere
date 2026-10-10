import 'dart:convert';
import 'package:http/http.dart' as http;

class MetaApiService {
  // Replace with your generated User Access Token from Meta Graph API Explorer
  static const String userAccessToken = 'EAAPtJOwQSrkBSnXkDDQgU4KuZBgmc8c3RqCN85XrZCn5SAGNNlUp6fzifwBrePg0BzC4xgnhkq3gW1yxpFw9YZCuwa8grIwIZC32aR5acVGl9eJ1h7VMKFN6vGY0eFNIZAe4t9qZBtckJ7h8zWlLMA2aQMlBlJWa2JRXl45eVHLoZA9uCBc9H0KtAk3H8yeeq8e3PPvGZCKenul0rY1GzV5ZCEgLDzXIQSwZC1j3kGdCa3qU2Vq7wLUZBX5keKA3f94o9drtbZAf0plv22FBepG6Q8oj';

  /// Fetches Facebook Pages managed by the user
  static Future<List<Map<String, dynamic>>> fetchFacebookPages() async {
    final url = Uri.parse(
      'https://graph.facebook.com/v26.0/me/accounts?fields=id,name,access_token,instagram_business_account&access_token=$userAccessToken',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception('Failed to fetch pages: ${response.body}');
  }
}