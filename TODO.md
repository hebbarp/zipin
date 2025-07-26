# Cream Social - Development Todo List

## Current Status
- ✅ Basic social media functionality working
- ✅ Post creation, editing, deletion
- ✅ Like and bookmark functionality
- ✅ Follow/unfollow system with optimized queries
- ✅ Repost and quote sharing functionality
- ✅ Mobile responsive design with dark mode
- ✅ Link preview extraction and display
- ✅ Real-time updates with Phoenix LiveView
- ✅ Media upload support (images/videos)

## Upcoming Features for Next Session

### 1. User Profile Pages 📝
**Priority: High**
- [ ] Create user profile page route (`/users/:id`)
- [ ] Design user profile layout with:
  - [ ] Cover photo upload and display
  - [ ] Profile picture
  - [ ] User bio/description
  - [ ] Follower/following counts
  - [ ] Follow/unfollow button for other users
  - [ ] User's posts timeline
- [ ] Add cover photo upload functionality
- [ ] Create user profile edit page
- [ ] Add profile photo upload
- [ ] Implement user bio editing

### 2. Search Functionality 🔍
**Priority: High**
- [ ] Create search page/component
- [ ] Implement search for:
  - [ ] Users (by name, username, email)
  - [ ] Posts (by content)
  - [ ] Hashtags
- [ ] Add search bar to navigation
- [ ] Real-time search suggestions
- [ ] Search results pagination
- [ ] Search history/recent searches

### 3. Hashtags and @Mentions 🏷️
**Priority: Medium**
- [ ] Hashtag functionality:
  - [ ] Parse hashtags from post content (`#hashtag`)
  - [ ] Create hashtags database table
  - [ ] Link hashtags to posts (many-to-many)
  - [ ] Hashtag pages showing all posts with that tag
  - [ ] Trending hashtags
  - [ ] Clickable hashtags in posts
- [ ] @Mention functionality:
  - [ ] Parse @mentions from post content (`@username`)
  - [ ] Auto-complete users when typing @
  - [ ] Notify mentioned users
  - [ ] Link mentions to user profiles
  - [ ] Clickable mentions in posts

## Technical Considerations

### Database Changes Needed
- [ ] Add `cover_photo_path` to users table
- [ ] Add `bio` field to users table
- [ ] Create `hashtags` table
- [ ] Create `post_hashtags` join table
- [ ] Create `mentions` table
- [ ] Add search indexes for performance

### Performance Optimizations
- [ ] Add database indexes for search queries
- [ ] Implement search result caching
- [ ] Optimize hashtag and mention parsing
- [ ] Add pagination for user profiles

### UI/UX Improvements
- [ ] Design user profile layouts
- [ ] Create search interface
- [ ] Style hashtags and mentions in posts
- [ ] Add loading states for search
- [ ] Mobile optimization for new features

## Files to Focus On

### New Files to Create
- `lib/cream_social_web/live/user_live/show.ex` - User profile page
- `lib/cream_social_web/live/user_live/show.html.heex` - Profile template
- `lib/cream_social_web/live/search_live/index.ex` - Search functionality
- `lib/cream_social/content/hashtag.ex` - Hashtag schema
- `lib/cream_social/content/mention.ex` - Mention schema

### Existing Files to Modify
- `lib/cream_social_web/router.ex` - Add profile and search routes
- `lib/cream_social/accounts/user.ex` - Add cover photo and bio fields
- `lib/cream_social/content.ex` - Add hashtag and mention functions
- `lib/cream_social/content/post.ex` - Add hashtag/mention associations
- `lib/cream_social_web/components/layouts/app.html.heex` - Add search bar

## Development Order Suggestion
1. **User Profile Pages** - Foundation for user discovery
2. **Search Functionality** - Essential for finding users and content
3. **Hashtags** - Content categorization and discovery
4. **@Mentions** - User engagement and notifications

## Notes
- All features should maintain mobile responsiveness
- Dark mode support for all new components
- Real-time updates where applicable
- Performance optimization for search and hashtag queries
- Consider implementing notifications system for mentions

---

**Last Updated:** July 2, 2025
**Current Session Completed:** Basic social media functionality with follow system and sharing
**Next Session Focus:** User profiles with cover photos, search, hashtags, and mentions