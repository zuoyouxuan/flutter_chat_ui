import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../../flutter_chat_ui.dart';
import '../../conditional/conditional.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';

/// A class that represents image message widget. Supports different
/// aspect ratios, renders blurred image as a background which is visible
/// if the image is narrow, renders image in form of a file if aspect
/// ratio is very small or very big.
class TextImageMessage extends StatefulWidget {
  /// Creates an image message widget based on [types.ImageMessage].
  const TextImageMessage({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.message,
    required this.messageWidth,
    this.avatarBuilder,
  });

  final Widget Function(types.User author)? avatarBuilder;

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })? imageProviderBuilder;

  /// [types.ImageMessage].
  final types.ImageMessage message;

  /// Maximum message width.
  final int messageWidth;

  @override
  State<TextImageMessage> createState() => _ImageMessageState();
}

/// [ImageMessage] widget state.
class _ImageMessageState extends State<TextImageMessage> {
  ImageProvider? _image;
  Size _size = Size.zero;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    _image = widget.imageProviderBuilder != null
        ? widget.imageProviderBuilder!(
            uri: widget.message.uri,
            imageHeaders: widget.imageHeaders,
            conditional: Conditional(),
          )
        : Conditional().getProvider(
            widget.message.uri,
            headers: widget.imageHeaders,
          );
    _size = Size(widget.message.width ?? 0, widget.message.height ?? 0);
  }

  void _getImage() {
    final oldImageStream = _stream;
    _stream = _image?.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == oldImageStream?.key) {
      return;
    }
    final listener = ImageStreamListener(_updateImage);
    oldImageStream?.removeListener(listener);
    _stream?.addListener(listener);
  }

  void _updateImage(ImageInfo info, bool _) {
    setState(() {
      _size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_size.isEmpty) {
      _getImage();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }

  Widget _avatarBuilder() =>
      widget.avatarBuilder?.call(widget.message.author) ??
      UserAvatar(
        author: widget.message.author,
      );

  @override
  Widget build(BuildContext context) {
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    if (_size.aspectRatio == 0) {
      return Container(
        color: InheritedChatTheme.of(context).theme.secondaryColor,
        height: _size.height,
        width: _size.width,
      );
    } else if (_size.aspectRatio < 0.1 || _size.aspectRatio > 10) {
      return Container(
        color: user.id == widget.message.author.id
            ? InheritedChatTheme.of(context).theme.primaryColor
            : InheritedChatTheme.of(context).theme.secondaryColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: 64,
              margin: EdgeInsetsDirectional.fromSTEB(
                InheritedChatTheme.of(context).theme.messageInsetsVertical,
                InheritedChatTheme.of(context).theme.messageInsetsVertical,
                16,
                InheritedChatTheme.of(context).theme.messageInsetsVertical,
              ),
              width: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image(
                  fit: BoxFit.cover,
                  image: _image!,
                ),
              ),
            ),
            Flexible(
              child: Container(
                margin: EdgeInsetsDirectional.fromSTEB(
                  0,
                  InheritedChatTheme.of(context).theme.messageInsetsVertical,
                  InheritedChatTheme.of(context).theme.messageInsetsHorizontal,
                  InheritedChatTheme.of(context).theme.messageInsetsVertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.name,
                      style: user.id == widget.message.author.id
                          ? InheritedChatTheme.of(context)
                              .theme
                              .sentMessageBodyTextStyle
                          : InheritedChatTheme.of(context)
                              .theme
                              .receivedMessageBodyTextStyle,
                      textWidthBasis: TextWidthBasis.longestLine,
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 4,
                      ),
                      child: Text(
                        formatBytes(widget.message.size.truncate()),
                        style: user.id == widget.message.author.id
                            ? InheritedChatTheme.of(context)
                                .theme
                                .sentMessageCaptionTextStyle
                            : InheritedChatTheme.of(context)
                                .theme
                                .receivedMessageCaptionTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.only(
          bottom: 8,
          top: 8,
        ),
        margin: EdgeInsets.fromLTRB(theme.messageInsetsHorizontal,
            theme.messageInsetsVertical, theme.messageInsetsHorizontal, 0),
        constraints: BoxConstraints(
          maxHeight: widget.messageWidth.toDouble(),
          minWidth: 170,
        ),
        // child: Stack(
        //   children: [
        //     Positioned(
        //       left: 0,
        //       top: 0,
        //       child: _avatarBuilder(),
        //     ),
        //     Padding(
        //       padding: const EdgeInsets.all(35),
        //       child: Image(
        //         fit: BoxFit.cover,
        //         image: _image!,
        //         width: 120,
        //       ),
        //     ),
        //   ],
        // ),
        //
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatarBuilder(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(theme.messageInsetsHorizontal,
                      theme.messageInsetsVertical, theme.messageInsetsHorizontal, 0),
                  child: TextMessageText(
                    text: 'message.text', bodyTextStyle: theme.sentMessageBodyTextStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child:  Image(
                      fit: BoxFit.cover,
                      image: _image!,
                      width: 120,
                    ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
