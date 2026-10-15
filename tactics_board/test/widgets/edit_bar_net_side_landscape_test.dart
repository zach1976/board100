import 'edit_bar_net_side_test.dart' show netSideCase;

/// The sideways half of edit_bar_net_side_test.dart, in its own isolate.
void main() => netSideCase(landscape: true);
