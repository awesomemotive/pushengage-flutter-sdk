import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_theme.dart';
import '../widgets/alert.dart';
import '../widgets/key_value_adder.dart';
import '../widgets/option_picker_sheet.dart';

/// Builds and sends a [TriggerAlert] via `PushEngage.addAlert`. Mirrors the RN
/// AlertEntry screen (type/availability pickers, date+time, key/value data).
class AlertEntryScreen extends StatefulWidget {
  const AlertEntryScreen({super.key});

  @override
  State<AlertEntryScreen> createState() => _AlertEntryScreenState();
}

class _AlertEntryScreenState extends State<AlertEntryScreen> {
  final TextEditingController _profileCtl = TextEditingController();
  final TextEditingController _mrpCtl = TextEditingController();
  final TextEditingController _productCtl = TextEditingController();
  final TextEditingController _linkCtl = TextEditingController();
  final TextEditingController _priceCtl = TextEditingController();
  final TextEditingController _variantCtl = TextEditingController();
  final TextEditingController _alertPriceCtl = TextEditingController();

  String _type = 'Price Drop';
  String _availability = 'Nil';
  DateTime? _date;
  TimeOfDay? _time;
  Map<String, String> _data = {};
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _profileCtl,
      _mrpCtl,
      _productCtl,
      _linkCtl,
      _priceCtl,
      _variantCtl,
      _alertPriceCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _pickType() async {
    final v = await showOptionPicker(context,
        title: 'Select type', options: const ['Price Drop', 'Inventory']);
    if (v != null && mounted) setState(() => _type = v);
  }

  Future<void> _pickAvailability() async {
    final v = await showOptionPicker(context,
        title: 'Select Availability', options: const ['Nil', 'Out of Stock']);
    if (v != null && mounted) setState(() => _availability = v);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null && mounted) setState(() => _time = t);
  }

  DateTime? _expiry() {
    if (_date == null || _time == null) return null;
    return DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
  }

  Future<void> _done() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final alertReq = TriggerAlert(
      type: _type == 'Price Drop'
          ? TriggerAlertType.priceDrop
          : TriggerAlertType.inventory,
      productId: _productCtl.text.trim(),
      link: _linkCtl.text.trim(),
      price: double.tryParse(_priceCtl.text.trim()) ?? 0,
      variantId: _nullIfEmpty(_variantCtl.text),
      expiryTimestamp: _expiry(),
      alertPrice: double.tryParse(_alertPriceCtl.text.trim()),
      availability: _availability == 'Out of Stock'
          ? TriggerAlertAvailabilityType.outOfStock
          : null,
      profileId: _nullIfEmpty(_profileCtl.text),
      mrp: double.tryParse(_mrpCtl.text.trim()),
      data: _data.isEmpty ? null : _data,
    );
    final res = await PushEngage.addAlert(alertReq);
    if (!mounted) return;
    setState(() => _loading = false);
    await showAlert(
      context,
      res.isSuccess ? 'Success' : 'Error',
      res.isSuccess
          ? (res.data ?? 'Alert added successfully')
          : res.error.toString(),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text,
            style: const TextStyle(
                color: DemoColors.header, fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController controller, String hint,
      {bool numeric = false}) {
    return TextField(
      controller: controller,
      autocorrect: false,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
          hintText: hint, border: const OutlineInputBorder(), isDense: true),
    );
  }

  Widget _pickerButton(String value, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          alignment: Alignment.centerLeft),
      child: Text(value, style: const TextStyle(color: Colors.black87)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? 'Select Date'
        : '${_date!.day}/${_date!.month}/${_date!.year}';
    final timeLabel = _time == null ? 'Select Time' : _time!.format(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('Alert Entry',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Enter profile id'),
            _field(_profileCtl, 'Enter profile id'),
            _label('MRP'),
            _field(_mrpCtl, 'MRP', numeric: true),
            _label('Select type'),
            _pickerButton(_type, _pickType),
            _label('Enter product id'),
            _field(_productCtl, 'Enter product id'),
            _label('Enter link'),
            _field(_linkCtl, 'Enter link'),
            _label('Enter price'),
            _field(_priceCtl, 'Enter price', numeric: true),
            _label('Enter variant id'),
            _field(_variantCtl, 'Enter variant id'),
            _label('Enter alert price'),
            _field(_alertPriceCtl, 'Enter alert price', numeric: true),
            _label('Select expiry time'),
            Row(
              children: [
                Expanded(child: _pickerButton(dateLabel, _pickDate)),
                const SizedBox(width: 12),
                Expanded(child: _pickerButton(timeLabel, _pickTime)),
              ],
            ),
            _label('Select Availability'),
            _pickerButton(_availability, _pickAvailability),
            const SizedBox(height: 16),
            KeyValueAdder(onChanged: (m) => _data = m),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DemoColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                onPressed: _loading ? null : _done,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
