import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/state_views.dart';

const Color kGreen = Color(0xFF0C831F);

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = [WalletTab.transactions, WalletTab.cashback, WalletTab.refunds];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadSummary();
      for (final t in _tabs) {
        context.read<WalletProvider>().loadTransactions(t);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        title: Text('GoFresh Money', style: GoogleFonts.poppins(color: scheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildSummary(scheme),
          TabBar(
            controller: _tabController,
            labelColor: kGreen,
            unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: kGreen,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [Tab(text: 'Transactions'), Tab(text: 'Cashback'), Tab(text: 'Refunds')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((t) => _WalletTabView(tab: t)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme scheme) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.summaryStatus == LoadStatus.loading) {
          return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
        }
        if (provider.summaryStatus == LoadStatus.error) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorView(
              message: provider.summaryError ?? 'Could not load wallet summary',
              onRetry: () => provider.loadSummary(refresh: true),
            ),
          );
        }
        final summary = provider.summary;
        if (summary == null) return const SizedBox();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGreen, Color(0xFF0A6E1A)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text('Current Balance', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('${summary.currentBalance}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _summaryStat('Cashback Earned', summary.cashbackEarned),
                  Container(width: 1, height: 32, color: Colors.white30),
                  _summaryStat('Total Savings', summary.totalSavings),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryStat(String label, int value) {
    return Column(
      children: [
        Text('$value', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _WalletTabView extends StatefulWidget {
  final WalletTab tab;
  const _WalletTabView({required this.tab});
  @override
  State<_WalletTabView> createState() => _WalletTabViewState();
}

class _WalletTabViewState extends State<_WalletTabView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<WalletProvider>().loadMore(widget.tab);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        final status = provider.statusFor(widget.tab);
        final items = provider.itemsFor(widget.tab);

        if (status == LoadStatus.loading) return const LoadingView();
        if (status == LoadStatus.error && items.isEmpty) {
          return ErrorView(
            message: provider.errorFor(widget.tab) ?? 'Something went wrong',
            onRetry: () => provider.loadTransactions(widget.tab, refresh: true),
          );
        }
        if (items.isEmpty) {
          return const EmptyView(icon: Icons.receipt_long_outlined, message: 'No transactions yet');
        }
        return RefreshIndicator(
          color: kGreen,
          onRefresh: () => provider.loadTransactions(widget.tab, refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                if (status == LoadStatus.loadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
                  );
                }
                return const SizedBox(height: 12);
              }
              return TransactionCard(transaction: items[index]);
            },
          ),
        );
      },
    );
  }
}
