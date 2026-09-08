import 'package:flutter/material.dart';
import '../core/theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'card',
      'name': 'Visa Card',
      'number': '•••• 4242',
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'isDefault': true,
    },
    {
      'type': 'upi',
      'name': 'Google Pay',
      'number': 'user@okicici',
      'icon': Icons.account_balance,
      'color': Colors.green,
      'isDefault': false,
    },
    {
      'type': 'cash',
      'name': 'Cash',
      'number': 'Pay in cash',
      'icon': Icons.money,
      'color': Colors.orange,
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Payment Methods List
          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: _paymentMethods.map((method) {
                return _buildPaymentMethodTile(method);
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Add New Payment Method
          GestureDetector(
            onTap: _showAddPaymentSheet,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.theme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: context.theme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Payment Method',
                    style: TextStyle(
                      color: context.theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Payment History Section
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildTransactionTile(
                  'Ride to Airport',
                  '₹450',
                  'Feb 5, 2026',
                  true,
                ),
                _buildTransactionTile(
                  'Ride to Office',
                  '₹250',
                  'Jan 30, 2026',
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (method['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          method['icon'] as IconData,
          color: method['color'] as Color,
        ),
      ),
      title: Row(
        children: [
          Text(
            method['name'],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
          if (method['isDefault'] == true) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Default',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        method['number'],
        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: context.colors.textSecondary,
        ),
        color: context.theme.cardColor,
        onSelected: (value) {
          if (value == 'default') {
            setState(() {
              for (var m in _paymentMethods) {
                m['isDefault'] = m == method;
              }
            });
          } else if (value == 'delete') {
            setState(() {
              _paymentMethods.remove(method);
            });
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'default',
            child: Text(
              'Set as Default',
              style: TextStyle(color: context.colors.textPrimary),
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    String title,
    String amount,
    String date,
    bool isDebit,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDebit ? Colors.red : Colors.green).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          color: isDebit ? Colors.red : Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: context.colors.textPrimary,
        ),
      ),
      subtitle: Text(
        date,
        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
      ),
      trailing: Text(
        '${isDebit ? '-' : '+'}$amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDebit ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  void _showAddPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.theme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildAddOption(
              Icons.credit_card,
              'Credit/Debit Card',
              Colors.blue,
            ),
            _buildAddOption(Icons.account_balance, 'UPI', Colors.green),
            _buildAddOption(
              Icons.account_balance_wallet,
              'Net Banking',
              Colors.purple,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(IconData icon, String title, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: context.colors.textPrimary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.colors.textSecondary),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title setup coming soon!')));
      },
    );
  }
}
