import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/ride_service.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> driver;
  final String? bookingId;
  const RatingScreen({super.key, required this.driver, this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _selectedRating = 4;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (widget.bookingId == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final driverId = widget.driver['uid'] ?? widget.driver['_id'] ?? widget.driver['driver_id'];
      await ref.read(rideServiceProvider).submitReview(
        bookingId: widget.bookingId!,
        driverId: driverId.toString(),
        rating: _selectedRating,
        comment: _commentController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  final List<String> _tags = [
    "Professional",
    "Clean Vehicle",
    "Smooth Driving",
    "Punctual",
    "Helpful",
    "Great Route",
  ];
  final Set<String> _selectedTags = {"Professional", "Smooth Driving"};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ratings & Reviews",
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _isSubmitting ? null : _submitReview,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "Post",
                  style: TextStyle(
                    color: _isSubmitting ? Colors.grey : context.theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Header
            Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.theme.dividerColor.withOpacity(0.1),
                      width: 4,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        (widget.driver['image'] != null && widget.driver['image'].toString().trim().startsWith('http'))
                            ? widget.driver['image'].toString().trim()
                            : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.driver['name'] ?? "Marco Rossi",
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${widget.driver['vehicle'] ?? "Toyota Camry"} • ${widget.driver['plate'] ?? "ROMA 4521"}",
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Text(
              "How was your ride?",
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your feedback helps improve the transport experience for everyone",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),
            // Star Interaction
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: index < _selectedRating
                          ? Colors.yellow
                          : context.theme.dividerColor.withOpacity(0.1),
                      size: 40,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "What went well?",
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? context.theme.primaryColor
                            : context.theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected
                            ? context.theme.primaryColor
                            : context.colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Write a review (optional)",
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.theme.dividerColor.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Tell us more about your experience...",
                  hintStyle: TextStyle(
                    color: context.colors.textSecondary?.withOpacity(0.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 32),
            // Driver's Lifetime Rating Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.theme.dividerColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "DRIVER'S LIFETIME RATING",
                    style: TextStyle(
                      color: Color(0xFF9DA6B9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "4.9",
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 14,
                              );
                            }),
                          ),
                          const Text(
                            "Based on 1.2k rides",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingBar(5, 0.85),
                            _buildRatingBar(4, 0.10),
                            _buildRatingBar(3, 0.03),
                            _buildRatingBar(2, 0.01),
                            _buildRatingBar(1, 0.01),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomSheet: Container(
        color: context.theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            shadowColor: context.theme.primaryColor.withOpacity(0.3),
          ),
          child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Submit Feedback",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$star",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: context.theme.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${(percent * 100).toInt()}%",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
