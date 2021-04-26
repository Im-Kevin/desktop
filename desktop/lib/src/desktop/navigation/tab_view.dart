import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../theme/theme.dart';

import 'route.dart';
import 'tab_route.dart';
import 'tab_scope.dart';

/// A tab view with a [Navigator] history.
class TabView extends StatefulWidget {
  const TabView({
    this.builder,
    this.navigatorKey,
    this.routes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.defaultTitle,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.restorationScopeId,
    Key? key,
  }) : super(key: key);

  /// The widget builder for the default route of the tab view
  /// ([Navigator.defaultRouteName], which is `/`).
  ///
  /// If a [builder] is specified, then [routes] must not include an entry for `/`,
  /// as [builder] takes its place.
  final WidgetBuilder? builder;

  final GlobalKey<NavigatorState>? navigatorKey;

  /// The title of the default route.
  final String? defaultTitle;

  /// This tab view's routing table.
  ///
  /// This routing table is not shared with any routing tables of ancestor or
  /// descendant [Navigator]s.
  final Map<String, WidgetBuilder>? routes;

  /// The route generator callback used when the tab view is navigated to a named route.
  final RouteFactory? onGenerateRoute;

  /// Called when [onGenerateRoute] also fails to generate a route.
  final RouteFactory? onUnknownRoute;

  /// The list of observers for the [Navigator] created in this tab view.
  final List<NavigatorObserver> navigatorObservers;

  /// Restoration ID to save and restore the state of the [Navigator] built by
  /// this [TabView].
  ///
  /// {@macro flutter.widgets.navigator.restorationScopeId}
  final String? restorationScopeId;

  @override
  TabViewState createState() => TabViewState();
}

class TabViewState extends State<TabView> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      onGenerateRoute: _onGenerateRoute,
      onUnknownRoute: _onUnknownRoute,
      observers: widget.navigatorObservers,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String? name = settings.name;
    WidgetBuilder? routeBuilder;
    String? title;

    if (name == Navigator.defaultRouteName && widget.builder != null) {
      routeBuilder = widget.builder;
      title = widget.defaultTitle;
    } else if (widget.routes != null) {
      routeBuilder = widget.routes![name];
    }

    if (routeBuilder != null) {
      return DesktopPageRoute<dynamic>(
        builder: routeBuilder,
        title: title,
        settings: settings,
      );
    }

    return widget.onGenerateRoute?.call(settings);
  }

  Route<dynamic>? _onUnknownRoute(RouteSettings settings) {
    if (widget.onUnknownRoute != null) {
      return widget.onUnknownRoute!(settings);
    }

    ThemeData themeData = Theme.of(context);

    return TabMenuRoute(
      context: context,
      barrierColor: themeData.colorScheme.background,
      axis: TabScope.of(context)!.axis,
      pageBuilder: (context) => Container(
        alignment: Alignment.center,
        color: themeData.colorScheme.background.toColor(),
        child: Text(
          'Page "${settings.name}" not found',
          style: themeData.textTheme.title,
        ),
      ),
      settings: settings,
    );
  }
}
