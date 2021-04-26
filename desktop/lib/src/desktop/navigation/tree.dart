import 'dart:collection';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../input/button.dart';
import '../theme/theme.dart';
import '../icons.dart';
import '../scrolling/scrollbar.dart';

import 'tab_view.dart';


class TreeNode {
  final List<TreeNode>? children;
  final WidgetBuilder? builder;
  final String title;

  const TreeNode(this.title, {this.builder, this.children})
      : assert(builder == null || children == null);
}

/// Tree
///
/// ```dart
/// Tree(
///   title: Builder(
///     builder: (context) => Text(
///       'Tree',
///       style: Theme.of(context).textTheme.body2,
///     ),
///   ),
///   nodes: [
///     TreeNode(
///       'Node0',
///       builder: (context) => Text('Node0'),
///     ),
///     TreeNode('Node1', children: [
///       TreeNode(
///         'Node0',
///         builder: (context) => Text('Node0'),
///       ),
///       TreeNode(
///         'Node1',
///         builder: (context) => Text('Node1'),
///       ),
///       TreeNode(
///         'Node2',
///         builder: (context) => Text('Node2'),
///       ),
///       TreeNode('Node3', children: [
///         TreeNode(
///           'Node0',
///           builder: (context) => Text('Node0'),
///         ),
///         TreeNode(
///           'Node1',
///           builder: (context) => Text('Node1'),
///         ),
///       ]),
///     ]),
///     TreeNode(
///       'Node2',
///       builder: (context) => Text('Node2'),
///     ),
///     TreeNode('Node3', children: [
///       TreeNode(
///         'Node0',
///         builder: (context) => Text('Node0'),
///       ),
///       TreeNode(
///         'Node1',
///         builder: (context) => Text('Node1'),
///       ),
///     ]),
///   ],
/// )```
class Tree extends StatefulWidget {
  Tree({
    this.title,
    required this.nodes,
    this.pagePadding,
    Key? key,
  }) : super(key: key);

  final Widget? title;
  final List<TreeNode> nodes;
  final EdgeInsets? pagePadding;

  @override
  _TreeState createState() => _TreeState();

  static _TreeState? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TreeScope>()?.treeState;
}

class _BuildTreePage {
  _BuildTreePage(this.builder);

  final WidgetBuilder builder;
  final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
  final FocusScopeNode focusScopeNode = FocusScopeNode(skipTraversal: true);
  bool shouldBuild = false;
}

class _TreeState extends State<Tree> {
  final _pages = HashMap<String, _BuildTreePage>();
  String? _current;
  void setPage(String name) => setState(() => _current = name);

  void _createEntries(String name, TreeNode node) {
    final nameResult = '''$name${node.title}''';

    if (node.children != null) {
      for (var child in node.children!) {
        _createEntries(nameResult, child);
      }
    } else if (node.builder != null) {
      _pages[nameResult] = _BuildTreePage(node.builder!);
    } else {
      throw Exception('Either builder or children must be non null');
    }
  }

  @override
  void didUpdateWidget(Tree oldWidget) {
    super.didUpdateWidget(oldWidget);

    // FIXME!!!!!!!
    // if (widget.items.length - _shouldBuildView.length > 0) {
    //   _shouldBuildView.addAll(List<bool>.filled(
    //       widget.items.length - _shouldBuildView.length, false));
    // } else {
    //   _shouldBuildView.removeRange(
    //       widget.items.length, _shouldBuildView.length);
    // }

    // if (widget.items.length - _navigators.length > 0) {
    //   _navigators.addAll(List<GlobalKey<NavigatorState>>.generate(
    //       widget.items.length - _navigators.length,
    //       (index) => GlobalKey<NavigatorState>()));
    // } else {
    //   _navigators.removeRange(widget.items.length, _navigators.length);
    // }

    //  _focusView();
  }

  @override
  void initState() {
    super.initState();

    if (widget.nodes.isEmpty) {
      throw Exception('Nodes cannot be empty');
    }

    for (var node in widget.nodes) {
      _createEntries('', node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagesResult = List<Widget>.empty(growable: true);

    _current ??= widget.nodes.first.title;

    for (var entry in _pages.entries) {
      final active = entry.key == _current!;
      entry.value.shouldBuild = active || entry.value.shouldBuild;

      pagesResult.add(
        Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: FocusScope(
              node: entry.value.focusScopeNode,
              canRequestFocus: active,
              child: Builder(
                builder: (context) {
                  return entry.value.shouldBuild
                      ? Padding(
                          padding: widget.pagePadding ?? EdgeInsets.zero,
                          child: TabView(
                            navigatorKey: entry.value.navigator,
                            builder: entry.value.builder,
                          ),
                        )
                      : Container();
                },
              ),
            ),
          ),
        ),
      );
    }

    final controller = ScrollController();

    Widget result = Row(
      children: [
        Container(
          alignment: Alignment.topLeft,
          width: 200.0,
          child: Scrollbar(
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.title != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: widget.title!,
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.nodes
                          .map((e) => _TreeColumn(node: e, parentName: ''))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: pagesResult,
          ),
        )
      ],
    );

    result = _TreeScope(
      child: result,
      treeState: this,
    );

    return result;
  }
}

class _TreeScope extends InheritedWidget {
  const _TreeScope({
    Key? key,
    required this.treeState,
    required Widget child,
  }) : super(key: key, child: child);

  final _TreeState treeState;

  @override
  bool updateShouldNotify(_TreeScope old) => old.treeState != treeState;
}

class _TreeColumn extends StatefulWidget {
  _TreeColumn({
    required this.node,
    required this.parentName,
    Key? key,
  }) : super(key: key);

  final TreeNode node;
  final String parentName;

  @override
  _TreeColumnState createState() => _TreeColumnState();
}

class _TreeColumnState extends State<_TreeColumn> {
  var _collapsed = true;

  String get name => '${widget.parentName}${widget.node.title}';

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;

    if (widget.node.title.isEmpty) {
      throw Exception('Title in tree cannot be null');
    }

    if (widget.node.children != null) {
      final iconCollpased = _collapsed ? Icons.expand_more : Icons.expand_less;
      final chidrenWidget = Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.node.children!
              .map((e) => _TreeColumn(
                    node: e,
                    parentName: name,
                  ))
              .toList(),
        ),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ButtonTheme.merge(
            data: ButtonThemeData(
              color: textTheme.textLow,
              hoverColor: colorScheme.shade,
              highlightColor: colorScheme.shade,
            ),
            child: Button(
              bodyPadding: EdgeInsets.zero,
              trailingPadding: EdgeInsets.only(left: 8.0),
              padding: EdgeInsets.zero,
              body: Text(widget.node.title),
              trailing: Icon(iconCollpased),
              onPressed: () => setState(() => _collapsed = !_collapsed),
            ),
          ),
          Offstage(
            child: chidrenWidget,
            offstage: _collapsed,
          ),
        ],
      );
    } else {
      final active = Tree._of(context)!._current == name;
      final hoverColor = active ? colorScheme.primary1 : textTheme.textHigh;
      final activeColor = active ? colorScheme.primary1 : textTheme.textLow;
      final highlightColor = colorScheme.primary1;

      return ButtonTheme.merge(
        data: ButtonThemeData(
          color: activeColor,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          focusColor: hoverColor,
        ),
        child: Button(
          padding: EdgeInsets.zero,
          bodyPadding: EdgeInsets.zero,
          body: Text(widget.node.title),
          onPressed: () {
            Tree._of(context)!.setPage(name);
          },
        ),
      );
    }
  }
}
