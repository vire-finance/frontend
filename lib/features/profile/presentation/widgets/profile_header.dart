import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.role,
    required this.imagePath,
    super.key,
  });

  final String? name;
  final String role;
  final String imagePath;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 322,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _CurvedHeaderClipper(),
                child: const ColoredBox(color: AppColors.blue400),
              ),
            ),
            Positioned(
              top: 82,
              child: Container(
                width: 146,
                height: 146,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange400,
                ),
                child: ClipOval(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.orange50,
                      child: Icon(Icons.person, size: 86, color: AppColors.grey500),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 236,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    name?.trim().isNotEmpty == true ? name!.trim() : '—',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey700,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(role, style: const TextStyle(color: AppColors.grey700, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .68)
    ..quadraticBezierTo(size.width * .5, size.height * .40, size.width, size.height * .68)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
