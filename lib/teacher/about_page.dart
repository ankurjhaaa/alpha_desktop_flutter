import 'package:flutter/material.dart';
import '../layout/teacher_layout.dart';
import '../core/widgets/about_content.dart';

class TeacherAboutPage extends StatelessWidget {
  const TeacherAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeacherLayout(
      title: 'About Us',
      child: AboutContent(),
    );
  }
}
