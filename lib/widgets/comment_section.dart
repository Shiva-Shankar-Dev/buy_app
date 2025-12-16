import 'package:flutter/material.dart';
import 'package:buy_app/models/models.dart';
import 'package:buy_app/ColorPallete/color_pallete.dart';
import 'package:buy_app/services/comment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buy_app/widgets/comment_tile.dart';
import 'package:buy_app/widgets/add_comment_dialog.dart';

class CommentSection extends StatefulWidget {
  final String productId;
  final String? variantId;
  final Map<String, String>? variantAttributes;

  const CommentSection({
    super.key,
    required this.productId,
    this.variantId,
    this.variantAttributes,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  List<ProductComment> comments = [];
  CommentStatistics stats = CommentStatistics.empty();
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasUserCommented = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final [
        commentsData,
        statisticsData,
        userCommentData,
      ] = await Future.wait([
        CommentService.getProductComments(widget.productId, limit: 10),
        CommentService.getCommentStatistics(widget.productId),
        CommentService.hasUserCommented(
          widget.productId,
          variantId: widget.variantId,
        ),
      ]);

      setState(() {
        comments = commentsData as List<ProductComment>;
        stats = statisticsData as CommentStatistics;
        hasUserCommented = userCommentData as bool;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading comment data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (isLoadingMore || comments.isEmpty) return;

    setState(() => isLoadingMore = true);

    try {
      final moreComments = await CommentService.getProductComments(
        widget.productId,
        limit: 10,
        lastDocumentId: comments.last.commentId,
      );

      setState(() {
        comments.addAll(moreComments);
        isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more comments: $e');
      setState(() => isLoadingMore = false);
    }
  }

  void _showAddCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCommentDialog(
        productId: widget.productId,
        variantId: widget.variantId,
        variantAttributes: widget.variantAttributes,
        onCommentAdded: () {
          _loadData(); // Refresh after adding comment
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: ColorPallete.color1),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with statistics
        _buildHeader(),

        // Rating summary
        if (stats.totalComments > 0) _buildRatingSummary(),

        // Add comment button
        _buildAddCommentButton(),

        const SizedBox(height: 16),

        // Comments list
        if (comments.isEmpty) _buildEmptyState() else _buildCommentsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Reviews & Ratings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey[900],
            ),
          ),
          const Spacer(),
          if (stats.totalComments > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorPallete.color1.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${stats.totalComments} review${stats.totalComments > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorPallete.color1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Average rating display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stats.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 16,
                                color: index < stats.averageRating.floor()
                                    ? Colors.amber
                                    : Colors.grey[300],
                              );
                            }),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stats.totalComments} reviews',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Rating distribution
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 5; i >= 1; i--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$i', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 12, color: Colors.amber[600]),
                          const SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: stats.totalComments > 0
                                  ? (stats.ratingDistribution[i] ?? 0) /
                                        stats.totalComments
                                  : 0,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber[600],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stats.ratingDistribution[i] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommentButton() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Please log in to write a review',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: hasUserCommented ? null : _showAddCommentDialog,
          icon: Icon(
            hasUserCommented ? Icons.check_circle : Icons.rate_review,
            size: 20,
          ),
          label: Text(
            hasUserCommented
                ? 'You have reviewed this product'
                : 'Write a Review',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasUserCommented
                ? Colors.grey[300]
                : ColorPallete.color1,
            foregroundColor: hasUserCommented ? Colors.grey[600] : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts about this product!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: [
        ...comments.map(
          (comment) =>
              CommentTile(comment: comment, onCommentUpdated: _loadData),
        ),

        // Load more button
        if (comments.length >= 10)
          Container(
            margin: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: isLoadingMore ? null : _loadMoreComments,
              child: isLoadingMore
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorPallete.color1,
                      ),
                    )
                  : Text(
                      'Load More Reviews',
                      style: TextStyle(
                        color: ColorPallete.color1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
