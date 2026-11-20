import 'package:flutter/material.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/resources/app_icons.dart' as icons;
import 'package:smooth_app/themes/smooth_theme_colors.dart';

/// A Button similar to a [PopupMenuButton] for non Apple platforms.
/// On iOS and macOS, it's still an [IconButton], but that opens a
/// [CupertinoActionSheet].
class SmoothPopupMenuButton<T> extends StatefulWidget {
  const SmoothPopupMenuButton({
    required this.onSelected,
    required this.itemBuilder,
    this.actionsTitle,
    this.buttonIcon,
    this.buttonLabel,
  }) : assert(buttonLabel == null || buttonLabel.length > 0),
       assert(actionsTitle == null || actionsTitle.length > 0);

  final void Function(T value) onSelected;
  final Iterable<SmoothPopupMenuItem<T>> Function(BuildContext context)
  itemBuilder;
  final String? actionsTitle;
  final Icon? buttonIcon;
  final String? buttonLabel;

  @override
  State<SmoothPopupMenuButton<T>> createState() =>
      _SmoothPopupMenuButtonState<T>();
}

class _SmoothPopupMenuButtonState<T> extends State<SmoothPopupMenuButton<T>> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: widget.buttonIcon ?? const Icon(Icons.more_vert_rounded),
      tooltip:
          widget.buttonLabel ??
          MaterialLocalizations.of(context).showMenuTooltip,
      onPressed: _openMenu,
    );
  }

  /// "Menus start at their button": the menu opens right under the button
  /// that was tapped and grows from it, instead of sliding up from the
  /// bottom of the screen.
  Future<void> _openMenu() async {
    final RenderObject? buttonBox = context.findRenderObject();
    final RenderObject? overlayBox = Navigator.of(
      context,
      rootNavigator: true,
    ).overlay?.context.findRenderObject();
    if (buttonBox is! RenderBox || overlayBox is! RenderBox) {
      return;
    }

    final Rect below = Rect.fromPoints(
      buttonBox.localToGlobal(
        buttonBox.size.bottomLeft(Offset.zero),
        ancestor: overlayBox,
      ),
      buttonBox.localToGlobal(
        buttonBox.size.bottomRight(Offset.zero),
        ancestor: overlayBox,
      ),
    );

    final List<SmoothPopupMenuItem<T>> list = widget
        .itemBuilder(context)
        .where((SmoothPopupMenuItem<T> item) => item.enabled)
        .toList();
    if (list.isEmpty) {
      return;
    }

    // The position in the list is the value, so items whose own value is
    // empty can still be told apart from closing the menu.
    final int? selected = await showMenu<int>(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromRect(below, Offset.zero & overlayBox.size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 8.0,
      popUpAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        duration: const Duration(milliseconds: 280),
        reverseDuration: const Duration(milliseconds: 180),
      ),
      items: <PopupMenuEntry<int>>[
        for (int i = 0; i < list.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: <Widget>[
                if (list[i].icon != null) ...<Widget>[
                  list[i].icon!,
                  const SizedBox(width: 12.0),
                ],
                Flexible(
                  child: Text(
                    list[i].label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (selected != null) {
      widget.onSelected.call(list[selected].value);
    }
  }
}

class SmoothRoundMenuButton extends StatelessWidget {
  const SmoothRoundMenuButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final SmoothColorsThemeExtension extension = context
        .extension<SmoothColorsThemeExtension>();

    return Tooltip(
      message: MaterialLocalizations.of(context).showMenuTooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color: extension.primaryMedium,
          ),
          child: Padding(
            padding: const EdgeInsets.all(SMALL_SPACE),
            child: icons.ThreeDots.vertical(
              size: 12.0,
              color: extension.primarySemiDark,
            ),
          ),
        ),
      ),
    );
  }
}

class SmoothPopupMenuItem<T> {
  const SmoothPopupMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  }) : assert(label.length > 0);

  final T value;
  final String label;
  final Widget? icon;
  final bool enabled;
}
