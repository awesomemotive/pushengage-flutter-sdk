import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';
import 'package:pushengage_flutter_sdk/model/trigger_alert.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

enum SelectedType { priceDrop, inventory }

extension SelectedTypeString on SelectedType {
  String get value =>
      this == SelectedType.priceDrop ? 'Price Drop' : 'Inventory';
}

class AlertEntryScreen extends StatefulWidget {
  const AlertEntryScreen({Key? key}) : super(key: key);

  @override
  _AlertEntryScreenState createState() => _AlertEntryScreenState();
}

class _AlertEntryScreenState extends State<AlertEntryScreen> {
  SelectedType _selectedType = SelectedType.priceDrop;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedAvailability = 'Nil';
  final TextEditingController _profileIdController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _variantIdController = TextEditingController();
  final TextEditingController _alertPriceController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  final List<Map<String, String>> _dataList = [];

  String _formatDate(DateTime date) {
    const List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  DateTime? _getCombinedDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
    return null;
  }

  Future<void> _addAlert() async {
    final alert = TriggerAlert(
      type: _selectedType == SelectedType.priceDrop
          ? TriggerAlertType.priceDrop
          : TriggerAlertType.inventory,
      productId: _productIdController.text,
      link: _linkController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      variantId: _variantIdController.text.isNotEmpty
          ? _variantIdController.text
          : null,
      expiryTimestamp: _getCombinedDateTime(),
      alertPrice: double.tryParse(_alertPriceController.text),
      availability: _getAvailability(_selectedAvailability),
      profileId: _profileIdController.text.isNotEmpty
          ? _profileIdController.text
          : null,
      mrp: double.tryParse(_mrpController.text),
      data: _combineMaps(),
    );

    PushEngageResult result = await PushEngage.addAlert(alert);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isSuccess ? result.data : result.error)),
    );
  }

  TriggerAlertAvailabilityType? _getAvailability(String availability) {
    return availability == 'Out of Stock'
        ? TriggerAlertAvailabilityType.outOfStock
        : null;
  }

  Map<String, String> _combineMaps() {
    return Map.fromEntries(
        _dataList.map((map) => MapEntry(map['key']!, map['value']!)));
  }

  void _addData() {
    if (_keyController.text.isNotEmpty && _valueController.text.isNotEmpty) {
      setState(() {
        _dataList.add({
          'key': _keyController.text,
          'value': _valueController.text,
        });
        _keyController.clear();
        _valueController.clear();
      });
    }
  }

  void _removeData(int index) {
    setState(() {
      _dataList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trigger Campaign'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_profileIdController, 'Enter profile id'),
            const SizedBox(height: 10),
            _buildTextField(_mrpController, 'MRP',
                TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 10),
            _buildTypeDropdown(),
            const SizedBox(height: 10),
            _buildTextField(_productIdController, 'Enter product id'),
            const SizedBox(height: 10),
            _buildTextField(_linkController, 'Enter link'),
            const SizedBox(height: 10),
            _buildTextField(_priceController, 'Enter price',
                TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 10),
            _buildTextField(_variantIdController, 'Enter variant id'),
            const SizedBox(height: 10),
            _buildTextField(_alertPriceController, 'Enter alert price',
                TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 20),
            _buildDateTimePickers(),
            const SizedBox(height: 20),
            _buildAvailabilityDropdown(),
            const SizedBox(height: 20),
            _buildDataEntry(),
            const SizedBox(height: 20),
            _buildDataList(),
            Center(
              child: ElevatedButton(
                onPressed: _addAlert,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: const Color.fromARGB(255, 34, 74, 219),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select type', style: TextStyle(color: Colors.blue)),
        DropdownButton<SelectedType>(
          isExpanded: true,
          value: _selectedType,
          onChanged: (SelectedType? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedType = newValue;
              });
            }
          },
          items: SelectedType.values.map((SelectedType value) {
            return DropdownMenuItem<SelectedType>(
              value: value,
              child: Text(value.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select expiry time'),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                child: Text(_selectedDate == null
                    ? 'Select Date'
                    : _formatDate(_selectedDate!)),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                child: Text(_selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context)),
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null && picked != _selectedTime) {
                    setState(() {
                      _selectedTime = picked;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Availability'),
        DropdownButton<String>(
          isExpanded: true,
          value: _selectedAvailability,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedAvailability = newValue;
              });
            }
          },
          items: ['Nil', 'Out of Stock']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(child: _buildTextField(_keyController, 'Key')),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField(_valueController, 'Value')),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addData,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 40),
                backgroundColor: const Color.fromARGB(255, 34, 74, 219),
              ),
              child: const Text('Add',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: _dataList.length,
        itemBuilder: (context, index) {
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${_dataList[index]['key']} : ${_dataList[index]['value']}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _removeData(index),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 40),
                  backgroundColor: const Color.fromARGB(255, 219, 34, 34),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          );
        },
      ),
    );
  }
}
