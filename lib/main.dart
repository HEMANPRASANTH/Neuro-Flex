import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// 1. GLOBAL THEME ENGINE (INSTANT SWITCH)
// ==========================================

// Global State for Instant Theme Switching
final ValueNotifier<bool> themeNotifier = ValueNotifier(true);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NeuroFlexApp());
}

class NeuroFlexApp extends StatelessWidget {
  const NeuroFlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NeuroFlex',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }

  // --- DARK MODE THEME ---
  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050505),
    primaryColor: const Color(0xFFBB86FC),
    canvasColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
      onPrimary: Colors.black,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
  );

  // --- LIGHT MODE THEME ---
  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    primaryColor: const Color(0xFF6200EE),
    canvasColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6200EE),
      secondary: Color(0xFF018786),
      surface: Colors.white,
      onSurface: Colors.black,
      onPrimary: Colors.white,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}

// ==========================================
// 2. USER DATA MANAGER (SINGLETON)
// ==========================================

class UserData {
  static final UserData _instance = UserData._internal();
  factory UserData() => _instance;
  UserData._internal();

  String name = "";
  String email = "";
  String password = "";
  String phone = "";

  bool hasAccount = false;
  bool isLoggedIn = false;

  int level = 1;
  int currentXP = 0;
  int xpToNextLevel = 500;

  Map<String, int> scores = {
    'Memory Tiles': 0,
    'Quick Math': 0,
  };

  void addXP(int amount) {
    currentXP += amount;
    if (currentXP >= xpToNextLevel) {
      level++;
      currentXP -= xpToNextLevel;
      xpToNextLevel = (xpToNextLevel * 1.2).toInt();
    }
  }

  void resetProgress() {
    level = 1;
    currentXP = 0;
    xpToNextLevel = 500;
    scores = {
      'Memory Tiles': 0,
      'Quick Math': 0,
    };
  }

  void logout() {
    isLoggedIn = false;
  }
}

// ==========================================
// 3. REUSABLE GLASS UI WIDGET
// ==========================================

