import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_navigation_screen.dart';
import '../widgets/app_drawer.dart';
import 'series_screen.dart';
import 'read_screen.dart';
import 'Videos.dart';
import 'Training_screen.dart';
import 'Contact.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = 'User';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // 🔁 Refresh greeting every minute (real-time)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? 'User';
    });
  }

  // 🌍 LOCAL TIME BASED GREETING
  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final bottomPadding = media.padding.bottom;

    // ================= RESPONSIVE HELPERS =================
    final double scale = width / 430;
    final double heightScale = height / 932;
    double responsive(double size) => size * math.min(scale, heightScale);

    final bool isVerySmall = width < 350;
    final bool isTablet = width >= 600;

    // ================= SIZES =================
    final double logoWidth = responsive(141);
    final double logoHeight = responsive(71.48);

    final double greetingTop = responsive(218);
    final double greetingLeft = responsive(32);
    final double greetingFontSize = isVerySmall ? 32 : responsive(40);

    final double buttonWidth = isVerySmall ? responsive(150) : responsive(178);
    final double buttonHeight = responsive(165);
    final double horizontalSpacing = responsive(16);
    final double verticalSpacing = responsive(20);

    final double firstRowTop = greetingTop + responsive(120);
    final double secondRowTop = firstRowTop + buttonHeight + verticalSpacing;

    final double rowLeftMargin =
        (width - ((buttonWidth * 2) + horizontalSpacing)) / 2;

    final double secondRowButtonWidth =
    isVerySmall ? responsive(100) : (isTablet ? responsive(130) : responsive(115));

    final double secondRowLeftMargin =
        (width - ((secondRowButtonWidth * 3) + horizontalSpacing * 2)) / 2;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // ================= TOP GRADIENT =================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: responsive(186),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFED3237),
                    Color(0x00FFFFFF),
                  ],
                  stops: [0.0, 0.84],
                ),
              ),
            ),
          ),

          // ================= VECTOR 7 =================
          Positioned(
            top: responsive(-80),
            right: responsive(-220),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(-1.0, 1.0)
                ..rotateZ(27.37 * math.pi / 180),
              child: SizedBox(
                width: responsive(847.9),
                height: responsive(347.6),
                child: Image.asset(
                  'assets/images/Vector7.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // ================= VECTOR 8 =================
          Positioned(
            top: responsive(520),
            left: responsive(-200),
            child: Transform.rotate(
              angle: -12.24 * math.pi / 180,
              child: SizedBox(
                width: responsive(847.9),
                height: responsive(347.6),
                child: Image.asset(
                  'assets/images/vector8.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // ================= LOGO =================
          Positioned(
            top: responsive(74),
            left: (width - logoWidth) / 2,
            child: SizedBox(
              width: logoWidth,
              height: logoHeight,
              child: Image.asset('assets/images/javed.png'),
            ),
          ),

          // ================= GREETING (DYNAMIC) =================
          Positioned(
            top: greetingTop,
            left: greetingLeft,
            child: Text(
              "${getGreeting()}\n$_fullName",
              style: GoogleFonts.poppins(
                fontSize: greetingFontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF871C1F),
              ),
            ),
          ),

          // ================= BOOKS =================
          Positioned(
            top: firstRowTop,
            left: rowLeftMargin,
            child: GestureDetector(
              onTap: () {
                MainNavigationScreen.of(context)
                    ?.pushScreen(const SeriesScreen());
              },
              child: SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: Image.asset('assets/images/resources.png'),
              ),
            ),
          ),

          // ================= RESOURCES =================
          Positioned(
            top: firstRowTop,
            left: rowLeftMargin + buttonWidth + horizontalSpacing,
            child: GestureDetector(
              onTap: () {
                MainNavigationScreen.of(context)
                    ?.pushScreen(const ReadScreen());
              },
              child: SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: Image.asset('assets/images/books.png'),
              ),
            ),
          ),

          // ================= VIDEOS =================
          Positioned(
            top: secondRowTop,
            left: secondRowLeftMargin,
            child: GestureDetector(
              onTap: () {
                MainNavigationScreen.of(context)
                    ?.pushScreen(const VideosScreen());
              },
              child: SizedBox(
                width: secondRowButtonWidth,
                height: buttonHeight,
                child: Image.asset('assets/images/videos.png'),
              ),
            ),
          ),

          // ================= TRAINING =================
          Positioned(
            top: secondRowTop,
            left: secondRowLeftMargin +
                secondRowButtonWidth +
                horizontalSpacing,
            child: GestureDetector(
              onTap: () {
                MainNavigationScreen.of(context)
                    ?.pushScreen(const TrainingScreen());
              },
              child: SizedBox(
                width: secondRowButtonWidth,
                height: buttonHeight,
                child: Image.asset('assets/images/traning.png'),
              ),
            ),
          ),

          // ================= CONTACT =================
          Positioned(
            top: secondRowTop,
            left: secondRowLeftMargin +
                (secondRowButtonWidth + horizontalSpacing) * 2,
            child: GestureDetector(
              onTap: () {
                MainNavigationScreen.of(context)
                    ?.pushScreen(const ContactScreen());
              },
              child: SizedBox(
                width: secondRowButtonWidth,
                height: buttonHeight,
                child: Image.asset('assets/images/contact.png'),
              ),
            ),
          ),

          // ================= BOTTOM LOGOS =================
          if (!isVerySmall)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + responsive(10),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? responsive(40) : responsive(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/insp.png', width: responsive(95)),
                    Image.asset('assets/images/stem.png', width: responsive(65)),
                    Image.asset('assets/images/javed.png', width: responsive(75)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
