import 'package:flutter/material.dart';

class ProfileBalanceHistoryScreen extends StatelessWidget {
  const ProfileBalanceHistoryScreen({super.key});

  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    // Пока статический список — потом можно подцепить API / провайдер.
    final operations = <_Operation>[
      const _Operation(
        title: 'Пополнение баланса',
        date: 'Сегодня, 12:34',
        amount: '+500 с',
        isIncome: true,
      ),
      const _Operation(
        title: 'Оплата доставки',
        date: 'Сегодня, 09:12',
        amount: '-230 с',
        isIncome: false,
      ),
      const _Operation(
        title: 'Пополнение баланса',
        date: 'Вчера, 18:02',
        amount: '+1000 с',
        isIncome: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'История пополнений/трат',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: _tileBorder,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _tileBorder, width: 1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Текущий баланс',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: _greyText,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '0 с',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Пополните баланс перед оплатой доставки.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: _greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Все',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Пополнения',
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Списания',
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: operations.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: operations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final op = operations[index];
                  return _OperationTile(operation: op);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _accent : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _Operation {
  const _Operation({
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
  });

  final String title;
  final String date;
  final String amount;
  final bool isIncome;
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.operation});

  final _Operation operation;

  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final color = operation.isIncome ? _green : _red;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              operation.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.title,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  operation.date,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: _greyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            operation.amount,
            style: TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: _greyText,
            ),
            SizedBox(height: 12),
            Text(
              'Пока нет операций',
              style: TextStyle(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Когда вы начнёте пополнять баланс и оплачивать заказы, '
                  'здесь появится история.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: _greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
