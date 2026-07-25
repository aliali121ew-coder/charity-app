import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';
import 'package:charity_app/features/help_requests/domain/entities/urgency_level.dart';
import 'package:charity_app/features/help_requests/domain/entities/location_info.dart';
import 'package:charity_app/features/help_requests/domain/entities/media_attachment.dart';
import 'package:charity_app/features/help_requests/providers/help_requests_provider.dart';
import 'package:charity_app/features/help_requests/providers/location_provider.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/shared_fields_section.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/general_help_section.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/doctor_booking_section.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/treatment_section.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/food_basket_section.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/financial_section.dart';
import 'package:charity_app/features/help_requests/widgets/form_sections/household_materials_section.dart';
import 'package:charity_app/features/help_requests/widgets/location_summary_widget.dart';
import 'package:charity_app/features/help_requests/widgets/media_attachment_section.dart';

class HelpRequestFormPage extends ConsumerStatefulWidget {
  final String typeName;
  final String? editId;

  const HelpRequestFormPage({
    super.key,
    required this.typeName,
    this.editId,
  });

  @override
  ConsumerState<HelpRequestFormPage> createState() =>
      _HelpRequestFormPageState();
}

class _HelpRequestFormPageState extends ConsumerState<HelpRequestFormPage> {
  static const _uuid = Uuid();

  late RequestType _type;
  Map<String, String> _sharedData = {};
  Map<String, String> _typeData = {};
  List<MediaAttachment> _attachments = [];
  bool _isSubmitting = false;
  HelpRequest? _editRequest;

  @override
  void initState() {
    super.initState();
    _type = RequestType.values.firstWhere(
      (t) => t.name == widget.typeName,
      orElse: () => RequestType.generalHelp,
    );

    if (widget.editId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final request =
            ref.read(helpRequestsProvider.notifier).getById(widget.editId!);
        if (request != null) {
          setState(() {
            _editRequest = request;
            _type = request.type;
            _sharedData = {
              SharedFieldKeys.fullName: request.fullName,
              SharedFieldKeys.phone: request.phone,
              SharedFieldKeys.title: request.title,
              SharedFieldKeys.description: request.description,
              SharedFieldKeys.urgency: request.urgency.name,
              SharedFieldKeys.familySize: request.familySize?.toString() ?? '',
              SharedFieldKeys.notes: request.notes ?? '',
            };
            _typeData = Map<String, String>.from(request.typeData);
            _attachments = List<MediaAttachment>.from(request.attachments);
          });
        }
      });
    }
  }

  bool get _isEdit => widget.editId != null;

  String? _validate() {
    final name = _sharedData[SharedFieldKeys.fullName]?.trim() ?? '';
    final phone = _sharedData[SharedFieldKeys.phone]?.trim() ?? '';
    final title = _sharedData[SharedFieldKeys.title]?.trim() ?? '';
    final desc = _sharedData[SharedFieldKeys.description]?.trim() ?? '';

    if (name.isEmpty) return 'يرجى إدخال الاسم الكامل';
    if (phone.isEmpty) return 'يرجى إدخال رقم الهاتف';
    if (title.isEmpty) return 'يرجى إدخال عنوان الطلب';
    if (desc.isEmpty) return 'يرجى إدخال وصف الطلب';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: GoogleFonts.cairo()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final locationState = ref.read(locationProvider);
    final location = _editRequest?.location ??
        locationState.location ??
        const LocationInfo(
          address: 'غير محدد',
          governorate: 'غير محدد',
          area: 'غير محدد',
        );

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final urgency = UrgencyLevel.values.firstWhere(
      (u) => u.name == (_sharedData[SharedFieldKeys.urgency] ?? ''),
      orElse: () => UrgencyLevel.medium,
    );
    final familySizeStr = _sharedData[SharedFieldKeys.familySize] ?? '';
    final familySize =
        familySizeStr.isNotEmpty ? int.tryParse(familySizeStr) : null;

    if (_isEdit && _editRequest != null) {
      final updated = _editRequest!.copyWith(
        fullName: _sharedData[SharedFieldKeys.fullName] ?? _editRequest!.fullName,
        phone: _sharedData[SharedFieldKeys.phone] ?? _editRequest!.phone,
        title: _sharedData[SharedFieldKeys.title] ?? _editRequest!.title,
        description: _sharedData[SharedFieldKeys.description] ?? _editRequest!.description,
        urgency: urgency,
        familySize: familySize,
        notes: _sharedData[SharedFieldKeys.notes],
        attachments: _attachments,
        typeData: _typeData,
      );
      ref.read(helpRequestsProvider.notifier).updateRequest(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تحديث الطلب بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } else {
      final request = HelpRequest(
        id: _uuid.v4(),
        type: _type,
        status: RequestStatus.pending,
        submittedAt: DateTime.now(),
        fullName: _sharedData[SharedFieldKeys.fullName] ?? '',
        phone: _sharedData[SharedFieldKeys.phone] ?? '',
        governorate: location.governorate,
        area: location.area,
        fullAddress: location.address,
        title: _sharedData[SharedFieldKeys.title] ?? '',
        description: _sharedData[SharedFieldKeys.description] ?? '',
        urgency: urgency,
        familySize: familySize,
        notes: _sharedData[SharedFieldKeys.notes],
        location: location,
        attachments: _attachments,
        typeData: _typeData,
      );
      ref.read(helpRequestsProvider.notifier).addRequest(request);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        context.go('/help-requests');
        messenger.showSnackBar(SnackBar(
          content: Text('تم تقديم الطلب بنجاح ✓', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEdit ? 'تعديل الطلب' : _type.labelAr,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 3 indicator (only for new)
            if (!_isEdit) ...[
              _StepIndicator(isDark: isDark),
              const SizedBox(height: 20),
            ],

            // Location summary
            if (locationState.hasLocation || _editRequest != null) ...[
              LocationSummaryWidget(
                location: _editRequest?.location ?? locationState.location!,
                compact: true,
              ),
              const SizedBox(height: 20),
            ],

            // Shared fields
            SharedFieldsSection(
              data: _sharedData,
              onChanged: (d) => setState(() => _sharedData = d),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Type-specific section
            _buildTypeSection(isDark),
            const SizedBox(height: 20),

            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Media attachments
            MediaAttachmentSection(
              attachments: _attachments,
              onChanged: (a) => setState(() => _attachments = a),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPurple,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEdit ? 'حفظ التعديلات' : 'تقديم الطلب',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSection(bool isDark) {
    switch (_type) {
      case RequestType.generalHelp:
        return GeneralHelpSection(
          data: _typeData,
          onChanged: (d) => setState(() => _typeData = d),
        );
      case RequestType.doctorBooking:
        return DoctorBookingSection(
          data: _typeData,
          onChanged: (d) => setState(() => _typeData = d),
        );
      case RequestType.treatment:
        return TreatmentSection(
          data: _typeData,
          onChanged: (d) => setState(() => _typeData = d),
        );
      case RequestType.foodBasket:
        return FoodBasketSection(
          data: _typeData,
          onChanged: (d) => setState(() => _typeData = d),
        );
      case RequestType.financial:
        return FinancialSection(
          data: _typeData,
          onChanged: (d) => setState(() => _typeData = d),
        );
      case RequestType.householdMaterials:
        return HouseholdMaterialsSection(
          data: _typeData,
          onChanged: (d) => setState(() => _typeData = d),
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final bool isDark;
  const _StepIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'الخطوة 3 من 3',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}
