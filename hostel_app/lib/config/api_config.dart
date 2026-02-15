/// API Configuration
/// Change this to your server's URL when deploying
class ApiConfig {
  // For local development with Android emulator, use 10.0.2.2
  // For physical device, use your computer's IP address
  // For iOS simulator, use localhost
  // For production, use your deployed Next.js URL
  
  // const String baseUrl = 'http://localhost:3000'; // Android emulator
  static const String baseUrl = 'http://localhost:3000'; // iOS simulator / Web
  // static const String baseUrl = 'http://192.168.x.x:3000'; // Physical device - replace with your IP
  // const String baseUrl = 'https://dbmsproj-xi.vercel.app'; // Production
  
  static const Duration timeout = Duration(seconds: 30);
}
