import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_assets.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ScrollController _scrollController = ScrollController();

  late int _selectedTheme;
  late bool _autoRealTimeTheme;

  bool _waterReminder = true;
  bool _sleepReminder = true;
  bool _workoutReminder = true;
  bool _screenTimeReminder = true;
  bool _quoteReminder = true;

  String _nickname = 'Nickname';
  String _username = '@username';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _selectedTheme = AppColors.currentTheme.index;
    _autoRealTimeTheme = AppColors.autoRealTimeTheme;
    _loadUserInfo();
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _waterReminder = prefs.getBool('water_reminder') ?? true;
      _sleepReminder = prefs.getBool('sleep_reminder') ?? true;
      _workoutReminder = prefs.getBool('workout_reminder') ?? true;
      _screenTimeReminder = prefs.getBool('screentime_reminder') ?? true;
      _quoteReminder = prefs.getBool('quote_reminder') ?? true;
    });

    // Khởi tạo dịch vụ thông báo và lên lịch
    await NotificationService.init();
    NotificationService.scheduleWaterReminder(_waterReminder);
    NotificationService.scheduleSleepReminder(_sleepReminder);
    NotificationService.scheduleWorkoutReminder(_workoutReminder);
    NotificationService.scheduleQuoteReminder(_quoteReminder);
  }

  void _updateReminderSetting(String key, bool val, Function(bool) scheduleCall) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    scheduleCall(val);
  }

  void _loadUserInfo() async {
    final profile = await UserRepository.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        if (profile.fullName != null && profile.fullName!.isNotEmpty) {
          _nickname = profile.fullName!;
        } else if (profile.username.isNotEmpty) {
          _nickname = profile.username;
        }
        _username = '@${profile.username.toLowerCase().replaceAll(' ', '')}';
        _avatarUrl = profile.avatarUrl;
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      final name = user.userMetadata?['username'] as String?;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _nickname = name;
          _username = '@${name.toLowerCase().replaceAll(' ', '')}';
        });
      } else if (user.email != null) {
        final emailPrefix = user.email!.split('@').first;
        setState(() {
          _nickname = emailPrefix;
          _username = '@$emailPrefix';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 175.0;
    const double profileCardTop = 135.0;
    const double clipTop = 95.0;

    return ListenableBuilder(
      listenable: AppColors.instance,
      builder: (context, child) {
        _selectedTheme = AppColors.currentTheme.index;
        _autoRealTimeTheme = AppColors.autoRealTimeTheme;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: Stack(
                  children: [
                    Image.asset(
                      AppColors.mountainImage,
                      width: double.infinity,
                      height: headerHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: headerHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE0F2FE),
                                AppColors.background,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        );
                      },
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0, top: 12.0),
                        child: Image.asset(
                          AppAssets.logoColored,
                          height: 38,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              'Healthiez',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned.fill(
                top: clipTop,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                      stops: [0.0, 0.12],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: profileCardTop - clipTop,
                      left: 20,
                      right: 20,
                      bottom: 40,
                    ),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 16),
                        _buildThemeCard(),
                        const SizedBox(height: 16),
                        _buildNotificationCard(),
                        const SizedBox(height: 16),
                        _buildSecurityCard(),
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF475569)),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard() {
    Widget avatarChild;
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      avatarChild = CircleAvatar(
        radius: 31,
        backgroundImage: NetworkImage(_avatarUrl!),
      );
    } else {
      avatarChild = Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          color: Color(0xFFD9D9D9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 36, color: Colors.white),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              avatarChild,
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nickname,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              if (updated == true) {
                _loadUserInfo();
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tealLightBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/Pencil.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.edit, size: 16, color: AppColors.tealAccent);
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sửa',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tealAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealLightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/PaintBoard.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.palette_outlined, color: AppColors.tealAccent, size: 22);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao diện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Chọn phong cách của bạn',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  index: 0,
                  label: 'Ngày',
                  assetName: 'assets/images/day.png',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildThemeOption(
                  index: 1,
                  label: 'Chiều',
                  assetName: 'assets/images/noon.png',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildThemeOption(
                  index: 2,
                  label: 'Đêm',
                  assetName: 'assets/images/night.png',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Image.asset(
                'assets/images/Clock.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.access_time, size: 22, color: AppColors.textSecondary);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thay đổi theo thời gian thực',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tự động thay đổi giao diện theo giờ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoRealTimeTheme,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.tealAccent,
                onChanged: (val) {
                  AppColors.setAutoRealTime(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required int index,
    required String label,
    required String assetName,
  }) {
    final bool isSelected = _selectedTheme == index;
    return InkWell(
      onTap: () {
        AppColors.setAutoRealTime(false);
        AppColors.setThemeMode(AppThemeMode.values[index]);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.tealLightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.tealAccent : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                assetName,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, size: 36, color: AppColors.tealAccent);
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealLightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/ring.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.notifications_none, color: AppColors.tealAccent, size: 22);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Nhận thông báo cho hành trình sức khỏe',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildNotificationItem(
            assetName: 'assets/images/water.png',
            title: 'Uống nước',
            subtitle: 'Nhắc bạn uống đủ nước mỗi ngày!',
            value: _waterReminder,
            onChanged: (val) {
              setState(() => _waterReminder = val);
              _updateReminderSetting('water_reminder', val, NotificationService.scheduleWaterReminder);
            },
          ),

          const SizedBox(height: 12),

          _buildNotificationItem(
            assetName: 'assets/images/zzz.png',
            title: 'Giấc ngủ',
            subtitle: 'Nhắc bạn ngủ đúng giờ!',
            value: _sleepReminder,
            onChanged: (val) {
              setState(() => _sleepReminder = val);
              _updateReminderSetting('sleep_reminder', val, NotificationService.scheduleSleepReminder);
            },
          ),

          const SizedBox(height: 12),

          _buildNotificationItem(
            assetName: 'assets/images/run.png',
            title: 'Vận động',
            subtitle: 'Nhắc bạn vận động mỗi ngày!',
            value: _workoutReminder,
            onChanged: (val) {
              setState(() => _workoutReminder = val);
              _updateReminderSetting('workout_reminder', val, NotificationService.scheduleWorkoutReminder);
            },
          ),

          const SizedBox(height: 12),

          _buildNotificationItem(
            assetName: 'assets/images/phone.png',
            title: 'Điện thoại',
            subtitle: 'Nhắc bạn về thời gian dùng điện thoại!',
            value: _screenTimeReminder,
            onChanged: (val) {
              setState(() => _screenTimeReminder = val);
              _updateReminderSetting('screentime_reminder', val, (enable) {
                NotificationService.checkAndShowScreenTimeReminder(
                  enable: enable,
                  usageHoursToday: 3.5, // Mẫu thời gian dùng điện thoại để nhắc nhở
                );
              });
            },
          ),

          const SizedBox(height: 12),

          _buildNotificationItem(
            assetName: 'assets/images/quote.png',
            title: 'Thông điệp',
            subtitle: 'Gửi bạn chút ấm áp và động lực mỗi ngày!',
            value: _quoteReminder,
            onChanged: (val) {
              setState(() => _quoteReminder = val);
              _updateReminderSetting('quote_reminder', val, NotificationService.scheduleQuoteReminder);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String assetName,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.tealLightBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Image.asset(
              assetName,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.circle_outlined, size: 20, color: AppColors.tealAccent);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.tealAccent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    final user = Supabase.instance.client.auth.currentUser;
    final String provider = (user?.appMetadata['provider']?.toString() ?? 'email').toLowerCase();
    final String email = user?.email ?? '';
    final bool hasEmail = email.isNotEmpty && email.contains('@');
    final bool isFacebookNoEmail = (provider == 'facebook') && !hasEmail;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealLightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.security_outlined,
                    color: AppColors.tealAccent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bảo mật',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Bảo vệ tài khoản và phiên đăng nhập',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (!isFacebookNoEmail) ...[
            InkWell(
              onTap: () async {
                if (!hasEmail) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài khoản chưa liên kết Email. Vui lòng cập nhật email trong phần Sửa hồ sơ!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  await AuthService.sendPasswordResetCode(email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi mã xác minh đổi mật khẩu về Email của bạn!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushNamed(context, '/code-confirmation', arguments: email);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AuthService.getErrorMessage(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.tealLightBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.key_outlined,
                        size: 20,
                        color: AppColors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Gửi mã xác minh về Email để đặt mật khẩu mới',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          InkWell(
            onTap: () async {
              await AuthService.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đăng xuất tài khoản thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          'Thoát phiên làm việc khỏi thiết bị này',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
