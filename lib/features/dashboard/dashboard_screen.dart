import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import 'widgets/health_score_widget.dart';
import 'widgets/month_summary_widget.dart';
import 'widgets/projection_widget.dart';
import 'widgets/ai_insights_widget.dart';
import 'widgets/quick_stats_widget.dart';
import 'widgets/net_worth_widget.dart';
import 'widgets/fiscal_period_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final hasData = provider.availableMonths.isNotEmpty;

          final period = provider.fiscalPeriodProgress();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: provider.refresh,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, provider),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      NetWorthWidget(
                        totalBalance: provider.totalBalance,
                        avgMonthlySavings: provider.avgMonthlySavings,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      FiscalPeriodWidget(
                        start: period.start,
                        end: period.end,
                        daysPassed: period.daysPassed,
                        daysInPeriod: period.daysInPeriod,
                      ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.1),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                if (!hasData)
                  SliverFillRemaining(child: _buildEmptyState(context))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        HealthScoreWidget(score: provider.computeHealthScore())
                            .animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        MonthSummaryWidget(summary: provider.currentMonthlySummary)
                            .animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        ProjectionWidget(projection: provider.projectEndOfMonth())
                            .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        QuickStatsWidget(
                          avgSavings: provider.avgMonthlySavings,
                          period: provider.referencePeriod,
                          totalMonths: provider.availableMonths.length,
                        ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        AiInsightsWidget()
                            .animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final months = ['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'];
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${months[now.month - 1]} ${now.year}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: provider.refresh,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.upload_file, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Nessun dato ancora', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Importa il file Excel dal tuo banking\nper iniziare l\'analisi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/transactions'),
              icon: const Icon(Icons.add),
              label: const Text('Importa movimenti'),
            ),
          ],
        ),
      ),
    );
  }
}
