import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';
import 'package:pushengage_flutter_sdk/model/DynamicSegment.dart';
import 'package:pushengage_flutter_sdk/model/trigger_campaign.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';
import 'package:pushengage_flutter_sdk_example/goal.dart';
import 'package:pushengage_flutter_sdk_example/trigger_entry.dart';
import 'package:pushengage_flutter_sdk_example/trigger_listing.dart';

enum PushEngageAction {
  addSegment,
  removeSegments,
  addDynamicSegments,
  addSubscriberAttributes,
  deleteAttributes,
  addProfileId,
  getSubscriberDetails,
  getSubscriberAttributes,
  setSubscriberAttributes,
  sendGoal,
  triggerCampaigns
}

extension PushEngageActionString on PushEngageAction {
  String get value {
    switch (this) {
      case PushEngageAction.addSegment:
        return "Add Segment";
      case PushEngageAction.removeSegments:
        return "Remove Segments";
      case PushEngageAction.addDynamicSegments:
        return "Add Dynamic Segments";
      case PushEngageAction.addSubscriberAttributes:
        return "Add Subscriber Attributes";
      case PushEngageAction.deleteAttributes:
        return "Delete Attributes";
      case PushEngageAction.addProfileId:
        return "Add Profile Id";
      case PushEngageAction.getSubscriberDetails:
        return "Get Subscriber Details";
      case PushEngageAction.getSubscriberAttributes:
        return "Get Subscriber Attributes";
      case PushEngageAction.setSubscriberAttributes:
        return "Set Subscriber Attributes";
      case PushEngageAction.sendGoal:
        return "Send Goal";
      case PushEngageAction.triggerCampaigns:
        return "Trigger Campaigns";
      default:
        return "";
    }
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String responseText = ""; // Initial text
  final TextEditingController _controller = TextEditingController();
  late StreamSubscription _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    PushEngage.enableLogging(true);
    PushEngage.deepLinkStream.listen((data) {
      _handleDeepLink(data);
    });
  }

