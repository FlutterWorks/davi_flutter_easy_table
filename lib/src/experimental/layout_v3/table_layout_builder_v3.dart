import 'package:easy_table/src/experimental/layout_v3/layout_child_v3.dart';
import 'package:easy_table/src/experimental/layout_v3/table_layout_v3.dart';
import 'package:easy_table/src/experimental/metrics/table_layout_settings_v3.dart';
import 'package:easy_table/src/experimental/row_callbacks.dart';
import 'package:easy_table/src/experimental/table_layout_settings.dart';
import 'package:easy_table/src/experimental/table_paint_settings.dart';
import 'package:easy_table/src/experimental/table_scroll_controllers.dart';
import 'package:easy_table/src/experimental/table_scrollbar.dart';
import 'package:easy_table/src/last_visible_row_listener.dart';
import 'package:easy_table/src/model.dart';
import 'package:easy_table/src/row_hover_listener.dart';
import 'package:easy_table/src/theme/theme.dart';
import 'package:easy_table/src/theme/theme_data.dart';
import 'package:flutter/material.dart';

class TableLayoutBuilderV3<ROW> extends StatelessWidget {
  const TableLayoutBuilderV3(
      {Key? key,
      required this.onHoverListener,
      required this.hoveredRowIndex,
      required this.layoutSettingsBuilder,
      required this.scrollControllers,
      required this.multiSortEnabled,
      required this.onLastVisibleRowListener,
      required this.model,
      required this.cellContentHeight,
      required this.columnsFit,
      required this.visibleRowsLength,
      required this.rowCallbacks})
      : super(key: key);

  final int? hoveredRowIndex;
  final OnLastVisibleRowListener? onLastVisibleRowListener;
  final OnRowHoverListener onHoverListener;
  final TableScrollControllers scrollControllers;
  final TableLayoutSettingsBuilder layoutSettingsBuilder;
  final EasyTableModel<ROW>? model;
  final bool multiSortEnabled;
  final RowCallbacks? rowCallbacks;
  final bool columnsFit;
  final double cellContentHeight;
  final int? visibleRowsLength;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _builder);
  }

  Widget _builder(BuildContext context, BoxConstraints constraints) {
    final EasyTableThemeData theme = EasyTableTheme.of(context);

    TableLayoutSettingsV3<ROW> layoutSettings = TableLayoutSettingsV3<ROW>(
        constraints: constraints,
        model: model,
        theme: theme,
        columnsFit: columnsFit,
        verticalOffset: scrollControllers.verticalOffset,
        cellContentHeight: cellContentHeight,
        visibleRowsLength: visibleRowsLength);

    final List<LayoutChildV3> children = [];

    if (layoutSettings.hasVerticalScrollbar) {
      children.add(LayoutChildV3.verticalScrollbar(
          child: TableScrollbar(
              axis: Axis.vertical,
              contentSize: layoutSettings.contentHeight,
              scrollController: scrollControllers.vertical,
              color: theme.scrollbar.verticalColor,
              borderColor: theme.scrollbar.verticalBorderColor)));
    }

    if (layoutSettings.hasHeader) {
      children.add(LayoutChildV3.header());
      if (layoutSettings.hasVerticalScrollbar) {
        children.add(LayoutChildV3.topCorner());
      }
    }

    if (layoutSettings.hasHorizontalScrollbar) {
      children.add(LayoutChildV3.horizontalScrollbars([
        TableScrollbar(
            axis: Axis.horizontal,
            scrollController: scrollControllers.leftPinnedContentArea,
            color: theme.scrollbar.pinnedHorizontalColor,
            borderColor: theme.scrollbar.pinnedHorizontalBorderColor,
            contentSize: layoutSettings.leftPinnedContentWidth),
        TableScrollbar(
            axis: Axis.horizontal,
            scrollController: scrollControllers.unpinnedContentArea,
            color: theme.scrollbar.unpinnedHorizontalColor,
            borderColor: theme.scrollbar.unpinnedHorizontalBorderColor,
            contentSize: layoutSettings.unpinnedContentWidth)
      ]));
      if (layoutSettings.hasVerticalScrollbar) {
        children.add(LayoutChildV3.bottomCorner());
      }
    }

    children
        .add(LayoutChildV3<ROW>.rows(model: model, layoutSettings: layoutSettings));

    TablePaintSettings paintSettings =
        TablePaintSettings(hoveredRowIndex: null, debugAreas: false);

    return TableLayoutV3<ROW>(
        layoutSettings: layoutSettings,
        paintSettings: paintSettings,
        theme: theme,
        children: children);
  }
}
