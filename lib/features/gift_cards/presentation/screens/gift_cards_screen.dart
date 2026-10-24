import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../providers/gift_card_provider.dart';
import '../widgets/gift_card_tile.dart';
import 'redeem_gift_card_screen.dart';

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GiftCardProvider>();
      provider.loadRedeemedCards();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Gift Cards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Gift Cards'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RedeemGiftCardScreen()),
          );
        },
        icon: const Icon(Icons.redeem_rounded),
        label: const Text('Redeem'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RedeemedCardsTab(),
        ],
      ),
    );
  }
}

class _RedeemedCardsTab extends StatelessWidget {
  const _RedeemedCardsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GiftCardProvider>();

    switch (provider.redeemedStatus) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return SkeletonListView(itemBuilder: (_) => const _GiftCardSkeleton());
      case ViewStatus.error:
        return ErrorStateWidget(
          message: provider.redeemedErrorMessage ?? 'Please try again.',
          onRetry: provider.loadRedeemedCards,
        );
      case ViewStatus.empty:
        return const EmptyStateWidget(
          icon: Icons.history_rounded,
          title: 'No gift cards yet',
          message: 'Redeem a gift card code to see it here.',
        );
      case ViewStatus.loaded:
        return RefreshIndicator(
          onRefresh: provider.loadRedeemedCards,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.redeemedCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                GiftCardTile(card: provider.redeemedCards[index]),
          ),
        );
    }
  }
}

class _GiftCardSkeleton extends StatelessWidget {
  const _GiftCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 180, height: 16, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 80, height: 24, borderRadius: BorderRadius.circular(4)),
                SkeletonBox(width: 90, height: 24, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

