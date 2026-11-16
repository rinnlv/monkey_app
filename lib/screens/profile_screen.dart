import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../db/database_helper.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_bottom_nav.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  String _selectedAvatar = 'avatar1';
  int _streak = 0;
  int _daysWithUs = 1;
  bool _isLoading = true;

  final List<String> _avatars = ['avatar1', 'avatar2', 'avatar3'];

  // Фирменные цвета
  final Color colorBrown = const Color(0xFF85422D);
  final Color colorGreen = const Color(0xFF688B4B);
  final Color colorTerracotta = const Color(0xFFC25A3F);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final db = DatabaseHelper();
    final name = await db.getSetting('user_name') ?? 'Друг';
    final avatar = await db.getSetting('user_avatar') ?? 'avatar1';
    final streakStr = await db.getSetting('streak_count') ?? '0';
    String? firstOpen = await db.getSetting('first_open_date');

    if (firstOpen == null || firstOpen.isEmpty) {
      firstOpen = DateTime.now().toIso8601String().substring(0, 10);
      await db.setSetting('first_open_date', firstOpen);
    }

    final firstDate = DateTime.parse(firstOpen);
    final now = DateTime.now();
    final difference = now.difference(firstDate).inDays + 1;

    if (mounted) {
      setState(() {
        _nameController.text = name;
        _selectedAvatar = avatar;
        _streak = int.tryParse(streakStr) ?? 0;
        _daysWithUs = difference;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final db = DatabaseHelper();
    await db.setSetting('user_name', _nameController.text.trim());
    await db.setSetting('user_avatar', _selectedAvatar);
    
    ref.invalidate(settingsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль обновлен!'), 
          backgroundColor: Color(0xFF688B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getDaysText(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) return 'дня';
    return 'дней';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аккаунт', style: TextStyle(fontFamily: 'Gluten', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: colorGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
      
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              children: [
                // 1. Приветствие и подпись
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Привет, ${_nameController.text}!',
                        style: TextStyle(
                          fontFamily: 'Gluten',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Держим руку на пульсе твоего кошелька',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Большая аватарка (Белый фон, коричневая обводка)
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white, 
                      border: Border.all(color: colorBrown, width: 4), 
                      boxShadow: [
                        BoxShadow(
                          color: colorBrown.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/avatars/$_selectedAvatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 3. Выбор аватарки (в белой карточке)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                        child: Text(
                          'Выбери своего героя:',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorBrown),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _avatars.map((avatar) => _buildAvatarOption(avatar)).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Поле ввода имени
                TextField(
                  controller: _nameController,
                  onChanged: (val) => setState(() {}), 
                  decoration: InputDecoration(
                    labelText: 'Твое имя',
                    labelStyle: TextStyle(color: colorBrown),
                    prefixIcon: Icon(Icons.person_outline, color: colorBrown),
                    suffixIcon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: colorBrown.withOpacity(0.3), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: colorGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Карточка статистики
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7BA359), Color(0xFF5A7A3F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorGreen.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Серия', '$_streak', _getDaysText(_streak)),
                      Container(width: 2, height: 50, color: Colors.white30),
                      _buildStatItem('С нами', '$_daysWithUs', _getDaysText(_daysWithUs)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 6. Кнопка сохранения (Пилюля)
                Center(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [colorBrown, colorTerracotta],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorBrown.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: _saveProfile,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Center(
                            child: Text(
                              'Сохранить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // Метод выбора аватарки (Белый фон, коричневая обводка)
  Widget _buildAvatarOption(String avatarId) {
    final isSelected = _selectedAvatar == avatarId;

    return GestureDetector(
      onTap: () => setState(() => _selectedAvatar = avatarId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, 
          border: Border.all(
            color: colorBrown, 
            width: isSelected ? 4 : 2, // Выбранная получает обводку потолще
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/avatars/$avatarId.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // Метод отрисовки статистики
  Widget _buildStatItem(String title, String value, String subtitle) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Gluten',
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ],
    );
  }
}