import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'email_metadata.dart';

class GmailApiService {
  static const String _baseUrl =
      'https://gmail.googleapis.com/gmail/v1/users/me';

  Future<List<EmailMetadata>> fetchInboxEmails(
    Map<String, String> authHeaders,
  ) async {
    try {
      // Fetch list of message IDs from inbox
      final listUrl = Uri.parse(
        '$_baseUrl/messages?maxResults=50&labelIds=INBOX',
      );
      final listResponse = await http.get(listUrl, headers: authHeaders);

      if (listResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch inbox: ${listResponse.statusCode} ${listResponse.body}',
        );
      }

      final listData = jsonDecode(listResponse.body) as Map<String, dynamic>;
      final messages = listData['messages'] as List<dynamic>? ?? [];

      if (messages.isEmpty) {
        return [];
      }

      // Fetch full metadata for each message
      final emails = <EmailMetadata>[];

      for (var msg in messages) {
        try {
          final msgId = msg['id'];
          final msgUrl = Uri.parse(
            '$_baseUrl/messages/$msgId?format=metadata&metadataHeaders=Subject&metadataHeaders=From&metadataHeaders=Date',
          );

          final msgResponse = await http.get(msgUrl, headers: authHeaders);

          if (msgResponse.statusCode == 200) {
            final msgData =
                jsonDecode(msgResponse.body) as Map<String, dynamic>;
            final emailMetadata = EmailMetadata.fromGmailMessage(msgData);
            emails.add(emailMetadata);
          } else {
            debugPrint(
              'Failed to fetch message $msgId: ${msgResponse.statusCode}',
            );
          }
        } catch (e) {
          debugPrint('Error fetching individual message: $e');
          continue;
        }
      }

      return emails;
    } catch (e) {
      debugPrint('Error in fetchInboxEmails: $e');
      rethrow;
    }
  }

  Future<List<EmailMetadata>> fetchSpamEmails(
    Map<String, String> authHeaders, {
    int maxResults = 50,
  }) async {
    try {
      // Fetch list of message IDs from SPAM label
      final listUrl = Uri.parse(
        '$_baseUrl/messages?maxResults=$maxResults&labelIds=SPAM',
      );
      final listResponse = await http.get(listUrl, headers: authHeaders);

      if (listResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch spam: ${listResponse.statusCode} ${listResponse.body}',
        );
      }

      final listData = jsonDecode(listResponse.body) as Map<String, dynamic>;
      final messages = listData['messages'] as List<dynamic>? ?? [];

      if (messages.isEmpty) {
        return [];
      }

      // Fetch full metadata for each message
      final emails = <EmailMetadata>[];

      for (var msg in messages) {
        try {
          final msgId = msg['id'];
          // Use format=full to get labelIds, but limit to essential fields
          final msgUrl = Uri.parse(
            '$_baseUrl/messages/$msgId?format=full&fields=id,threadId,labelIds,payload/headers(name,value),internalDate,snippet',
          );

          final msgResponse = await http.get(msgUrl, headers: authHeaders);

          if (msgResponse.statusCode == 200) {
            final msgData =
                jsonDecode(msgResponse.body) as Map<String, dynamic>;
            final emailMetadata = EmailMetadata.fromGmailMessage(msgData);
            emails.add(emailMetadata);
          } else {
            debugPrint(
              'Failed to fetch spam message $msgId: ${msgResponse.statusCode}',
            );
          }
        } catch (e) {
          debugPrint('Error fetching individual spam message: $e');
          continue;
        }
      }

      // Sort by date descending (most recent first)
      emails.sort((a, b) {
        if (a.date == null || b.date == null) return 0;
        return b.date!.compareTo(a.date!);
      });

      return emails;
    } catch (e) {
      debugPrint('Error in fetchSpamEmails: $e');
      rethrow;
    }
  }
}
