import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';

abstract class HelpRequestsRepository {
  List<HelpRequest> getAll();
  HelpRequest? getById(String id);
  HelpRequest add(HelpRequest request);
  HelpRequest? update(HelpRequest request);
  bool delete(String id);
}
