// lib/widgets/investment_amount_slider.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvestmentAmountSlider extends StatefulWidget {
  final double currentAmount;
  final Function(double) onChanged;
  final double min;
  final double max;

  const InvestmentAmountSlider({
    Key? key,
    required this.currentAmount,
    required this.onChanged,
    required this.min,
    required this.max,
  }) : super(key: key);

  @override
  _InvestmentAmountSliderState createState() => _InvestmentAmountSliderState();
}

class _InvestmentAmountSliderState extends State<InvestmentAmountSlider> {
  late TextEditingController _controller;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentAmount;
    _controller = TextEditingController(text: widget.currentAmount.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(InvestmentAmountSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAmount != widget.currentAmount) {
      _sliderValue = widget.currentAmount;
      _controller.text = widget.currentAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Amount (₹)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 7,
              child: Slider(
                value: _sliderValue,
                min: widget.min,
                max: widget.max,
                divisions: ((widget.max - widget.min) / 10).round(),
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    _controller.text = value.toStringAsFixed(0);
                  });
                  widget.onChanged(value);
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixText: '₹',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onSubmitted: (value) {
                    final amount = double.tryParse(value) ?? widget.currentAmount;
                    final constrainedAmount = amount.clamp(widget.min, widget.max);
                    setState(() {
                      _sliderValue = constrainedAmount;
                      _controller.text = constrainedAmount.toStringAsFixed(0);
                    });
                    widget.onChanged(constrainedAmount);
                  },
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${widget.min.toInt()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              '₹${widget.max.toInt()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickAmountButton(10),
            _buildQuickAmountButton(100),
            _buildQuickAmountButton(1000),
            _buildQuickAmountButton(5000),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    final isSelected = _sliderValue == amount;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _sliderValue = amount;
          _controller.text = amount.toStringAsFixed(0);
        });
        widget.onChanged(amount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '₹${amount.toInt()}',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