class ModernGlassBox extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final bool hasBorder;

  const ModernGlassBox({
    super.key,
    required this.child,
    this.opacity = 0.15,
    this.blur = 20.0,
    this.padding,
    this.borderRadius = 24.0,
    this.color,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
    // FIXED: Replaced withOpacity with withValues
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.05);
    final bgColor = color ?? (isDark ? Colors.black : Colors.white);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // FIXED: Replaced withOpacity with withValues
            color: bgColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder
                ? Border.all(color: borderColor, width: 1.0)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==========================================
// 4. SPLASH SCREEN
// ==========================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (UserData().isLoggedIn) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const AuthScreen()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          body: Stack(
            children: [
              _buildBackground(context),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: const Icon(Icons.psychology,
                              size: 80, color: Colors.white),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "NeuroFlex",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
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
}

// ==========================================
// 5. AUTH SCREEN
// ==========================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isLoginMode;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    isLoginMode = UserData().hasAccount;
    if (UserData().hasAccount) {
      _emailController.text = UserData().email;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!isLoginMode) {
        UserData().name = _nameController.text;
        UserData().email = _emailController.text;
        UserData().password = _passwordController.text;
        UserData().phone = _mobileController.text;
        UserData().hasAccount = true;
      }
      UserData().isLoggedIn = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) { return 'Password is required'; }
    if (value.length < 8) { return 'Min 8 characters'; }
    int specialCount =
        value.split('').where((c) => "!@#\$&*~".contains(c)).length;
    if (specialCount < 2) { return 'Need 2 special chars (!@#\$&*~)'; }
    return null;
  }

  String? _validateEmail(String? value) {
    // FIXED: Removed invalid escape char in Regex
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value == null || !emailRegex.hasMatch(value)) {
      return 'Invalid Email Format';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(context),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ModernGlassBox(
                opacity: 0.1,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoginMode ? "Welcome Back" : "Create Account",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 30),
                      if (!isLoginMode) ...[
                        _buildField(
                            _nameController, "Full Name", Icons.person, false),
                        const SizedBox(height: 15),
                        _buildField(_mobileController, "Mobile Number",
                            Icons.phone, false, TextInputType.phone),
                        const SizedBox(height: 15),
                      ],
                      _buildField(_emailController, "Email", Icons.email, false,
                          TextInputType.emailAddress, _validateEmail),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: _validatePassword,
                        style: TextStyle(color: textColor),
                        decoration: _inputDeco("Password", Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(isLoginMode ? "Log In" : "Sign Up",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              isLoginMode = !isLoginMode;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            isLoginMode
                                ? "New User? Create Account"
                                : "Have an account? Log In",
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.8)),
                          ),
                        ),
                      ),
                      const Divider(),
                      _buildGoogleBtn(textColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon, bool obscure,
      [TextInputType? type, String? Function(String?)? validator]) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      validator: validator ??
              (v) {
            if (v!.isEmpty) return "$hint required";
            return null;
          },
      style: TextStyle(color: textColor),
      decoration: _inputDeco(hint, icon),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InputDecoration(
      labelText: hint,
      labelStyle: TextStyle(color: color.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon, color: color.withValues(alpha: 0.7)),
      filled: true,
      fillColor: color.withValues(alpha: 0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color.withValues(alpha: 0.1))),
    );
  }

  Widget _buildGoogleBtn(Color textColor) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (ctx) => Container(
              padding: const EdgeInsets.all(20),
              height: 200,
              color: Theme.of(context).canvasColor,
              child: Column(children: [
                Text("Select Google Account",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.account_circle,
                      size: 40, color: Colors.blue),
                  title: Text("user.device@gmail.com",
                      style: TextStyle(color: textColor)),
                  onTap: () {
                    UserData().name = "Google User";
                    UserData().email = "user.device@gmail.com";
                    UserData().hasAccount = true;
                    UserData().isLoggedIn = true;
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const HomeScreen()));
                  },
                )
              ]),
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]),
        child:
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.g_mobiledata, size: 30, color: Colors.blue),
          SizedBox(width: 10),
          Text("Continue with Google",
              style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }
}

