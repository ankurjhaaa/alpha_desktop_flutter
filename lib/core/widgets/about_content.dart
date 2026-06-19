import 'package:flutter/material.dart';

class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Us',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Learn more about our mission and vision',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoCard(
            context,
            title: 'Alpha Graphics',
            content: 'Alpha Graphics is a Computer Training Institute Since 2004, which is also Registered by Government of India. Our mission is to empower individuals with the essential computer skills needed to succeed in today\'s rapidly evolving digital landscape. We are committed to providing high-quality, accessible, and industry-relevant computer training in Patna.\n\nOur core values are rooted in excellence, integrity, and student success. We believe in fostering a supportive and engaging learning environment where every student can thrive.\n\nWe are proud of the success of our students, many of whom have secured fulfilling careers in top companies or have launched their own successful ventures. Our commitment to excellence has made us a leading computer training institute in Patna, and we are dedicated to continuing to empower individuals with the skills they need to achieve their full potential.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Our Mission & Vision',
            content: 'Providing best computer training to all the students and make them eligible to get a good job in the always growing market of computer. For students who don\'t know what to do, our mission is to provide them a proper target and a platform to achieve that target.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Developed by Brolytics Technologies',
            content: 'This app is proudly developed by Brolytics Technologies, dedicated to delivering innovative and user-friendly solutions for Alpha Graphics.\n\nBrolytics Technologies is a dynamic software development company specializing in creating cutting-edge solutions for education, business, and technology sectors. With a team of skilled developers and a passion for innovation, Brolytics has crafted Alpha Graphics to meet the evolving needs of modern education. Our commitment to quality and customer satisfaction drives us to deliver world-class applications.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String content}) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
