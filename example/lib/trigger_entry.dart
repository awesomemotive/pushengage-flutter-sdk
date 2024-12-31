import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';
import 'package:pushengage_flutter_sdk/model/trigger_campaign.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

class TriggerCampaignEntry extends StatefulWidget {
  const TriggerCampaignEntry({Key? key}) : super(key: key);

  @override
  _TriggerCampaignEntryState createState() => _TriggerCampaignEntryState();
}

class _TriggerCampaignEntryState extends State<TriggerCampaignEntry> {
  final TextEditingController campaignController = TextEditingController();
  final TextEditingController eventController = TextEditingController();
  final TextEditingController profileController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController keyController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  final List<Map<String, String>> dataList = [];

  void _addData() {
    if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
      setState(() {
        dataList.add({
          'key': keyController.text,
          'value': valueController.text,
        });
        keyController.clear();
        valueController.clear();
      });
    }
  }

  Map<String, String> _combineMaps() {
    return Map.fromEntries(
        dataList.map((map) => MapEntry(map['key']!, map['value']!)));
  }

  Future<void> _addTriggerCampaign() async {
    final triggerCampaign = TriggerCampaign(
      campaignName: campaignController.text,
      eventName: eventController.text,
      referenceId:
          referenceController.text.isEmpty ? null : referenceController.text,
      profileId: profileController.text.isEmpty ? null : profileController.text,
      data: _combineMaps(),
    );
    PushEngageResult result =
        await PushEngage.sendTriggerEvent(triggerCampaign);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isSuccess ? result.data : result.error)),
    );
  }

  void _removeData(int index) {
    setState(() {
      dataList.removeAt(index);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(campaignController, 'Enter campaign name'),
              const SizedBox(height: 10),
              _buildTextField(eventController, 'Enter event name'),
              const SizedBox(height: 10),
              _buildTextField(profileController, 'Enter profile id'),
              const SizedBox(height: 10),
              _buildTextField(referenceController, 'Enter reference id'),
              const SizedBox(height: 20),
              const Text(
                'Enter Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDataEntryRow(),
              const SizedBox(height: 20),
              _buildDataList(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _addTriggerCampaign,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    backgroundColor: const Color.fromARGB(255, 34, 74, 219),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDataEntryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(keyController, 'Key'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField(valueController, 'Value'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _addData,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 40),
            backgroundColor: const Color.fromARGB(255, 34, 74, 219),
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${dataList[index]['key']} : ${dataList[index]['value']}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _removeData(index),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 40),
                  backgroundColor: const Color.fromARGB(255, 219, 34, 34),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
