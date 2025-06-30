import 'package:flutter/material.dart';

class JobSeekerRatings extends StatelessWidget {
  final List<dynamic> reviews;
  const JobSeekerRatings({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text('No reviews yet.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }
    final avgRating = reviews.map((r) => r['rating'] as num).reduce((a, b) => a + b) / reviews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rating: ',
              style: TextStyle(
                color: Colors.amber[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            ...List.generate(5, (i) => Icon(
              i < avgRating.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            )),
            SizedBox(width: 8),
            Text(
              avgRating.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.amber[800],
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(' (${reviews.length} reviews)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        Text('Reviews:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 16)),
        const SizedBox(height: 6),
        ...reviews.map((r) => Card(
          color: Colors.amber.withOpacity(0.08),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(Icons.star, color: Colors.amber[700]),
            title: Text(r['comment'] ?? '', style: const TextStyle(fontSize: 15)),
            subtitle: Text('By: ${r['reviewer']?['name'] ?? 'Anonymous'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => Icon(
                i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              )),
            ),
          ),
        )),
      ],
    );
  }
}