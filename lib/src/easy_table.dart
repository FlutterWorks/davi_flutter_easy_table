import 'dart:math' as math;
import 'package:easy_table/src/easy_table_column.dart';
import 'package:easy_table/src/easy_table_model.dart';
import 'package:easy_table/src/private/layout/horizontal_layout.dart';
import 'package:easy_table/src/theme/easy_table_theme.dart';
import 'package:easy_table/src/theme/easy_table_theme_data.dart';
import 'package:easy_table/src/theme/header_theme_data.dart';
import 'package:flutter/material.dart';

/// Table view designed for a large number of data.
///
/// The type [ROW] represents the data of each row.
class EasyTable<ROW> extends StatefulWidget {
//TODO handle negative values
//TODO allow null and use defaults?
  const EasyTable(this.model,
      {Key? key,
      this.horizontalScrollController,
      this.verticalScrollController})
      : super(key: key);

  final EasyTableModel<ROW>? model;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;

  @override
  State<StatefulWidget> createState() => _EasyTableState<ROW>();
}

/// The [EasyTable] state.
class _EasyTableState<ROW> extends State<EasyTable<ROW>> {
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;

  final ScrollController _headerHorizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    widget.model?.addListener(_rebuild);

    _horizontalScrollController =
        widget.horizontalScrollController ?? ScrollController();
    _verticalScrollController =
        widget.verticalScrollController ?? ScrollController();

