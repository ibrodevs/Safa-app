import 'package:flutter/material.dart';

import 'package:dogo/core/design/app_colors.dart';

class BalanceTopUpScreen extends StatefulWidget {
  const BalanceTopUpScreen({super.key});

  @override
  State<BalanceTopUpScreen> createState() => _BalanceTopUpScreenState();
}

class _BalanceTopUpScreenState extends State<BalanceTopUpScreen> {
  static const _accent = AppColors.primary;
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  final _controller = TextEditingController();
  int? _selectedAmount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _controller.text = amount.toString();
    });
  }

  void _topUp() {
    final text = _controller.text.trim();
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму пополнения.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Пополнение на $amount с (заглушка).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    'Пополнить счет',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: _tileBorder),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _tileBorder, width: 1),
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
                      'Пополните баланс, чтобы оплачивать доставку и комиссии.',
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
              const SizedBox(height: 20),
              const Text(
                'Быстрые суммы',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickAmountChip(
                    amount: 100,
                    selected: _selectedAmount == 100,
                    onTap: () => _selectAmount(100),
                  ),
                  _QuickAmountChip(
                    amount: 200,
                    selected: _selectedAmount == 200,
                    onTap: () => _selectAmount(200),
                  ),
                  _QuickAmountChip(
                    amount: 500,
                    selected: _selectedAmount == 500,
                    onTap: () => _selectAmount(500),
                  ),
                  _QuickAmountChip(
                    amount: 1000,
                    selected: _selectedAmount == 1000,
                    onTap: () => _selectAmount(1000),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Другая сумма',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Введите сумму в сомах',
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: _greyText,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _tileBorder,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _topUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Пополнить',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Сейчас это демонстрационный экран. Позже сюда можно '
                'подключить реальный способ оплаты (карта, кошелёк и т.п.).',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: _greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = AppColors.primary;
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _accent : Colors.white;
    final border = selected ? _accent : _tileBorder;
    final textColor = selected ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Text(
          '$amount с',
          style: TextStyle(
            fontSize: 14,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
