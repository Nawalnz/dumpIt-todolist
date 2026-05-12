import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.psychology,
      "title": "Dump all your tasks",
      "desc": "Get it out of your head and into the list. Clear your mental space instantly."
    },
    {
      "icon": Icons.timer_off,
      "title": "No Due Dates",
      "desc": "Minimize mental fatigue. Focus on the task, not the deadline."
    },
    {
      "icon": Icons.loop,
      "title": "Short-Term Focus",
      "desc": "Set tasks for today or the week. No monthly clutter, just what matters right now."
    },
    {
      "icon": Icons.devices,
      "title": "Login on Phone or Web",
      "desc": "Your tasks sync everywhere. Access your brain dump anytime, anywhere."
    },


  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => _buildStep(
                  onboardingData[index]['icon'],
                  onboardingData[index]['title'],
                  onboardingData[index]['desc'],
                ),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: Colors.blueAccent),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    bool isLastPage = _currentPage == onboardingData.length - 1;
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicator Dots
          Row(
            children: List.generate(
              onboardingData.length,
              (index) => Container(
                margin: const EdgeInsets.all(4),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.blueAccent : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Button
          ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                Navigator.pushReplacementNamed(context, '/register');
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(isLastPage ? "Get Started" : "Next"),
          ),
        ],
      ),
    );
  }
}
