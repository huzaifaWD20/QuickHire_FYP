class AppConfig {
  // Server configuration
  static const String serverIP = "192.168.100.233";
  static const String apiBaseUrl = "http://$serverIP:5000";
  static const String socketUrl = "http://$serverIP:5000";
  
  // API endpoints
  static const String authEndpoint = "$apiBaseUrl/api/v1/auth"; // Added v1 to the path
  static const String projectsEndpoint = "$apiBaseUrl/api/v1/projects";
  
  // Auth endpoints
  static const String loginEndpoint = "$authEndpoint/login";
  static const String signupEndpoint = "$authEndpoint/register"; // Changed from signup to register
  static const String resendOtpEndpoint = "$authEndpoint/resend-otp";
  
  // Other global configuration
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}


