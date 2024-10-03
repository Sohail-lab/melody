import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'dart:math';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends State<Player> with WidgetsBindingObserver {
  final AudioPlayer disc = AudioPlayer();
  bool loop = false;
  bool pause = true;
  bool volume = true;
  Color controlButtonSplashColor = Colors.blue;
  late String currentMusic;
  final List<String> music = [
    'assets/music/yad.mp3',
    'assets/music/positions.mp3',
    'assets/music/dandelions.mp3',
    'assets/music/december.mp3',
  ];

  late Stream<DurationState> _durationState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();

    _durationState = Stream.periodic(const Duration(seconds: 1), (_) {
      final position = disc.position;
      final duration = disc.duration ?? Duration.zero;
      final buffered = disc.bufferedPosition;

      return DurationState(
        progress: position,
        buffered: buffered,
        total: duration,
      );
    }).asBroadcastStream();
  }

  String getMusic() {
    return music[Random().nextInt(music.length)];
  }

  String skipMusic(String direction) {
    int index = music.indexOf(currentMusic);
    if (direction == 'back') {
      index = index > 0 ? index - 1 : 0;
    }
    if (direction == 'ahead') {
      index = index < music.length - 1 ? index + 1 : music.length - 1;
    }
    currentMusic = music[index];
    return currentMusic;
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    try {
      currentMusic = getMusic();
      await disc.setAudioSource(AudioSource.asset(currentMusic));
    } on PlayerException catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Melody",
          style:
              TextStyle(fontSize: 40, fontFamily: 'ICE', color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.black26, Colors.blue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 90,
              ),
              const Icon(
                Icons.music_video_rounded,
                size: 250,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 30)),
                  Expanded(
                    // Use Expanded to prevent overflow
                    child: StreamBuilder<DurationState>(
                      stream: _durationState,
                      builder: (context, snapshot) {
                        final durationState = snapshot.data;
                        final progress =
                            durationState?.progress ?? Duration.zero;
                        final buffered =
                            durationState?.buffered ?? Duration.zero;
                        final total = durationState?.total ?? Duration.zero;

                        return ProgressBar(
                          progress: progress,
                          buffered: buffered,
                          total: total,
                          onSeek: (duration) {
                            disc.seek(duration);
                          },
                          timeLabelLocation: TimeLabelLocation.below,
                          progressBarColor: Colors.black,
                          baseBarColor: Colors.white54,
                          bufferedBarColor: Colors.transparent,
                          thumbColor: Colors.black87,
                          thumbCanPaintOutsideBar: true,
                          timeLabelType: TimeLabelType.totalTime,
                        );
                      },
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(right: 30)),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.white70,
                    splashColor: controlButtonSplashColor,
                    elevation: volume ? 6.0 : 0.0,
                    onPressed: () {
                      volume = !volume;
                      disc.setVolume(volume ? 1.0 : 0.0);
                      setState(() {});
                    },
                    child: volume
                        ? const Icon(
                            Icons.volume_up,
                            color: Colors.black87,
                            size: 30,
                          )
                        : const Icon(
                            Icons.volume_off,
                            color: Colors.black87,
                            size: 30,
                          ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.white70,
                    splashColor: controlButtonSplashColor,
                    onPressed: () {
                      disc.setAudioSource(AudioSource.asset(skipMusic('back')));
                      if (music.indexOf(currentMusic) == 0) {
                        showToast("Already at the end of playlist",
                            context: context,
                            textStyle: const TextStyle(
                                fontFamily: 'ICE', color: Colors.white));
                      }
                    },
                    child: const Icon(
                      Icons.skip_previous,
                      size: 30,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  FloatingActionButton.large(
                    backgroundColor: Colors.white70,
                    shape: const CircleBorder(),
                    splashColor: controlButtonSplashColor,
                    onPressed: () {
                      if (pause) {
                        disc.play();
                      } else {
                        disc.pause();
                      }
                      setState(() {
                        pause = !pause;
                      });
                    },
                    child: pause
                        ? const Icon(
                            Icons.play_arrow,
                            size: 80,
                            color: Colors.black87,
                          )
                        : const Icon(
                            Icons.pause,
                            size: 50,
                            color: Colors.black87,
                          ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.white70,
                    splashColor: controlButtonSplashColor,
                    onPressed: () {
                      disc.setAudioSource(
                          AudioSource.asset(skipMusic('ahead')));
                      if (music.indexOf(currentMusic) == music.length - 1) {
                        showToast('Already at the end of playlist',
                            context: context,
                            textStyle: const TextStyle(
                              fontFamily: 'ICE',
                              color: Colors.white,
                            ));
                      }
                    },
                    child: const Icon(
                      Icons.skip_next,
                      color: Colors.black87,
                      size: 30,
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.white70,
                    splashColor: controlButtonSplashColor,
                    elevation: loop ? 0.0 : 6.0,
                    onPressed: () {
                      if (!loop) {
                        disc.setLoopMode(LoopMode.one);
                      } else {
                        disc.setLoopMode(LoopMode.off);
                      }
                      setState(() {
                        loop = !loop;
                      });
                    },
                    child: loop
                        ? const Icon(
                            Icons.loop,
                            color: Colors.blueAccent,
                            size: 30,
                          )
                        : const Icon(
                            Icons.loop,
                            color: Colors.black87,
                            size: 30,
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

class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });
  final Duration progress;
  final Duration buffered;
  final Duration total;
}
