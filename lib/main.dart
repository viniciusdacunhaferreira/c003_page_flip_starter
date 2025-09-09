import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          // Use Center as layout has unconstrained width (loose constraints),
          // together with SizedBox to specify the max width (tight constraints)
          // See this thread for more info:
          // https://twitter.com/biz84/status/1445400059894542337
          child: Center(
            child: SizedBox(
              width: 500, // max allowed width
              child: HomePage(),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final pageFlipKey = GlobalKey<PageFlipBuilderState>();

  @override
  Widget build(BuildContext context) {
    return PageFlipBuilder(
      key: pageFlipKey,
      frontBuilder: (_) => LightHomePage(
        onFlip: () => pageFlipKey.currentState?.flip(),
      ),
      backBuilder: (_) => DarkHomePage(
        onFlip: () => pageFlipKey.currentState?.flip(),
      ),
    );
  }
}

class PageFlipBuilder extends StatefulWidget {
  const PageFlipBuilder({
    super.key,
    required this.frontBuilder,
    required this.backBuilder,
  });
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;

  @override
  PageFlipBuilderState createState() => PageFlipBuilderState();
}

// Note: there's no underscore here as we want this State subclass to be public.
// This is so that we can call the flip() method from the outside.
class PageFlipBuilderState extends State<PageFlipBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const kDuration = Durations.short4;
  static const kCurve = Easing.linear;

  bool get _inFrontSide => _controller.value.abs() < 0.5;

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double delta = details.primaryDelta!;

    if (_controller.value == 1 && !delta.isNegative) _controller.value = -1;
    if (_controller.value == -1 && delta.isNegative) _controller.value = 1;

    _controller.value += delta / screenWidth;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final double velocity = details.velocity.pixelsPerSecond.dx;

    if (velocity == 0 &&
        (_controller.value == -1 ||
            _controller.value == 1 ||
            _controller.value == 0)) {
      return;
    }

    if (velocity.abs() > 1000) {
      if (velocity.isNegative) {
        if (_inFrontSide) {
          _controller.animateTo(-1, curve: kCurve, duration: kDuration);
        } else {
          _controller.animateTo(0, curve: kCurve, duration: kDuration);
        }
      } else {
        if (_inFrontSide) {
          _controller.animateTo(1, curve: kCurve, duration: kDuration);
        } else {
          _controller.animateTo(0, curve: kCurve, duration: kDuration);
        }
      }
    } else {
      flip();
    }
  }

  void flip() {
    debugPrint('\n_controller.isCompleted = ${_controller.isCompleted}');
    debugPrint('_controller.isDismissed = ${_controller.isDismissed}');
    debugPrint('_controller.value = ${_controller.value}');
    debugPrint('_controller.value != 1.0 = ${_controller.value != 1.0}\n');

    if (_controller.isAnimating) return;

    if (_inFrontSide) {
      if (_controller.value == 0) {
        _controller.animateTo(1, curve: kCurve, duration: kDuration);
      } else {
        _controller.animateTo(0, curve: kCurve, duration: kDuration);
      }
    } else {
      if (_controller.value == 1) {
        _controller.value = -1;
        _controller.animateTo(0, curve: kCurve, duration: kDuration);
      } else if (_controller.value == -1) {
        _controller.animateTo(0, curve: kCurve, duration: kDuration);
      } else if (_controller.value.isNegative) {
        _controller.animateTo(-1, curve: kCurve, duration: kDuration);
      } else {
        _controller.animateTo(1, curve: kCurve, duration: kDuration);
      }
    }
  }

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: kDuration,
      lowerBound: -1,
      upperBound: 1,
      value: 0,
    );

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          final child = _inFrontSide
              ? widget.frontBuilder(context)
              : widget.backBuilder(context);

          double getTilt() {
            var tilt = (value - 0.5).abs() - 0.5;
            if (value < -0.5) {
              tilt = 1.0 + value;
            }
            return tilt * (_inFrontSide ? -0.003 : 0.003);
          }

          double rotationAngle() {
            final rotationValue = value * pi;
            if (value > 0.5) {
              return pi - rotationValue; // input from 0.5 to 1.0
            } else if (value > -0.5) {
              return rotationValue; // input from -0.5 to 0.5
            } else {
              return -pi - rotationValue; // input from -1.0 to -0.5
            }
          }

          return Transform(
            transform: Matrix4.rotationY(rotationAngle())
              ..setEntry(3, 0, getTilt()),
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }
}

class LightHomePage extends StatelessWidget {
  const LightHomePage({super.key, this.onFlip});
  final VoidCallback? onFlip;
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        textTheme: TextTheme(
          displaySmall: Theme.of(context)
              .textTheme
              .displaySmall!
              .copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 5),
          ),
          child: Column(
            children: [
              const ProfileHeader(prompt: 'Hello,\nsunshine!'),
              const Spacer(),
              const VectorGraphic(
                loader: AssetBytesLoader('assets/forest-day.svg'),
                semanticsLabel: 'Forest',
                width: 300,
                height: 300,
              ),
              const Spacer(),
              BottomFlipIconButton(onFlip: onFlip),
            ],
          ),
        ),
      ),
    );
  }
}

class DarkHomePage extends StatelessWidget {
  const DarkHomePage({super.key, this.onFlip});
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
          brightness: Brightness.dark,
          textTheme: TextTheme(
            displaySmall: Theme.of(context)
                .textTheme
                .displaySmall!
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          )),
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 5),
          ),
          child: Column(
            children: [
              const ProfileHeader(prompt: 'Good night,\nsleep tight!'),
              const Spacer(),
              const VectorGraphic(
                loader: AssetBytesLoader('assets/forest-night.svg'),
                semanticsLabel: 'Forest',
                width: 300,
                height: 300,
              ),
              const Spacer(),
              BottomFlipIconButton(onFlip: onFlip),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          Text(prompt, style: Theme.of(context).textTheme.displaySmall),
          const Spacer(),
          const VectorGraphic(
            loader: AssetBytesLoader('assets/man.svg'),
            semanticsLabel: 'Profile',
            width: 50,
            height: 50,
          ),
        ],
      ),
    );
  }
}

class BottomFlipIconButton extends StatelessWidget {
  const BottomFlipIconButton({super.key, this.onFlip});
  final VoidCallback? onFlip;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onFlip,
          icon: const Icon(Icons.flip),
        )
      ],
    );
  }
}
