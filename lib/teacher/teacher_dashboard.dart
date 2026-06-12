import 'package:flutter/material.dart';
import '../layout/teacher_layout.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherLayout(
      title: 'Dashboard',
      child: _TeacherDashboardContent(),
    );
  }
}

class _TeacherDashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Teacher!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here is your summary for today.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New Assignment'),
              )
            ],
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: isDesktop ? 2.2 : 1.5,
            children: [
              _buildStatCard(context, 'Total Students', '1,242', Icons.people_alt, Colors.blue),
              _buildStatCard(context, 'Active Classes', '14', Icons.class_, Colors.green),
              _buildStatCard(context, 'Assignments to Grade', '38', Icons.grading, Colors.orange),
              _buildStatCard(context, 'Upcoming Exams', '3', Icons.event_note, Colors.purple),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildRecentActivity(context),
              ),
              if (isDesktop) const SizedBox(width: 32),
              if (isDesktop)
                Expanded(
                  flex: 4,
                  child: _buildUpcomingSchedule(context),
                ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 32),
          if (!isDesktop) _buildUpcomingSchedule(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text('12%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildActivityItem(context, 'Rohan Sharma submitted Physics Assignment', '10 mins ago', Icons.check_circle, Colors.green),
            const Divider(height: 32),
            _buildActivityItem(context, 'New student joined Advanced Math', '1 hour ago', Icons.person_add, Colors.blue),
            const Divider(height: 32),
            _buildActivityItem(context, 'Grade required for Final Project', '3 hours ago', Icons.warning, Colors.orange),
            const Divider(height: 32),
            _buildActivityItem(context, 'System maintenance scheduled', 'Yesterday', Icons.info, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String text, String time, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSchedule(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                )
              ],
            ),
            const SizedBox(height: 16),
            _buildScheduleItem(context, 'Advanced Physics', '10:00 AM - 11:30 AM', 'Room 302'),
            const SizedBox(height: 16),
            _buildScheduleItem(context, 'Mathematics 101', '1:00 PM - 2:30 PM', 'Room 105'),
            const SizedBox(height: 16),
            _buildScheduleItem(context, 'Computer Science', '3:00 PM - 4:30 PM', 'Lab A'),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, String subject, String time, String room) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? primary.withOpacity(0.05) : primary.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(time, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(room, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
