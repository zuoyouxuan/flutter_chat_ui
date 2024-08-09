import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_highlighting/themes/github-dark-dimmed.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart' show LinkPreview;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:photo_view_v3/photo_view.dart';

import '../../../flutter_chat_ui.dart';
import '../cache_memory_image_provider.dart';
import '../code_wrapper.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';

class TileTextMessage extends StatefulWidget {
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
  final EmojiEnlargementBehavior emojiEnlargementBehavior;
  final bool hideBackgroundOnEmojiMessages;
  final types.TextMessage message;
  final Widget Function(types.User)? nameBuilder;
  final void Function(types.TextMessage, types.PreviewData)? onPreviewDataFetched;
  final TextMessageOptions options;
  final bool showName;
  final bool usePreviewData;
  final String? userAgent;
  final Widget Function(types.Message message, {required BuildContext context})? msgExtraBarBuild;

  @override
  State<TileTextMessage> createState() => _TileTextMessageState();
}

class _TileTextMessageState extends State<TileTextMessage> {
  bool _isHovering = false;

  Widget _avatarBuilder() => widget.avatarBuilder?.call(widget.message.author) ?? UserAvatar(author: widget.message.author);

  Widget _linkPreview(types.User user, double width, BuildContext context) {
    final theme = InheritedChatTheme.of(context).theme;
    final isUserAuthor = user.id == widget.message.author.id;
    
    return LinkPreview(
      enableAnimation: true,
      metadataTextStyle: isUserAuthor ? theme.sentMessageLinkDescriptionTextStyle : theme.receivedMessageLinkDescriptionTextStyle,
      metadataTitleStyle: isUserAuthor ? theme.sentMessageLinkTitleTextStyle : theme.receivedMessageLinkTitleTextStyle,
      onLinkPressed: widget.options.onLinkPressed,
      onPreviewDataFetched: _onPreviewDataFetched,
      openOnPreviewImageTap: widget.options.openOnPreviewImageTap,
      openOnPreviewTitleTap: widget.options.openOnPreviewTitleTap,
      padding: EdgeInsets.symmetric(
        horizontal: theme.messageInsetsHorizontal,
        vertical: theme.messageInsetsVertical,
      ),
      previewData: widget.message.previewData,
      text: widget.message.text,
      textWidget: _textWidgetBuilder(user, context, false),
      userAgent: widget.userAgent,
      width: width,
    );
  }

  void _onPreviewDataFetched(types.PreviewData previewData) {
    if (widget.message.previewData == null) {
      widget.onPreviewDataFetched?.call(widget.message, previewData);
    }
  }

  String _generateDateStringWithRandomChars() {
    final now = DateTime.now();
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final randomChars = List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
    return '$formattedDate-$randomChars-HelixAI';
  }

