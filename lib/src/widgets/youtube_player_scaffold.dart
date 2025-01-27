// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:youtube_player_iframe/src/helpers/images.dart';
import 'package:youtube_player_iframe/src/widgets/widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A widget the scaffolds the [YoutubePlayer] so that it can be moved around easily in the view
/// and handles the fullscreen functionality.
class YoutubePlayerScaffold extends StatefulWidget {
  /// Creates [YoutubePlayerScaffold].
  const YoutubePlayerScaffold({
    super.key,
    required this.builder,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.function,
    this.autoFullScreen = true,
    required this.isBackVisible,
    required this.controlsPadding,
    this.defaultOrientations = DeviceOrientation.values,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.fullscreenOrientations = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.lockedOrientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.enableFullScreenOnVerticalDrag = true,
    this.backgroundColor,
    @Deprecated('Unused parameter. Use `YoutubePlayerParam.userAgent` instead.')
    this.userAgent,
  });

  /// Builds the child widget.
  final Widget Function(BuildContext context, Widget player) builder;

  /// The player controller.
  final YoutubePlayerController controller;

  /// Padding for controls
  final double controlsPadding;

  final bool isBackVisible;

  /// The aspect ratio of the player.
  ///
  /// The value is ignored on fullscreen mode.
  final double aspectRatio;

  /// Whether the player should be fullscreen on device orientation changes.
  final bool autoFullScreen;

  /// The default orientations for the device.
  final List<DeviceOrientation> defaultOrientations;

  /// The orientations that are used when in fullscreen.
  final List<DeviceOrientation> fullscreenOrientations;

  /// The orientations that are used when not in fullscreen and auto rotate is disabled.
  final List<DeviceOrientation> lockedOrientations;

  final void Function()? function;

  /// Enables switching full screen mode on vertical drag in the player.
  ///
  /// Default is true.
  final bool enableFullScreenOnVerticalDrag;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// This property is ignored in web.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The background color of the [WebView].
  final Color? backgroundColor;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  ///
  /// By default `userAgent` is null.
  final String? userAgent;

  @override
  State<YoutubePlayerScaffold> createState() => _YoutubePlayerScaffoldState();
}

class _YoutubePlayerScaffoldState extends State<YoutubePlayerScaffold> {
  late final GlobalObjectKey _playerKey;
  late Timer _hideControlsTimer;
  @override
  void initState() {
    super.initState();
    timerStart();
    _playerKey = GlobalObjectKey(widget.controller);
  }

