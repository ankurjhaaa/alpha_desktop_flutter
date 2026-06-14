import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'leaderboard_page.dart';
import '../core/utils/pdf_helper.dart';

class ExamResultPage extends StatefulWidget {
  final Map<String, dynamic> result;

  const ExamResultPage({super.key, required this.result});

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Play confetti if score is >= 50%
    final double percentage = double.parse(widget.result['percentage'].toString());
    if (percentage >= 50.0) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = widget.result['score'];
    final total = widget.result['total_questions'];
    final percentage = double.parse(widget.result['percentage'].toString());

    final bool isPass = percentage >= 50.0;
    final color = isPass ? Colors.green : Colors.red;
    final icon = isPass ? Icons.emoji_events : Icons.sentiment_dissatisfied;
    final message = isPass ? 'Congratulations!' : 'Better luck next time!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Force them to use buttons
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 80, color: color),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have successfully submitted the exam.',
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Score',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$score',
                                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              ),
                              Text(
                                ' / $total',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Percentage', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                  const SizedBox(height: 4),
                                  Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Status', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      isPass ? 'PASS' : 'FAIL',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context), // Back to exams list
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Back to Exams', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              PdfHelper.generateExamResultPdf(
                                context: context,
                                paperTitle: widget.result['paper_title'] ?? 'Exam Result',
                                resultData: widget.result,
                              );
                            },
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LeaderboardPage(
                                    paperId: widget.result['mcq_paper_id'],
                                    paperTitle: widget.result['paper_title'] ?? 'Leaderboard',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