  void _handleDeepLink(Map<String, dynamic>? data) {
    // Parse the deep link and navigate accordingly
    Uri uri = Uri.parse(data?['deepLink']);
    print('Path: ${uri.path}');
    updateResponseText(data.toString());
    switch (uri.path) {
      case 'trigger':
      case '/trigger':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => TriggerCampaignEntry()));
        break;
    }
  }

  void updateResponseText(String newText) {
    setState(() {
      responseText = newText; // Update the text on response
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'PushEngage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 34, 74, 219),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment
            .spaceBetween, // Aligns the children with space between them
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Result',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 243, 239,
                      239), // Background color for the text display area
                ),
                child: Container(
                  height: 150, // Fixed height for the text display area
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment
                      .topLeft, // Aligns the text inside to the top left
                  child: SingleChildScrollView(
                    // Makes the text inside scrollable
                    child: Text(
                      responseText,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16), // Adjust text style as needed
                    ),
                  ),
                )),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: PushEngageAction.values.length, // Number of buttons
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4.0), // Adjust horizontal padding here
                  child: ElevatedButton(
                      onPressed: () {
                        handleButtonClick(PushEngageAction.values[
                            index]); // Call the handleButtonClick function with the selected action
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Set the corner radius to 20
                        ),
                      ),
                      child: Text(
                        PushEngageAction.values[index].value,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      )),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: ElevatedButton(
                onPressed: () {
                  handleNotificationPermissionRequest();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 34, 74, 219),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8), // Set the corner radius to 20
                  ),
                ),
                child: const Text(
                  "Request Notification Permission",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                )),
          )
        ],
      ),
    );
  }

  void handleNotificationPermissionRequest() {
    PushEngage.requestNotificationPermission();
  }

  Future<String?> showInputDialog() async {
    String? inputText = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Values'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Comma separated values"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop(_controller.text);
              },
            ),
          ],
        );
      },
    );
    return inputText;
  }

  Future<void> handleButtonClick(PushEngageAction action) async {
    switch (action) {
      case PushEngageAction.addSegment:
        String? input = await showInputDialog();
        List<String>? segments =
            input?.split(',').map((e) => e.trim()).toList();
        if (segments == null) {
          return;
        }

        final result = await PushEngage.addSegment(segments);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "Segment added");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to add segment");
            break;
        }
        break;
      case PushEngageAction.removeSegments:
        String? input = await showInputDialog();
        List<String>? segments =
            input?.split(',').map((e) => e.trim()).toList();
        if (segments == null) {
          return;
        }

        final result = await PushEngage.removeSegment(segments);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "Segment removed");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to remove segment");
            break;
        }
        break;
      case PushEngageAction.addDynamicSegments:
        String? input = await showInputDialog();
        List<DynamicSegment> segments = [];
        List<String> inputList = input?.split(',') ?? [];
        for (String item in inputList) {
          List<String> keyValue = item.split(':');
          if (keyValue.length == 2) {
            String name = keyValue[0].trim();
            int days = int.parse(keyValue[1].trim());
            var segment = DynamicSegment(name: name, duration: days);
            segments.add(segment);
          }
        }
        if (segments.isEmpty) {
          return;
        }

        final result = await PushEngage.addDynamicSegment(segments);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(
                result.data?.toString() ?? "Dynamic Segment added");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to add Dynamic Segment");
            break;
        }
        break;
      case PushEngageAction.addSubscriberAttributes:
        String? input = await showInputDialog();
        List<String> inputList = input?.split(',') ?? [];
        Map<String, String> inputMap = {};
        for (String item in inputList) {
          List<String> keyValue = item.split(':');
          if (keyValue.length == 2) {
            String key = keyValue[0].trim();
            String value = keyValue[1].trim();
            inputMap[key] = value;
          }
        }

        final result = await PushEngage.addSubscriberAttributes(inputMap);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "Attributes added");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to add attributes");
            break;
        }
        break;
      case PushEngageAction.deleteAttributes:
        String? input = await showInputDialog();
        List<String>? attributes =
            input?.split(',').map((e) => e.trim()).toList();
        if (attributes == null) {
          return;
        }

        final result = await PushEngage.deleteSubscriberAttributes(attributes);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "Attributes deleted");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to delete attributes");
            break;
        }
        break;
      case PushEngageAction.addProfileId:
        String? input = await showInputDialog();
        if (input == null) {
          return;
        }

        final result = await PushEngage.addProfileId(input);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "Profile ID added");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to add Profile ID");
            break;
        }
        break;
      case PushEngageAction.getSubscriberDetails:
        List<String> subscriberAttributes = [
          "city",
          "device",
          "host",
          "user_agent",
          "has_unsubscribed",
          "device_type",
          "timezone",
          "country",
          "ts_created",
          "state",
          "profile_id"
        ];

        final result =
            await PushEngage.getSubscriberDetails(subscriberAttributes);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "No details found");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to fetch details");
            break;
        }
        break;
      case PushEngageAction.getSubscriberAttributes:
        final result = await PushEngage.getSubscriberAttributes();
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(
                result.data?.toString() ?? "No attributes found");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText("Failed to fetch attributes");
            break;
        }
      case PushEngageAction.setSubscriberAttributes:
        String? input = await showInputDialog();
        List<String> inputList = input?.split(',') ?? [];
        Map<String, String> inputMap = {};
        for (String item in inputList) {
          List<String> keyValue = item.split(':');
          if (keyValue.length == 2) {
            String key = keyValue[0].trim();
            String value = keyValue[1].trim();
            inputMap[key] = value;
          }
        }
        final result = await PushEngage.setSubscriberAttributes(inputMap);
        switch (result.status) {
          case PushEngageResultStatus.success:
            updateResponseText(result.data?.toString() ?? "Attributes set");
            break;
          case PushEngageResultStatus.failure:
            updateResponseText(result.error ?? "Failed to set attributes");
            break;
        }
        break;
      case PushEngageAction.sendGoal:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SendGoalPage()));
        break;
      case PushEngageAction.triggerCampaigns:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => TriggerCampaignsPage()));
        break;
      default:
        break;
    }
  }
}
