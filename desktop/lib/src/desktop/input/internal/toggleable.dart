// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

// Duration of the animation that moves the toggle from one state to another.
const Duration _kToggleDuration = Duration(milliseconds: 120);

abstract class RenderToggleable extends RenderConstrainedBox {
  /// Creates a toggleable render object.
  ///
  /// The [activeColor], and [inactiveColor] arguments must not be
  /// null. The [value] can only be null if tristate is true.
  RenderToggleable({
    bool? value,
    bool tristate = false,
    required Color activeColor,
    required Color inactiveColor,
    required Color disabledColor,
    required Color focusColor,
    ValueChanged<bool?>? onChanged,
    required BoxConstraints additionalConstraints,
    required TickerProvider vsync,
    bool hasFocus = false,
    bool hovering = false,
  })  : assert(tristate || value != null),
        _value = value,
        _tristate = tristate,
        _activeColor = activeColor,
        _inactiveColor = inactiveColor,
        _disabledColor = disabledColor,
        _focusColor = focusColor,
        _onChanged = onChanged,
        _hasFocus = hasFocus,
        _hovering = hovering,
        _vsync = vsync,
        super(additionalConstraints: additionalConstraints) {
    _tap = TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;

    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: value == false ? 0.0 : 1.0,
      vsync: vsync,
    );

