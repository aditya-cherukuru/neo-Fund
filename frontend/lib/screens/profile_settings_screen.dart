import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_app_bar.dart';
import 'auth/sign_in_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = context.read<AuthService>();
      if (!authService.isAuthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = File(image.path);
        });
        
        // Upload the image
        await _uploadProfileImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImageBytes == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final userService = context.read<UserService>();
      final success = await userService.uploadProfilePicture(_selectedImageBytes!);
      
      if (success) {
        await context.read<AuthService>().refreshUserData();
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(color: Colors.red[600]),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = context.read<AuthService>();
        await authService.logout();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B2B6B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 20),
                  _buildMenuOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? user) {
    final profilePictureData = user?['profilePicture'];
    final fullName = '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B2B6B), Color(0xFF6B2B6B)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPatternPainter(),
            ),
          ),
          // Profile content
          Column(
            children: [
              // Profile Picture
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildProfilePictureWidget(profilePictureData),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // User Name
              Text(
                fullName.isNotEmpty ? fullName : 'User',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Edit Profile Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Change Photo',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureWidget(String? profilePictureData) {
    // Show selected image if available
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileIcon();
        },
      );
    } else if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileIcon();
        },
      );
    }
    
    // Show current profile picture from backend
    if (profilePictureData != null && profilePictureData.isNotEmpty) {
      if (profilePictureData.startsWith('data:image/')) {
        try {
          final base64Data = profilePictureData.split(',')[1];
          final imageBytes = base64Decode(base64Data);
          
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProfileIcon();
            },
          );
        } catch (e) {
          return _buildDefaultProfileIcon();
        }
      } else {
        return Image.network(
          'http://localhost:3000/$profilePictureData',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultProfileIcon();
          },
        );
      }
    }
    
    return _buildDefaultProfileIcon();
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              // Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              // Navigate to notifications screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.security,
            title: 'Security',
            onTap: () {
              // Navigate to security screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {
              // Navigate to help screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            isLogout: true,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isLogout ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout 
                ? Colors.red.withOpacity(0.1) 
                : const Color(0xFF6B2B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red[600] : const Color(0xFF6B2B6B),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.red[600] : Colors.grey[800],
          ),
        ),
        subtitle: isLogout ? Text(
          'Sign out of your account',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ) : null,
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: isLogout ? Colors.red[600] : Colors.grey[600],
            size: 14,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw concentric circles
    for (double radius = 30; radius < size.width * 0.4; radius += 25) {
      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw dots around the center
    final Paint dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    for (double angle = 0; angle < 360; angle += 45) {
      final double rad = angle * 3.1415926535 / 180;
      final double r = 60;
      final Offset dotOffset = Offset(
        center.dx + r * cos(rad),
        center.dy + r * sin(rad),
      );
      canvas.drawCircle(dotOffset, 2, dotPaint);
    }
    
    // Draw some additional decorative elements
    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw some curved lines
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width, size.height * 0.3);
    canvas.drawPath(path, linePaint);
    
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height * 0.7);
    canvas.drawPath(path2, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

 