import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../component.dart';
import '../theme/theme.dart';

const _kHeaderHeight = 38.0;
const _kMinColumnWidth = 38.0;
const _kHandlerWidth = 8.0;
//const _kDefaultItemExtent = 40.0;

typedef TableHeaderBuilder = Widget Function(
  BuildContext context,
  int col,
  BoxConstraints colConstraints,
);

typedef TableRowBuilder = Widget Function(
  BuildContext context,
  int row,
  int col,
  BoxConstraints colConstraints,
);

//typedef RowMouseEvent = void Function(int row, MouseEvent event);

typedef RowPressedCallback = void Function(int index);

class ListTable extends StatefulWidget {
  const ListTable({
    this.tableBorder,
    required this.colCount,
    required this.itemCount,
    required this.tableHeaderBuilder,
    required this.tableRowBuilder,
    this.headerColumnBorder,
    this.colFraction,
    this.controller,
    this.itemExtent = _kHeaderHeight,
    this.showHiddenColumnsIndicator = true,
    this.onPressed,
    Key? key,
  })  : assert(colCount > 0),
        assert(itemExtent >= 0.0),
        super(key: key);

  final BorderSide? headerColumnBorder;

  final int colCount;

  final int itemCount;

  final Map<int, double>? colFraction;

  final TableRowBuilder tableRowBuilder;

  final TableHeaderBuilder tableHeaderBuilder;

  final TableBorder? tableBorder;

  final bool? showHiddenColumnsIndicator;

  final ScrollController? controller;

  final double itemExtent;

  final RowPressedCallback? onPressed;

  @override
  _ListTableState createState() => _ListTableState();
}

class _ListTableState extends State<ListTable> implements _TableDragUpdate {
  var columnWidths = {};
  bool hasHiddenColumns = false;

  int hoveredIndex = -1;
  int pressedIndex = -1;
  int waitingIndex = -1;