    _horizontalScrollController.addListener(_syncHorizontalScroll);
  }

  @override
  void dispose() {
    widget.model?.removeListener(_rebuild);
    _horizontalScrollController.removeListener(_syncHorizontalScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EasyTable<ROW> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model?.removeListener(_rebuild);
      widget.model?.addListener(_rebuild);
    }
    if (widget.horizontalScrollController != null) {
      _horizontalScrollController.removeListener(_syncHorizontalScroll);
      _horizontalScrollController = widget.horizontalScrollController!;
      _horizontalScrollController.addListener(_syncHorizontalScroll);
    }
    if (widget.verticalScrollController != null) {
      _verticalScrollController = widget.verticalScrollController!;
    }
  }

  void _rebuild() {
    setState(() {});
  }

  void _syncHorizontalScroll() {
    _headerHorizontalScrollController
        .jumpTo(_horizontalScrollController.offset);
  }

  @override
  Widget build(BuildContext context) {
    Widget table = LayoutBuilder(builder: (context, constraints) {
      if (widget.model != null) {
        EasyTableModel<ROW> model = widget.model!;
        EasyTableThemeData theme = EasyTableTheme.of(context);

        double rowHeight = theme.cell.contentHeight;
        if (theme.cell.padding != null) {
          rowHeight += theme.cell.padding!.vertical;
        }

        double requiredWidth = model.columnsWidth;
        requiredWidth += (model.columnsLength) * theme.columnGap;
        double maxWidth = math.max(constraints.maxWidth, requiredWidth);
        return HorizontalLayout(
            top: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                    controller: _headerHorizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: _header(
                        context: context, model: model, maxWidth: maxWidth))),
            center: Scrollbar(
                isAlwaysShown: true,
                controller: _horizontalScrollController,
                child: _rows(
                    context: context,
                    model: model,
                    maxWidth: maxWidth,
                    rowHeight: rowHeight)));
      }
      return Container();
    });
    EasyTableThemeData theme = EasyTableTheme.of(context);
    if (theme.decoration != null) {
      table = Container(child: table, decoration: theme.decoration);
    }
    return table;
  }

  /// Builds a headers
  Widget _header(
      {required BuildContext context,
      required EasyTableModel<ROW> model,
      required double maxWidth}) {
    List<Widget> children = [];
    for (int columnIndex = 0;
        columnIndex < model.columnsLength;
        columnIndex++) {
      EasyTableColumn<ROW> column = model.columnAt(columnIndex);
      children.add(_headerCell(
          context: context, column: column, columnIndex: columnIndex));
    }
    HeaderThemeData headerTheme = EasyTableTheme.of(context).header;
    BoxDecoration? decoration;
    if (headerTheme.bottomBorder != null) {
      decoration =
          BoxDecoration(border: Border(bottom: headerTheme.bottomBorder!));
    }
    return Container(
        child: Row(children: children),
        width: maxWidth,
        decoration: decoration);
  }

  /// Builds the table content.
  Widget _rows(
      {required BuildContext context,
      required EasyTableModel<ROW> model,
      required double maxWidth,
      required double rowHeight}) {
    EasyTableThemeData theme = EasyTableTheme.of(context);
    return Scrollbar(
        isAlwaysShown: true,
        controller: _verticalScrollController,
        notificationPredicate: (p) {
          return true;
        },
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            child: SizedBox(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView.builder(
                        controller: _verticalScrollController,
                        itemExtent: rowHeight + theme.rowGap,
                        itemBuilder: (context, index) {
                          return _row(
                              context: context,
                              model: model,
                              rowIndex: index,
                              rowHeight: rowHeight);
                        },
                        itemCount: model.rowsLength)),
                width: maxWidth)));
  }

  /// Builds a single table row.
  Widget _row(
      {required BuildContext context,
      required EasyTableModel<ROW> model,
      required int rowIndex,
      required double rowHeight}) {
    EasyTableThemeData theme = EasyTableTheme.of(context);
    ROW row = model.rowAt(rowIndex);
    List<Widget> children = [];
    for (int columnIndex = 0;
        columnIndex < model.columnsLength;
        columnIndex++) {
      EasyTableColumn<ROW> column = model.columnAt(columnIndex);
      children.add(_cell(
          context: context,
          row: row,
          column: column,
          rowIndex: rowIndex,
          rowHeight: rowHeight));
    }
    Widget rowWidget = Row(children: children);

    if (theme.rowColor != null) {
      rowWidget = Container(child: rowWidget, color: theme.rowColor!(rowIndex));
    }
    if (theme.rowGap > 0) {
      rowWidget = Padding(
          child: rowWidget, padding: EdgeInsets.only(bottom: theme.rowGap));
    }

    return rowWidget;
  }

  /// Builds a table cell.
  Widget _cell(
      {required BuildContext context,
      required ROW row,
      required EasyTableColumn<ROW> column,
      required int rowIndex,
      required double rowHeight}) {
    EasyTableThemeData theme = EasyTableTheme.of(context);
    double width = column.width;

    Widget? cellWidget = column.buildCellWidget(context, row);
    EdgeInsetsGeometry? padding;
    if (theme.columnGap > 0) {
      width += theme.columnGap;
      padding = EdgeInsets.only(right: theme.columnGap);
    }
    if (theme.cell.padding != null) {
      if (padding != null) {
        padding = theme.cell.padding!.add(padding);
      } else {
        padding = theme.cell.padding!;
      }
    }
    if (padding != null) {
      cellWidget = Padding(padding: padding, child: cellWidget);
    }
    return ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width, height: rowHeight),
        child: cellWidget);
  }

  /// Builds a table header cell.
  Widget _headerCell(
      {required BuildContext context,
      required EasyTableColumn column,
      required int columnIndex}) {
    EasyTableThemeData theme = EasyTableTheme.of(context);
    double width = column.width;
    Widget? headerCellWidget;
    if (column.headerCellBuilder != null) {
      headerCellWidget =
          column.headerCellBuilder!(context, column, columnIndex);
    }
    EdgeInsetsGeometry? padding;
    if (theme.columnGap > 0) {
      width += theme.columnGap;
      padding = EdgeInsets.only(right: theme.columnGap);
    }
    if (theme.headerCell.padding != null) {
      if (padding != null) {
        padding = theme.headerCell.padding!.add(padding);
      } else {
        padding = theme.headerCell.padding!;
      }
    }
    if (padding != null) {
      headerCellWidget = Padding(padding: padding, child: headerCellWidget);
    }
    return ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: headerCellWidget);
  }
}
