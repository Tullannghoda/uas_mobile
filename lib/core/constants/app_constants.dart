class AppConstants {
  AppConstants._();

  // Roles
  static const String roleUser = 'user';
  static const String roleHelpdesk = 'helpdesk';
  static const String roleAdmin = 'admin';

  // Ticket Status
  static const String statusSend = 'send';
  static const String statusOpen = 'open';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';
  static const String statusClosed = 'closed';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeDashboard = '/dashboard';
  static const String routeTicketList = '/tickets';
  static const String routeTicketDetail = '/ticket-detail';
  static const String routeCreateTicket = '/create-ticket';
  static const String routeProfile = '/profile';
  static const String routeNotification = '/notification';

  // SharedPreferences Keys
  static const String keyToken = 'token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyThemeMode = 'theme_mode';

  // App Info
  static const String appName = 'E-Helpdesk';
  static const String appVersion = '2.0.0';

  // Supabase Info
  static const String supabaseUrl = 'https://fakapmaalxymvskkdxor.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZha2FwbWFhbHh5bXZza2tkeG9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMyNjM2NDAsImV4cCI6MjA5ODgzOTY0MH0.1BvxgJwERqjyuwulFNcxjr58UaBb8dEmCb09bMbyseE';
}