import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_highlighting/themes/github-dark-dimmed.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart'
    show LinkPreview;
import 'package:markdown_widget/markdown_widget.dart';

import '../../../flutter_chat_ui.dart';
import '../code_wrapper.dart';
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
    this.avatarBuilder,
  });

  final Widget Function(String userId)? avatarBuilder;

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

  Widget _avatarBuilder() =>
      avatarBuilder?.call(message.author.id) ??
      UserAvatar(
        author: message.author,
      );

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

    const codeConfig = CodeConfig(
      style: TextStyle(
        inherit: false,
        backgroundColor: Colors.transparent,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );

    CodeWrapperWidget codeWrapper(child, text) =>
        CodeWrapperWidget(child: child, text: text);

    final exp = RegExp(r'```(.*?)\n', dotAll: true);
    final match = exp.firstMatch(message.text);
    final language = match?.group(1);

    final darkPreConfig = PreConfig.darkConfig.copy(
      textStyle: const TextStyle(fontSize: 14),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(30, 31, 34, 1),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      theme: githubDarkDimmedTheme,
      wrapper: codeWrapper,
      language: language,
    );

    final preConfig = isDark
        ? darkPreConfig
        : const PreConfig().copy(
            textStyle: const TextStyle(fontSize: 14),
            wrapper: codeWrapper,
            language: language,
            theme: githubTheme,
          );

    markdownConfig = markdownConfig.copy(configs: [
      PConfig(textStyle: bodyTextStyle),
      preConfig,
      codeConfig,
    ]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatarBuilder(),
        const SizedBox(
          height: 8,
        ),
        // Row(
        //   mainAxisSize: MainAxisSize.max,
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // MarkdownBody(
              //   styleSheet: ,
              //   selectable: true,
              //   data: message.text,
              //   extensionSet: md.ExtensionSet(
              //     md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              //     <md.InlineSyntax>[
              //       md.EmojiSyntax(),
              //       ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
              //     ],
              //   ),
              // ),
              if (user.id != message.author.id)
                MarkdownWidget(
                  data: message.text,
                  shrinkWrap: true,
                  selectable: true,
                  padding: EdgeInsets.zero,
                  config: markdownConfig,
                ),
              if (user.id == message.author.id)
                SelectableText(message.text, style: emojiTextStyle)
                //
                // if (enlargeEmojis)
                //
                // else
                //   Padding(
                //     padding: const EdgeInsets.only(left: 5),
                //     child: TextMessageText(
                //       bodyLinkTextStyle: bodyLinkTextStyle,
                //       bodyTextStyle: bodyTextStyle,
                //       boldTextStyle: boldTextStyle,
                //       codeTextStyle: codeTextStyle,
                //       options: options,
                //       text: message.text,
                //     ),
                //   ),
            ],
          ),
        ),
        //   ],
        // ),
        Container(
          padding: EdgeInsets.zero,
          alignment: Alignment.bottomRight,
          child: (msgExtraBarBuild != null)
              ? msgExtraBarBuild!(message, context: context)
              : const Text(''),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            isConsistsOfEmojis(emojiEnlargementBehavior, message);
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;

    return Container(
      margin: EdgeInsets.fromLTRB(theme.messageInsetsHorizontal,
          theme.messageInsetsVertical, theme.messageInsetsHorizontal, 0),
      child: _textWidgetBuilder(user, context, enlargeEmojis),
    );
  }
}
