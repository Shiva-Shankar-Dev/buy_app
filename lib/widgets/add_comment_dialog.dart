import 'package:flutter/material.dart';
import 'package:buy_app/ColorPallete/color_pallete.dart';
import 'package:buy_app/services/comment_service.dart';

class AddCommentDialog extends StatefulWidget {
  final String productId;
  final String? variantId;
  final Map<String, String>? variantAttributes;
  final VoidCallback? onCommentAdded;

  const AddCommentDialog({
    super.key,
    required this.productId,
    this.variantId,
    this.variantAttributes,
    this.onCommentAdded,
  });

  @override
  State<AddCommentDialog> createState() => _AddCommentDialogState();
}

class _AddCommentDialogState extends State<AddCommentDialog>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;
  late AnimationController _starController;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _starAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.rate_review, color: ColorPallete.color1, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Write a Review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Variant info if available
              if (widget.variantAttributes != null &&
                  widget.variantAttributes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reviewing variant:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.variantAttributes!.values.join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Rating section
              const Text(
                'How would you rate this product?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Rating stars
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => _setRating((index + 1).toDouble()),
                          child: AnimatedBuilder(
                            animation: _starAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: index < _rating
                                    ? _starAnimation.value
                                    : 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    size: 36,
                                    color: index < _rating
                                        ? Colors.amber[600]
                                        : Colors.grey[300],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRatingText(_rating),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getRatingColor(_rating),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Comment section
              const Text(
                'Share your experience',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Tell others about this product...\n\n• What did you like?\n• How was the quality?\n• Would you recommend it?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ColorPallete.color1,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPallete.color1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Submitting Review...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Submit Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setRating(double rating) {
    setState(() => _rating = rating);
    _starController.forward().then((_) => _starController.reverse());
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Rate this product';
    }
  }

  Color _getRatingColor(double rating) {
    switch (rating.toInt()) {
      case 1:
        return Colors.red[600]!;
      case 2:
        return Colors.orange[600]!;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen[600]!;
      case 5:
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      _showErrorSnackbar('Please write a review');
      return;
    }

    if (comment.length < 10) {
      _showErrorSnackbar('Review must be at least 10 characters long');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await CommentService.addComment(
        productId: widget.productId,
        comment: comment,
        rating: _rating,
        variantId: widget.variantId,
        variantAttributes: widget.variantAttributes,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Review submitted successfully!')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          if (widget.onCommentAdded != null) {
            widget.onCommentAdded!();
          }
        } else {
          _showErrorSnackbar('Failed to submit review. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('An error occurred. Please try again.');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
