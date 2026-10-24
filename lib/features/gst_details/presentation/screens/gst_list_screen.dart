import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../providers/gst_provider.dart';
import '../widgets/gst_card.dart';
import 'add_edit_gst_screen.dart';

class GstListScreen extends StatefulWidget {
  const GstListScreen({super.key});

  @override
  State<GstListScreen> createState() => _GstListScreenState();
}

class _GstListScreenState extends State<GstListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GstProvider>().loadGstDetails();
    });
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove GST details'),
        content: const Text('This GSTIN will be removed from your account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final gstProvider = context.read<GstProvider>();
      final messenger = ScaffoldMessenger.of(context);
      await gstProvider.deleteGst(id);
      if (gstProvider.errorMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(gstProvider.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GstProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('GST Details')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditGstScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add GST'),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, GstProvider provider) {
    switch (provider.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return SkeletonListView(
          itemBuilder: (_) => const _GstCardSkeleton(),
        );
      case ViewStatus.error:
        return ErrorStateWidget(
          message: provider.errorMessage ?? 'Please try again.',
          onRetry: provider.loadGstDetails,
        );
      case ViewStatus.empty:
        return EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'No GST details added',
          message: 'Add your business GSTIN to get GST invoices on orders.',
          actionLabel: 'Add GST',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGstScreen()),
          ),
        );
      case ViewStatus.loaded:
        return RefreshIndicator(
          onRefresh: provider.loadGstDetails,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.gstList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final gst = provider.gstList[index];
              return GstCard(
                gst: gst,
                isBusy: provider.pendingIds.contains(gst.id),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditGstScreen(existing: gst),
                  ),
                ),
                onDelete: () => _confirmDelete(context, gst.id),
              );
            },
          ),
        );
    }
  }
}

class _GstCardSkeleton extends StatelessWidget {
  const _GstCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 160, height: 16, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 10),
            SkeletonBox(width: 200, height: 12, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 12, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      ),
    );
  }
}

