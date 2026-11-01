import 'package:flutter/material.dart';

import '../../../../stores/presentation/screens/stores_dashboard_screen.dart';

/// ظˆط§ط¬ظ‡ط© ظ‚ط³ظ… ط§ظ„ظ…ط®ط§ط²ظ† â€” ظ„ظˆط­ط© ط¨ط«ظ…ط§ظ†ظٹط© ط£ظ†ط¸ظ…ط© ظپط±ط¹ظٹط©
/// The stores section â€” a dashboard over eight sub-systems.
///
/// ظƒط§ظ† ظ‡ط°ط§ ط§ظ„ظ…ظ„ظپ ط­ط§ظ„ط©ظ‹ ظپط§ط±ط؛ط© (`DataListScaffold`)ط› طµط§ط± ط§ظ„ط¢ظ† ظٹط¹ظٹط¯ ظ„ظˆط­ط© ط§ظ„ظ‚ط³ظ… ط§ظ„ط­ظ‚ظٹظ‚ظٹط©.
/// ط§ظ„ظ„ظˆط­ط© ظ†ظپط³ظ‡ط§ طھط­ط¬ط¨ ظƒظ„ ط¨ط·ط§ظ‚ط© ط¨طµظ„ط§ط­ظٹطھظ‡ط§طŒ ظپط§ظ„طµط¯ظپط© ظ‡ظ†ط§ ظ„ط§ طھط­طھط§ط¬ ط£ظٹ ط´ط±ط· ط¥ط¶ط§ظپظٹ.
/// This file used to be an empty DataListScaffold; it now returns the real module
/// dashboard. The dashboard gates every card by its own grant, so this wrapper adds no rule.
class StoresSection extends StatelessWidget {
  const StoresSection({super.key});

  @override
  Widget build(BuildContext context) => const StoresDashboardScreen();
}
