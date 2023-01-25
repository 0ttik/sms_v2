import 'package:flutter/material.dart';
import 'package:sms_v2/sms.dart';

class MessageGroupService {
  static MessageGroupService of(BuildContext context) {
    return new MessageGroupService._private(context);
  }

  MessageGroupService._private(this.context);

  final BuildContext context;

  List<Group> groupByDate(List<SmsMessage> messages) {
    final groups = new _GroupCollection();
    messages.forEach((message) {
      final date = message.date;
      final groupLabel =
          date == null ? 'null' : MaterialLocalizations.of(context).formatFullDate(date);
      if (groups.contains(groupLabel)) {
        groups.get(groupLabel).addMessage(message);
      } else {
        groups.add(new Group(groupLabel, messages: [message]));
      }
    });
    return groups.groups;
  }
}

class Group {
  String label;
  List<SmsMessage> messages;

  Group(this.label, {this.messages = const <SmsMessage>[]});

  void addMessage(SmsMessage message) {
    messages.insert(0, message);
  }
}

class _GroupCollection {
  List<Group> groups = <Group>[];

  bool contains(String label) {
    return groups.any((group) {
      return group.label == label;
    });
  }

  Group get(String label) {
    return groups.singleWhere((group) {
      return group.label == label;
    });
  }

  void add(Group group) {
    groups.add(group);
  }
}
