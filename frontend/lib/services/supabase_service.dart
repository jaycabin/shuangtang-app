import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

/// 封装所有 Supabase 操作，Flutter 页面只需调这些方法
class SupabaseService {
  final supabase = Supabase.instance.client;

  // ========== 单例 ==========
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  // ========== 当前用户 ==========
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String get userId => currentUser!.id;

  // ========== Auth ==========
  Future<AuthResponse> signUp(String email, String password) async {
    return supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ========== Couple 情侣空间 ==========
  Future<Map<String, dynamic>> createCouple() async {
    final code = await supabase.rpc('create_couple');
    return {'invitation_code': code};
  }

  Future<bool> joinCouple(String code) async {
    final result = await supabase.rpc('join_couple', params: {'code': code});
    return result as bool;
  }

  Future<Map<String, dynamic>?> getMyCouple() async {
    final data = await supabase
        .from('couples')
        .select('*, profiles!couples_user1_id_fkey(*), profiles!couples_user2_id_fkey(*)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .eq('status', 'active')
        .maybeSingle();
    return data;
  }

  Future<Map<String, dynamic>?> getPartner() async {
    final data = await supabase.rpc('get_partner').maybeSingle();
    return data;
  }

  // ========== Moments 时光轴 ==========
  Future<List<Map<String, dynamic>>> getTimeline(String coupleId, {int limit = 20}) async {
    final data = await supabase
        .from('moments')
        .select('*, profiles!moments_author_id_fkey(nickname, avatar_url)')
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false)
        .limit(limit);
    return data;
  }

  Future<void> createMoment(String coupleId, {
    required String content,
    List<String> imageUrls = const [],
    Map<String, dynamic>? location,
    String? moodTag,
  }) async {
    await supabase.from('moments').insert({
      'couple_id': coupleId,
      'author_id': userId,
      'type': 'moment',
      'content': content,
      'image_urls': imageUrls,
      'location': location,
      'mood_tag': moodTag,
    });
  }

  /// Realtime 订阅时光轴变化
  RealtimeChannel subscribeTimeline(String coupleId, Function(Map<String, dynamic>) onEvent) {
    return supabase
        .channel('timeline:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'moments',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'couple_id', value: coupleId),
          callback: (payload) => onEvent(payload.newRecord),
        )
        .subscribe();
  }

  // ========== Anniversaries 纪念日 ==========
  Future<List<Map<String, dynamic>>> getAnniversaries(String coupleId) async {
    return supabase
        .from('anniversaries')
        .select()
        .eq('couple_id', coupleId)
        .order('date', ascending: true);
  }

  Future<void> createAnniversary(String coupleId, {
    required Map<String, String> title,
    required DateTime date,
    bool recurring = true,
    int remindBefore = 1,
    String icon = '❤️',
  }) async {
    await supabase.from('anniversaries').insert({
      'couple_id': coupleId,
      'title': title,
      'date': date.toIso8601String().split('T')[0],
      'is_recurring': recurring,
      'remind_before': remindBefore,
      'icon': icon,
      'created_by': userId,
    });
  }

  // ========== Check-in 打卡 ==========
  Future<List<Map<String, dynamic>>> getCheckInTasks(String coupleId) async {
    return supabase
        .from('check_in_tasks')
        .select<dynamic>()
        .eq('couple_id', coupleId)
        .eq('is_active', true)
        .order('sort_order');
  }

  Future<void> doCheckIn(String taskId) async {
    await supabase.from('check_in_records').insert({
      'task_id': taskId,
      'user_id': userId,
      'check_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<List<Map<String, dynamic>>> getCheckInRecords(String coupleId) async {
    return supabase
        .from('check_in_records')
        .select('*, check_in_tasks!inner(couple_id)')
        .eq('check_in_tasks.couple_id', coupleId)
        .order('check_date', ascending: false);
  }

  // ========== Wishlist 愿望清单 ==========
  Future<List<Map<String, dynamic>>> getWishlist(String coupleId) async {
    return supabase
        .from('wishlist_items')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false);
  }

  Future<void> addWish(String coupleId, Map<String, String> title) async {
    await supabase.from('wishlist_items').insert({
      'couple_id': coupleId,
      'creator_id': userId,
      'title': title,
    });
  }

  Future<void> claimWish(String wishId) async {
    await supabase.from('wishlist_items').update({
      'status': 'claimed',
      'claimed_by': userId,
    }).eq('id', wishId);
  }

  Future<void> completeWish(String wishId) async {
    await supabase.from('wishlist_items').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', wishId);
  }

  // ========== Secret Messages 悄悄话 ==========
  Future<List<Map<String, dynamic>>> getSecretMessages(String coupleId) async {
    return supabase
        .from('secret_messages')
        .select('*, profiles!secret_messages_sender_id_fkey(nickname)')
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false)
        .limit(50);
  }

  Future<void> sendSecretMessage(String coupleId, String content) async {
    await supabase.from('secret_messages').insert({
      'couple_id': coupleId,
      'sender_id': userId,
      'content': content,
    });
  }

  Future<void> markSecretRead(String messageId) async {
    await supabase.from('secret_messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  // ========== Albums 相册 ==========
  Future<List<Map<String, dynamic>>> getAlbums(String coupleId) async {
    return supabase
        .from('albums')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false);
  }

  Future<String> uploadPhoto(String coupleId, String filePath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('albums').upload(fileName, filePath);
    final url = supabase.storage.from('albums').getPublicUrl(fileName);

    await supabase.from('albums').insert({
      'couple_id': coupleId,
      'uploader_id': userId,
      'image_url': url,
    });
    return url;
  }

  // ========== Location Sharing 位置共享 ==========
  Future<void> shareLocation(String coupleId, double lat, double lng, int battery, bool moving) async {
    await supabase.from('location_shares').insert({
      'couple_id': coupleId,
      'user_id': userId,
      'latitude': lat,
      'longitude': lng,
      'battery_level': battery,
      'is_moving': moving,
    });
  }

  /// 实时监听伴侣位置
  RealtimeChannel subscribeLocation(String coupleId, Function(Map<String, dynamic>) onUpdate) {
    return supabase
        .channel('location:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'location_shares',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'couple_id', value: coupleId),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  // ========== Notifications 通知 ==========
  Future<List<Map<String, dynamic>>> getNotifications() async {
    return supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
  }

  Future<void> markNotifRead(String id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }
}
