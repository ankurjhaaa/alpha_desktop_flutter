import 'package:flutter/material.dart';
import '../layout/student_layout.dart';
import '../core/widgets/about_content.dart';

class StudentAboutPage extends StatelessWidget {
  const StudentAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentLayout(
      title: 'About Us',
      child: AboutContent(),
    );
  }
}
