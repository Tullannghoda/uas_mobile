import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = SupabaseService.client;

  Future<UserModel> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login gagal');
    }

    // Ambil data profil
    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    final user = UserModel.fromJson(profileData);
    
    // Save to local storage for quick access
    await LocalStorageService.saveToken(response.session?.accessToken ?? '');
    await LocalStorageService.saveUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      department: user.department,
    );
    
    return user;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? department,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': 'user', // Default role untuk registrasi
        if (phone != null) 'phone': phone,
        if (department != null) 'department': department,
      },
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    await LocalStorageService.clearAll();
  }

  UserModel? getCurrentUser() {
    final id = LocalStorageService.getUserId();
    if (id == null) return null;
    return UserModel(
      id: id,
      name: LocalStorageService.getUserName() ?? '',
      email: LocalStorageService.getUserEmail() ?? '',
      role: LocalStorageService.getUserRole() ?? 'user',
      phone: LocalStorageService.getUserPhone(),
      department: LocalStorageService.getUserDepartment(),
    );
  }

  bool isLoggedIn() => _supabase.auth.currentSession != null;
  
  // Fitur Admin: Get all helpdesk
  Future<List<UserModel>> getHelpdeskList() async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'helpdesk');
    
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  // Fitur Admin: Create Helpdesk Account
  // Supabase Auth requires admin privileges to create other users without signing in.
  // We can do this via an edge function, or sign up and re-login admin.
  // Tapi untuk simplifikasi di sisi client dengan Supabase flutter:
  // Supabase belum mengizinkan create user by admin langsung dari client SDK (hanya lewat Service Role key).
  // Oleh karena itu kita asumsikan di sini Admin sudah menambahkan Helpdesk secara manual di Dashboard,
  // atau kita menggunakan trik menyimpan session saat ini, sign up user baru, lalu restore session.
  Future<void> createHelpdeskAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    // Note: Cara termudah tanpa Edge Function adalah menyimpan email/password admin,
    // buat akun baru, logout, login admin lagi. Tapi itu tidak aman.
    // Solusi: Kita pakai SignUp biasa (akan mengganti current session).
    // Karena ini project responsi, ini workaround yang sering dipakai.
    // Yang benar adalah menggunakan RPC function dengan pgcrypto di DB, 
    // atau menggunakan Service Role Key di server backend.
    
    // Di sini kita catat error jika tidak diimplementasi backend.
    throw Exception('Pendaftaran akun helpdesk harus melalui Edge Function atau Supabase Dashboard untuk alasan keamanan.');
  }

  // Fitur Admin: Delete User (Soft Delete / Non-Aktif)
  Future<void> deleteUser(String id) async {
    try {
      // Mengubah status user menjadi tidak aktif di tabel profiles
      await _supabase.from('profiles').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Gagal menonaktifkan pengguna: ${e.toString()}');
    }
  }
}