  void _openDialog(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Scaffold(
          appBar: AppBar(title: const Text('Image Preview')),
          body: GestureDetector(
            onTapDown: (_) => Navigator.pop(context),
            child: Center(child: PhotoView(tightMode: true, imageProvider: imageProvider)),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _saveImage(imageProvider),
            child: const Tooltip(message: 'Save Image', child: Icon(Icons.save_alt)),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage(ImageProvider imageProvider) async {
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: '${_generateDateStringWithRandomChars()}.png',
    );
    if (outputFile != null) {
      await _writeImageStreamToFile(imageProvider, outputFile);
    }
  }

  Future<void> _writeImageStreamToFile(ImageProvider imageProvider, String fileName) async {
    final completer = Completer<String>();
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    
    listener = ImageStreamListener((imageInfo, _) async {
      final byteData = await imageInfo.image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      
      if (bytes != null) {
        await File(fileName).writeAsBytes(bytes);
        if (kDebugMode) print('Image saved: $fileName');
      }
      
      if (!completer.isCompleted) {
        imageStream.removeListener(listener);
        completer.complete(fileName);
      }
    });
    
    imageStream.addListener(listener);
    await completer.future;
  }

  Widget _textWidgetBuilder(types.User user, BuildContext context, bool enlargeEmojis) {
    final theme = InheritedChatTheme.of(context).theme;
    final isUserAuthor = user.id == widget.message.author.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyTextStyle = isUserAuthor ? theme.sentMessageBodyTextStyle : theme.receivedMessageBodyTextStyle;
    final bodyLinkTextStyle = isUserAuthor ? theme.sentMessageBodyLinkTextStyle : theme.receivedMessageBodyLinkTextStyle;
    final boldTextStyle = isUserAuthor ? theme.sentMessageBodyBoldTextStyle : theme.receivedMessageBodyBoldTextStyle;
    final codeTextStyle = isUserAuthor ? theme.sentMessageBodyCodeTextStyle : theme.receivedMessageBodyCodeTextStyle;
    final emojiTextStyle = isUserAuthor ? theme.sentEmojiMessageTextStyle : theme.receivedEmojiMessageTextStyle;

    final markdownConfig = (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig).copy(
      configs: [
        PConfig(textStyle: bodyTextStyle),
        _getPreConfig(isDark),
        const CodeConfig(
          style: TextStyle(
            inherit: false,
            backgroundColor: Colors.transparent,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatarBuilder(),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUserAuthor)
                    MarkdownWidget(
                      key: ValueKey('${widget.message.id}_md'),
                      data: widget.message.text,
                      shrinkWrap: true,
                      selectable: true,
                      padding: EdgeInsets.zero,
                      config: markdownConfig,
                    ),
                  if (isUserAuthor)
                    if (enlargeEmojis)
                      SelectableText(widget.message.text, style: emojiTextStyle)
                    else
                      Padding(padding: const EdgeInsets.only(top:10), child: SelectionArea(
                          child: TextMessageText(
                            bodyLinkTextStyle: bodyLinkTextStyle,
                            bodyTextStyle: bodyTextStyle,
                            boldTextStyle: boldTextStyle,
                            codeTextStyle: codeTextStyle,
                            options: widget.options,
                            text: widget.message.text,
                          ),
                      ),),
                  if (widget.message.previewData?.image?.url != null)
                    _buildImagePreview(context),
                ],
              ),
            ),
          ],
        ),
        _buildExtraBar(),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final previewData = widget.message.previewData!;
    final imageUrl = previewData.image!.url;
    final isBase64Image = RegExp(r'data:image/(png|jpeg|jpg|gif);base64,').hasMatch(imageUrl);
    final imageProvider = isBase64Image
        ? CacheMemoryImageProvider('${widget.message.id}_image_preview', base64Decode(imageUrl.split(',').last))
        : CachedNetworkImageProvider(imageUrl) as ImageProvider;

    return Padding(
      key: ValueKey('${widget.message.id}_image'),
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 4),
      child: InkWell(
        onTap: () => _openDialog(context, imageProvider),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image(
            fit: BoxFit.cover,
            height: previewData.image!.height.toDouble(),
            image: imageProvider,
          ),
        ),
      ),
    );
  }

  Widget _buildExtraBar() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isHovering ? 1.0 : 0.0,
      child: Container(
        padding: EdgeInsets.zero,
        alignment: Alignment.bottomRight,
        child: widget.msgExtraBarBuild?.call(widget.message, context: context),
      ),
    );
  }

  PreConfig _getPreConfig(bool isDark) {
    final language = RegExp(r'```(.*?)\n', dotAll: true).firstMatch(widget.message.text)?.group(1) ?? 'javascript';
    final baseConfig = isDark ? PreConfig.darkConfig : const PreConfig();
    
    return baseConfig.copy(
      textStyle: const TextStyle(fontSize: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1b1b1b) : const Color.fromRGBO(105, 145, 214, 0.1215686275),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      theme: isDark ? githubDarkDimmedTheme : githubTheme,
      wrapper: (child, code, language) => CodeWrapperWidget(child, code, language),
      language: language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enlargeEmojis = widget.emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
        isConsistsOfEmojis(widget.emojiEnlargementBehavior, widget.message);
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        key: ValueKey('${widget.message.id}_text_message_container'),
        padding: EdgeInsets.fromLTRB(theme.messageInsetsHorizontal, theme.messageInsetsVertical * 1.2, theme.messageInsetsHorizontal * 1.4, theme.messageInsetsVertical),
        child: _textWidgetBuilder(user, context, enlargeEmojis),
      ),
    );
  }
}
