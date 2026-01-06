import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main_navigation_screen.dart';
import '../widgets/app_drawer.dart';

class ReadScreen extends StatelessWidget {
  const ReadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;

    // Responsive scaling factors
    final double scale = width / 430;
    double responsive(double size) => size * scale;

    final bool isVerySmall = width < 350;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // ================= BACKGROUND =================

          // ================= TOP GRADIENT =================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: responsive(100),
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

          // ================= LOGO BANNERS =================
          Positioned(
            top: media.padding.top + responsive(10),
            left: responsive(16),
            right: responsive(16),
            child: Visibility(
              visible: !isVerySmall,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/insp.png',
                    width: responsive(90),
                    height: responsive(35),
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/stem.png',
                    width: responsive(60),
                    height: responsive(44),
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/javed.png',
                    width: responsive(70),
                    height: responsive(38),
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          // ================= VECTOR 7 (TOP RIGHT → LEFT FLOW) =================
          Positioned(
            top: responsive(-60),
            right: responsive(-220),
            child: Opacity(
              opacity: 0.99,
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
          ),

          // ================= VECTOR 8 (BOTTOM LEFT SUPPORT) =================
          Positioned(
            top: responsive(520),
            left: responsive(-200),
            child: Opacity(
              opacity: 0.99,
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
          ),

          // ================= MAIN CONTENT =================
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive(16),
              media.padding.top + responsive(85),
              responsive(16),
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title
                Text(
                  'Books',
                  style: GoogleFonts.poppins(
                    fontSize: responsive(24),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF871C1F),
                  ),
                ),
                const SizedBox(height: 6),

                // Coming Soon Content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: responsive(60),
                          color: Colors.white,
                        ),
                        SizedBox(height: responsive(20)),
                        Text(
                          "Books Coming Soon!",
                          style: TextStyle(
                            fontSize: responsive(32),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF871C1F),
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: responsive(10)),
                        Text(
                          "Exciting content is on the way",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF871C1F),
                          ),
                        ),
                        Text(
                          "Stay tuned for updates!",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF871C1F),
                          ),
                        ),
                      ],
                    ),
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