  Widget createHeader() {
    final TableBorder? tableBorder = widget.tableBorder;
    final bool hasBorder =
        tableBorder != null && tableBorder.top != BorderSide.none;

    final int lastNonZero = colSizes.lastIndexWhere((elem) => elem > 0.0);

    return Container(
      decoration: hasBorder
          ? BoxDecoration(
              border: Border(bottom: tableBorder.top)) // TODO(as): ???
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: List<Widget>.generate(colCount, (col) {
          assert(col < colSizes.length);

          if (colSizes[col] == 0.0) {
            return Container();
          }

          Widget result;

          if (colCount > 1 && col < colCount - 1) {
            result = Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return widget.tableHeaderBuilder(
                        context,
                        col,
                        constraints,
                      );
                    },
                  ),
                ),
                _TableColHandler(
                  tableDragUpdate: this,
                  col: col,
                  hasIndicator: (widget.showHiddenColumnsIndicator ?? false) &&
                      hasHiddenColumns &&
                      lastNonZero == col,
                  border:
                      widget.headerColumnBorder ?? tableBorder?.verticalInside,
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
            );
          } else {
            result = widget.tableHeaderBuilder(
              context,
              col,
              BoxConstraints.tightFor(
                width: colSizes[col],
                height: _kHeaderHeight,
              ),
            );
          }

          return ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              height: _kHeaderHeight,
              width: colSizes[col],
            ),
            child: result,
          );
        }).toList(),
      ),
    );
  }

  Widget createList(int index) {
    final int lastNonZero = colSizes.lastIndexWhere((elem) => elem > 0.0);

    return MouseRegion(
      onEnter: (_) => dragging ? null : setState(() => hoveredIndex = index),
      onExit: (_) => dragging ? null : setState(() => hoveredIndex = -1),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown:
            dragging ? null : (_) => setState(() => pressedIndex = index),
        onTapUp: dragging ? null : (_) => setState(() => pressedIndex = -1),
        onTapCancel: dragging ? null : () => setState(() => pressedIndex = -1),
        onTap: dragging
            ? null
            : () {
                if (widget.onPressed != null) {
                  if (waitingIndex == index) {
                    return;
                  }
                  waitingIndex = index;
                  final dynamic result = widget.onPressed!(index)
                      as dynamic; // TODO(as): fix dynamic

                  if (result is Future) {
                    setState(() => waitingIndex = index);
                    result.then((_) => setState(() => waitingIndex = -1));
                  } else {
                    waitingIndex = -1;
                  }
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: List<Widget>.generate(colCount, (col) {
            assert(col < colSizes.length);

            Widget result = LayoutBuilder(
              builder: (context, constraints) => widget.tableRowBuilder(
                context,
                index,
                col,
                constraints,
              ),
            );

            result = Align(alignment: Alignment.bottomLeft, child: result);

            final colorScheme = Theme.of(context).colorScheme;

            final HSLColor? backgroundColor =
                pressedIndex == index || waitingIndex == index
                    ? colorScheme.primary[60]
                    : hoveredIndex == index
                        ? colorScheme.shade[100]
                        : null;

            BoxDecoration decoration =
                BoxDecoration(color: backgroundColor?.toColor());

            // TODO(as): !!
            if (widget.tableBorder != null &&
                (widget.tableBorder!.horizontalInside != BorderSide.none ||
                    widget.tableBorder!.verticalInside != BorderSide.none)) {
              final isBottom = index < widget.itemCount - 1 || hasExtent;
              final isRight = col < widget.colCount - 1 && col < lastNonZero;

              final horizontalInside = widget.tableBorder!.horizontalInside;
              final verticalInside = widget.tableBorder!.verticalInside;

              final border = Border(
                bottom: isBottom ? horizontalInside : BorderSide.none,
                right: isRight ? verticalInside : BorderSide.none,
              );

              decoration = decoration.copyWith(border: border);
            }

            return Container(
              constraints: BoxConstraints.tightFor(
                width: colSizes[col],
              ),
              decoration: decoration,
              child: result,
            );
          }),
        ),
      ),
    );
  }

  List<double> colSizes = List.empty(growable: true);
  Map<int, double>? colFraction;

  bool dragging = false;
  double? previousWidth;
  double? totalWidth;
  List<double>? previousColSizes;
  Map<int, double>? previousColFraction;

  int get colCount => colSizes.length;

  ScrollController? currentController;
  ScrollController get controller =>
      widget.controller ?? (currentController ??= ScrollController());

  @override
  void dragStart(int col) {
    previousColFraction = Map<int, double>.from(colFraction!);
    previousColSizes = List<double>.from(colSizes);

    previousWidth = colSizes.sublist(col).reduce((v, e) => v + e);
    totalWidth = colSizes.reduce((v, e) => v + e);
    dragging = true;
  }

  @override
  void dragUpdate(int col, double delta) {
    setState(() {
      if (delta < 0) {
        delta = delta.clamp(-previousColSizes![col] + _kMinColumnWidth, 0.0);
      } else {
        delta = delta.clamp(0.0, previousWidth!);
      }

      final double newWidth = previousColSizes![col] + delta;
      colFraction![col] = newWidth / totalWidth!;

      final int totalRemain = colCount - (col + 1);

      if (totalRemain > 0) {
        final double valueEach = delta / totalRemain;
        double remWidth = previousWidth! - newWidth;

        for (int i = col + 1; i < colCount; i++) {
          if (remWidth >= _kMinColumnWidth) {
            final double newWidth = (previousColSizes![i] - valueEach)
                .clamp(_kMinColumnWidth, remWidth);
            colFraction![i] = newWidth / totalWidth!;
            remWidth -= newWidth;
          } else {
            colFraction![i] = 0.0;
          }
        }
      }
    });
  }

  @override
  void dragEnd() {
    setState(() {
      dragging = false;
      totalWidth = null;
      previousWidth = null;
      previousColSizes = null;
      previousColFraction = null;
    });
  }

  @override
  void dragCancel() => dragEnd();

  @override
  void initState() {
    super.initState();
  }

  bool hasExtent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance!.addPostFrameCallback((Duration duration) {
      final position = controller.position;
      position.didUpdateScrollPositionBy(0.0);
      //hasExtent = position.maxScrollExtent > position.minScrollExtent;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;

    if (notification.depth == 0) {
      final y = metrics.maxScrollExtent <= metrics.minScrollExtent;
      if (hasExtent != y) {
        setState(() => hasExtent = y);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = LayoutBuilder(
      builder: (context, constraints) {
        final int colCount = widget.colCount;
        colFraction ??= Map<int, double>.from(widget.colFraction ?? {});
        colSizes = List<double>.filled(colCount, 0);

        final double totalWidth = constraints.maxWidth;
        double remWidth = totalWidth;

        // TODO(as): make sure this is considering only the valid indexes
        int nfactors = 0;
        for (final value in colFraction!.keys) {
          if (value < colCount) {
            nfactors += 1;
          }
        }

        if (nfactors > 0) {
          for (int i = 0; i < colCount; i++) {
            if (remWidth <= 0.0) {
              remWidth = 0.0;
              break;
            }

            if (colFraction!.containsKey(i)) {
              if (remWidth >= _kMinColumnWidth) {
                // the last item
                if (nfactors == colCount && i == colCount - 1) {
                  colSizes[i] = remWidth;
                  remWidth = 0.0;
                  break;
                }

                final double width = (colFraction![i]! * totalWidth)
                    .roundToDouble()
                    .clamp(_kMinColumnWidth, remWidth);
                colSizes[i] = width;
                remWidth -= width;

                assert(remWidth >= 0.0,
                    'Wrong fraction value at $i value ${colFraction![i]}.');
              }
            }
          }
        }

        // if there's no key for every index in columns
        if (nfactors < colCount) {
          int remNFactors = colCount - nfactors;
          double nonFactorWidth = (remWidth / remNFactors).roundToDouble();

          assert(remWidth >= 0.0);

          for (int i = 0; i < colCount; i++) {
            if (!colFraction!.containsKey(i)) {
              remNFactors -= 1;

              if (remWidth < _kMinColumnWidth) {
                colFraction![i] = 0.0;
                continue;
              }

              // last item
              if (i == colCount - 1 || remNFactors == 0) {
                colSizes[i] = remWidth;
                colFraction![i] = remWidth / totalWidth;
                remWidth = 0;
                break;
              }

              if (nonFactorWidth > remWidth) {
                nonFactorWidth = remWidth;
              }

              colFraction![i] = nonFactorWidth / totalWidth;

              colSizes[i] = nonFactorWidth;
              remWidth -= nonFactorWidth;
            }
          }
        }

        if (remWidth > 0.0) {
          colSizes[colSizes.lastIndexWhere((value) => value > 0.0)] += remWidth;
          remWidth = 0.0;
        }

        hasHiddenColumns = !colSizes.every((elem) => elem > 0.0);

        return Column(
          children: [
            createHeader(),
            Expanded(
              child: ListView.custom(
                childrenDelegate: SliverChildBuilderDelegate(
                  (context, index) => createList(index),
                  childCount: widget.itemCount,
                ),
                controller: controller,
                itemExtent: widget.itemExtent,
              ),
            ),
          ],
        );
      },
    );

    final tableBorder = widget.tableBorder;

    if (tableBorder != null &&
        (tableBorder.left != BorderSide.none ||
            tableBorder.right != BorderSide.none ||
            tableBorder.top != BorderSide.none ||
            tableBorder.bottom != BorderSide.none)) {
      result = Container(
        decoration: BoxDecoration(
          border: Border(
            left: tableBorder.left,
            right: tableBorder.right,
            top: tableBorder.top,
            bottom: tableBorder.bottom,
          ),
        ),
        child: result,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: result,
    );
  }
}

abstract class _TableDragUpdate {
  void dragStart(int col);
  void dragUpdate(int col, double value);
  void dragEnd();
  void dragCancel();
}

class _TableColHandler extends StatefulWidget {
  const _TableColHandler({
    required this.tableDragUpdate,
    required this.col,
    required this.hasIndicator,
    this.border,
    Key? key,
  }) : super(key: key);

  final bool hasIndicator;
  final _TableDragUpdate tableDragUpdate;
  final int col;
  final BorderSide? border;

  @override
  _TableColHandlerState createState() => _TableColHandlerState();
}

class _TableColHandlerState extends State<_TableColHandler>
    with ComponentStateMixin {
  Map<Type, GestureRecognizerFactory> get _gestures {
    final gestures = <Type, GestureRecognizerFactory>{};

    gestures[HorizontalDragGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
      () => HorizontalDragGestureRecognizer(
        debugOwner: this,
      ),
      (HorizontalDragGestureRecognizer instance) {
        instance
          ..dragStartBehavior = DragStartBehavior.down
          ..onStart = _handleDragStart
          ..onDown = _handleDragDown
          ..onUpdate = _handleDragUpdate
          ..onCancel = _handleDragCancel
          ..onEnd = _handleDragEnd;
      },
    );

    return gestures;
  }

  double? currentPosition;
  _TableDragUpdate get tableUpdateColFactor => widget.tableDragUpdate;
  int get col => widget.col;

  void _handleDragStart(DragStartDetails details) {
    tableUpdateColFactor.dragStart(col);
    currentPosition = details.globalPosition.dx;
  }

  void _handleDragDown(DragDownDetails details) =>
      setState(() => dragged = true);

  void _handleDragUpdate(DragUpdateDetails details) {
    tableUpdateColFactor.dragUpdate(
        col, details.globalPosition.dx - currentPosition!);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() => dragged = false);
    tableUpdateColFactor.dragEnd();
  }

  void _handleDragCancel() {
    setState(() => dragged = false);
    tableUpdateColFactor.dragCancel();
  }

  void _handleMouseEnter(PointerEnterEvent event) =>
      setState(() => hovered = true);

  void _handleMouseExit(PointerExitEvent event) =>
      setState(() => hovered = false);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hoveredColor = colorScheme.shade[50];
    final draggedColor = colorScheme.shade[60];

    BorderSide? border = widget.border;
    final bool hasFocus = hovered || dragged || widget.hasIndicator;

    if (border != null && border != BorderSide.none) {
      final HSLColor borderColor = dragged
          ? draggedColor
          : hovered
              ? hoveredColor
              : HSLColor.fromColor(border.color);

      border = border.copyWith(
          color: borderColor.toColor(),
          width: hasFocus
              ? border.width + (border.width / 2.0).roundToDouble()
              : border.width);
    } else {
      final color = colorScheme.shade[40];
      final width = hasFocus ? 2.0 : 1.0;
      final borderColor = dragged
          ? draggedColor
          : hovered
              ? hoveredColor
              : color;
      border = BorderSide(width: width, color: borderColor.toColor());
    }

    return RawGestureDetector(
      gestures: _gestures,
      behavior: HitTestBehavior.translucent,
      child: MouseRegion(
        opaque: false,
        cursor: SystemMouseCursors.click,
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        child: Container(
          margin: EdgeInsets.only(
            left: (_kHandlerWidth - border.width).clamp(0.0, double.infinity),
          ),
          decoration: BoxDecoration(border: Border(right: border)),
        ),
      ),
    );
  }
}
