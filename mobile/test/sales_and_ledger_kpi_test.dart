import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/core/ui/kpi_card.dart';
import 'package:dk_track_mobile/core/ui/sparkline_chart.dart';
import 'package:dk_track_mobile/core/ui/sales_performance_card.dart';
import 'package:dk_track_mobile/core/ui/ledger_transactions_section.dart';

void main() {
  group('Executive Dashboard Sales & Graphical KPI Widget Tests', () {
    testWidgets('SparklineChart renders smoothly without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SparklineChart(
                data: [100, 150, 120, 200, 180, 250, 300],
                lineColor: Colors.blue,
                height: 40,
                width: 100,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SparklineChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('KpiCard renders clean title, separate GL code tag, amount and sparkline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KpiCard(
                title: 'Cash in Hand',
                glCode: '1010',
                amount: 14200.0,
                icon: Icons.account_balance_wallet_rounded,
                sparklineData: [12000, 13000, 14200],
                subtitle: 'Liquid Main Cash',
              ),
            ),
          ),
        ),
      );

      // Verify clean title without raw parenthesis
      expect(find.text('Cash in Hand'), findsOneWidget);
      expect(find.text('GL 1010'), findsOneWidget);
      expect(find.text('Liquid Main Cash'), findsOneWidget);
      expect(find.byType(SparklineChart), findsOneWidget);
    });

    testWidgets('SalesPerformanceCard renders Monthly Sales default, today pulse & triggers period callback', (tester) async {
      String? selectedPeriod;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SalesPerformanceCard(
                salesAmount: 85400.0,
                todaySalesAmount: 3200.0,
                salesCount: 28,
                activePeriod: 'this_month',
                activePeriodLabel: 'This Month (Default)',
                trendPoints: const [1000, 2000, 1500, 3200],
                verticalIndustry: 'cafe_bakery',
                onPeriodSelected: (period, {startDate, endDate}) {
                  selectedPeriod = period;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Net Sales & Revenue'), findsOneWidget);
      expect(find.text('Bakery Counter & POS Sales'), findsOneWidget);
      expect(find.text('SALES TODAY'), findsOneWidget);
      expect(find.text('28 Transactions / Bills'), findsOneWidget);

      // Tap on 'Today' quick filter chip
      final todayChip = find.text('Today');
      expect(todayChip, findsOneWidget);
      await tester.tap(todayChip);
      await tester.pumpAndSettle();

      expect(selectedPeriod, equals('today'));
    });

    testWidgets('LedgerTransactionsSection renders journal vouchers, signed amounts & filter chips', (tester) async {
      String? selectedLedgerPeriod;

      final testEntries = [
        {
          'id': 'rcpt_1',
          'voucher_no': 'RCPT-101',
          'title': 'Payment Receipt - Sri Murugan Mess',
          'party_name': 'Sri Murugan Mess',
          'amount': 1450.0,
          'is_credit': true,
          'formatted_date': 'Today, 04:30 PM',
          'account_code': '1010',
          'account_name': 'Main Cash',
          'category': 'receipt',
          'payment_mode': 'Cash',
        },
        {
          'id': 'exp_1',
          'voucher_no': 'EXP-202',
          'title': 'Diesel Fuel Expense',
          'party_name': 'Fuel Station',
          'amount': 500.0,
          'is_credit': false,
          'formatted_date': 'Today, 02:15 PM',
          'account_code': '5010',
          'account_name': 'Operating Expense',
          'category': 'expense',
          'payment_mode': 'Cash',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LedgerTransactionsSection(
                entries: testEntries,
                activePeriod: 'today',
                activePeriodLabel: 'Today (Default)',
                verticalIndustry: 'packaged_water',
                onDateFilterSelected: (period, {startDate, endDate}) {
                  selectedLedgerPeriod = period;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Live Accounting Ledger Postings'), findsOneWidget);
      expect(find.text('Payment Receipt - Sri Murugan Mess'), findsOneWidget);
      expect(find.text('+₹1,450.00'), findsOneWidget);
      expect(find.text('Diesel Fuel Expense'), findsOneWidget);
      expect(find.text('-₹500.00'), findsOneWidget);

      // Tap on 'This Week' filter chip
      final thisWeekChip = find.text('This Week');
      expect(thisWeekChip, findsOneWidget);
      await tester.tap(thisWeekChip);
      await tester.pumpAndSettle();

      expect(selectedLedgerPeriod, equals('this_week'));
    });
  });
}
