import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import 'theme_data.dart';

const EdgeInsets _kDialogPadding = EdgeInsets.all(16.0);
const EdgeInsets _kTitlePadding = EdgeInsets.only(bottom: 16.0);
const EdgeInsets _kMenuPadding = EdgeInsets.only(top: 16.0);
const EdgeInsets _kOutsidePadding = EdgeInsets.symmetric(vertical: 32.0);
const double _kMinDialogWidth = 640.0;
const double _kMinDialogHeight = 120.0;

@immutable
class DialogThemeData {
  const DialogThemeData({
    this.dialogPadding = _kDialogPadding,
    this.outsidePadding = _kOutsidePadding,
    this.titlePadding = _kTitlePadding,
    this.menuPadding = _kMenuPadding,
    this.constraints = const BoxConstraints(
      minWidth: _kMinDialogWidth,
      minHeight: _kMinDialogHeight,
    ),
    this.background,
    this.barrierColor,
  });

  final BoxConstraints constraints;

  final EdgeInsets menuPadding;

  final EdgeInsets titlePadding;

  final EdgeInsets outsidePadding;

  final EdgeInsets dialogPadding;

  final HSLColor? background;

  final HSLColor? barrierColor;

  DialogThemeData copyWidth({
    BoxConstraints? constraints,
    EdgeInsets? menuPadding,
    EdgeInsets? titlePadding,
    EdgeInsets? outsidePadding,
    EdgeInsets? dialogPadding,
    HSLColor? background,
    HSLColor? barrierColor,
  }) {
    return DialogThemeData(
      constraints: constraints ?? this.constraints,
      menuPadding: menuPadding ?? this.menuPadding,
      titlePadding: titlePadding ?? this.titlePadding,
      outsidePadding: outsidePadding ?? this.outsidePadding,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      background: background ?? this.background,
      barrierColor: barrierColor ?? this.barrierColor,
    );
  }

  bool get isConcrete {
    return background != null || barrierColor != null;
  }

  @override
  int get hashCode {
    return hashValues(
      constraints,
      menuPadding,
      titlePadding,
      outsidePadding,
      dialogPadding,
      background,
      barrierColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DialogThemeData &&
        other.constraints == constraints &&
        other.menuPadding == menuPadding &&
        other.titlePadding == titlePadding &&
        other.outsidePadding == outsidePadding &&
        other.dialogPadding == dialogPadding &&
        other.background == background &&
        other.barrierColor == barrierColor;
  }
}

@immutable
class DialogTheme extends InheritedTheme {
  const DialogTheme({
    required this.data,
    required Widget child,
    Key? key,
  }) : super(child: child, key: key);

  final DialogThemeData data;

  static DialogThemeData of(BuildContext context) {
    final DialogTheme? dialogTheme =
        context.dependOnInheritedWidgetOfExactType<DialogTheme>();
    DialogThemeData? dialogThemeData = dialogTheme?.data;

    if (dialogThemeData?.background == null ||
        dialogThemeData?.barrierColor == null) {
      final ThemeData themeData = Theme.of(context);
      dialogThemeData ??= themeData.dialogTheme;

      if (dialogThemeData.background == null) {
        dialogThemeData = dialogThemeData.copyWidth(
            background: themeData.colorScheme.background);
      }

      if (dialogThemeData.barrierColor == null) {
        final barrierColor =
            themeData.colorScheme.brightness == Brightness.light
                ? const HSLColor.fromAHSL(0.8, 0.0, 0.0, 0.8)
                : const HSLColor.fromAHSL(0.8, 0.0, 0.0, 0.2);
        dialogThemeData = dialogThemeData.copyWidth(barrierColor: barrierColor);
      }
    }

    assert(dialogThemeData!.isConcrete);

    return dialogThemeData!; // TODO(as): ???
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final DialogTheme? ancestorTheme =
        context.findAncestorWidgetOfExactType<DialogTheme>();
    return identical(this, ancestorTheme)
        ? child
        : DialogTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DialogTheme oldWidget) => data != oldWidget.data;
}
