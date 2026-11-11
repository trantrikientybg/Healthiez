import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/widgets/custom_textfield.dart';
import '../auth/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String _gender = 'Nam';
  String? _selectedAvatarUrl;
  File? _pickedImageFile;
  bool _isLoading = false;
  bool _isSaving = false;
  String _authProvider = 'email';
  String _originalEmail = '';

  final List<Map<String, String>> _publicAvatars = [
    {
      'name': 'Thiền định',
      'icon': '🧘‍♀️',
      'url': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=200',
    },
    {
      'name': 'Thiên nhiên',
      'icon': '🌿',
      'url': 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=200',
    },
    {
      'name': 'Vận động',
      'icon': '🏃‍♂️',
      'url': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=200',
    },
    {
      'name': 'Năng lượng',
      'icon': '☀️',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200',
    },
    {
      'name': 'Nước mát',
      'icon': '💧',
      'url': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=200',
    },
    {
      'name': 'Tâm trí',
      'icon': '🌸',
      'url': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=200',
    },
    {
      'name': 'Thể thao',
      'icon': '🏋️‍♂️',
      'url': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200',
    },
    {
      'name': 'Sức sống',
      'icon': '🍃',
      'url': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=200',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _authProvider = (user.appMetadata['provider']?.toString() ?? 'email').toLowerCase();
      _originalEmail = user.email ?? '';
      _emailController.text = _originalEmail;
    }

    try {
      final profile = await UserRepository.getCurrentUserProfile();
      if (profile != null) {
        _usernameController.text = profile.username;
        _fullNameController.text = profile.fullName ?? profile.username;
        if (profile.email.isNotEmpty) {
          _originalEmail = profile.email;
          _emailController.text = profile.email;
        }
        _dobController.text = profile.dateOfBirth ?? '';
        _gender = profile.gender ?? 'Nam';
        _weightController.text = profile.weight != null ? profile.weight!.round().toString() : '';
        _heightController.text = profile.height != null ? profile.height!.round().toString() : '';
        _selectedAvatarUrl = profile.avatarUrl;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImageFile = File(image.path);
        _selectedAvatarUrl = null;
      });
    }
  }

  void _showAvatarPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              _buildAvatarCircle(radius: 42),
              const SizedBox(height: 22),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: _publicAvatars.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.tealLightBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tealAccent, width: 1.5),
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.tealAccent,
                          size: 22,
                        ),
                      ),
                    );
                  }

                  final avatar = _publicAvatars[index - 1];
                  final isSelected = _selectedAvatarUrl == avatar['url'] && _pickedImageFile == null;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAvatarUrl = avatar['url'];
                        _pickedImageFile = null;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.tealAccent : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(avatar['url']!),
                        backgroundColor: AppColors.tealLightBg,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 20));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.tealAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _handleSaveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? finalAvatarUrl = _selectedAvatarUrl;

      if (_pickedImageFile != null) {
        final uploadedUrl = await UserRepository.uploadAvatarImage(
          userId: user.id,
          imageFile: _pickedImageFile!,
        );
        if (uploadedUrl != null) {
          finalAvatarUrl = uploadedUrl;
        }
      }

      final newEmail = _emailController.text.trim();
      bool emailUpdated = false;

      // Xử lý đổi Email trên Supabase Auth nếu đăng nhập bằng Email / Facebook và người dùng thay đổi Email
      if (_authProvider != 'google' && newEmail.isNotEmpty && newEmail != _originalEmail) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: newEmail),
        );
        emailUpdated = true;
      }

      final weightVal = double.tryParse(_weightController.text.trim());
      final heightVal = double.tryParse(_heightController.text.trim());

      final updatedProfile = UserProfile(
        id: user.id,
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : 'User',
        email: emailUpdated ? _originalEmail : newEmail, // Email cũ giữ nguyên tới khi bấm xác nhận trong mail
        fullName: _fullNameController.text.trim(),
        avatarUrl: finalAvatarUrl,
        dateOfBirth: _dobController.text.trim(),
        gender: _gender,
        weight: weightVal,
        height: heightVal,
      );

      await UserRepository.updateFullUserProfile(updatedProfile);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      String message = 'Cập nhật thông tin cá nhân thành công!';
      if (emailUpdated) {
        message = 'Đã gửi link xác thực về email mới. Vui lòng kiểm tra hộp thư để hoàn tất đổi email!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.tealAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thông tin thất bại: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAvatarCircle({double radius = 40}) {
    if (_pickedImageFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_pickedImageFile!),
      );
    } else if (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_selectedAvatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD9D9D9),
      child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 160.0;

    return ListenableBuilder(
      listenable: AppColors.instance,
      builder: (context, child) {
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
                          color: AppColors.primary,
                        );
                      },
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0, top: 12.0),
                        child: Image.asset(
                          AppAssets.logoColored,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              'Healthiez',
                              style: TextStyle(
                                fontSize: 24,
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
                top: headerHeight - 20,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: AppColors.tealAccent),
                        )
                      else ...[
                        _buildPersonalInfoCard(),
                        const SizedBox(height: 16),
                        _buildBodyMetricsCard(),
                        const SizedBox(height: 24),
                        if (_isSaving)
                          CircularProgressIndicator(color: AppColors.tealAccent)
                        else
                          PrimaryButton(
                            text: 'Lưu thay đổi',
                            type: ButtonType.gradient,
                            onPressed: _handleSaveProfile,
                          ),
                        const SizedBox(height: 30),
                      ],
                    ],
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

  Widget _buildPersonalInfoCard() {
    final bool isGoogleAuth = _authProvider == 'google';

    return Container(
      padding: const EdgeInsets.all(20),
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
          Center(
            child: GestureDetector(
              onTap: _showAvatarPickerModal,
              child: Stack(
                children: [
                  _buildAvatarCircle(radius: 42),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.tealAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // Tên hiển thị (Nickname)
          CustomTextField(
            hintText: 'Tên hiển thị (Nickname)',
            controller: _fullNameController,
          ),

          const SizedBox(height: 12),

          // Email liên kết (Có kiểm tra tài khoản Google để khóa chỉnh sửa)
          CustomTextField(
            hintText: 'Email liên kết',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          if (isGoogleAuth) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                '🔒 Tài khoản liên kết Google không thể thay đổi email.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Ngày tháng năm sinh
          InkWell(
            onTap: _selectDateOfBirth,
            child: IgnorePointer(
              child: CustomTextField(
                hintText: 'Ngày tháng năm sinh (DD/MM/YYYY)',
                controller: _dobController,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Giới tính:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: ['Nam', 'Nữ', 'Khác'].map((g) {
              final isSelected = _gender == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _gender = g;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.tealAccent : AppColors.tealLightBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricsCard() {
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
          Text(
            'Chỉ số cơ thể',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: 'Cân nặng (kg)',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  hintText: 'Chiều cao (cm)',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
