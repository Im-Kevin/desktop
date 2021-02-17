import 'package:desktop/desktop.dart';
import 'defaults.dart';

class ColorschemePage extends StatefulWidget {
  ColorschemePage({Key? key}) : super(key: key);

  @override
  _ColorschemePageState createState() => _ColorschemePageState();
}

Widget _itemPrimary(
  BuildContext context,
  PrimaryColor color, [
  HSLColor? foreground,
]) {
  return _createItemForColor(context, color, color.toString(), foreground);
}

Widget _createItemForColor(
  BuildContext context,
  HSLColor color,
  String name, [
  HSLColor? foreground,
]) {
  final textStyle = Theme.of(context).textTheme.body2.copyWith(
        color: foreground?.toColor(),
      );
  return Container(
    color: color.toColor(),
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.all(8.0),
    height: 200.0,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: textStyle,
        ),
        Text(
          'Hue: ${(color.hue.round()).toString()}',
          style: textStyle,
        ),
        Text(
          'Saturation: ${(color.saturation * 100.0).round().toString()}%',
          style: textStyle,
        ),
        Text(
          'Lightness: ${(color.lightness * 100.0).round().toString()}%',
          style: textStyle,
        ),
        Text(
          'Alpha: ${(color.alpha * 100.0).round().toString()}%',
          style: textStyle,
        ),
      ],
    ),
  );
}

class _ColorschemePageState extends State<ColorschemePage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final light = ColorScheme(Brightness.dark).inverted;
    final dark = ColorScheme(Brightness.dark).background;

    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: [
            Defaults.createHeader(context, 'Color Scheme'),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _createItemForColor(
                    context,
                    colorScheme.background,
                    'Background',
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.background1,
                    'Background 1',
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.background2,
                    'Background 2',
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.background3,
                    'Background 3',
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.background4,
                    'Background 4',
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.disabled,
                    'Disabled',
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.inverted,
                    'Inverted',
                    colorScheme.background,
                  ),
                  _createItemForColor(
                    context,
                    textTheme.textLow,
                    'Text Low',
                    colorScheme.background,
                  ),
                  _createItemForColor(
                    context,
                    textTheme.textMedium,
                    'Text Medium',
                    colorScheme.background,
                  ),
                  _createItemForColor(
                    context,
                    textTheme.textHigh,
                    'Text High',
                    colorScheme.background,
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.primary,
                    'Primary',
                    light,
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.primary1,
                    'Primary 1',
                    light,
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.primary2,
                    'Primary 2',
                    light,
                  ),
                  _createItemForColor(
                    context,
                    colorScheme.error,
                    'Error',
                    light,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Defaults.createTitle(context, 'Primary Colors'),
                  _itemPrimary(context, PrimaryColors.coral, light),
                  _itemPrimary(context, PrimaryColors.sandyBrown, light),
                  _itemPrimary(context, PrimaryColors.orange, light),
                  _itemPrimary(context, PrimaryColors.goldenrod, light),
                  _itemPrimary(context, PrimaryColors.springGreen, light),
                  _itemPrimary(context, PrimaryColors.turquoise, light),
                  _itemPrimary(context, PrimaryColors.deepSkyBlue, light),
                  _itemPrimary(context, PrimaryColors.steelBlue, light),
                  _itemPrimary(context, PrimaryColors.dodgerBlue, light),
                  _itemPrimary(context, PrimaryColors.cornflowerBlue, light),
                  _itemPrimary(context, PrimaryColors.royalBlue, light),
                  _itemPrimary(context, PrimaryColors.slateBlue, light),
                  _itemPrimary(context, PrimaryColors.purple, light),
                  _itemPrimary(context, PrimaryColors.violet, light),
                  _itemPrimary(context, PrimaryColors.orchid, light),
                  _itemPrimary(context, PrimaryColors.hotPink, light),
                  _itemPrimary(context, PrimaryColors.violetRed, light),
                  _itemPrimary(context, PrimaryColors.red, light),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}