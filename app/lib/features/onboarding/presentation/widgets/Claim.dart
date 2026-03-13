import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/OnboardingInfoCard.dart';
import 'package:resiwash/theme.dart';
import 'package:video_player/video_player.dart';

class Claim extends StatefulWidget {
  const Claim({Key? key}) : super(key: key);

  @override
  State<Claim> createState() => _ClaimState();
}

class _ClaimState extends State<Claim> {
  final CarouselController controller = CarouselController(initialItem: 1);
  final HeroMediaInfo mediaInfo = const HeroMediaInfo(
    url: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
    title: 'Claim Alerts',
    subtitle: 'Get notified when your machine is done',
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingInfoCard(
          title: "Check",
          titleAccompany: " for availability",
          body: "Learn how to check and interpret machine statuses",
          onTap: () {
            debugPrint('Card tapped.');
          },
          actionText: "I got it!",
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 2,
            children: [
              Row(
                children: [
                  MachineStatusIndicator(status: MachineStatus.available),
                  SizedBox(width: 8),
                  Text(
                    "Available",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.success.colorContainer,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MachineStatusIndicator(status: MachineStatus.inUse),
                  SizedBox(width: 8),
                  Text(
                    "In Use",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.inUse.colorContainer,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MachineStatusIndicator(status: MachineStatus.finishing),
                  SizedBox(width: 8),
                  Text(
                    "Finishing (expected to finish in ~10 mins)",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.inUse.colorContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: CarouselView.weighted(
            controller: controller,
            itemSnapping: true,
            flexWeights: const <int>[1, 7, 1],
            children: [HeroLayoutCard(mediaInfo: mediaInfo)],
          ),
        ),
      ],
    );
  }
}

class HeroMediaInfo {
  const HeroMediaInfo({
    required this.url,
    required this.title,
    required this.subtitle,
  });

  final String url;
  final String title;
  final String subtitle;

  bool get isMp4 => url.toLowerCase().endsWith('.mp4');
}

class HeroLayoutCard extends StatefulWidget {
  const HeroLayoutCard({super.key, required this.mediaInfo});

  final HeroMediaInfo mediaInfo;

  @override
  State<HeroLayoutCard> createState() => _HeroLayoutCardState();
}

class _HeroLayoutCardState extends State<HeroLayoutCard> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(covariant HeroLayoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaInfo.url != widget.mediaInfo.url) {
      _disposeVideoController();
      _initializeMedia();
    }
  }

  void _initializeMedia() {
    if (!widget.mediaInfo.isMp4) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaInfo.url),
    );
    _videoController = controller;
    controller
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) {
          return;
        }
        controller.play();
        setState(() {});
      });
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  Widget _buildMedia() {
    if (!widget.mediaInfo.isMp4) {
      return Image.network(widget.mediaInfo.url, fit: BoxFit.cover);
    }

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: _buildMedia(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.mediaInfo.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                widget.mediaInfo.subtitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
