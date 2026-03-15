import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HeroMediaInfo {
  const HeroMediaInfo({
    this.url,
    this.assetPath,
    required this.title,
    required this.subtitle,
  }) : assert(
         (url != null && url != '') || (assetPath != null && assetPath != ''),
         'Either url or assetPath must be provided.',
       );

  final String? url;
  final String? assetPath;
  final String title;
  final String subtitle;

  bool get isAsset => assetPath != null && assetPath!.isNotEmpty;

  String get source => isAsset ? assetPath! : url!;

  bool get isMp4 => source.toLowerCase().endsWith('.mp4');
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
    if (oldWidget.mediaInfo.source != widget.mediaInfo.source) {
      _disposeVideoController();
      _initializeMedia();
    }
  }

  void _initializeMedia() {
    if (!widget.mediaInfo.isMp4) {
      return;
    }

    final controller = widget.mediaInfo.isAsset
        ? VideoPlayerController.asset(widget.mediaInfo.source)
        : VideoPlayerController.networkUrl(Uri.parse(widget.mediaInfo.source));
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
      return widget.mediaInfo.isAsset
          ? Image.asset(widget.mediaInfo.source, fit: BoxFit.cover)
          : Image.network(widget.mediaInfo.source, fit: BoxFit.cover);
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
    return Center(
      child: AspectRatio(
        aspectRatio: 1080 / 2340,
        child: Stack(
          fit: StackFit.expand,
          alignment: AlignmentDirectional.bottomStart,
          children: <Widget>[
            ClipRect(child: _buildMedia()),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    widget.mediaInfo.title,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.mediaInfo.subtitle,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ClipRect(
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black12,
                      Colors.black54,
                    ],
                    stops: [0.45, 0.7, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(color: Colors.black26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