// ==========================================
// 6. HOME SCREEN
// ==========================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text("Brain Exercise",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 20),
                      // Memory Tiles
                      _gameCard(
                          "Memory Tiles",
                          Icons.grid_view_rounded,
                          Colors.blueAccent,
                          const MemoryTilesDifficultyScreen()),
                      const SizedBox(height: 15),
                      // Quick Math
                      _gameCard("Quick Math", Icons.calculate_rounded,
                          Colors.orangeAccent, const QuickMathGame()),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final color = Theme.of(context).colorScheme.onSurface;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            accountName: Text(UserData().name,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            accountEmail: null,
            currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black)),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: color),
            title: Text("Settings", style: TextStyle(color: color)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out",
                style:
                TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              UserData().logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (c) => const AuthScreen()),
                      (r) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: textColor),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(UserData().name,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              Row(
                children: [
                  Text("Lvl ${UserData().level}",
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor:
                      UserData().currentXP / UserData().xpToNextLevel,
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(5))),
                    ),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _gameCard(String title, IconData icon, Color color, Widget page) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () async {
        // IMPORTANT: Updates the Home Screen INSTANTLY when returning from a game
        await Navigator.push(
            context, MaterialPageRoute(builder: (context) => page));
        if (mounted) {
          setState(() {});
        }
      },
      child: ModernGlassBox(
        color: color,
        opacity: 0.15,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text("Score: ${UserData().scores[title] ?? 0}",
                      style:
                      TextStyle(color: textColor.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: textColor.withValues(alpha: 0.5), size: 16)
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. SETTINGS SCREEN (PERFECT THEME TOGGLE)
// ==========================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: color),
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // THEME TOGGLE (Instant via Global Notifier)
              ModernGlassBox(
                opacity: 0.05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      // Using ValueListenableBuilder to listen to global theme
                      ValueListenableBuilder<bool>(
                        valueListenable: themeNotifier,
                        builder: (ctx, isDark, _) => Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: color),
                      ),
                      const SizedBox(width: 16),
                      Text("Theme Mode",
                          style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ]),

                    // THE SWITCH
                    ValueListenableBuilder<bool>(
                      valueListenable: themeNotifier,
                      builder: (ctx, isDark, child) {
                        return Switch(
                          value: isDark,
                          onChanged: (val) {
                            // Update Global State Instantly
                            themeNotifier.value = val;
                            // Update Status Bar Instantly
                            SystemChrome.setSystemUIOverlayStyle(
                              SystemUiOverlayStyle(
                                statusBarColor: Colors.transparent,
                                statusBarIconBrightness: val ? Brightness.light : Brightness.dark,
                              ),
                            );
                          },
                          // FIXED: Using modern colors
                          activeTrackColor: Colors.purple.withValues(alpha: 0.5),
                          activeThumbColor: Colors.purple,
                          inactiveThumbColor: Colors.amber,
                          inactiveTrackColor: Colors.amber.withValues(alpha: 0.5),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ACCOUNT OPTION
              ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Colors.blue)),
                title: Text("Account",
                    style:
                    TextStyle(color: color, fontWeight: FontWeight.bold)),
                subtitle: Text("Edit name, email, password",
                    style: TextStyle(color: color.withValues(alpha: 0.6))),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: color.withValues(alpha: 0.5)),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const AccountEditScreen()));
                },
              ),
              const Divider(),

              // FACTORY RESET
              ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever, color: Colors.red)),
                title: const Text("Factory Reset",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: Text("Wipe all progress data",
                    style: TextStyle(color: color.withValues(alpha: 0.6))),
                onTap: () {
                  _confirmReset(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Factory Reset?"),
          content: const Text(
              "This will delete all game scores and reset level to 1. This cannot be undone."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  // 1. Reset Data
                  UserData().resetProgress();
                  Navigator.pop(ctx);

                  // 2. Restart App to apply changes visually
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (c) => const SplashScreen()),
                        (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("System Reset Successfully"),
                      backgroundColor: Colors.red));
                },
                child: const Text("RESET",
                    style: TextStyle(color: Colors.red))),
          ],
        ));
  }
}

// ==========================================
// 8. ACCOUNT EDIT SCREEN
// ==========================================

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = UserData().name;
    _emailCtrl.text = UserData().email;
    _passCtrl.text = UserData().password;
    _phoneCtrl.text = UserData().phone;
  }

  void _save() {
    setState(() {
      UserData().name = _nameCtrl.text;
      UserData().email = _emailCtrl.text;
      UserData().password = _passCtrl.text;
      UserData().phone = _phoneCtrl.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Profile Updated!"), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: TextStyle(color: color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: color),
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _editField("Full Name", _nameCtrl, false),
                const SizedBox(height: 15),
                _editField("Email", _emailCtrl, false),
                const SizedBox(height: 15),
                _editField("Mobile Number", _phoneCtrl, false),
                const SizedBox(height: 15),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: TextStyle(color: color),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: color.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: color.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: color),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor),
                    child: const Text("SAVE CHANGES",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, bool obscure) {
    final color = Theme.of(context).colorScheme.onSurface;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withValues(alpha: 0.7)),
        filled: true,
        fillColor: color.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ==========================================
// 9. GAME: MEMORY TILES (BAR TIMER + FIX)
// ==========================================

class MemoryTilesDifficultyScreen extends StatelessWidget {
  const MemoryTilesDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Difficulty", style: TextStyle(color: color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: color),
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _levelBtn(context, "Easy", 3), // 3x3 Grid
                const SizedBox(height: 20),
                _levelBtn(context, "Medium", 5), // 5x5 Grid
                const SizedBox(height: 20),
                _levelBtn(context, "Hard", 9), // 9x9 Grid
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _levelBtn(BuildContext context, String label, int gridDimension) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        onPressed: () {
          // PushReplacement ensures we go to game, but when game pops, we go to Home
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MemoryTilesGame(
                      difficulty: label, dimension: gridDimension)));
        },
        child: Text(label,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}

