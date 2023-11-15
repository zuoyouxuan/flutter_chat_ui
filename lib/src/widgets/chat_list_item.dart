
import 'package:flutter/material.dart';

class ChatListItem extends StatefulWidget {
  final Widget item;

  ChatListItem({required this.item});

  @override
  _ChatListItemState createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.item;
  }
}