import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  });

  /// See [Message.emojiEnlargementBehavior].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// See [Message.hideBackgroundOnEmojiMessages].
  final bool hideBackgroundOnEmojiMessages;

  /// [types.TextMessage].
  final types.TextMessage message;

  /// This is to allow custom user name builder
  /// By using this we can fetch newest user info based on id
  final Widget Function(String userId)? nameBuilder;

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

  @override
  Widget build(BuildContext context) {
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            isConsistsOfEmojis(emojiEnlargementBehavior, message);
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    final width = MediaQuery.of(context).size.width;

    // if (usePreviewData && onPreviewDataFetched != null) {
    //   final urlRegexp = RegExp(regexLink, caseSensitive: false);
    //   final matches = urlRegexp.allMatches(message.text);
    //
    //   if (matches.isNotEmpty) {
    //     return _linkPreview(user, width, context);
    //   }
    // }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: theme.messageInsetsHorizontal,
        vertical: theme.messageInsetsVertical,
      ),
      child: _textWidgetBuilder(user, context, enlargeEmojis),
    );
  }

  Widget _linkPreview(
    types.User user,
    double width,
    BuildContext context,
  ) {
    final linkDescriptionTextStyle = user.id == message.author.id
        ? InheritedChatTheme.of(context)
            .theme
            .sentMessageLinkDescriptionTextStyle
        : InheritedChatTheme.of(context)
            .theme
            .receivedMessageLinkDescriptionTextStyle;
    final linkTitleTextStyle = user.id == message.author.id
        ? InheritedChatTheme.of(context).theme.sentMessageLinkTitleTextStyle
        : InheritedChatTheme.of(context)
            .theme
            .receivedMessageLinkTitleTextStyle;

    return LinkPreview(
      enableAnimation: true,
      metadataTextStyle: linkDescriptionTextStyle,
      metadataTitleStyle: linkTitleTextStyle,
      onLinkPressed: options.onLinkPressed,
      onPreviewDataFetched: _onPreviewDataFetched,
      openOnPreviewImageTap: options.openOnPreviewImageTap,
      openOnPreviewTitleTap: options.openOnPreviewTitleTap,
      padding: EdgeInsets.symmetric(
        horizontal:
            InheritedChatTheme.of(context).theme.messageInsetsHorizontal,
        vertical: InheritedChatTheme.of(context).theme.messageInsetsVertical,
      ),
      previewData: message.previewData,
      text: message.text,
      textWidget: _textWidgetBuilder(user, context, false),
      userAgent: userAgent,
      width: width,
    );
  }

  void _onPreviewDataFetched(types.PreviewData previewData) {
    if (message.previewData == null) {
      onPreviewDataFetched?.call(message, previewData);
    }
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

    var markdownConfig =
        isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    PreConfig preConfig = isDark
        ? PreConfig.darkConfig.copy(textStyle: const TextStyle(fontSize: 14))
        : PreConfig().copy(textStyle: const TextStyle(fontSize: 14));

    markdownConfig = markdownConfig.copy(configs: [
      const PConfig(textStyle: TextStyle(fontSize: 14)),
      // CodeConfig(style: codeConfigStyle),
      preConfig
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
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
              flex: 1,
              child: Column(
                children: [
                  MarkdownWidget(
                    data: message.text,
                    shrinkWrap: true,
                    selectable: true,
                    config: markdownConfig,
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

            Align(
                alignment: Alignment.topRight,
                child: IconButton(
                    tooltip: '点击复制',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                    },
                    icon: Icon(
                      size: 14,
                      Icons.copy_all_sharp,
                      color: bodyTextStyle.color?.withOpacity(0.5),
                    ))),
          ],
        )
      ],
    );
  }
}