class MemoryTilesGame extends StatefulWidget {
  final String difficulty;
  final int dimension;
  const MemoryTilesGame(
      {super.key, required this.difficulty, required this.dimension});

  @override
  State<MemoryTilesGame> createState() => _MemoryTilesGameState();
}

class _MemoryTilesGameState extends State<MemoryTilesGame> {
  List<Color?> pattern = [];
  List<Color?> userGrid = [];
  bool isPreview = true;
  double timerProgress = 1.0; // For Bar
  Timer? _timer;

  final List<Color> palette = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.lime,
    Colors.indigo,
    Colors.amber,
    Colors.brown,
    Colors.deepOrange,
    Colors.lightBlue
  ];

  @override
  void initState() {
    super.initState();
    _startNewLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewLevel() {
    setState(() {
      isPreview = true;
      timerProgress = 1.0;
      int totalCells = widget.dimension * widget.dimension;

      pattern = List.filled(totalCells, null);
      userGrid = List.filled(totalCells, null);

      int tilesToColor = (totalCells * 0.4).toInt();
      if (tilesToColor < 3) {
        tilesToColor = 3;
      }

      int placed = 0;
      while (placed < tilesToColor) {
        int idx = Random().nextInt(totalCells);
        if (pattern[idx] == null) {
          pattern[idx] = palette[Random().nextInt(palette.length)];
          placed++;
        }
      }
    });

    // 10 Seconds Timer Bar
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          timerProgress -= 0.01; // 1.0 / 100 ticks = 10s
          if (timerProgress <= 0) {
            _timer?.cancel();
            isPreview = false;
          }
        });
      }
    });
  }

  void _handleTileTap(int index) {
    if (isPreview) return;

    setState(() {
      if (userGrid[index] != null) {
        userGrid[index] = null; // Undo
        return;
      }

      if (pattern[index] != null) {
        userGrid[index] = pattern[index];
        _checkWinCondition();
      } else {
        _showRetryDialog();
      }
    });
  }

  void _checkWinCondition() {
    bool allFound = true;
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] != null && userGrid[i] == null) {
        allFound = false;
        break;
      }
    }

    if (allFound) {
      // 5 XP Per Win - UPDATE SINGLETON IMMEDIATELY
      UserData().addXP(5);
      UserData().scores['Memory Tiles'] =
          (UserData().scores['Memory Tiles'] ?? 0) + 5;
      _showSuccessDialog();
    }
  }

  void _showRetryDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.red[900],
          title: const Text("Wrong Tile!",
              style: TextStyle(color: Colors.white)),
          content: const Text("You tapped a wrong box.",
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Pop Dialog
                  Navigator.pop(context); // Pop Game Screen (Returns to await in Home)
                },
                child: const Text("Quit",
                    style: TextStyle(color: Colors.white))),
            ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _startNewLevel();
                },
                child: const Text("Retry",
                    style: TextStyle(color: Colors.black))),
          ],
        ));
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.green[900],
          title: const Text("Level Complete!",
              style: TextStyle(color: Colors.white)),
          content: const Text("+5 XP Gained",
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Pop Dialog
                  Navigator.pop(context); // Pop Game Screen (Returns to await in Home)
                },
                child: const Text("Menu",
                    style: TextStyle(color: Colors.white))),
            ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _startNewLevel();
                },
                child: const Text("Next Level",
                    style: TextStyle(color: Colors.black))),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    double spacing = widget.dimension > 7 ? 4.0 : 8.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Memory Tiles", style: TextStyle(color: color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: color),
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(isPreview ? "Memorize Pattern" : "Tap the Pattern",
                        style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // SMOOTH GREEN -> RED TIMER BAR
                    LinearProgressIndicator(
                      value: timerProgress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      // Smooth transition from Green (1.0) to Red (0.0)
                      valueColor: AlwaysStoppedAnimation(
                          Color.lerp(Colors.red, Colors.green, timerProgress)),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.dimension * widget.dimension,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.dimension,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemBuilder: (context, index) {
                          Color? displayColor;
                          if (isPreview) {
                            displayColor = pattern[index];
                          } else {
                            displayColor = userGrid[index];
                          }
                          Color tileColor =
                              displayColor ?? color.withValues(alpha: 0.1);

                          return GestureDetector(
                            onTap: () => _handleTileTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(
                                    widget.dimension > 7 ? 4 : 8),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1)),
                                boxShadow: displayColor != null
                                    ? [
                                  BoxShadow(
                                      color: displayColor,
                                      blurRadius: 8,
                                      spreadRadius: 1)
                                ]
                                    : [],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 10. GAME: QUICK MATH (GREEN->RED BAR)
// ==========================================

class QuickMathGame extends StatefulWidget {
  const QuickMathGame({super.key});
  @override
  State<QuickMathGame> createState() => _QuickMathGameState();
}

class _QuickMathGameState extends State<QuickMathGame> {
  int n1 = 0, n2 = 0, ans = 0;
  String op = "+";
  List<int> opts = [];

  int timeLeft = 5;
  Timer? _gameTimer;
  double _progress = 1.0;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    timeLeft = 5;
    _progress = 1.0;
    _gameTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // 5 seconds total. Update every 0.1s. Decrement = 1/(5/0.1) = 0.02
          _progress -= 0.02;
          if (_progress <= 0) {
            timer.cancel();
            _gameOver("Time's Up!");
          }
        });
      }
    });
  }

  void _generateProblem() {
    _startTimer();
    setState(() {
      n1 = Random().nextInt(20) + 1;
      n2 = Random().nextInt(20) + 1;
      if (Random().nextBool()) {
        op = "+";
        ans = n1 + n2;
      } else {
        op = "-";
        if (n1 < n2) {
          int t = n1;
          n1 = n2;
          n2 = t;
        }
        ans = n1 - n2;
      }
      opts = [ans, ans + 1, ans - 1, ans + 2]..shuffle();
    });
  }

  void _check(int v) {
    if (v == ans) {
      // 5 XP Per Win
      UserData().addXP(5);
      UserData().scores['Quick Math'] =
          (UserData().scores['Quick Math'] ?? 0) + 5;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Correct! +5 XP"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 300)));
      _generateProblem();
    } else {
      _gameTimer?.cancel();
      _gameOver("Wrong Answer!");
    }
  }

  void _gameOver(String reason) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Game Over"),
          content: Text(reason),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Exit")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _generateProblem();
                },
                child: const Text("Retry"))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    List<int> topRow = opts.sublist(0, 2);
    List<int> bottomRow = opts.sublist(2, 4);

    return Scaffold(
      appBar: AppBar(
          title: Text("Quick Math", style: TextStyle(color: color)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: color)),
      body: Stack(
        children: [
          _buildBackground(context),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // SMOOTH GREEN -> RED TIMER BAR
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  // Smooth transition Green -> Red
                  valueColor: AlwaysStoppedAnimation(
                      Color.lerp(Colors.red, Colors.green, _progress)),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 60),

                // 2. Question
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ModernGlassBox(
                      child: Text("$n1 $op $n2 = ?",
                          style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ),
                  ),
                ),

                // 3. 2x2 Layout Choices
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOptionRow(topRow),
                      const SizedBox(height: 20),
                      _buildOptionRow(bottomRow),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOptionRow(List<int> choices) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: choices.map((val) {
        return Container(
          width: 140,
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: () => _check(val),
            child: Text("$val",
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================
// 11. BACKGROUND UTILITY
// ==========================================

Widget _buildBackground(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF000000), const Color(0xFF1C1C1E)]
            : [const Color(0xFFF2F2F7), const Color(0xFFFFFFFF)],
      ),
    ),
  );
}
