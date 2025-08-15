import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/common/views/homeMainCard.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  const HomeHeader({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(36.0, 48, 36, 48),
        color: Theme.of(context).colorScheme.primary,

        child: SafeArea(
          child: Column(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    "Welcome back,",
                    style:
                        GoogleFonts.poppinsTextTheme(
                          Theme.of(context).textTheme,
                        ).headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  Text(
                    "Marcus!",
                    style:
                        GoogleFonts.poppinsTextTheme(
                          Theme.of(context).textTheme,
                        ).headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          // fontFamily: "Open Sans",
                        ),
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: HomeMainCard(
                      leading: AssetIcons.washerIcon(context),
                      title: "Washers",
                      count: "2/4",
                      actionText: "View",
                      onAction: () {},
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: HomeMainCard(
                      leading: AssetIcons.dryerIcon(context),
                      title: "Dryers",
                      count: "2/4",
                      actionText: "View",
                      onAction: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
