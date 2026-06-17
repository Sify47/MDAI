// lib/widgets/chat_message_bubble.dart
// تصميم محسن لفقاعات الرسائل باستخدام Material 3

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';
import '../models/chat_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;
  final bool isUser;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTranslate;
  final VoidCallback? onReport;
  final bool showContextMenu;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.theme,
    required this.isUser,
    this.onCopy,
    this.onShare,
    this.onSave,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onTranslate,
    this.onReport,
    this.showContextMenu = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isUser ? _buildUserMessage() : _buildBotMessage();
  }

  Widget _buildUserMessage() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: DesignConstants.spacingLg,
        left: 40,
        right: DesignConstants.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              padding: DesignConstants.edgeInsetsCard,
              decoration: BoxDecoration(
                color: AppColors.userMessage,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignConstants.radiusFeatured),
                  topRight: Radius.circular(DesignConstants.radiusFeatured),
                  bottomLeft: Radius.circular(DesignConstants.radiusFeatured),
                  bottomRight: Radius.circular(DesignConstants.radiusSmall),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.userMessage.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // محتوى الرسالة
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: DesignConstants.spacingSm),
                  
                  // معلومات إضافية
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: DesignConstants.fontSm,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(width: DesignConstants.spacingXs),
                      Icon(
                        Icons.done_all,
                        size: DesignConstants.iconSmall,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ),
                  
                  // إجراءات السياق للمستخدم
                  if (showContextMenu && (onCopy != null || onShare != null || onEdit != null || onDelete != null))
                    Padding(
                      padding: EdgeInsets.only(top: DesignConstants.spacingSm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onCopy != null)
                            _buildActionButton(
                              icon: Icons.content_copy,
                              color: Colors.white,
                              onTap: onCopy!,
                            ),
                          if (onShare != null)
                            _buildActionButton(
                              icon: Icons.share,
                              color: Colors.white,
                              onTap: onShare!,
                            ),
                          if (onEdit != null)
                            _buildActionButton(
                              icon: Icons.edit,
                              color: Colors.white,
                              onTap: onEdit!,
                            ),
                          if (onDelete != null)
                            _buildActionButton(
                              icon: Icons.delete,
                              color: Colors.white,
                              onTap: onDelete!,
                            ),
                          
                          // قائمة السياق المتقدمة للمستخدم
                          if (showContextMenu && (onReply != null || onTranslate != null || onReport != null))
                            _buildContextMenuButton(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: DesignConstants.spacingLg),
          
          // صورة المستخدم
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.userMessageContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.userMessage.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                color: AppColors.userMessage,
                size: DesignConstants.iconMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage() {
    final source = message.metadata?['source'] ?? 'general';
    final sourceColor = _getSourceColor(source);
    final sourceIcon = _getSourceIcon(source);
    final sourceName = _getSourceName(source);
    final confidence = (message.metadata?['confidence'] as double?) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: DesignConstants.spacingLg,
        left: DesignConstants.spacingSm,
        right: 40,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة البوت
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.botMessageContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.botMessage.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🤖',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SizedBox(width: DesignConstants.spacingLg),
          
          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              padding: DesignConstants.edgeInsetsCard,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignConstants.radiusSmall),
                  topRight: Radius.circular(DesignConstants.radiusFeatured),
                  bottomLeft: Radius.circular(DesignConstants.radiusFeatured),
                  bottomRight: Radius.circular(DesignConstants.radiusFeatured),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: AppColors.botMessageContainer.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس الرسالة مع المصدر
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          message.title ?? 'إجابة المساعد الصحي',
                          style: const TextStyle(
                            fontSize: DesignConstants.fontLg,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: DesignConstants.spacingSm),
                      
                      // شارة المصدر
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.paddingCompact,
                          vertical: DesignConstants.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: sourceColor.withOpacity(0.1),
                          borderRadius: DesignConstants.borderRadiusButton,
                          border: Border.all(
                            color: sourceColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sourceIcon,
                              style: TextStyle(fontSize: DesignConstants.fontSm),
                            ),
                            SizedBox(width: DesignConstants.spacingXs),
                            Text(
                              sourceName,
                              style: TextStyle(
                                fontSize: DesignConstants.fontSm,
                                fontWeight: FontWeight.w600,
                                color: sourceColor,
                              ),
                            ),
                            if (confidence > 0) ...[
                              SizedBox(width: DesignConstants.spacingXs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.spacingXs,
                                  vertical: DesignConstants.spacingXs - 2,
                                ),
                                decoration: BoxDecoration(
                                  color: sourceColor.withOpacity(0.2),
                                  borderRadius: DesignConstants.borderRadiusSmall,
                                ),
                                child: Text(
                                  '${(confidence * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: DesignConstants.fontXs,
                                    fontWeight: FontWeight.bold,
                                    color: sourceColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: DesignConstants.spacingMd),
                  
                  // محتوى الرسالة
                  if (message.content.isNotEmpty &&
                      message.content != message.title) ...[
                    Text(
                      message.content,
                      style: const TextStyle(
                        fontSize: DesignConstants.fontMd,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: DesignConstants.spacingMd),
                  ],
                  
                  // النقاط الفرعية
                  if (message.bullets != null && message.bullets!.isNotEmpty) ...[
                    ..._buildBulletPoints(),
                    SizedBox(height: DesignConstants.spacingMd),
                  ],
                  
                  // تذييل الرسالة مع الإجراءات
                  Row(
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: const TextStyle(
                          fontSize: DesignConstants.fontSm,
                          color: AppColors.textHint,
                        ),
                      ),
                      const Spacer(),
                      
                      // إجراءات السياق الأساسية
                      if (showContextMenu && (onCopy != null || onShare != null || onSave != null))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onCopy != null)
                              _buildActionButton(
                                icon: Icons.content_copy,
                                color: AppColors.primary,
                                onTap: onCopy!,
                              ),
                            if (onShare != null)
                              _buildActionButton(
                                icon: Icons.share,
                                color: AppColors.secondary,
                                onTap: onShare!,
                              ),
                            if (onSave != null)
                              _buildActionButton(
                                icon: Icons.bookmark,
                                color: AppColors.tertiary,
                                onTap: onSave!,
                              ),
                          ],
                        ),
                      
                      // قائمة السياق المتقدمة
                      if (showContextMenu && (onReply != null || onEdit != null || onDelete != null || onTranslate != null || onReport != null))
                        _buildContextMenuButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBulletPoints() {
    List<Widget> bulletWidgets = [];
    
    for (var bullet in message.bullets!) {
      if (bullet.trim().isEmpty) continue;
      
      // إذا كانت النقطة عنوان فرعي
      if (bullet.trim().endsWith(':') ||
          (bullet.trim().endsWith('؟') == false &&
              bullet.length < 30 &&
              !bullet.startsWith('•'))) {
        bulletWidgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: DesignConstants.spacingSm,
              bottom: DesignConstants.spacingXs,
            ),
            child: Text(
              bullet.trim(),
              style: const TextStyle(
                fontSize: DesignConstants.fontMd,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      } else {
        String displayBullet = bullet.trim();
        if (!displayBullet.startsWith('•') &&
            !displayBullet.startsWith('-') &&
            !displayBullet.startsWith('*')) {
          displayBullet = '• $displayBullet';
        }
        
        bulletWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: DesignConstants.spacingXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(
                    fontSize: DesignConstants.fontMd,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: DesignConstants.paddingCompact),
                Expanded(
                  child: Text(
                    displayBullet.substring(1).trim(),
                    style: const TextStyle(
                      fontSize: DesignConstants.fontMd,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return bulletWidgets;
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: DesignConstants.spacingSm),
        padding: DesignConstants.edgeInsetsCompact,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: DesignConstants.iconSmall,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContextMenuButton() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        margin: EdgeInsets.only(left: DesignConstants.spacingSm),
        padding: DesignConstants.edgeInsetsCompact,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert,
          size: DesignConstants.iconSmall,
          color: AppColors.primary,
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (onReply != null)
          PopupMenuItem<String>(
            value: 'reply',
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text('رد'),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.secondary,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text('تعديل'),
              ],
            ),
          ),
        if (onCopy != null)
          PopupMenuItem<String>(
            value: 'copy',
            child: Row(
              children: [
                Icon(
                  Icons.content_copy,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text('نسخ'),
              ],
            ),
          ),
        if (onShare != null)
          PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  size: 18,
                  color: AppColors.secondary,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text('مشاركة'),
              ],
            ),
          ),
        if (onSave != null)
          PopupMenuItem<String>(
            value: 'save',
            child: Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 18,
                  color: AppColors.tertiary,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text('حفظ'),
              ],
            ),
          ),
        if (onTranslate != null)
          PopupMenuItem<String>(
            value: 'translate',
            child: Row(
              children: [
                Icon(
                  Icons.translate,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text('ترجمة'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        if (onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete,
                  size: 18,
                  color: AppColors.danger,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text(
                  'حذف',
                  style: TextStyle(color: AppColors.danger),
                ),
              ],
            ),
          ),
        if (onReport != null)
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 18,
                  color: AppColors.warning,
                ),
                SizedBox(width: DesignConstants.spacingSm),
                const Text(
                  'الإبلاغ',
                  style: TextStyle(color: AppColors.warning),
                ),
              ],
            ),
          ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'reply':
            onReply?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'copy':
            onCopy?.call();
            break;
          case 'share':
            onShare?.call();
            break;
          case 'save':
            onSave?.call();
            break;
          case 'translate':
            onTranslate?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
          case 'report':
            onReport?.call();
            break;
        }
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعة';
    } else {
      return '${difference.inDays} يوم';
    }
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'medical':
        return AppColors.danger;
      case 'nutrition':
        return AppColors.success;
      case 'fitness':
        return AppColors.primary;
      case 'general':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  String _getSourceIcon(String source) {
    switch (source) {
      case 'medical':
        return '🏥';
      case 'nutrition':
        return '🥗';
      case 'fitness':
        return '🏃';
      case 'general':
        return '🤖';
      default:
        return '📚';
    }
  }

  String _getSourceName(String source) {
    switch (source) {
      case 'medical':
        return 'طبي';
      case 'nutrition':
        return 'تغذية';
      case 'fitness':
        return 'رياضة';
      case 'general':
        return 'عام';
      default:
        return 'مصدر';
    }
  }
}