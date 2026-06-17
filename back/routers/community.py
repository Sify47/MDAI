# backend/routers/community.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional
from datetime import datetime, timedelta

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/api/community", tags=["community"])


# ============================================
# 1. إنشاء منشور جديد
# ============================================
@router.post("/posts", response_model=schemas.CommunityPostResponse, status_code=201)
def create_post(
    post_data: schemas.CommunityPostCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إنشاء منشور جديد في المجتمع"""
    print(f"📝 [Community] إنشاء منشور جديد للمستخدم {current_user.id}")

    # تحديد المجموعة بناءً على group_id إذا تم توفيره
    group = None
    if post_data.group_id:
        group = db.query(models.CommunityGroup).filter(models.CommunityGroup.id == post_data.group_id).first()
        if not group:
            raise HTTPException(status_code=404, detail="المجموعة غير موجودة")
    
    # إذا لم يتم توفير group_id، نبحث عن المجموعة بناءً على category
    if not group:
        group = (
            db.query(models.CommunityGroup)
            .filter(models.CommunityGroup.condition_tag == post_data.category)
            .first()
        )

    post = models.CommunityPost(
        user_id=current_user.id,
        group_id=post_data.group_id,
        title=post_data.title,
        content=post_data.content,
        post_type=post_data.post_type,
        category=post_data.category,
        is_anonymous=post_data.is_anonymous,
    )

    db.add(post)

    # زيادة عدد المنشورات في المجموعة المناسبة
    if group:
        group.posts_count += 1

    db.commit()
    db.refresh(post)

    # تحويل النتيجة إلى JSON
    result = {
        "id": post.id,
        "user_id": post.user_id,
        "group_id": post.group_id,
        "title": post.title,
        "content": post.content,
        "post_type": post.post_type,
        "category": post.category,
        "group_name": group.name if group else None,
        "group_icon": group.icon if group else None,
        "is_anonymous": post.is_anonymous,
        "is_featured": getattr(post, "is_featured", False),
        "likes_count": getattr(post, "likes_count", 0),
        "comments_count": getattr(post, "comments_count", 0),
        "views_count": getattr(post, "views_count", 0),
        "created_at": post.created_at.isoformat() if post.created_at else None,
        "updated_at": post.updated_at.isoformat() if post.updated_at else None,
        "author": {
            "id": current_user.id,
            "name": "مستخدم مجهول" if post_data.is_anonymous else current_user.name,
            "is_verified": getattr(current_user, "is_verified", False),
        },
    }

    return result


# ============================================
# 2. جلب المنشورات
# ============================================
@router.get("/posts")
def get_posts(
    category: Optional[str] = None,
    post_type: Optional[str] = None,
    featured: Optional[bool] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب المنشورات من المجتمع"""
    print(f"📋 [Community] جلب المنشورات للمستخدم {current_user.id}")

    query = db.query(models.CommunityPost)

    if category:
        query = query.filter(models.CommunityPost.category == category)

    if post_type:
        query = query.filter(models.CommunityPost.post_type == post_type)

    if featured is not None:
        query = query.filter(models.CommunityPost.is_featured == featured)

    posts = (
        query.order_by(models.CommunityPost.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    # تحويل النتيجة إلى JSON مع معلومات المستخدم
    result = []
    for post in posts:
        # جلب معلومات المستخدم
        user = db.query(models.User).filter(models.User.id == post.user_id).first()

        post_dict = {
            "id": post.id,
            "user_id": post.user_id,
            "title": post.title,
            "content": post.content,
            "post_type": post.post_type,
            "category": post.category,
            "is_anonymous": post.is_anonymous,
            "is_featured": getattr(post, "is_featured", False),
            "likes_count": getattr(post, "likes_count", 0),
            "comments_count": getattr(post, "comments_count", 0),
            "views_count": getattr(post, "views_count", 0),
            "created_at": post.created_at.isoformat() if post.created_at else None,
            "updated_at": post.updated_at.isoformat() if post.updated_at else None,
            "author": {
                "id": user.id if user else 0,
                "name": (
                    "مستخدم مجهول"
                    if post.is_anonymous
                    else (user.name if user else "مستخدم")
                ),
                "is_verified": (
                    user.is_verified if user and not post.is_anonymous else False
                ),
            },
        }
        result.append(post_dict)

    return result


# ============================================
# 3. جلب منشور معين
# ============================================
@router.get("/posts/{post_id}")
def get_post(
    post_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب منشور معين"""
    print(f"📋 [Community] جلب المنشور {post_id} للمستخدم {current_user.id}")

    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )

    if not post:
        raise HTTPException(status_code=404, detail="المنشور غير موجود")

    # زيادة عدد المشاهدات
    if hasattr(post, "views_count"):
        post.views_count += 1
        db.commit()
        db.refresh(post)

    # جلب معلومات المستخدم
    user = db.query(models.User).filter(models.User.id == post.user_id).first()

    result = {
        "id": post.id,
        "user_id": post.user_id,
        "title": post.title,
        "content": post.content,
        "post_type": post.post_type,
        "category": post.category,
        "is_anonymous": post.is_anonymous,
        "is_featured": getattr(post, "is_featured", False),
        "likes_count": getattr(post, "likes_count", 0),
        "comments_count": getattr(post, "comments_count", 0),
        "views_count": getattr(post, "views_count", 0),
        "created_at": post.created_at.isoformat() if post.created_at else None,
        "updated_at": post.updated_at.isoformat() if post.updated_at else None,
        "author": {
            "id": user.id if user else 0,
            "name": (
                "مستخدم مجهول"
                if post.is_anonymous
                else (user.name if user else "مستخدم")
            ),
            "is_verified": (
                user.is_verified if user and not post.is_anonymous else False
            ),
        },
    }

    return result


# ============================================
# 4. تحديث منشور
# ============================================
@router.put("/posts/{post_id}")
def update_post(
    post_id: int,
    post_data: schemas.CommunityPostCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تحديث منشور"""
    print(f"📝 [Community] تحديث المنشور {post_id} للمستخدم {current_user.id}")

    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )

    if not post:
        raise HTTPException(status_code=404, detail="المنشور غير موجود")

    if post.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="غير مصرح لك بتحديث هذا المنشور")

    post.title = post_data.title
    post.content = post_data.content
    post.post_type = post_data.post_type
    post.category = post_data.category
    post.is_anonymous = post_data.is_anonymous
    post.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(post)

    # جلب معلومات المستخدم
    user = db.query(models.User).filter(models.User.id == post.user_id).first()

    result = {
        "id": post.id,
        "user_id": post.user_id,
        "title": post.title,
        "content": post.content,
        "post_type": post.post_type,
        "category": post.category,
        "is_anonymous": post.is_anonymous,
        "is_featured": getattr(post, "is_featured", False),
        "likes_count": getattr(post, "likes_count", 0),
        "comments_count": getattr(post, "comments_count", 0),
        "views_count": getattr(post, "views_count", 0),
        "created_at": post.created_at.isoformat() if post.created_at else None,
        "updated_at": post.updated_at.isoformat() if post.updated_at else None,
        "author": {
            "id": user.id if user else 0,
            "name": (
                "مستخدم مجهول"
                if post.is_anonymous
                else (user.name if user else "مستخدم")
            ),
            "is_verified": (
                user.is_verified if user and not post.is_anonymous else False
            ),
        },
    }

    return result


# ============================================
# 5. حذف منشور
# ============================================
@router.delete("/posts/{post_id}")
def delete_post(
    post_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حذف منشور"""
    print(f"🗑️ [Community] حذف المنشور {post_id} للمستخدم {current_user.id}")

    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )

    if not post:
        raise HTTPException(status_code=404, detail="المنشور غير موجود")

    if post.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="غير مصرح لك بحذف هذا المنشور")

    # حذف التعليقات المرتبطة أولاً
    db.query(models.CommunityComment).filter(
        models.CommunityComment.post_id == post_id
    ).delete()

    # حذف الإعجابات المرتبطة
    db.query(models.CommunityLike).filter(
        models.CommunityLike.post_id == post_id
    ).delete()

    # حذف المنشور
    db.delete(post)
    db.commit()

    return {"message": "تم حذف المنشور بنجاح"}


# ============================================
# 6. إنشاء تعليق
# ============================================
@router.post("/posts/{post_id}/comments", status_code=201)
def create_comment(
    post_id: int,
    comment_data: schemas.CommunityCommentCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إنشاء تعليق على منشور"""
    print(
        f"💬 [Community] إنشاء تعليق للمستخدم {current_user.id} على المنشور {post_id}"
    )

    # التحقق من وجود المنشور
    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="المنشور غير موجود")

    comment = models.CommunityComment(
        user_id=current_user.id,
        post_id=post_id,
        content=comment_data.content,
        parent_comment_id=comment_data.parent_comment_id,
    )

    # زيادة عدد التعليقات في المنشور
    if hasattr(post, "comments_count"):
        post.comments_count += 1

    db.add(comment)
    db.commit()
    db.refresh(comment)

    # جلب معلومات المستخدم
    user = db.query(models.User).filter(models.User.id == current_user.id).first()

    result = {
        "id": comment.id,
        "user_id": comment.user_id,
        "post_id": comment.post_id,
        "content": comment.content,
        "parent_comment_id": comment.parent_comment_id,
        "likes_count": getattr(comment, "likes_count", 0),
        "is_helpful": getattr(comment, "is_helpful", False),
        "created_at": comment.created_at.isoformat() if comment.created_at else None,
        "updated_at": comment.updated_at.isoformat() if comment.updated_at else None,
        "author": {
            "id": user.id if user else 0,
            "name": user.name if user else "مستخدم",
            "is_verified": getattr(user, "is_verified", False) if user else False,
        },
        "replies": [],
    }

    return result


# ============================================
# 7. جلب تعليقات منشور
# ============================================
@router.get("/posts/{post_id}/comments")
def get_post_comments(
    post_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب تعليقات منشور معين"""
    print(f"📋 [Community] جلب تعليقات المنشور {post_id} للمستخدم {current_user.id}")

    # جلب التعليقات الرئيسية (بدون parent)
    comments = (
        db.query(models.CommunityComment)
        .filter(
            models.CommunityComment.post_id == post_id,
            models.CommunityComment.parent_comment_id.is_(None),
        )
        .order_by(models.CommunityComment.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    result = []
    for comment in comments:
        # جلب معلومات المستخدم للتعليق
        user = db.query(models.User).filter(models.User.id == comment.user_id).first()

        # جلب الردود
        replies = (
            db.query(models.CommunityComment)
            .filter(models.CommunityComment.parent_comment_id == comment.id)
            .order_by(models.CommunityComment.created_at.asc())
            .all()
        )

        replies_list = []
        for reply in replies:
            reply_user = (
                db.query(models.User).filter(models.User.id == reply.user_id).first()
            )
            replies_list.append(
                {
                    "id": reply.id,
                    "user_id": reply.user_id,
                    "post_id": reply.post_id,
                    "content": reply.content,
                    "parent_comment_id": reply.parent_comment_id,
                    "likes_count": getattr(reply, "likes_count", 0),
                    "is_helpful": getattr(reply, "is_helpful", False),
                    "created_at": (
                        reply.created_at.isoformat() if reply.created_at else None
                    ),
                    "updated_at": (
                        reply.updated_at.isoformat() if reply.updated_at else None
                    ),
                    "author": {
                        "id": reply_user.id if reply_user else 0,
                        "name": reply_user.name if reply_user else "مستخدم",
                        "is_verified": (
                            getattr(reply_user, "is_verified", False)
                            if reply_user
                            else False
                        ),
                    },
                    "replies": [],
                }
            )

        comment_dict = {
            "id": comment.id,
            "user_id": comment.user_id,
            "post_id": comment.post_id,
            "content": comment.content,
            "parent_comment_id": comment.parent_comment_id,
            "likes_count": getattr(comment, "likes_count", 0),
            "is_helpful": getattr(comment, "is_helpful", False),
            "created_at": (
                comment.created_at.isoformat() if comment.created_at else None
            ),
            "updated_at": (
                comment.updated_at.isoformat() if comment.updated_at else None
            ),
            "author": {
                "id": user.id if user else 0,
                "name": user.name if user else "مستخدم",
                "is_verified": getattr(user, "is_verified", False) if user else False,
            },
            "replies": replies_list,
        }
        result.append(comment_dict)

    return result


# ============================================
# 8. تمييز تعليق كمفيد
# ============================================
@router.post("/comments/{comment_id}/helpful")
def mark_comment_helpful(
    comment_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تمييز تعليق كمفيد"""
    print(f"👍 [Community] تمييز التعليق {comment_id} كمفيد للمستخدم {current_user.id}")

    comment = (
        db.query(models.CommunityComment)
        .filter(models.CommunityComment.id == comment_id)
        .first()
    )

    if not comment:
        raise HTTPException(status_code=404, detail="التعليق غير موجود")

    comment.is_helpful = True
    if hasattr(comment, "likes_count"):
        comment.likes_count += 1

    db.commit()

    return {"message": "تم تمييز التعليق كمفيد"}


# ============================================
# 9. إضافة تفاعل (إعجاب)
# ============================================
@router.post("/posts/{post_id}/reactions", status_code=201)
def add_reaction(
    post_id: int,
    reaction_data: schemas.CommunityReactionCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إضافة تفاعل على منشور"""
    print(
        f"❤️ [Community] إضافة تفاعل للمستخدم {current_user.id} على المنشور {post_id}"
    )

    # التحقق من وجود المنشور
    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="المنشور غير موجود")

    # التحقق من عدم تكرار التفاعل
    existing_like = (
        db.query(models.CommunityLike)
        .filter(
            models.CommunityLike.user_id == current_user.id,
            models.CommunityLike.post_id == post_id,
        )
        .first()
    )

    if existing_like:
        raise HTTPException(status_code=400, detail="لقد تفاعلت مع هذا المنشور بالفعل")

    # زيادة عدد الإعجابات في المنشور
    if hasattr(post, "likes_count"):
        post.likes_count += 1

    like = models.CommunityLike(
        user_id=current_user.id,
        post_id=post_id,
        reaction_type=reaction_data.reaction_type,
    )

    db.add(like)
    db.commit()

    return {
        "message": "تمت إضافة التفاعل بنجاح",
        "likes_count": post.likes_count if hasattr(post, "likes_count") else 0,
    }


# ============================================
# 10. إزالة تفاعل
# ============================================
@router.delete("/posts/{post_id}/reactions")
def remove_reaction(
    post_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إزالة تفاعل من منشور"""
    print(f"💔 [Community] إزالة تفاعل المستخدم {current_user.id} من المنشور {post_id}")

    like = (
        db.query(models.CommunityLike)
        .filter(
            models.CommunityLike.user_id == current_user.id,
            models.CommunityLike.post_id == post_id,
        )
        .first()
    )

    if not like:
        raise HTTPException(status_code=404, detail="لم تجد تفاعلاً")

    # تقليل عدد الإعجابات في المنشور
    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )
    if post and hasattr(post, "likes_count") and post.likes_count > 0:
        post.likes_count -= 1

    db.delete(like)
    db.commit()

    return {
        "message": "تمت إزالة التفاعل بنجاح",
        "likes_count": post.likes_count if post and hasattr(post, "likes_count") else 0,
    }


# ============================================
# 11. إحصائيات المجتمع
# ============================================
@router.get("/stats/community")
def get_community_stats(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب إحصائيات المجتمع"""
    print(f"📊 [Community] جلب إحصائيات المجتمع للمستخدم {current_user.id}")

    total_posts = db.query(func.count(models.CommunityPost.id)).scalar() or 0
    total_comments = db.query(func.count(models.CommunityComment.id)).scalar() or 0
    total_likes = db.query(func.count(models.CommunityLike.id)).scalar() or 0

    # حساب نسبة التفاعل
    engagement_rate = 0
    if total_posts > 0:
        engagement_rate = (total_comments + total_likes) / (total_posts * 10)
        engagement_rate = min(engagement_rate, 1.0)

    return {
        "totalPosts": total_posts,
        "totalComments": total_comments,
        "totalLikes": total_likes,
        "engagementRate": engagement_rate,
    }


# ============================================
# 12. إحصائيات المستخدم
# ============================================
@router.get("/stats/user")
def get_user_stats(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب إحصائيات المستخدم"""
    print(f"📊 [Community] جلب إحصائيات المستخدم {current_user.id}")

    user_posts_count = (
        db.query(func.count(models.CommunityPost.id))
        .filter(models.CommunityPost.user_id == current_user.id)
        .scalar()
        or 0
    )
    user_comments_count = (
        db.query(func.count(models.CommunityComment.id))
        .filter(models.CommunityComment.user_id == current_user.id)
        .scalar()
        or 0
    )
    user_likes_count = (
        db.query(func.count(models.CommunityLike.id))
        .filter(models.CommunityLike.user_id == current_user.id)
        .scalar()
        or 0
    )

    return {
        "userPostsCount": user_posts_count,
        "userCommentsCount": user_comments_count,
        "userLikesCount": user_likes_count,
    }


# ============================================
# 13. جلب الإشعارات
# ============================================
@router.get("/notifications")
def get_notifications(
    unread_only: bool = False,
    limit: int = Query(20, ge=1, le=50),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب إشعارات المجتمع للمستخدم"""
    print(f"🔔 [Community] جلب إشعارات المجتمع للمستخدم {current_user.id}")

    notifications = []

    # جلب التعليقات الجديدة على منشورات المستخدم
    user_posts = (
        db.query(models.CommunityPost.id)
        .filter(models.CommunityPost.user_id == current_user.id)
        .all()
    )
    user_posts_ids = [p[0] for p in user_posts]

    if user_posts_ids:
        recent_comments = (
            db.query(models.CommunityComment)
            .filter(
                models.CommunityComment.post_id.in_(user_posts_ids),
                models.CommunityComment.user_id != current_user.id,
            )
            .order_by(models.CommunityComment.created_at.desc())
            .limit(limit)
            .all()
        )

        for comment in recent_comments:
            comment_user = (
                db.query(models.User).filter(models.User.id == comment.user_id).first()
            )
            notifications.append(
                {
                    "id": comment.id,
                    "type": "comment",
                    "message": f"@{comment_user.name if comment_user else 'مستخدم'} علق على منشورك: {comment.content[:50]}...",
                    "created_at": (
                        comment.created_at.isoformat() if comment.created_at else None
                    ),
                    "is_read": False,
                    "data": {
                        "post_id": comment.post_id,
                        "comment_id": comment.id,
                    },
                }
            )

    # جلب الإعجابات الجديدة على منشورات المستخدم
    if user_posts_ids:
        recent_likes = (
            db.query(models.CommunityLike)
            .filter(
                models.CommunityLike.post_id.in_(user_posts_ids),
                models.CommunityLike.user_id != current_user.id,
            )
            .order_by(models.CommunityLike.created_at.desc())
            .limit(limit)
            .all()
        )

        for like in recent_likes:
            like_user = (
                db.query(models.User).filter(models.User.id == like.user_id).first()
            )
            post = (
                db.query(models.CommunityPost)
                .filter(models.CommunityPost.id == like.post_id)
                .first()
            )
            notifications.append(
                {
                    "id": like.id,
                    "type": "reaction",
                    "message": f"@{like_user.name if like_user else 'مستخدم'} أعجب بمنشورك: {post.title[:50] if post else ''}",
                    "created_at": (
                        like.created_at.isoformat() if like.created_at else None
                    ),
                    "is_read": False,
                    "data": {
                        "post_id": like.post_id,
                        "like_id": like.id,
                    },
                }
            )

    # ترتيب الإشعارات حسب التاريخ
    notifications.sort(
        key=lambda x: x["created_at"] if x["created_at"] else "", reverse=True
    )

    if unread_only:
        notifications = [n for n in notifications if not n["is_read"]]

    return notifications[:limit]


# backend/routers/community.py - أضف هذه الدوال


# ============================================
# التحقق من حالة الإعجاب لمنشور
# ============================================
@router.get("/posts/{post_id}/reaction-status")
def get_reaction_status(
    post_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """التحقق مما إذا كان المستخدم قد تفاعل مع منشور معين"""
    print(
        f"🔍 [Community] التحقق من حالة التفاعل للمستخدم {current_user.id} على المنشور {post_id}"
    )

    existing_like = (
        db.query(models.CommunityLike)
        .filter(
            models.CommunityLike.user_id == current_user.id,
            models.CommunityLike.post_id == post_id,
        )
        .first()
    )

    return {
        "has_reacted": existing_like is not None,
        "like_id": existing_like.id if existing_like else None,
    }


# ============================================
# تبديل حالة الإعجاب (تضيف أو تزيل)
# ============================================
@router.post("/posts/{post_id}/toggle-reaction")
def toggle_reaction(
    post_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تبديل حالة الإعجاب (إضافة إذا لم يكن موجوداً، إزالة إذا كان موجوداً)"""
    print(
        f"🔄 [Community] تبديل حالة التفاعل للمستخدم {current_user.id} على المنشور {post_id}"
    )

    # التحقق من وجود المنشور
    post = (
        db.query(models.CommunityPost)
        .filter(models.CommunityPost.id == post_id)
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="المنشور غير موجود")

    # التحقق من وجود تفاعل سابق
    existing_like = (
        db.query(models.CommunityLike)
        .filter(
            models.CommunityLike.user_id == current_user.id,
            models.CommunityLike.post_id == post_id,
        )
        .first()
    )

    if existing_like:
        # إزالة التفاعل
        if hasattr(post, "likes_count") and post.likes_count > 0:
            post.likes_count -= 1

        db.delete(existing_like)
        db.commit()

        return {
            "message": "تمت إزالة التفاعل بنجاح",
            "likes_count": post.likes_count if hasattr(post, "likes_count") else 0,
            "has_reacted": False,
        }
    else:
        # إضافة تفاعل جديد
        if hasattr(post, "likes_count"):
            post.likes_count += 1

        like = models.CommunityLike(
            user_id=current_user.id,
            post_id=post_id,
        )

        db.add(like)
        db.commit()

        return {
            "message": "تمت إضافة التفاعل بنجاح",
            "likes_count": post.likes_count if hasattr(post, "likes_count") else 0,
            "has_reacted": True,
        }


# backend/routers/community.py - أضف هذه الدوال في نهاية الملف

# ============================================
# 14. المجموعات (Groups)
# ============================================


@router.get("/groups", response_model=List[schemas.CommunityGroupResponse])
def get_groups(
    condition_tag: Optional[str] = None,
    joined_only: Optional[bool] = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب المجموعات المتاحة"""
    print(f"📋 [Community] جلب المجموعات للمستخدم {current_user.id}")

    # بناء الاستعلام الأساسي
    query = db.query(models.CommunityGroup)

    # تصفية حسب condition_tag إذا وجد
    if condition_tag:
        query = query.filter(models.CommunityGroup.condition_tag == condition_tag)

    # تصفية حسب joined_only إذا وجد
    if joined_only:
        # جلب المجموعات التي انضم إليها المستخدم
        query = query.join(
            models.CommunityGroupMember,
            models.CommunityGroupMember.group_id == models.CommunityGroup.id,
        ).filter(models.CommunityGroupMember.user_id == current_user.id)

    # ترتيب حسب عدد الأعضاء (تنازلي)
    query = query.order_by(models.CommunityGroup.members_count.desc())

    # تطبيق pagination
    groups = query.offset(offset).limit(limit).all()

    # تحويل النتائج إلى قاموس مع إضافة حقل is_joined
    result = []
    for group in groups:
        group_dict = group.to_dict()

        # التحقق مما إذا كان المستخدم منضم للمجموعة
        is_joined = (
            db.query(models.CommunityGroupMember)
            .filter(
                models.CommunityGroupMember.user_id == current_user.id,
                models.CommunityGroupMember.group_id == group.id,
            )
            .first()
            is not None
        )

        group_dict["is_joined"] = is_joined

        # إضافة الحقول المطلوبة للاستجابة
        group_dict["rules"] = group.rules or []
        group_dict["created_at"] = group.created_at

        result.append(group_dict)

    return result


@router.post("/groups/{group_id}/join")
def join_group(
    group_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """الانضمام إلى مجموعة"""
    print(f"🔗 [Community] المستخدم {current_user.id} ينضم إلى المجموعة {group_id}")

    # التحقق من وجود المجموعة
    group = (
        db.query(models.CommunityGroup)
        .filter(models.CommunityGroup.id == group_id)
        .first()
    )
    if not group:
        raise HTTPException(status_code=404, detail="المجموعة غير موجودة")

    # التحقق مما إذا كان المستخدم منضم بالفعل
    existing_member = (
        db.query(models.CommunityGroupMember)
        .filter(
            models.CommunityGroupMember.user_id == current_user.id,
            models.CommunityGroupMember.group_id == group_id,
        )
        .first()
    )

    if existing_member:
        raise HTTPException(status_code=400, detail="أنت منضم بالفعل إلى هذه المجموعة")

    # إنشاء سجل العضوية
    new_member = models.CommunityGroupMember(
        user_id=current_user.id,
        group_id=group_id,
        role="member",
        joined_at=datetime.utcnow(),
    )

    db.add(new_member)

    # زيادة عدد الأعضاء في المجموعة
    group.members_count += 1

    db.commit()

    return {"message": "تم الانضمام إلى المجموعة بنجاح"}


@router.post("/groups/{group_id}/leave")
def leave_group(
    group_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """مغادرة مجموعة"""
    print(f"🚪 [Community] المستخدم {current_user.id} يغادر المجموعة {group_id}")

    # التحقق من وجود المجموعة
    group = (
        db.query(models.CommunityGroup)
        .filter(models.CommunityGroup.id == group_id)
        .first()
    )
    if not group:
        raise HTTPException(status_code=404, detail="المجموعة غير موجودة")

    # البحث عن سجل العضوية
    member = (
        db.query(models.CommunityGroupMember)
        .filter(
            models.CommunityGroupMember.user_id == current_user.id,
            models.CommunityGroupMember.group_id == group_id,
        )
        .first()
    )

    if not member:
        raise HTTPException(status_code=400, detail="أنت لست منضم إلى هذه المجموعة")

    # حذف سجل العضوية
    db.delete(member)

    # تقليل عدد الأعضاء في المجموعة
    group.members_count = max(0, group.members_count - 1)

    db.commit()

    return {"message": "تمت مغادرة المجموعة بنجاح"}


@router.get("/groups/{group_id}", response_model=schemas.CommunityGroupDetailResponse)
def get_group(
    group_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب تفاصيل مجموعة محددة"""
    print(f"📋 [Community] جلب تفاصيل المجموعة {group_id} للمستخدم {current_user.id}")

    # جلب المجموعة من قاعدة البيانات
    group = (
        db.query(models.CommunityGroup)
        .filter(models.CommunityGroup.id == group_id)
        .first()
    )
    if not group:
        raise HTTPException(status_code=404, detail="المجموعة غير موجودة")

    # التحقق مما إذا كان المستخدم منضم للمجموعة
    is_joined = (
        db.query(models.CommunityGroupMember)
        .filter(
            models.CommunityGroupMember.user_id == current_user.id,
            models.CommunityGroupMember.group_id == group_id,
        )
        .first()
        is not None
    )

    # تحويل المجموعة إلى قاموس وإضافة حقل is_joined
    group_dict = group.to_dict()
    group_dict["is_joined"] = is_joined
    group_dict["rules"] = group.rules or []
    group_dict["created_at"] = group.created_at

    return group_dict


@router.get("/groups/{group_id}/posts")
def get_group_posts(
    group_id: int,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب منشورات مجموعة محددة"""
    print(f"📋 [Community] جلب منشورات المجموعة {group_id} للمستخدم {current_user.id}")

    # جلب المجموعة للتحقق من وجودها والحصول على condition_tag
    group = (
        db.query(models.CommunityGroup)
        .filter(models.CommunityGroup.id == group_id)
        .first()
    )
    if not group:
        raise HTTPException(status_code=404, detail="المجموعة غير موجودة")

    # جلب المنشورات وتصفيتها حسب condition_tag الخاص بالمجموعة
    query = db.query(models.CommunityPost).filter(
        models.CommunityPost.category == group.condition_tag
    )

    posts = (
        query.order_by(models.CommunityPost.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    result = []
    for post in posts:
        user = db.query(models.User).filter(models.User.id == post.user_id).first()
        result.append(
            {
                "id": post.id,
                "user_id": post.user_id,
                "title": post.title,
                "content": post.content,
                "post_type": post.post_type,
                "category": post.category,
                "is_anonymous": post.is_anonymous,
                "likes_count": getattr(post, "likes_count", 0),
                "comments_count": getattr(post, "comments_count", 0),
                "views_count": getattr(post, "views_count", 0),
                "created_at": post.created_at.isoformat() if post.created_at else None,
                "updated_at": post.updated_at.isoformat() if post.updated_at else None,
                "author": {
                    "id": user.id if user else 0,
                    "name": (
                        "مستخدم مجهول"
                        if post.is_anonymous
                        else (user.name if user else "مستخدم")
                    ),
                    "is_verified": (
                        user.is_verified if user and not post.is_anonymous else False
                    ),
                },
            }
        )

    return result
