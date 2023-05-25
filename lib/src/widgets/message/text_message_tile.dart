import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart'
    show LinkPreview, regexEmail, regexLink;
import 'package:markdown_widget/markdown_widget.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';

/// A class that represents text message widget with optional link preview.
class TileTextMessage extends StatelessWidget {
  /// Creates a text message widget from a [types.TextMessage] class.
  const TileTextMessage({
    super.key,
    required this.emojiEnlargementBehavior,
    required this.hideBackgroundOnEmojiMessages,
    required this.message,
    this.nameBuilder,
    this.onPreviewDataFetched,
    this.options = const TextMessageOptions(),
    required this.showName,
    required this.usePreviewData,
    this.userAgent,
    this.msgExtraBarBuild,
  });

  /// See [Message.emojiEnlargementBehavior].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// See [Message.hideBackgroundOnEmojiMessages].
  final bool hideBackgroundOnEmojiMessages;

  /// [types.TextMessage].
  final types.TextMessage message;

  /// This is to allow custom user name builder
  /// By using this we can fetch newest user info based on id
  final Widget Function(types.User)? nameBuilder;

  /// See [LinkPreview.onPreviewDataFetched].
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;

  /// Customisation options for the [TextMessage].
  final TextMessageOptions options;

  /// Show user name for the received message. Useful for a group chat.
  final bool showName;

  /// Enables link (URL) preview.
  final bool usePreviewData;

  /// User agent to fetch preview data with.
  final String? userAgent;

  final Widget Function(types.Message message, {required BuildContext context})?
      msgExtraBarBuild;

  @override
  Widget build(BuildContext context) {
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            isConsistsOfEmojis(emojiEnlargementBehavior, message);
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    // final width = MediaQuery.of(context).size.width;

    // if (usePreviewData && onPreviewDataFetched != null) {
    //   final urlRegexp = RegExp(regexLink, caseSensitive: false);
    //   final matches = urlRegexp.allMatches(message.text);
    //
    //   if (matches.isNotEmpty) {
    //     return _linkPreview(user, width, context);
    //   }
    // }

    return Container(
      // margin: EdgeInsets.symmetric(
      //   horizontal: theme.messageInsetsHorizontal,
      //   vertical: theme.messageInsetsVertical,
      // ),
      //
      margin: EdgeInsets.fromLTRB(theme.messageInsetsHorizontal, theme.messageInsetsVertical, theme.messageInsetsHorizontal, 0),
      child: _textWidgetBuilder(user, context, enlargeEmojis),
    );
  }

  Widget _textWidgetBuilder(
    types.User user,
    BuildContext context,
    bool enlargeEmojis,
  ) {
    final theme = InheritedChatTheme.of(context).theme;
    final bodyLinkTextStyle = user.id == message.author.id
        ? InheritedChatTheme.of(context).theme.sentMessageBodyLinkTextStyle
        : InheritedChatTheme.of(context).theme.receivedMessageBodyLinkTextStyle;
    final bodyTextStyle = user.id == message.author.id
        ? theme.sentMessageBodyTextStyle
        : theme.receivedMessageBodyTextStyle;
    final boldTextStyle = user.id == message.author.id
        ? theme.sentMessageBodyBoldTextStyle
        : theme.receivedMessageBodyBoldTextStyle;
    final codeTextStyle = user.id == message.author.id
        ? theme.sentMessageBodyCodeTextStyle
        : theme.receivedMessageBodyCodeTextStyle;
    final emojiTextStyle = user.id == message.author.id
        ? theme.sentEmojiMessageTextStyle
        : theme.receivedEmojiMessageTextStyle;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final isDark = true;

    var markdownConfig =
        isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;

    final darkPreConfig = PreConfig.darkConfig.copy(
      textStyle: const TextStyle(fontSize: 14),
      // theme : a11yDarkTheme,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );

    final preConfig = isDark
        ? darkPreConfig
        : const PreConfig().copy(textStyle: const TextStyle(fontSize: 14));

    const codeConfig = CodeConfig(
        style: TextStyle(
            inherit: false,
            backgroundColor: Colors.transparent,
            fontWeight: FontWeight.bold,
            color: Colors.green));

    markdownConfig = markdownConfig.copy(configs: [
      PConfig(textStyle: bodyTextStyle),
      preConfig,
      codeConfig,
      // codeConfig
    ]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(
                  author: message.author,
                ),
              ],
            ),
            // if (showName)
            SizedBox(
              width: 5,
            ),

            Expanded(
              // flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.id != message.author.id)
                    MarkdownWidget(
                      data: message.text,
                      shrinkWrap: true,
                      selectable: true,
                      config: markdownConfig,
                    ),
                  if (user.id == message.author.id)
                    if (enlargeEmojis)
                      SelectableText(message.text, style: emojiTextStyle)
                    else
                      TextMessageText(
                        bodyLinkTextStyle: bodyLinkTextStyle,
                        bodyTextStyle: bodyTextStyle,
                        boldTextStyle: boldTextStyle,
                        codeTextStyle: codeTextStyle,
                        options: options,
                        text: message.text,
                      ),
                  //
                  //
                  // if (enlargeEmojis)
                  //   if (options.isTextSelectable)
                  //     SelectableText(message.text, style: emojiTextStyle)
                  //   else
                  //     Text(message.text, style: emojiTextStyle)
                  //
                ],
              ),
            ),

            // Align(
            //     alignment: Alignment.topRight,
            //     child: IconButton(
            //         tooltip: '点击复制',
            //         onPressed: () async {
            //           await Clipboard.setData(ClipboardData(text: message.text))
            //               .then((value) => {});
            //         },
            //         icon: Icon(
            //           size: 14,
            //           Icons.copy_all_sharp,
            //           color: bodyTextStyle.color?.withOpacity(0.5),
            //         ))),
          ],
        ),
        Container(
          padding: EdgeInsets.zero,
          // padding: const EdgeInsets.all(5.0),
          alignment: Alignment.bottomRight,
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //     colors: <Color>[
          //       Colors.black.withAlpha(0),
          //       Colors.black12,
          //       Colors.black45
          //     ],
          //   ),
          // ),
          child: (msgExtraBarBuild != null)
              ? msgExtraBarBuild!(message, context: context)
              : Text(""),
        ),

        //
        // Row(
        //   mainAxisSize: MainAxisSize.max,
        //   // crossAxisAlignment: CrossAxisAlignment.end,
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   children: msgExtraBarBuild!(message),
        //
        //   //
        //   // children: [
        //   //   IconButton(
        //   //     color: Colors.grey.withOpacity(0.5),
        //   //     iconSize: 14,
        //   //     onPressed: () {},
        //   //     icon: Icon(Icons.copy),
        //   //   ),
        //   //   SizedBox(
        //   //     width: 5,
        //   //   ),
        //   //   Icon(
        //   //     Icons.refresh,
        //   //     color: Colors.grey.withOpacity(0.5),
        //   //     size: 16,
        //   //   ),
        //   // ],
        // )
      ],
    );
  }
}
