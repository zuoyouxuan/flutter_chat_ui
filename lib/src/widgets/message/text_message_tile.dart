import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
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

  String generateDateStringWithRandomChars() {
    // 获取当前日期并格式化
    String formattedDate =
        DateTime.now().toString().substring(0, 10); // yyyy-MM-dd

    // 定义一个字符串，其中包含所有可能用于生成随机字符的字符
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    // 创建一个随机数发生器
    Random random = Random();

    // 生成一个包含5个随机字符的字符串
    String randomChars =
        List.generate(5, (index) => chars[random.nextInt(chars.length)]).join();

    // 将格式化的日期和随机字符拼接成一个字符串
    return 'Helix-AI-$formattedDate-$randomChars';
  }

  void openDialog(BuildContext context, ImageProvider imageProvider) =>
      showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Image Preview'),
            ),
            body: PhotoView(
              tightMode: true,
              imageProvider: imageProvider,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                String? outputFile = await FilePicker.platform.saveFile(
                  dialogTitle: 'Please select an output file:',
                  fileName: '${generateDateStringWithRandomChars()}.png',
                );

                if (outputFile == null) {
                  writeImageStreamToFile(imageProvider, outputFile!);
                }
                //
                // FilePicker.platform
                //     .saveFile(
                //       dialogTitle: 'Please select an output file:',
                //       fileName: '${generateDateStringWithRandomChars()}.png',
                //     )
                //     .then((outputFile) => {
                //           if (outputFile != null)
                //             {writeImageStreamToFile(imageProvider, outputFile)},
                //         });
              },
              child: const Tooltip(
                message: 'Save Image',
                child: Icon(
                  Icons.save_alt,
                ),
              ),
            ),
          ),
        ),
      );

  void writeImageStreamToFile(ImageProvider imageProvider, String fileName) {
    final completer = Completer<String>();
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        imageInfo.image
            .toByteData(
          format: ImageByteFormat.png,
        )
            .then((byteData) {
          final Uint8List? bytes = byteData?.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );

          if (bytes != null) {
            File(fileName).writeAsBytes(bytes).then((value) => {});
          }
          if (!completer.isCompleted) {
            if (listener != null) {
              imageStream.removeListener(listener);
            }
            completer.complete(fileName);
          }
        });
      },
    );
    imageStream.addListener(listener);
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

    const codeConfig = CodeConfig(
      style: TextStyle(
        inherit: false,
        backgroundColor: Colors.transparent,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );

    CodeWrapperWidget codeWrapper(child, code, language) =>
        CodeWrapperWidget(child, code, language);

    final exp = RegExp(r'```(.*?)\n', dotAll: true);
    RegExp imageRegEx = RegExp(r'data:image/(png|jpeg|jpg|gif);base64,');
    String? base64Image;
    bool isBase64Image = false;
    if (message.previewData != null &&
        message.previewData?.image != null &&
        message.previewData?.image?.url != null) {
      base64Image = message.previewData!.image!.url;
      base64Image = base64Image.replaceAll(imageRegEx, '');
      isBase64Image = imageRegEx.hasMatch(message.previewData!.image!.url);
    }

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
                // if(message.status != types.Status.sending)
                MarkdownWidget(
                  key: ValueKey('${message.id}_md'),
                  data: message.text,
                  shrinkWrap: true,
                  selectable: true,
                  padding: EdgeInsets.zero,
                  config: markdownConfig,
                ),
              // if(user.id != message.author.id && message.status == types.Status.sending)
              //   Center(child: SiriWaveform.ios9(options: const IOS9SiriWaveformOptions(height: 60),),),

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
                  message.previewData?.image != null &&
                  message.previewData?.image?.url != null)
                Padding(
                  key: ValueKey('${message.id}_image'),
                  padding: const EdgeInsets.only(top: 15, bottom: 15, left: 4),
                  child: InkWell(
                    onTap: () {
                      openDialog(
                        context,
                        (isBase64Image && base64Image != null)
                            ? Image(
                                fit: BoxFit.cover,
                                image: CacheMemoryImageProvider(
                                  '${message.id}_image_preview',
                                  base64Decode(
                                    base64Image,
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
                      child: (isBase64Image && base64Image != null)
                          ? Image(
                              fit: BoxFit.cover,
                              height:
                                  message.previewData!.image!.height.toDouble(),
                              image: CacheMemoryImageProvider(
                                '${message.id}_image_preview',
                                base64Decode(
                                  base64Image,
                                ),
                              ),
                            )
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
      key: ValueKey('${message.id}_text_message_container'),
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
