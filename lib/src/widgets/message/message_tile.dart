import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/src/widgets/message/text_image_message.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../flutter_chat_ui.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';
import 'text_message_tile.dart';

/// Base widget for all message types in the chat. Renders bubbles around
/// messages and status. Sets maximum width for a message for
/// a nice look on larger screens.
class TileMessage extends Message {
  /// Creates a particular message from any message type.
  const TileMessage({
    super.key,
    super.audioMessageBuilder,
    super.avatarBuilder,
    super.bubbleBuilder,
    super.bubbleRtlAlignment,
    super.customMessageBuilder,
    super.customStatusBuilder,
    required super.emojiEnlargementBehavior,
    super.fileMessageBuilder,
    required super.hideBackgroundOnEmojiMessages,
    super.imageHeaders,
    super.imageMessageBuilder,
    super.imageProviderBuilder,
    required super.message,
    required super.messageWidth,
    super.nameBuilder,
    super.onAvatarTap,
    super.onMessageDoubleTap,
    super.onMessageLongPress,
    super.onMessageStatusLongPress,
    super.onMessageStatusTap,
    super.onMessageTap,
    super.onMessageVisibilityChanged,
    super.onPreviewDataFetched,
    required super.roundBorder,
    required super.showAvatar,
    required super.showName,
    required super.showStatus,
    required super.showUserAvatars,
    super.textMessageBuilder,
    required super.textMessageOptions,
    required super.usePreviewData,
    super.userAgent,
    super.videoMessageBuilder,
    super.msgExtraBarBuild,
  });

  Widget _bubbleBuilder(
    BuildContext context,
    BorderRadius borderRadius,
    bool currentUserIsAuthor,
    bool enlargeEmojis,
  ) =>
      bubbleBuilder != null
          ? bubbleBuilder!(
              _messageBuilder(),
              message: message,
              nextMessageInGroup: roundBorder,
            )
          : enlargeEmojis && hideBackgroundOnEmojiMessages
              ? _messageBuilder()
              : Container(
                  decoration: BoxDecoration(
                    // borderRadius: borderRadius,
                    border: Border(
                      bottom: BorderSide(
                        color: InheritedChatTheme.of(context)
                            .theme
                            .messageBorderColor,
                        width: 1.0,
                      ),
                    ),
                    // Color.fromRGBO(32, 33, 35, .5)
                    color: !currentUserIsAuthor ||
                            message.type == types.MessageType.image
                        ? InheritedChatTheme.of(context).theme.secondaryColor
                        : InheritedChatTheme.of(context).theme.primaryColor,
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: _messageBuilder(),
                  ),
                );

  Widget _messageBuilder() {
    switch (message.type) {
      case types.MessageType.audio:
        final audioMessage = message as types.AudioMessage;
        return audioMessageBuilder != null
            ? audioMessageBuilder!(audioMessage, messageWidth: messageWidth)
            : const SizedBox();
      case types.MessageType.custom:
        final customMessage = message as types.CustomMessage;
        return customMessageBuilder != null
            ? customMessageBuilder!(customMessage, messageWidth: messageWidth)
            : const SizedBox();
      case types.MessageType.file:
        final fileMessage = message as types.FileMessage;
        return fileMessageBuilder != null
            ? fileMessageBuilder!(fileMessage, messageWidth: messageWidth)
            : FileMessage(message: fileMessage);
      case types.MessageType.image:
        final imageMessage = message as types.ImageMessage;
        return imageMessageBuilder != null
            ? imageMessageBuilder!(imageMessage, messageWidth: messageWidth)
            : TextImageMessage(
                imageHeaders: imageHeaders,
                imageProviderBuilder: imageProviderBuilder,
                message: imageMessage,
                messageWidth: messageWidth,
                avatarBuilder: super.avatarBuilder,
              );
      case types.MessageType.text:
        final textMessage = message as types.TextMessage;
        return textMessageBuilder != null
            ? textMessageBuilder!(
                textMessage,
                messageWidth: messageWidth,
                showName: showName,
              )
            : TileTextMessage(
                emojiEnlargementBehavior: emojiEnlargementBehavior,
                hideBackgroundOnEmojiMessages: hideBackgroundOnEmojiMessages,
                message: textMessage,
                nameBuilder: nameBuilder,
                onPreviewDataFetched: onPreviewDataFetched,
                options: textMessageOptions,
                showName: showName,
                usePreviewData: usePreviewData,
                userAgent: userAgent,
                msgExtraBarBuild: msgExtraBarBuild,
                avatarBuilder: super.avatarBuilder,
              );
      case types.MessageType.video:
        final videoMessage = message as types.VideoMessage;
        return videoMessageBuilder != null
            ? videoMessageBuilder!(videoMessage, messageWidth: messageWidth)
            : const SizedBox();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final user = InheritedUser.of(context).user;
    final currentUserIsAuthor = user.id == message.author.id;
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            message is types.TextMessage &&
            isConsistsOfEmojis(
              emojiEnlargementBehavior,
              message as types.TextMessage,
            );
    final messageBorderRadius =
        InheritedChatTheme.of(context).theme.messageBorderRadius;
    final borderRadius = Radius.zero;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      textDirection: bubbleRtlAlignment == BubbleRtlAlignment.left
          ? null
          : TextDirection.ltr,
      children: [
        Expanded(
          child: GestureDetector(
            onDoubleTap: () => onMessageDoubleTap?.call(context, message),
            onLongPress: () => onMessageLongPress?.call(context, message),
            onTap: () => onMessageTap?.call(context, message),
            child: onMessageVisibilityChanged != null
                ? VisibilityDetector(
                    key: Key(message.id),
                    onVisibilityChanged: (visibilityInfo) =>
                        onMessageVisibilityChanged!(
                      message,
                      visibilityInfo.visibleFraction > 0.1,
                    ),
                    child: _bubbleBuilder(
                      context,
                      BorderRadius.zero,
                      currentUserIsAuthor,
                      enlargeEmojis,
                    ),
                  )
                : _bubbleBuilder(
                    context,
                    BorderRadius.zero,
                    currentUserIsAuthor,
                    enlargeEmojis,
                  ),
          ),
        ),
      ],
    );
  }
}
