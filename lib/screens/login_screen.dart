import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hammami_transport_app/services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  String? errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  // Remplace signInWithEmailAndPassword() dans login_screen.dart

    Future<void> signInWithEmailAndPassword() async {
    if (_controllerEmail.text.trim().isEmpty ||
        _controllerPassword.text.trim().isEmpty) {
      setState(() => errorMessage = 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() { _isLoading = true; errorMessage = null; });

    try {
      await Auth().signInWithEmailAndPassword(
        email:    _controllerEmail.text.trim(),
        password: _controllerPassword.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = _friendlyError(e.code));
    } catch (e) {
      setState(() => errorMessage = 'Erreur inattendue. Réessaie.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Traduction des codes Firebase en messages lisibles ─────────────────────
  String _friendlyError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mot de passe incorrect.';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      default:
        return 'Erreur de connexion ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8501A).withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF2EDE8),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'Images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_shipping_outlined,
                            color: Color(0xFFE8501A),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hammami Transport',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accédez à votre espace logistique sécurisé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Email field
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email ou Identifiant',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _controllerEmail,
                      hint: 'nom@entreprise.tn',
                      icon: Icons.person_outline,
                      keyBoardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mot de passe',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // Mini dialog register pour tester
                            await _showRegisterDialog();
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              text: 'Nouveau partenaire ? ',
                              style: TextStyle(color: Color(0xFF444444), fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Demander un accès',
                                  style: TextStyle(
                                    color: Color(0xFFE8501A), 
                                    fontWeight: FontWeight.w700
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _controllerPassword,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixeIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF888888),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Remember me
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFFE8501A),
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Se souvenir de moi',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Se connecter button
                    SizedBox(
                      width: double.infinity,
                      child: _FilledButton(
                        label: 'Se connecter',
                        isLoading: _isLoading,
                        onTap: signInWithEmailAndPassword, 
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFDDDDDD), thickness: 1),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          text: 'Nouveau partenaire ? ',
                          style: TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'Demander un accès',
                              style: TextStyle(
                                color: Color(0xFFE8501A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _showRegisterDialog() async {
      final emailCtrl    = TextEditingController();
      final passwordCtrl = TextEditingController();
      String? err;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Créer un compte'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8501A)),
                onPressed: () async {
                try {
                  await Auth().createUserWithEmailAndPassword(
                    email:    emailCtrl.text.trim(),
                    password: passwordCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  setS(() => err = _friendlyError(e.code));
                }
              },
              child: const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Champs de saisie
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyBoardType = TextInputType.text,
    Widget? suffixeIcon,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyBoardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 20),
          suffixIcon: suffixeIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _FilledButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8501A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
    );
  }
}