    _position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    )
      ..addListener(markNeedsPaint)
      ..addStatusListener(_handlePositionStateChanged);
  }

  /// Used by subclasses to manipulate the visual value of the control.
  ///
  /// Some controls respond to user input by updating their visual value. For
  /// example, the thumb of a switch moves from one position to another when
  /// dragged. These controls manipulate this animation controller to update
  /// their [position] and eventually trigger an [onChanged] callback when the
  /// animation reaches either 0.0 or 1.0.
  @protected
  AnimationController get positionController => _positionController;
  late AnimationController _positionController;

  /// The visual value of the control.
  ///
  /// When the control is inactive, the [value] is false and this animation has
  /// the value 0.0. When the control is active, the value either true or tristate
  /// is true and the value is null. When the control is active the animation
  /// has a value of 1.0. When the control is changing from inactive
  /// to active (or vice versa), [value] is the target value and this animation
  /// gradually updates from 0.0 to 1.0 (or vice versa).
  CurvedAnimation get position => _position;
  late CurvedAnimation _position;

  /// True if this toggleable has the input focus.
  bool get hasFocus => _hasFocus;
  bool _hasFocus;
  set hasFocus(bool value) {
    if (value == _hasFocus) return;
    _hasFocus = value;
    if (_hasFocus) {
//      _reactionFocusFadeController.forward();
    } else {
      //    _reactionFocusFadeController.reverse();
    }
    markNeedsPaint();
  }

  /// True if this toggleable is being hovered over by a pointer.
  bool get hovering => _hovering;
  bool _hovering;
  set hovering(bool value) {
    if (value == _hovering) return;
    _hovering = value;
    if (_hovering) {
      //  _reactionHoverFadeController.forward();
    } else {
      //_reactionHoverFadeController.reverse();
    }
    markNeedsPaint();
  }

  /// The [TickerProvider] for the [AnimationController]s that run the animations.
  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    if (value == _vsync) return;
    _vsync = value;
    positionController.resync(vsync);
    // reactionController.resync(vsync);
  }

  /// False if this control is "inactive" (not checked, off, or unselected).
  ///
  /// If value is true then the control "active" (checked, on, or selected). If
  /// tristate is true and value is null, then the control is considered to be
  /// in its third or "indeterminate" state.
  ///
  /// When the value changes, this object starts the [positionController] and
  /// [position] animations to animate the visual appearance of the control to
  /// the new value.
  bool? get value => _value;
  bool? _value;
  set value(bool? value) {
    assert(tristate! || value != null);
    if (value == _value) return;
    _value = value;
    markNeedsSemanticsUpdate();

    _position
      ..curve = Curves.easeIn
      ..reverseCurve = Curves.easeOut;

    if (tristate!) {
      switch (_positionController.status) {
        case AnimationStatus.forward:
        case AnimationStatus.completed:
          _positionController.reverse();
          break;
        default:
          _positionController.forward();
      }
    } else {
      if (value == true)
        _positionController.forward();
      else
        _positionController.reverse();
    }
  }

  /// If true, [value] can be true, false, or null, otherwise [value] must
  /// be true or false.
  ///
  /// When [tristate] is true and [value] is null, then the control is
  /// considered to be in its third or "indeterminate" state.
  bool? get tristate => _tristate;
  bool? _tristate;
  set tristate(bool? value) {
    assert(tristate != null);
    if (value == _tristate) return;
    _tristate = value;
    markNeedsSemanticsUpdate();
  }

  /// The color that should be used in the active state (i.e., when [value] is true).
  ///
  /// For example, a checkbox should use this color when checked.
  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    if (value == _activeColor) return;
    _activeColor = value;
    markNeedsPaint();
  }

  /// The color that should be used in the inactive state (i.e., when [value] is false).
  ///
  /// For example, a checkbox should use this color when unchecked.
  Color get inactiveColor => _inactiveColor;
  Color _inactiveColor;
  set inactiveColor(Color value) {
    if (value == _inactiveColor) return;
    _inactiveColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when [hovering] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it is being hovered over.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get disabledColor => _disabledColor;
  Color _disabledColor;
  set disabledColor(Color value) {
    if (value == _disabledColor) return;
    _disabledColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when [hasFocus] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it has focus.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get focusColor => _focusColor;
  Color _focusColor;
  set focusColor(Color value) {
    if (value == _focusColor) return;
    _focusColor = value;
    markNeedsPaint();
  }

  /// Called when the control changes value.
  ///
  /// If the control is tapped, [onChanged] is called immediately with the new
  /// value. If the control changes value due to an animation (see
  /// [positionController]), the callback is called when the animation
  /// completes.
  ///
  /// The control is considered interactive (see [isInteractive]) if this
  /// callback is non-null. If the callback is null, then the control is
  /// disabled, and non-interactive. A disabled checkbox, for example, is
  /// displayed using a grey color and its value cannot be changed.
  ValueChanged<bool?>? get onChanged => _onChanged;
  ValueChanged<bool?>? _onChanged;
  set onChanged(ValueChanged<bool?>? value) {
    if (value == _onChanged) return;
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// Whether [value] of this control can be changed by user interaction.
  ///
  /// The control is considered interactive if the [onChanged] callback is
  /// non-null. If the callback is null, then the control is disabled, and
  /// non-interactive. A disabled checkbox, for example, is displayed using a
  /// grey color and its value cannot be changed.
  bool get isInteractive => onChanged != null;

  late TapGestureRecognizer _tap;
  Offset? _downPosition;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (value == false)
      _positionController.reverse();
    else
      _positionController.forward();
  }

  @override
  void detach() {
    _positionController.stop();
    super.detach();
  }

  // Handle the case where the _positionController's value changes because
  // the user dragged the toggleable: we may reach 0.0 or 1.0 without
  // seeing a tap. The Switch does this.
  void _handlePositionStateChanged(AnimationStatus status) {
    if (isInteractive && !tristate!) {
      if (status == AnimationStatus.completed && _value == false) {
        onChanged!(true);
      } else if (status == AnimationStatus.dismissed && _value != false) {
        onChanged!(false);
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      _downPosition = globalToLocal(details.globalPosition);
    }
  }

  void _handleTap() {
    if (!isInteractive) return;
    switch (value) {
      case false:
        onChanged!(true);
        break;
      case true:
        onChanged!((tristate ?? false) ? null : false);
        break;
      default: // case null:
        onChanged!(false);
        break;
    }

    sendSemanticsEvent(const TapSemanticEvent());
  }

  void _handleTapUp(TapUpDetails details) => _downPosition = null;

  void _handleTapCancel() => _downPosition = null;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) _tap.addPointer(event);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isEnabled = isInteractive;
    if (isInteractive) config.onTap = _handleTap;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('value',
        value: value, ifTrue: 'checked', ifFalse: 'unchecked', showName: true));
    properties.add(FlagProperty('isInteractive',
        value: isInteractive,
        ifTrue: 'enabled',
        ifFalse: 'disabled',
        defaultValue: true));
  }
}