  timerStart() {
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      // if(widget.controller)
      widget.controller.update(isControlsVisible: false);
      log('calling timer');
    });
  }

  _toggleControlles() {
    if (widget.controller.value.isControlsVisible) {
      widget.controller.update(isControlsVisible: false);
    } else {
      timerStart();
      widget.controller.update(isControlsVisible: true);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Function for time parse
    String intToTime(int value) {
      int h, m, s;
      String hh, mm, ss, r;

      h = value ~/ 3600;

      m = ((value - h * 3600)) ~/ 60;

      s = value % 60;

      hh = h.toString().padLeft(2, '0');
      mm = m.toString().padLeft(2, '0');
      ss = s.toString().padLeft(2, '0');

      if (hh == '00') {
        r = '$mm:$ss';
      } else {
        r = '$hh:$mm:$ss';
      }
      return r;
    }

    final player = KeyedSubtree(
      key: _playerKey,
      child: Builder(builder: (context) {
        return Container(
          // width: widget.controlsPadding,
          color: Colors.black,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                //! Boundary
                SizedBox(width: double.infinity, height: double.infinity),

                //! Player
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(
                      controller: widget.controller,
                      aspectRatio: widget.aspectRatio,
                      gestureRecognizers: widget.gestureRecognizers,
                      enableFullScreenOnVerticalDrag:
                          widget.enableFullScreenOnVerticalDrag,
                      backgroundColor: widget.backgroundColor,
                    ),
                  ),
                ),

                //! Shelter
                YoutubeValueBuilder(builder: (context, value) {
                  return GestureDetector(
                    onTap: () {
                      _toggleControlles();
                    },
                    child: Visibility(
                      // visible: value.playerState == PlayerState.paused,
                      child: AnimatedContainer(
                          width: double.infinity,
                          height: double.infinity,
                          duration: const Duration(milliseconds: 300),
                          // color: _controller.value.isControlsVisible ? Colors.black.withAlpha(150) : Colors.transparent,
                          color: value.isControlsVisible
                              ? Colors.black.withAlpha(120)
                              : value.playerState == PlayerState.paused
                                  ? Colors.black.withAlpha(160)
                                  : Colors.transparent
                          // color: Colors.red,
                          ),
                    ),
                  );
                }),

                //!  Center controls
                Positioned(
                  right: 0,
                  bottom: 0,
                  left: 0,
                  top: 0,
                  child: YoutubeValueBuilder(
                    builder: (context, value) {
                      return Visibility(
                        visible: value.isControlsVisible,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // TODO
                            // for the seek we need to change to seek bar and player durarion also
                            // so seek multiple times is holded
                            StreamBuilder<YoutubeVideoState>(
                              initialData: const YoutubeVideoState(),
                              stream: widget.controller.videoStateStream,
                              builder: (context, snapshot) {
                                final position =
                                    snapshot.data?.position.inSeconds ?? 0;

                                return Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      // if (position >= 10) {
                                      await widget.controller.seekTo(
                                        seconds: position - 5,
                                        allowSeekAhead: true,
                                      );
                                      await widget.controller.playVideo();

                                      // }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x33263047),
                                        // color: Colors.white.withOpacity(.8),
                                      ),
                                      padding: EdgeInsets.fromLTRB(9, 6, 9, 9),
                                      child: SvgPicture.asset(
                                        PlayerImages.seekBack,
                                        fit: BoxFit.scaleDown,
                                        height: value.fullScreenOption.enabled
                                            ? 50
                                            : 28,
                                        width: value.fullScreenOption.enabled
                                            ? 50
                                            : 28,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  value.playerState == PlayerState.playing
                                      ? context.ytController.pauseVideo()
                                      : context.ytController.playVideo();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

                                    color: const Color(0x33263047),
                                    // color: Colors.white.withOpacity(.8),
                                  ),
                                  padding:
                                      value.playerState == PlayerState.playing
                                          ? EdgeInsets.fromLTRB(11, 11, 11, 11)
                                          : EdgeInsets.fromLTRB(11, 11, 7, 11),
                                  child: value.playerState ==
                                          PlayerState.playing
                                      ? SvgPicture.asset(
                                          PlayerImages.pause,
                                          fit: BoxFit.scaleDown,
                                          height: value.fullScreenOption.enabled
                                              ? 50
                                              : 24,
                                          width: value.fullScreenOption.enabled
                                              ? 50
                                              : 24,
                                        )
                                      : SvgPicture.asset(
                                          PlayerImages.play,
                                          fit: BoxFit.scaleDown,
                                          height: value.fullScreenOption.enabled
                                              ? 50
                                              : 24,
                                          width: value.fullScreenOption.enabled
                                              ? 50
                                              : 24,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            StreamBuilder<YoutubeVideoState>(
                              initialData: YoutubeVideoState(),
                              stream: widget.controller.videoStateStream,
                              builder: (context, snapshot) {
                                var position =
                                    snapshot.data?.position.inSeconds ?? 0;
                                // var lastPosition = 0;
                                // var pressedCount = 0;
                                return Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      await widget.controller.seekTo(
                                        seconds: (position + 5),
                                        allowSeekAhead: true,
                                      );
                                      await widget.controller.playVideo();
                                      // pressedCount += 1;
                                      // final duration = context.ytController.metadata.duration.inSeconds;
                                      // if (lastPosition > position) {
                                      //   widget.controller.seekTo(seconds: (lastPosition + 10));
                                      //   lastPosition = position + 10;
                                      // } else {
                                      //   widget.controller.seekTo(seconds: (position + 10));
                                      //   lastPosition = position +10;
                                      // }

                                      // if ((position - lastPosition) <= 2) {
                                      //   widget.controller
                                      //       .seekTo(seconds: (position + (10 * pressedCount)).toDouble());
                                      // }else{
                                      //    widget.controller
                                      //       .seekTo(seconds: (position + 10).toDouble());
                                      // }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x33263047),
                                        // color: Colors.white.withOpacity(.8),
                                      ),
                                      padding: EdgeInsets.fromLTRB(9, 6, 9, 9),
                                      child: SvgPicture.asset(
                                        PlayerImages.seekFront,
                                        fit: BoxFit.scaleDown,
                                        height: value.fullScreenOption.enabled
                                            ? 54
                                            : 28,
                                        width: value.fullScreenOption.enabled
                                            ? 54
                                            : 28,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                //! Top back row

                Positioned.fill(
                  top: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: YoutubeValueBuilder(builder: (context, value) {
                      return Builder(builder: (context) {
                        return SizedBox(
                          // width: MediaQuery.of(context).size.width,
                          width: double.infinity - widget.controlsPadding,
                          child: Visibility(
                            visible: value.isControlsVisible,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(11, 12, 11, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Visibility(
                                    replacement: SizedBox(
                                      width: 20,
                                    ),
                                    visible: widget.isBackVisible,
                                    child: InkWell(
                                      onTap: widget.function,
                                      child: Container(
                                        width: 31,
                                        height: 31,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0x33263047)
                                              .withOpacity(.8),
                                          // color: Colors.white.withOpacity(.8),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_back,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Spacer(),
                                  Visibility(
                                    visible: !value.fullScreenOption.enabled,
                                    child: InkWell(
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            fit: BoxFit.scaleDown,
                                            PlayerImages.speed,
                                            height: 24,
                                            width: 24,
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          Text(
                                            '1x',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold),
                                          )
                                        ],
                                      ),
                                      onTap: () {
                                        // showSettingsBottomSheet(context, widget.controller);
                                        showPlayBackBottomSheet(
                                          context,
                                          value.fullScreenOption.enabled,
                                          widget.controller,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                    }),
                  ),
                ),

                //! Seek bar
                YoutubeValueBuilder(
                  builder: (context, value) {
                    return Positioned.fill(
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Visibility(
                          visible: value.isControlsVisible,
                          child: Builder(builder: (context) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: SizedBox(
                                // height: 20,
                                width: double.infinity - widget.controlsPadding,
                                child: Column(
                                  // mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        StreamBuilder<YoutubeVideoState>(
                                          initialData:
                                              const YoutubeVideoState(),
                                          stream: widget
                                              .controller.videoStateStream,
                                          builder: (context, snapshot) {
                                            final position = snapshot
                                                    .data?.position.inSeconds ??
                                                0;

                                            return Text(
                                              intToTime(position),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400),
                                            );
                                          },
                                        ),
                                        Expanded(
                                          child: const VideoPositionSeeker(),
                                        ),
                                        StreamBuilder<YoutubeVideoState>(
                                          initialData:
                                              const YoutubeVideoState(),
                                          stream: widget
                                              .controller.videoStateStream,
                                          builder: (context, snapshot) {
                                            final duration = context
                                                .ytController
                                                .metadata
                                                .duration
                                                .inSeconds;
                                            return Text(
                                              intToTime(duration),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400),
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            value.fullScreenOption.enabled
                                                ? widget.controller
                                                    .exitFullScreen()
                                                : widget.controller
                                                    .enterFullScreen();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10,
                                                left: 5,
                                                top: 1,
                                                bottom: 1),
                                            child: SvgPicture.asset(
                                              height: 24,
                                              width: 24,
                                              value.fullScreenOption.enabled
                                                  ? PlayerImages.exitFullScreen
                                                  : PlayerImages.fullScreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Visibility(
                                      visible: value.fullScreenOption.enabled,
                                      child: InkWell(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              fit: BoxFit.scaleDown,
                                              PlayerImages.speed,
                                              height: 24,
                                              width: 24,
                                            ),
                                            SizedBox(
                                              width: 4,
                                            ),
                                            Text(
                                              '1x',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          ],
                                        ),
                                        onTap: () {
                                          // showSettingsBottomSheet(context, widget.controller);
                                          showPlayBackBottomSheet(
                                            context,
                                            value.fullScreenOption.enabled,
                                            widget.controller,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        );
      }),
    );

    return YoutubePlayerControllerProvider(
      controller: widget.controller,
      child: kIsWeb
          ? widget.builder(context, player)
          : YoutubeValueBuilder(
              controller: widget.controller,
              buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
              builder: (context, value) {
                return _FullScreen(
                  auto: widget.autoFullScreen,
                  defaultOrientations: widget.defaultOrientations,
                  fullscreenOrientations: widget.fullscreenOrientations,
                  lockedOrientations: widget.lockedOrientations,
                  fullScreenOption: value.fullScreenOption,
                  child: Builder(
                    builder: (context) {
                      if (value.fullScreenOption.enabled)
                        return Center(child: player);
                      return widget.builder(context, player);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class VideoPositionSeeker extends StatelessWidget {
  ///
  const VideoPositionSeeker({super.key});
  @override
  Widget build(BuildContext context) {
    var value = 0.0;
    return StreamBuilder<YoutubeVideoState>(
      stream: context.ytController.videoStateStream,
      initialData: const YoutubeVideoState(),
      builder: (context, snapshot) {
        final position = snapshot.data?.position.inSeconds ?? 0;
        final duration = context.ytController.metadata.duration.inSeconds;
        value = position == 0 || duration == 0 ? 0 : position / duration;
        return StatefulBuilder(
          builder: (context, setState) {
            return SliderTheme(
              data: const SliderThemeData(
                  trackHeight: 6,
                  thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 8, disabledThumbRadius: 5)),
              child: Slider(
                thumbColor: const Color(0xffFF6028),
                // overlayColor: Colors.accents,
                secondaryActiveColor: Colors.black,

                activeColor: const Color(0xffFF6028),
                inactiveColor: const Color(0xffF4F1FF).withOpacity(.5),
                value: value <= 1 ? value : 1,
                onChanged: (positionFraction) {
                  value = positionFraction;
                  setState(() {});
                  context.ytController.seekTo(
                    seconds: (value * duration).toDouble(),
                    allowSeekAhead: true,
                  );
                },
                min: 0,
                max: 1,
              ),
            );
          },
        );
      },
    );
  }
}

class _FullScreen extends StatefulWidget {
  const _FullScreen({
    required this.fullScreenOption,
    required this.defaultOrientations,
    required this.fullscreenOrientations,
    required this.lockedOrientations,
    required this.child,
    required this.auto,
  });

  final FullScreenOption fullScreenOption;
  final List<DeviceOrientation> defaultOrientations;
  final List<DeviceOrientation> fullscreenOrientations;
  final List<DeviceOrientation> lockedOrientations;
  final Widget child;
  final bool auto;

  @override
  State<_FullScreen> createState() => _FullScreenState();
}

class _FullScreenState extends State<_FullScreen> with WidgetsBindingObserver {
  Orientation? _previousOrientation;

  @override
  void initState() {
    super.initState();

    if (widget.auto) WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(_deviceOrientations);
    SystemChrome.setEnabledSystemUIMode(_uiMode);
  }

  @override
  void didUpdateWidget(_FullScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fullScreenOption != widget.fullScreenOption) {
      SystemChrome.setPreferredOrientations(_deviceOrientations);
      SystemChrome.setEnabledSystemUIMode(_uiMode);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final orientation = MediaQuery.of(context).orientation;
    final controller = YoutubePlayerControllerProvider.of(context);
    final isFullScreen = controller.value.fullScreenOption.enabled;

    if (_previousOrientation == orientation) return;

    if (!isFullScreen && orientation == Orientation.landscape) {
      controller.enterFullScreen(lock: false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }

    _previousOrientation = orientation;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleFullScreenBackAction,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (widget.auto) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<DeviceOrientation> get _deviceOrientations {
    final fullscreen = widget.fullScreenOption;

    if (!fullscreen.enabled && fullscreen.locked) {
      return widget.lockedOrientations;
    } else if (fullscreen.enabled) {
      return widget.fullscreenOrientations;
    }

    return widget.defaultOrientations;
  }

  SystemUiMode get _uiMode {
    return widget.fullScreenOption.enabled
        ? SystemUiMode.immersive
        : SystemUiMode.edgeToEdge;
  }

  Future<bool> _handleFullScreenBackAction() async {
    if (mounted && widget.fullScreenOption.enabled) {
      YoutubePlayerControllerProvider.of(context).exitFullScreen();
      return false;
    }

    return true;
  }
}
