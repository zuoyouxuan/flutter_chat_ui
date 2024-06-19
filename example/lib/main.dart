import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: ChatPage(),
      );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  static PatternStyle get code => PatternStyle(
        '`',
        RegExp(r'```([\\s\\S]*?)```[\\s]?'),
        '',
        TextStyle(
          fontFamily: 'monospace',
        ),
      );

  bool is_darkMode = true;

  bool _isHovering = false;

  _setHoveringValue(bool val) => setState(() => _isHovering = val);

  //
  // Widget _msgExtraBarBuild(types.Message message, {required BuildContext context}) => Row(
  //   mainAxisSize: MainAxisSize.max,
  //   mainAxisAlignment: MainAxisAlignment.end,
  //   children: [
  //     _buildHoverIconButton(
  //       icon: Icons.copy,
  //       tooltip: 'Copy Message',
  //       message: message,
  //       context: context,
  //     ),
  //     _buildHoverIconButton(
  //       icon: Icons.refresh,
  //       tooltip: 'Refresh Message',
  //       message: message,
  //       context: context,
  //     ),
  //   ],
  // );
  //
  // Widget _buildHoverIconButton({
  //   required IconData icon,
  //   required String tooltip,
  //   required types.Message message,
  //   required BuildContext context,
  // }) => MouseRegion(
  //     onEnter: (event) => _setHoveringValue(true),
  //     onExit: (event) => _setHoveringValue(false),
  //     child: AnimatedOpacity(
  //       duration: const Duration(milliseconds: 200),
  //       opacity: _isHovering ? 1 : 0.3,
  //       child: IconButton(
  //         tooltip: tooltip,
  //         color: Colors.grey,
  //         iconSize: 14,
  //         onPressed: () async {
  //           await Clipboard.setData(ClipboardData(text: message.toJson()['text']));
  //         },
  //         icon: Icon(icon),
  //       ),
  //     ),
  //   );

  Widget _msgExtraBarBuild(types.Message message,
          {required BuildContext context}) =>
      Row(
        mainAxisSize: MainAxisSize.max,
        // // crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        // crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            color: Colors.grey.withOpacity(0.5),
            iconSize: 14,
            onPressed: () async {
              await Clipboard.setData(
                      ClipboardData(text: message.toJson()['text']))
                  .then((value) => {});
            },
            icon: Icon(Icons.copy),
          ),
          IconButton(
            tooltip: '点击复制消息',
            color: Colors.grey.withOpacity(0.5),
            iconSize: 16,
            onPressed: () async {
              await Clipboard.setData(
                      ClipboardData(text: message.toJson()['text']))
                  .then((value) => {});
            },
            icon: Icon(Icons.refresh),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          
          onSendPressed: _handleSendPressed,
          chatListBuilder: ChatListBuilder(
            messages: _messages,
            tileLayout:true,
            onAttachmentPressed: _handleAttachmentPressed,
            onMessageTap: _handleMessageTap,
            onPreviewDataFetched: _handlePreviewDataFetched,
            user: _user,
            msgExtraBarBuild: (message, {required context}) => _msgExtraBarBuild(
              message,
              context: context,
            ),
          ),
          user: _user,
          // avatarBuilder: (String userId) => userId == _user.id
          //       ? const CircleAvatar(
          //     child: Icon(
          //       Icons.rocket,
          //       color: Colors.white,
          //     ),
          //     backgroundColor: Color.fromRGBO(25, 195, 125 , 1),
          //   )
          //       : CircleAvatar(
          //     backgroundColor: Colors.blue.withOpacity(0.3),
          //     child: const Icon(
          //       Icons.question_mark,
          //       color: Colors.white,
          //     ),
          //   ),
          imageGalleryOptions: ImageGalleryOptions(),
          

          inputOptions: const InputOptions(
            sendButtonVisibilityMode: SendButtonVisibilityMode.always,
            minLines: 3,
          ),
          theme: DefaultChatTheme(
              messageBorderColor: is_darkMode
                  ? const Color.fromRGBO(32, 33, 35, .5)
                  : Color.fromRGBO(0, 0, 0, .1),
              // deliveredIcon: Icon(
              //   Icons.double_arrow,
              //   size: 10,
              // ),
              errorIcon: Icon(
                Icons.warning,
                color: Colors.yellow,
              ),
              primaryColor: is_darkMode
                  ? Color.fromRGBO(52, 53, 65, 1)
                  : Color.fromRGBO(255, 255, 255, 1),
              secondaryColor: is_darkMode
                  ? Color.fromRGBO(68, 70, 84, 1)
                  : Color.fromRGBO(247, 247, 248, 1),
              backgroundColor:
                  is_darkMode ? Color.fromRGBO(40, 42, 58, 1) : Colors.white54,
              receivedMessageBodyTextStyle: TextStyle(
                color: is_darkMode
                    ? Color.fromRGBO(236, 236, 241, 1)
                    : Color.fromRGBO(52, 53, 65, 1),
                fontSize: 16,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
              sentMessageBodyTextStyle: TextStyle(
                color: is_darkMode
                    ? Color.fromRGBO(236, 236, 241, 1)
                    : Color.fromRGBO(52, 53, 65, 1),
                fontSize: 16,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
              inputContainerDecoration: BoxDecoration(
                  // gradient: LinearGradient(colors: [Colors.grey, Colors.white]), //背景渐变
                  // borderRadius: BorderRadius.circular(0),
                  border: Border(
                      top: BorderSide(
                          color: is_darkMode
                              ? const Color(0xFF1D1E2C)
                              : Color(0xFFE4E2E6)))),
              messageBorderRadius: 10,
              messageInsetsHorizontal: 20,
              messageInsetsVertical: 12,
              attachmentButtonIcon: Icon(Icons.tips_and_updates_outlined),
              inputPadding: const EdgeInsets.fromLTRB(18, 20, 20, 20),
              inputTextStyle:
                  TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
              inputTextColor:
                  is_darkMode ? const Color(0xFFFFFFFF) : Color(0xFF1D1E2C),
              inputBackgroundColor:
                  is_darkMode ? Color(0xFF1B1B1F) : Color(0xFFFFFFFF),
              inputBorderRadius: const BorderRadius.all(Radius.circular(0))),
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _handleAttachmentPressed() async {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    // final result = await FilePicker.platform.pickFiles(
    //   type: FileType.any,
    // );
    //
    // if (result != null && result.files.single.path != null) {
    //   final message = types.FileMessage(
    //     author: _user,
    //     createdAt: DateTime.now().millisecondsSinceEpoch,
    //     id: const Uuid().v4(),
    //     mimeType: lookupMimeType(result.files.single.path!),
    //     name: result.files.single.name,
    //     size: result.files.single.size,
    //     uri: result.files.single.path!,
    //   );
    //
    //   _addMessage(message);
    // }
  }

  void _handleImageSelection() async {
    print('handleImageSelection');

    // final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    //
    // final result = await ImagePicker().pickImage(
    //   imageQuality: 70,
    //   maxWidth: 1440,
    //   source: ImageSource.gallery,
    // );
    //
    // if (result != null) {
    //   final bytes = await result.readAsBytes();
    //   final image = await decodeImageFromList(bytes);
    //
    //   print('image: ${result.path}');
    //
    //   final message = types.ImageMessage(
    //     author: _user,
    //     createdAt: DateTime.now().millisecondsSinceEpoch,
    //     height: image.height.toDouble(),
    //     id: const Uuid().v4(),
    //     name: "image.name",
    //     size: bytes.length,
    //     uri: result.path,
    //     width: image.width.toDouble(),
    //   );
    //
    //   _addMessage(message);
    // }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      // await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
      status: types.Status.sending,
      // previewData: const types.PreviewData(
      //   image: types.PreviewDataImage(
      //       width: 120, height: 120, url: 'https://d1.awsstatic.com/codewhisper/icon_cw_serviceicon.65af1ed185a8674249a5aa38894f469e974714d3.png'),
      // ),
    );

    print('textMessage: ${textMessage.toJson()}');

    _addMessage(textMessage);
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }
}
