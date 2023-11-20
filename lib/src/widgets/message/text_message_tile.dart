import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_highlighting/themes/github-dark-dimmed.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart'
    show LinkPreview;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:photo_view_v3/photo_view.dart';

import '../../../flutter_chat_ui.dart';
import '../cache_memory_image_provider.dart';
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

  final Widget Function(types.User author)? avatarBuilder;

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
      avatarBuilder?.call(message.author) ??
      UserAvatar(
        author: message.author,
      );

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

  void openDialog(BuildContext context, ImageProvider imageProvider) =>
      showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
          child: PhotoView(
            tightMode: true,
            imageProvider: imageProvider,
            heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
          ),
        ),
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
    var language = match?.group(1);
    language ??= 'javascript';

    final darkPreConfig = PreConfig.darkConfig.copy(
      textStyle: const TextStyle(fontSize: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1b1b1b),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      theme: githubDarkDimmedTheme,
      wrapper: codeWrapper,
      language: language,
    );

    final preConfig = isDark
        ? darkPreConfig
        : const PreConfig().copy(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(105, 145, 214, 0.1215686275),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _avatarBuilder(),
            const Spacer(),
            Container(
              padding: EdgeInsets.zero,
              alignment: Alignment.bottomRight,
              child: (msgExtraBarBuild != null)
                  ? msgExtraBarBuild!(message, context: context)
                  : null,
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.id != message.author.id)
                MarkdownWidget(
                  key: ValueKey('${message.id}_md'),
                  data: message.text,
                  shrinkWrap: true,
                  selectable: true,
                  padding: EdgeInsets.zero,
                  config: markdownConfig,
                ),
              if (user.id == message.author.id)
                if (enlargeEmojis)
                  SelectableText(message.text, style: emojiTextStyle)
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: TextMessageText(
                      bodyLinkTextStyle: bodyLinkTextStyle,
                      bodyTextStyle: bodyTextStyle,
                      boldTextStyle: boldTextStyle,
                      codeTextStyle: codeTextStyle,
                      options: options,
                      text: message.text,
                    ),
                  ),

              if (message.previewData != null &&
                  message.previewData?.image != null)
                Padding(
                  key: ValueKey('${message.id}_image'),
                  padding: const EdgeInsets.only(top: 15, bottom: 15, left: 4),
                  child: InkWell(
                    onTap: () {
                      openDialog(
                        context,
                        (message.previewData!.image!.url
                                .contains('data:image/png;base64,'))
                            ? Image(
                               fit: BoxFit.cover,
                                image: CacheMemoryImageProvider(
                                  '${message.id}_image_preview',
                                  base64Decode(
                                    message.previewData!.image!.url.replaceAll(
                                      'data:image/png;base64,',
                                      '',
                                    ),
                                  ),
                                ),
                              ).image
                            : CachedNetworkImageProvider(
                                message.previewData!.image!.url,
                              ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: (message.previewData!.image!.url
                              .contains('data:image/png;base64,'))
                          ? Image(
                              fit: BoxFit.cover,
                              height: message.previewData!.image!.height.toDouble(),
                              image: CacheMemoryImageProvider(
                                '${message.id}_image_preview',
                                base64Decode(
                                  message.previewData!.image!.url.replaceAll(
                                    'data:image/png;base64,',
                                    '',
                                  ),
                                ),
                              ),
                            )
                          // Image.memory(
                          //       ,
                          //       fit: BoxFit.cover,
                          //       height:
                          //           message.previewData!.image!.height.toDouble(),
                          //     )
                          : CachedNetworkImage(
                              height:
                                  message.previewData!.image!.height.toDouble(),
                              fit: BoxFit.cover,
                              imageUrl: message.previewData!.image!.url,
                              repeat: ImageRepeat.repeatY,
                              placeholder: (context, url) => const SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: Icon(Icons.error),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              // SizedBox(width:320 , height:320 , child: _linkPreview(user, 320, context)),
            ],
          ),
        ),
        //   ],
        // ),
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
      margin: EdgeInsets.fromLTRB(
        theme.messageInsetsHorizontal,
        theme.messageInsetsVertical - 10,
        theme.messageInsetsHorizontal,
        theme.messageInsetsVertical,
      ),
      child: _textWidgetBuilder(user, context, enlargeEmojis),
    );
  }
}
