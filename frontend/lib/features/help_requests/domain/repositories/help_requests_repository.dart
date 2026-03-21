import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';

abstract class HelpRequestsRepository {
  List<HelpRequest> getAll();
  HelpRequest? getById(String id);
  HelpRequest add(HelpRequest request);
  HelpRequest? update(HelpRequest request);
  /// Force-update the status regardless of edit window (admin/staff only).
  HelpRequest? forceUpdateStatus(String id, RequestStatus newStatus);
  bool delete(String id);
}
