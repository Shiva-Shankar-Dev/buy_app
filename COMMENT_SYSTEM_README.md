# Product Comment System

This document explains the comment/review system implemented for your Flutter e-commerce app.

## Overview

The comment system allows users to:
- Add reviews and ratings (1-5 stars) for products
- View existing reviews and ratings
- Edit their own reviews
- Delete their own reviews
- See rating statistics and distribution
- Review specific product variants

## Database Structure

Comments are stored in Firestore collection: `product_comments`

Each comment document contains:
```
{
  "productId": "string",           // Product ID
  "userId": "string",              // User ID who wrote the review
  "userName": "string",            // User display name
  "userEmail": "string",           // User email
  "comment": "string",             // Review text
  "rating": "number",              // Rating 1.0-5.0
  "timestamp": "timestamp",        // When review was created
  "isVerified": "boolean",         // Whether user is verified purchaser
  "images": "array",              // Optional review images
  "variantId": "string",          // Optional: specific variant reviewed
  "variantAttributes": "object"    // Optional: variant attributes
}
```

## Components

### 1. Models (`lib/models/models.dart`)
- **ProductComment**: Main comment model
- **CommentStatistics**: Aggregated statistics (total, average, distribution)

### 2. Service (`lib/services/comment_service.dart`)
- **CommentService**: Handles all comment operations
  - `addComment()`: Add new review
  - `getProductComments()`: Fetch reviews for a product
  - `getCommentStatistics()`: Get rating statistics
  - `updateComment()`: Edit existing review
  - `deleteComment()`: Remove review
  - `hasUserCommented()`: Check if user already reviewed
  - `streamProductComments()`: Real-time comment updates

### 3. UI Components

#### CommentSection (`lib/widgets/comment_section.dart`)
Main component that displays:
- Review statistics summary
- Rating distribution chart
- Add review button
- List of all reviews
- Pagination (load more)

#### CommentTile (`lib/widgets/comment_tile.dart`)
Individual review display with:
- User info and avatar
- Star rating display
- Review text
- Variant information (if applicable)
- Edit/delete options for own reviews
- Review images

#### AddCommentDialog (`lib/widgets/add_comment_dialog.dart`)
Modal for adding new reviews:
- Interactive star rating
- Text input for review
- Variant information display
- Form validation

## Usage

### 1. Integration in Product Details

The comment section is integrated into your product details page:

```dart
import 'package:buy_app/widgets/comment_section.dart';

// In your product details build method:
CommentSection(
  productId: widget.product.pid,
  variantId: selectedVariantId,
  variantAttributes: selectedAttributes,
),
```

### 2. Adding Comments

Users can add reviews by:
1. Tapping "Write a Review" button
2. Selecting star rating (1-5)
3. Writing review text
4. Submitting the review

### 3. Viewing Comments

Comments are displayed with:
- User information
- Star rating
- Review text
- Date posted
- Variant information (if applicable)
- Statistics summary at the top

### 4. Managing Reviews

Users can:
- Edit their own reviews (tap menu icon → Edit)
- Delete their own reviews (tap menu icon → Delete)
- View all reviews from other users

## Features

### Rating System
- 1-5 star ratings
- Visual star display
- Animated star selection
- Rating distribution chart

### Variant Support
- Reviews can be specific to product variants
- Variant attributes displayed with review
- Separate reviews for different variants

### Security
- Users can only edit/delete their own reviews
- User authentication required
- Input validation and sanitization

### Performance
- Pagination for large review lists
- Efficient Firestore queries
- Real-time updates with streams

### User Experience
- Smooth animations
- Loading states
- Error handling
- Success feedback
- Empty states

## Firestore Security Rules

Add these rules to your Firestore security rules:

```javascript
// Product comments collection
match /product_comments/{commentId} {
  // Allow read access to all authenticated users
  allow read: if request.auth != null;
  
  // Allow create for authenticated users
  allow create: if request.auth != null 
    && request.auth.uid == request.resource.data.userId
    && validateComment(request.resource.data);
  
  // Allow update/delete only by comment author
  allow update, delete: if request.auth != null 
    && request.auth.uid == resource.data.userId;
}

function validateComment(data) {
  return data.keys().hasAll(['productId', 'userId', 'userName', 'comment', 'rating'])
    && data.rating is number
    && data.rating >= 1.0
    && data.rating <= 5.0
    && data.comment is string
    && data.comment.size() > 0
    && data.productId is string
    && data.productId.size() > 0;
}
```

## Customization

### Styling
All components use your app's `ColorPallete.color1` for consistency. You can customize:
- Colors in each widget file
- Card designs and spacing
- Star colors and sizes
- Typography styles

### Features
You can extend the system by:
- Adding image upload for reviews
- Implementing helpful/unhelpful votes
- Adding review reporting
- Creating review moderation
- Adding verified purchaser badges

## Error Handling

The system includes comprehensive error handling:
- Network connectivity issues
- Firestore permission errors
- Input validation
- User authentication checks
- Loading states for all operations

All errors are logged to the console and shown to users via SnackBars.