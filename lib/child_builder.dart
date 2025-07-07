import 'package:flutter/material.dart';

/// A stateless widget that enables advanced widget composition by passing a
/// `child` widget and a `builder` function.
///
/// - Takes a `child` widget and a `builder` function as arguments.
/// - The `builder` function receives the `BuildContext` and the `child` widget.
/// - Allows for constructing a widget tree where a part of it (the `child`)
///   is passed down to be incorporated by the `builder` function, promoting
///   widget composition and potentially optimization.
///
/// This is similar in concept to Flutter's built-in `Builder` widget, but
/// specifically designed to pass an existing `child` widget instance to the
/// `builder` function, which can be useful in scenarios like those handled by
/// `AnimatedBuilder` or `TweenAnimationBuilder` where a part of the widget
/// tree doesn't need to be rebuilt during animations.
/// Example usage:
/// ```dart
/// ChildBuilder(
///   builder: (context, child) {
///     return Container(
///       padding: EdgeInsets.all(16),
///       child: child,
///     );
///   },
///   child: Text('Hello, World!'),
/// )
/// ```
class ChildBuilder extends StatelessWidget {
  /// Creates a `ChildBuilder` widget.
  ///
  /// The [builder] parameter is a function that takes a [BuildContext] and a
  /// [Widget] (the `child`) and returns a new [Widget]. The [child] parameter
  /// is the widget to be passed to the `builder` function.
  const ChildBuilder({required this.builder, required this.child, super.key});

  /// The widget to be passed to the `builder` function.
  final Widget child;

  /// A function that takes the current [BuildContext] and the [child] widget
  /// and returns a new [Widget].
  final Widget Function(BuildContext context, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    // Calls the builder function with the current context and the child widget.
    return builder(context, child);
  }
}
