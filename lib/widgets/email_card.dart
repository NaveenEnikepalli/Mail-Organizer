import 'package:flutter/material.dart';
import '../core/email_metadata.dart';

class EmailCard extends StatelessWidget {
  final EmailMetadata email;

  const EmailCard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    // Extract initials from sender email or name
    String getInitials() {
      if (email.from.isEmpty) return '?';
      final parts = email.from.split(' ');
      if (parts[0].contains('@')) {
        // Email address like "sender@gmail.com"
        return parts[0].substring(0, 1).toUpperCase();
      }
      // Name format or just use first character
      return email.from.substring(0, 1).toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(child: Text(getInitials())),
        title: Row(
          children: [
            Expanded(
              child: Text(
                email.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (email.isImportant)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.star, color: Colors.amber[700], size: 20),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                email.from,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(
                email.snippet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Wrap(
              spacing: 8.0,
              children: [
                Chip(
                  label: const Text('Email'),
                  avatar: const Icon(Icons.mail, size: 18),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
