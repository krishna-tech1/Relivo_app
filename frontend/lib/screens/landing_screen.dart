import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refugee_app/screens/login_screen.dart';
import 'package:refugee_app/screens/register_screen.dart';
import 'package:refugee_app/widgets/custom_button.dart';
import 'package:refugee_app/theme/app_theme.dart'; // Ensure theme is imported

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar to dark icons for visibility
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          // Background decoration (optional subtle circle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Hero Image / Icon with glow
                  Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Refugee Support Platform',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkGray,
                          height: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tagline
                  Text(
                    'We are here to help you navigate your journey and find the support you need.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.mediumGray,
                          fontSize: 16,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  
                  // Buttons
                  CustomButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Log In',
                    isOutlined: true,
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }
}
