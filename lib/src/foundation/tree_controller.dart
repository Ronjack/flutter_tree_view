import 'dart:collection' show UnmodifiableListView;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'tree_data_source.dart';

/// Simple typedef for an unmodifiable list of [TreeNode<T>].
typedef FlatTree<T> = UnmodifiableListView<TreeNode<T>>;

/// A simple controller for managing the nodes that compose a tree.
///
/// The [dataSource] is responsible for providing the data that is required to
/// display a tree, also for updating the state of its items.
class TreeController<T> with ChangeNotifier {
  /// Creates a [TreeController].
  ///
  /// If [buildImediatelly] is set to `false`, [TreeController.rebuild] must be
  /// called to build the tree for the first time, otherwise the [TreeView]
  /// widget would display nothing. This could be used to defer the first
  /// traversal of the tree to a more convenient moment.
  TreeController({
    required this.dataSource,
    bool buildImediatelly = true,
  }) : _nodes = FlatTree<T>(const []) {
    if (buildImediatelly) {
      rebuild();
    }
  }

  /// The tree data source used to compose the tree hierarchy.
  final TreeDataSource<T> dataSource;

  /// The current nodes that are going to be displayed.
  FlatTree<T> get nodes => _nodes;
  FlatTree<T> _nodes;

  /// The length of the current flattened tree.
  int get treeSize => nodes.length;

  /// Returns the current node at [index] of the flattened tree.
  TreeNode<T> nodeAt(int index) => nodes[index];

  /// Rebuilds the current tree.
  ///
  /// Call this method whenever the tree state changes in any way (i.e child
  /// added/removed, expansion changed, item reordered, etc...).
  ///
  /// This method will traverse the tree gattering the new information and
  /// storing it as a flat tree in [nodes]. Then it calls [notifyListeners] so
  /// consumers can rebuild their view.
  void rebuild() {
    final List<TreeNode<T>> flatTree = buildFlatTree<T>(dataSource);
    _nodes = FlatTree<T>(flatTree);
    notifyListeners();
  }

  /// Updates the expansion state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already expanded.
  void expandItem(T item) {
    dataSource.updateExpansionState(item, true);
    rebuild();
  }

  /// Updates the expansion state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already collapsed.
  void collapseItem(T item) {
    dataSource.updateExpansionState(item, false);
    rebuild();
  }

  /// Checks the expansion state of [item] and updates it to the opposite state.
  void toggleItemExpansion(T item) {
    dataSource.findExpansionState(item) ? collapseItem(item) : expandItem(item);
  }

  void _toggleItemsCascading(T item, bool expanded) {
    dataSource.updateExpansionState(item, expanded);

    final List<T> children = dataSource.findChildren(item);

    for (final T child in children) {
      _toggleItemsCascading(child, expanded);
    }
  }

  /// Updates the expansion state of [item] and all its descendants to `true`.
  void expandItemCascading(T item) {
    _toggleItemsCascading(item, true);
    rebuild();
  }

  /// Updates the expansion state of [item] and all its descendants to `false`.
  void collapseItemCascading(T item) {
    _toggleItemsCascading(item, false);
    rebuild();
  }

  @override
  void dispose() {
    _nodes = FlatTree<T>(const []);
    super.dispose();
  }
}