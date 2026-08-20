// ignore_for_file: deprecated_member_use

import 'package:app/models/response/transaction_list_response/transaction_list_response.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../app_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/constants_o7lite.dart';
import '../../../shared/utils/responsive_util.dart';
import '../../../shared/widgets/custom_text_style.dart';
import '../../../shared/widgets/string_utils.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/widgets/jumping_dot.dart';
import '../../../shared/widgets/adaptive_loading_widget.dart';
import '../../../shared/utils/device_performance_detector.dart';
import '../../../theme/theme_helper.dart';
import 'transaction_history_controller.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/transaction_filters.dart';
import '../home_controller.dart';

class TransactionHistory extends StatelessWidget {
  TransactionHistory({Key? key}) : super(key: key);
  final AppController appController = Get.find();
  final TransactionHistoryController controller = Get.put(
    TransactionHistoryController(
      apiRepository: Get.find(),
    ),
  );

  // Get home controller to manage tab switching
  HomeController? get homeController {
    try {
      return Get.find<HomeController>();
    } catch (e) {
      return null;
    }
  }

  bool get isReturnHome {
    if (Get.arguments == null) return true;

    if (Get.arguments is Map) {
      return Get.arguments['isReturnHome'] ?? true;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!isReturnHome) {
          Get.back();
        } else {
          // Switch to home tab instead of reloading home screen
          if (homeController != null) {
            homeController!.setValueBottomIndex(0);
          } else {
            Get.offAllNamed(Routes.HOME);
          }
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: StorageService.isGw3
            ? (appController.isDarkModeOn.value
                ? ColorConstants.darkScaffoldBackgroundColor
                : Color(0xFFFBFBFB))
            : (appController.isDarkModeOn.value ? null : Colors.white),
        appBar: StorageService.isGw3 ? _buildGw3AppBar() : _buildLegacyAppBar(),
        body: StorageService.isGw3 ? _buildGw3Layout() : _buildLegacyLayout(),
      ),
    );
  }

  // GW3 AppBar following Figma design
  PreferredSizeWidget _buildGw3AppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.transactionHistory.tr,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF382F41),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : Color(0xFF382F41),
          size: 24,
        ),
        onPressed: () {
          if (!isReturnHome) {
            Get.back();
            return;
          }
          // Switch to home tab instead of reloading home screen
          if (homeController != null) {
            homeController!.setValueBottomIndex(0);
          } else {
            Get.offAllNamed(Routes.HOME);
          }
        },
      ),
      actions: [
        Obx(() => (controller.selectedBrands.isNotEmpty ||
                controller.selectedStates.isNotEmpty)
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.white
                      : Color(0xFF382F41),
                  size: 24,
                ),
                tooltip: CommonConstants.resetFiltersTooltip.tr,
                onPressed: () {
                  controller.resetFilters();
                },
              )
            : SizedBox.shrink()),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: appController.isDarkModeOn.value
                ? ColorConstants.white
                : Color(0xFF382F41),
            size: 24,
          ),
          onPressed: () {
            // Use bottom sheet for GW3
            TransactionFilters.showGw3FilterBottomSheet(
              context: Get.context!,
              selectedBrands: List<String>.from(controller.selectedBrands),
              selectedStates: List<String>.from(controller.selectedStates),
              selectedTypes: List<String>.from(controller.selectedTypes),
              onBrandsChanged: controller.onBrandsChanged,
              onStatesChanged: controller.onStatesChanged,
              onTypesChanged: controller.onTypesChanged,
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            ImageConstant.iconHistoryRefresh,
            color: appController.isDarkModeOn.value
                ? ColorConstants.white
                : Color(0xFF382F41),
          ),
          onPressed: () {
            controller.getData();
          },
        ),
        SizedBox(width: 8),
      ],
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // Legacy AppBar
  PreferredSizeWidget _buildLegacyAppBar() {
    return AppBar(
      centerTitle: true,
      title: Text(
        CommonConstants.transactionHistory.tr,
        style: CustomTextStyles.labelBlack500Size18Fw700,
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.nearlyWhite
              : Colors.black,
          size: ResponsiveUtil().getSize(24),
        ),
        onPressed: () {
          if (!isReturnHome) {
            Get.back();
            return;
          }
          // Switch to home tab instead of reloading home screen
          if (homeController != null) {
            homeController!.setValueBottomIndex(0);
          } else {
            Get.offAllNamed(Routes.HOME);
          }
        },
      ),
      actions: [
        Obx(() => (controller.selectedBrands.isNotEmpty ||
                controller.selectedStates.isNotEmpty)
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.nearlyWhite
                      : Colors.black,
                  size: ResponsiveUtil().getSize(24),
                ),
                tooltip: CommonConstants.resetFiltersTooltip.tr,
                onPressed: () {
                  controller.resetFilters();
                },
              )
            : SizedBox.shrink()),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: appController.isDarkModeOn.value
                ? ColorConstants.nearlyWhite
                : Colors.black,
            size: ResponsiveUtil().getSize(24),
          ),
          onPressed: () {
            // Use full screen for legacy users
            Navigator.of(Get.context!).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (BuildContext context) => TransactionFilters(
                  selectedFromDate: controller.selectedFromDate.value,
                  selectedToDate: controller.selectedToDate.value,
                  selectedBrands: controller.selectedBrands,
                  selectedStates: controller.selectedStates,
                  onBrandsChanged: controller.onBrandsChanged,
                  onStatesChanged: controller.onStatesChanged,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: appController.isDarkModeOn.value
                ? ColorConstants.nearlyWhite
                : Colors.black,
            size: ResponsiveUtil().getSize(24),
          ),
          onPressed: () {
            controller.getData();
          },
        ),
      ],
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // GW3 Layout following Figma design
  Widget _buildGw3Layout() {
    return Column(
      children: [
        // Fixed header (disabled collapsible for now to fix scroll issue)
        _buildCollapsibleHeader(),

        // Transaction List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.getData();
            },
            child: Obx(() {
              if (controller.isInitialLoading.value) {
                return const AdaptiveTransactionHistoryLoader();
              }

              if (controller.newsData.value == null ||
                  controller.newsData.value!.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildGw3EmptyState(),
                );
              }

              // Get data length here inside Obx to ensure reactivity
              final dataLength = controller.newsData.value?.length ?? 0;
              final hasMore = controller.hasMoreData.value;
              final itemCount = dataLength + (hasMore ? 1 : 0);

              return ListView.builder(
                key: const PageStorageKey<String>('gw3_transaction_list'),
                controller: controller.scrollController,
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // Show loading indicator at the end when there's more data
                  if (index == dataLength) {
                    return _buildLoadMoreIndicator();
                  }
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: RepaintBoundary(
                      key: ValueKey('gw3_transaction_$index'),
                      child: _buildGw3TransactionCard(index),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  // Collapsible header content
  Widget _buildCollapsibleHeader() {
    return Container(
      color: appController.isDarkModeOn.value
          ? ColorConstants.darkScaffoldBackgroundColor
          : Color(0xFFFBFBFB),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(height: 12),
          _buildGw3SearchField(),
          SizedBox(height: 16),
          _buildGw3DateSection(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // GW3 Search Field
  Widget _buildGw3SearchField() {
    return Container(
      height: 52,
      child: TextField(
        controller: controller.transactionIdController,
        onChanged: controller.onTransactionIdChanged,
        onSubmitted: (_) => controller.onSearchSubmitted(),
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF3A413A),
        ),
        decoration: InputDecoration(
          hintText: CommonConstants.searchTransactionId.tr,
          hintStyle: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: appController.isDarkModeOn.value
                ? ColorConstants.white
                : Color(0xFF382F41),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: appController.isDarkModeOn.value
                ? ColorConstants.white
                : Color(0xFF382F41),
            size: 24,
          ),
          suffixIcon: Obx(() => controller.searchText.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Color(0xFF827F85),
                    size: 24,
                  ),
                  onPressed: () {
                    controller.transactionIdController.clear();
                    controller.onTransactionIdChanged('');
                  },
                )
              : SizedBox.shrink()),
          filled: true,
          fillColor: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF7E01D7),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // GW3 Date Section
  Widget _buildGw3DateSection() {
    return Row(
      children: [
        // Start Date Field
        Expanded(
          child: _buildGw3DateField(
            isStartDate: true,
            date: controller.selectedFromDate.value,
          ),
        ),

        SizedBox(width: 16),

        // End Date Field
        Expanded(
          child: _buildGw3DateField(
            isStartDate: false,
            date: controller.selectedToDate.value,
          ),
        ),
      ],
    );
  }

  // GW3 Date Field
  Widget _buildGw3DateField({
    required bool isStartDate,
    required DateTime date,
  }) {
    return Obx(() => Container(
          height: 56, // increase touch target
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showGw3DatePicker(isStartDate),
              child: Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appController.isDarkModeOn.value
                        ? Color(0xFF4A5568)
                        : Color(0xFFCFD3D0),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        ImageConstant.iconHistoryDateRange,
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.white
                            : Color(0xFF382F41),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          StringUtils.dateToString(date),
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 16, // slightly larger for readability
                            fontWeight: FontWeight.w500,
                            color: appController.isDarkModeOn.value
                                ? Colors.white
                                : Color(0xFF3A413A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  // Show GW3 Date Picker Bottom Sheet
  void _showGw3DatePicker(bool isStartDate) {
    final DateTime initialDate = isStartDate
        ? controller.selectedFromDate.value
        : controller.selectedToDate.value;

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DatePickerBottomSheet(
        initialDate: initialDate,
        isDarkMode: appController.isDarkModeOn.value,
        onDateSelected: (selectedDate) {
          if (isStartDate) {
            controller.selectedFromDate.value = selectedDate;
          } else {
            controller.selectedToDate.value = selectedDate;
          }
          controller.getData();
          Navigator.pop(context);
        },
      ),
    );
  }

  // GW3 Empty State
  Widget _buildGw3EmptyState() {
    return SizedBox(
      height: MediaQuery.of(Get.context!).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              width: 171,
              height: 150,
              child: SvgPicture.asset(
                ImageConstant.iconHistoryEmpty,
                width: 171,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 24),

            // Title
            Text(
              CommonConstants.noTransactionFoundTitle.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : Color(0xFF382F41),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4),

            // Subtitle
            Text(
              CommonConstants.tryAdjustingFilters.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.8)
                    : Color(0xFF382F41),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Load more indicator widget
  Widget _buildLoadMoreIndicator() {
    return Obx(() => Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: controller.isLoading.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF7E01D7),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      CommonConstants.loadingMore.tr,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: appController.isDarkModeOn.value
                            ? Colors.white.withOpacity(0.7)
                            : Color(0xFF6B7280),
                      ),
                    ),
                  ],
                )
              : SizedBox(height: 40),
        ));
  }

  // GW3 Transaction Card with adaptive performance
  Widget _buildGw3TransactionCard(int index) {
    final transaction = controller.newsData.value?[index];
    if (transaction == null) return SizedBox();

    final detector = DevicePerformanceDetector.instance;
    final shouldSimplify =
        detector.isInitialized && detector.shouldUseSimplifiedUI();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          isTransactionFailed(
            transaction: transaction,
          )
              ? controller.showFailedTransactionDialog()
              : Get.toNamed(
                  Routes.TRANSACTION_HISTORY_DETAIL,
                  arguments: {
                    'mTransactionId': transaction.transactionId.toString(),
                    'originalRemarks': null,
                  },
                );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(shouldSimplify ? 8 : 12),
            color: appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : Colors.white,
            border: shouldSimplify
                ? null
                : Border.all(
                    color: appController.isDarkModeOn.value
                        ? Color(0xFF4A5568)
                        : Color(0xFFCFD3D0),
                    width: 1,
                  ),
            // Add simple border for low-spec devices
            boxShadow: shouldSimplify
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Brand icon + Transaction details + Amount & Type
                Row(
                  children: [
                    // Brand icon - Following Figma
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: appController.isDarkModeOn.value
                            ? Color(0xFF374151)
                            : Color(0xFFF9FAFB),
                        border: Border.all(
                          color: appController.isDarkModeOn.value
                              ? Color(0xFF4A5568)
                              : Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: getBrandImageWidget(
                        transaction.brandName ?? '',
                        isSGPLocation: appController.isSGPLocation(),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Transaction details (middle)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Transaction ID
                          Text(
                            transaction.transactionId ?? '',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: appController.isDarkModeOn.value
                                  ? Colors.white
                                  : Color(0xFF382F41),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 4),

                          // Transaction time
                          Text(
                            StringUtils.formatResponeDateTimeToString(
                              transaction.gatewayRequestDate ?? '',
                              'dd.MM.yyyy | HH:mm:ss',
                            ),
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: appController.isDarkModeOn.value
                                  ? Colors.white.withOpacity(0.7)
                                  : Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 12),

                    // Amount + Type (right side)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Amount
                        Text(
                          _formatGw3Amount(
                            transaction.totalAmount?.toString() ?? '',
                            transaction.transactionType?.toString() ?? '',
                            transaction.currency ?? '',
                          ),
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _getAmountColor(
                                transaction.transactionType?.toString() ?? ''),
                          ),
                        ),

                        SizedBox(height: 6),

                        // Payment type badge (below amount)
                        _buildGw3CompactTypeBadge(
                          transaction.transactionType?.toString() ?? '',
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Bottom row: Status badge only
                Row(
                  children: [
                    _buildGw3StatusBadge(
                      transaction.transactionState?.toString() ?? '',
                    ),
                    Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to format amount for GW3 design
  String _formatGw3Amount(
      String amount, String transactionType, String currency) {
    try {
      final doubleAmount = double.parse(StringUtils.toDollars(amount));
      final formattedAmount =
          StringUtils.formatAmount(doubleAmount, "#,##0.00#");

      // Check if it's a refund/void transaction type
      final isRefundType = [
        TransactionType.REFUND,
        TransactionType.VOID,
        TransactionType.REVERSE,
        TransactionType.EWALLET_VOID,
        GW3TransactionType.REFUND,
        GW3TransactionType.VOID,
      ].contains(transactionType);

      return isRefundType
          ? '$currency -$formattedAmount'
          : '$currency $formattedAmount';
    } catch (e) {
      return '$currency $amount';
    }
  }

  // Helper method to get amount color based on transaction type
  Color _getAmountColor(String transactionType) {
    final isRefundType = [
      TransactionType.REFUND,
      TransactionType.VOID,
      TransactionType.REVERSE,
      TransactionType.EWALLET_VOID,
      GW3TransactionType.REFUND,
      GW3TransactionType.VOID,
    ].contains(transactionType);

    if (isRefundType) {
      return Color(0xFFF75145); // Red for negative amounts
    } else {
      return appController.isDarkModeOn.value
          ? Colors.white
          : Color(0xFF382F41); // Default color for positive amounts
    }
  }

  // GW3 Status Badge with improved design (different from type badge)
  Widget _buildGw3StatusBadge(String transactionState) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (transactionState) {
      case TransactionState.STATE_SUCCESS:
      case TransactionState.STATE_AUTHORIZED:
      case TransactionState.STATE_SETTLEMENT_SUBMITTED:
      case GW3TransactionState.APPROVED:
      case GW3TransactionState.AUTHORIZED:
      case GW3TransactionState.CAPTURED:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF065F46).withOpacity(0.8)
            : Color(0xFFECFDF5);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFF34D399)
            : Color(0xFF065F46);
        text = CommonConstants.statusCompleted.tr;
        icon = Icons.check_circle_outline;
        break;
      case TransactionState.STATE_USER_PAYING:
      case GW3TransactionState.PENDING:
      case GW3TransactionState.REQUESTED:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF92400E).withOpacity(0.8)
            : Color(0xFFFEF3C7);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFFFBBF24)
            : Color(0xFF92400E);
        text = CommonConstants.statusPending.tr;
        icon = Icons.schedule_outlined;
        break;
      case TransactionState.STATE_ORDER_CLOSED:
      case TransactionState.STATE_DENIED:
      case TransactionState.STATE_SETTLEMENT_REJECTED:
      case GW3TransactionState.REJECTED:
      case GW3TransactionState.ERROR:
      case GW3TransactionState.EXPIRED:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF991B1B).withOpacity(0.8)
            : Color(0xFFFEE2E2);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFFEF4444)
            : Color(0xFF991B1B);
        text = CommonConstants.failed.tr;
        icon = Icons.error_outline;
        break;
      case GW3TransactionState.CANCELLED:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF991B1B).withOpacity(0.8)
            : Color(0xFFFEE2E2);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFFEF4444)
            : Color(0xFF991B1B);
        text = CommonConstants.statusCancelled.tr;
        icon = Icons.error_outline;
        break;
      case TransactionState.STATE_REVERSED:
      case TransactionState.STATE_VOIDED:
      case GW3TransactionState.VOIDED:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF7C2D12).withOpacity(0.8)
            : Color(0xFFFED7AA);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFFFB923C)
            : Color(0xFF7C2D12);
        text = CommonConstants.voided.tr;
        icon = Icons.block_outlined;
        break;
      case TransactionState.STATE_REFUNDED:
      case GW3TransactionState.REFUNDED:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF7C2D12).withOpacity(0.8)
            : Color(0xFFFED7AA);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFFFB923C)
            : Color(0xFF7C2D12);
        text = CommonConstants.refunded.tr;
        icon = Icons.replay_outlined;
        break;
      default:
        backgroundColor = appController.isDarkModeOn.value
            ? Color(0xFF374151).withOpacity(0.8)
            : Color(0xFFF3F4F6);
        textColor = appController.isDarkModeOn.value
            ? Color(0xFF9CA3AF)
            : Color(0xFF374151);
        text = CommonConstants.unknown.tr;
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // GW3 Compact Type Badge for display below amount
  Widget _buildGw3CompactTypeBadge(String transactionType) {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (transactionType) {
      case TransactionType.SALES:
        text = 'SALES';
        backgroundColor = Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case TransactionType.REFUND:
        text = 'REFUND';
        backgroundColor = Color(0xFFF75145);
        textColor = Colors.white;
        break;
      case TransactionType.VOID:
        text = 'VOID';
        backgroundColor = Color(0xFFF75145);
        textColor = Colors.white;
        break;
      case TransactionType.PREAUTH:
        text = 'PREAUTH';
        backgroundColor = Color(0xFFF59E0B);
        textColor = Colors.white;
        break;
      case TransactionType.QUICK_PAY:
        text = 'QUICK';
        backgroundColor = Color(0xFF7C3AED);
        textColor = Colors.white;
        break;
      case TransactionType.UNIFIED_ORDER:
        text = 'UNIFIED';
        backgroundColor = Color(0xFF3B82F6);
        textColor = Colors.white;
        break;
      case TransactionType.REVERSE:
        text = 'REVERSE';
        backgroundColor = Color(0xFFF75145);
        textColor = Colors.white;
        break;
      case TransactionType.EWALLET_VOID:
        text = 'E-VOID';
        backgroundColor = Color(0xFFF75145);
        textColor = Colors.white;
        break;
      case GW3TransactionType.SALE:
        text = 'SALE';
        backgroundColor = Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case GW3TransactionType.REFUND:
        text = 'REFUND';
        backgroundColor = Color(0xFFF75145);
        textColor = Colors.white;
        break;
      case GW3TransactionType.CAPTURE:
        text = 'CAPTURE';
        backgroundColor = Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case GW3TransactionType.VOID:
        text = 'VOID';
        backgroundColor = Color(0xFFF75145);
        textColor = Colors.white;
        break;
      case GW3TransactionType.AUTHORIZATION:
        text = 'AUTH';
        backgroundColor = Color(0xFFF59E0B);
        textColor = Colors.white;
        break;
      case GW3TransactionType.QUERY:
        text = 'QUERY';
        backgroundColor = Color(0xFF3B82F6);
        textColor = Colors.white;
        break;
      default:
        text = 'OTHER';
        backgroundColor = Color(0xFF6B7280);
        textColor = Colors.white;
        break;
    }

    // Dark mode adjustments
    if (appController.isDarkModeOn.value) {
      backgroundColor = backgroundColor.withOpacity(0.9);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Legacy Transaction Card with adaptive design
  Widget _buildLegacyTransactionCard(dynamic transaction, bool shouldSimplify) {
    return Material(
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : ColorConstants.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(shouldSimplify ? 8 : 12),
        splashColor: ColorConstants.backgroundColorButtonPrint.withOpacity(.26),
        onTap: () {
          isTransactionFailed(
            transaction: transaction,
          )
              ? controller.showFailedTransactionDialog()
              : Get.toNamed(
                  Routes.TRANSACTION_HISTORY_DETAIL,
                  arguments: {
                    'mTransactionId': transaction.transactionId.toString(),
                    'originalRemarks': null,
                  },
                );
        },
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: ResponsiveUtil().getSize(shouldSimplify ? 2 : 4),
            horizontal: ResponsiveUtil().getSize(shouldSimplify ? 2 : 4),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(shouldSimplify ? 8 : 12),
            color: appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : Colors.white,
            // Simplified shadows for low-spec devices
            boxShadow: shouldSimplify
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              width: 0.5,
              color: ColorConstants.colorBorderTextField.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
                ResponsiveUtil().getSize(shouldSimplify ? 12 : 16)),
            child: shouldSimplify
                ? _buildLegacySimplifiedContent(transaction)
                : _buildLegacyFullContent(transaction),
          ),
        ),
      ),
    );
  }

  // Simplified content for low-spec devices (2 rows)
  Widget _buildLegacySimplifiedContent(dynamic transaction) {
    return Column(
      children: [
        // Row 1: Brand + Transaction ID + Amount & Type
        Row(
          children: [
            // Smaller brand icon for low-spec
            Container(
              width: ResponsiveUtil().getSize(40),
              height: ResponsiveUtil().getSize(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.withOpacity(0.1),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(ResponsiveUtil().getSize(4)),
              child: getBrandImageWidget(
                transaction.brandName ?? '',
                height: ResponsiveUtil().getSize(32),
                isSGPLocation: appController.isSGPLocation(),
              ),
            ),

            SizedBox(width: ResponsiveUtil().getSize(12)),

            // Transaction ID and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction ID (smaller font)
                  Text(
                    transaction.transactionId ?? '',
                    style: TextStyle(
                      fontSize: ResponsiveUtil().getFontSize(14),
                      fontWeight: FontWeight.w600,
                      color: appController.isDarkModeOn.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtil().getSize(2)),

                  // Transaction time (smaller)
                  Text(
                    StringUtils.formatResponeDateTimeToString(
                      transaction.gatewayRequestDate ?? '',
                      'dd.MM.yy | HH:mm', // Shorter format for low-spec
                    ),
                    style: TextStyle(
                      fontSize: ResponsiveUtil().getFontSize(12),
                      fontWeight: FontWeight.w400,
                      color: appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: ResponsiveUtil().getSize(8)),

            // Amount + Type (right side)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount (smaller font)
                setTextTransactionAmount(
                  inputTransactionAmount: transaction.totalAmount.toString(),
                  inputTransactionType: transaction.transactionType.toString(),
                  currency: transaction.currency ?? '',
                ),
                SizedBox(height: ResponsiveUtil().getSize(4)),

                // Compact type badge
                _buildLegacyCompactTypeBadge(
                  transaction.transactionType.toString(),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: ResponsiveUtil().getSize(8)),

        // Row 2: Status badge only
        Row(
          children: [
            setTransactionState(
              inputTransactionState: transaction.transactionState.toString(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }

  // Full content for high-spec devices (original design)
  Widget _buildLegacyFullContent(dynamic transaction) {
    return Column(
      children: [
        // Top row: Brand + Transaction ID + Amount
        Row(
          children: [
            // Brand image with rounded container
            Container(
              width: ResponsiveUtil().getSize(64),
              height: ResponsiveUtil().getSize(64),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withOpacity(0.1),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(ResponsiveUtil().getSize(8)),
              child: getBrandImageWidget(
                transaction.brandName ?? '',
                height: ResponsiveUtil().getSize(48),
                isSGPLocation: appController.isSGPLocation(),
              ),
            ),
            SizedBox(width: ResponsiveUtil().getSize(16)),

            // Transaction ID and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction ID
                  Text(
                    transaction.transactionId ?? '',
                    style: TextStyle(
                      fontSize: ResponsiveUtil().getFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: appController.isDarkModeOn.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtil().getSize(4)),

                  // Transaction time
                  setTextTransactionTime(
                    inputTransactionTime: transaction.gatewayRequestDate ?? '',
                  ),
                  SizedBox(height: ResponsiveUtil().getSize(6)),

                  // Transaction state
                  setTransactionState(
                    inputTransactionState:
                        transaction.transactionState.toString(),
                  ),
                ],
              ),
            ),

            // Amount and Transaction Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                setTextTransactionAmount(
                  inputTransactionAmount: transaction.totalAmount.toString(),
                  inputTransactionType: transaction.transactionType.toString(),
                  currency: transaction.currency ?? '',
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                setTransactionTypeLabel(
                  inputTransactionType: transaction.transactionType.toString(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Compact type badge for legacy simplified view
  Widget _buildLegacyCompactTypeBadge(String transactionType) {
    String text;
    Color backgroundColor;

    switch (transactionType) {
      case TransactionType.SALES:
        text = 'SALES';
        backgroundColor = Color(0xFF10B981);
        break;
      case TransactionType.REFUND:
        text = 'REFUND';
        backgroundColor = Color(0xFFF75145);
        break;
      case TransactionType.VOID:
        text = 'VOID';
        backgroundColor = Color(0xFFF75145);
        break;
      case TransactionType.PREAUTH:
        text = 'PREAUTH';
        backgroundColor = Color(0xFFF59E0B);
        break;
      case TransactionType.QUICK_PAY:
        text = 'QUICK';
        backgroundColor = Color(0xFF7C3AED);
        break;
      case TransactionType.UNIFIED_ORDER:
        text = 'UNIFIED';
        backgroundColor = Color(0xFF3B82F6);
        break;
      case TransactionType.REVERSE:
        text = 'REVERSE';
        backgroundColor = Color(0xFFF75145);
        break;
      case TransactionType.EWALLET_VOID:
        text = 'E-VOID';
        backgroundColor = Color(0xFFF75145);
        break;
      default:
        text = 'OTHER';
        backgroundColor = Color(0xFF6B7280);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtil().getSize(6),
        vertical: ResponsiveUtil().getSize(2),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveUtil().getFontSize(9),
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Legacy Layout
  Widget _buildLegacyLayout() {
    return Column(
      children: [
        // Fixed header section (search + date pickers)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(
                height: ResponsiveUtil().getSize(10),
              ),
              TextField(
                controller: controller.transactionIdController,
                onChanged: controller.onTransactionIdChanged,
                onSubmitted: (_) => controller.onSearchSubmitted(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: CommonConstants.searchByTransactionId.tr,
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Obx(() => controller.searchText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            controller.transactionIdController.clear();
                            controller.onTransactionIdChanged('');
                          },
                        )
                      : SizedBox.shrink()),
                  filled: true,
                  fillColor: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorConstants.colorBorderTextField,
                      width: 0.6,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              SizedBox(height: ResponsiveUtil().getSize(16)),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          CommonConstants.startDate.tr,
                          style: CustomTextStyles.labelBlack500Size16Fw500,
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveUtil().getSize(20),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          CommonConstants.endDate.tr,
                          style: CustomTextStyles.labelBlack500Size16Fw500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveUtil().getSize(8),
                  ),
                  Row(
                    children: [
                      Obx(
                        () {
                          return Expanded(
                            flex: 1,
                            child: Material(
                              borderRadius: BorderRadius.circular(8),
                              color: ColorConstants.backgroundColorButtonPrint,
                              child: InkWell(
                                splashColor: ColorConstants
                                    .backgroundColorButtonPrint
                                    .withOpacity(.26),
                                onTap: () {
                                  controller.selectDate(Get.context!, true);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    StringUtils.dateToString(
                                        controller.selectedFromDate.value),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: CustomTextStyles
                                        .labelWhite700Size16Fw600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: ResponsiveUtil().getSize(20),
                      ),
                      Obx(
                        () {
                          return Expanded(
                            flex: 1,
                            child: Material(
                              borderRadius: BorderRadius.circular(8),
                              color: ColorConstants.backgroundColorButtonPrint,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                splashColor: ColorConstants
                                    .backgroundColorButtonPrint
                                    .withOpacity(.26),
                                onTap: () {
                                  controller.selectDate(Get.context!, false);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    StringUtils.dateToString(
                                        controller.selectedToDate.value),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: CustomTextStyles
                                        .labelWhite700Size16Fw600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: ResponsiveUtil().getSize(16),
              ),
            ],
          ),
        ),
        // Scrollable transaction list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.getData();
            },
            child: Obx(() {
              if (controller.isInitialLoading.value) {
                return const AdaptiveTransactionHistoryLoader();
              }

              if (controller.newsData.value == null ||
                  controller.newsData.value!.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(Get.context!).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/o7lite/images/lt_no_data_history.json',
                            height: ResponsiveUtil().getSize(200),
                            width: ResponsiveUtil().getSize(200),
                          ),
                          SizedBox(height: ResponsiveUtil().getSize(16)),
                          Text(
                            CommonConstants.noTransactionFound.tr,
                            style: CustomTextStyles.labelBlack500Size16Fw500,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveUtil().getSize(8)),
                          Text(
                            CommonConstants.tryAdjustingFilters.tr,
                            style: CustomTextStyles.labelGray500Size12Fw400,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return _buildLegacyTransactionListView();
            }),
          ),
        ),
      ],
    );
  }

  // Legacy Transaction ListView with scroll controller for load more
  Widget _buildLegacyTransactionListView() {
    final detector = DevicePerformanceDetector.instance;
    // Read data inside the method - parent Obx will trigger rebuild when data changes
    final dataLength = controller.newsData.value?.length ?? 0;
    final hasMore = controller.hasMoreData.value;
    final itemCount = dataLength + (hasMore ? 1 : 0);

    return ListView.builder(
      key: const PageStorageKey<String>('legacy_transaction_list'),
      controller: controller.scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent:
          detector.isInitialized ? detector.getOptimalCacheExtent() : 200.0,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show loading indicator at the end when there's more data
        if (index == dataLength) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Obx(() => controller.isLoading.value
                ? const JumpingDots()
                : SizedBox(height: 40)),
          );
        }

        final transaction = controller.newsData.value?[index];
        if (transaction == null) return SizedBox();

        final shouldSimplify =
            detector.isInitialized && detector.shouldUseSimplifiedUI();

        return Padding(
          padding: ResponsiveUtil().getPadding(bottom: shouldSimplify ? 6 : 10),
          child: RepaintBoundary(
            key: ValueKey('legacy_transaction_$index'),
            child: _buildLegacyTransactionCard(transaction, shouldSimplify),
          ),
        );
      },
    );
  }

  bool isTransactionFailed({required TransactionListResponse transaction}) {
    // if (transaction.transactionState == null ||
    //     transaction.transactionState == '' ||
    //     transaction.hostTxnId == null ||
    //     transaction.hostTxnId == '') {
    //   return true;
    // }

    if (transaction.transactionState == null ||
        transaction.transactionState == '') {
      return true;
    }

    final inputTransactionState = transaction.transactionState.toString();

    // GW3-aware branching: check GW3 states when in GW3 mode
    if (StorageService.isGw3) {
      switch (inputTransactionState) {
        case GW3TransactionState.REJECTED:
        case GW3TransactionState.ERROR:
          return true;
        case GW3TransactionState.APPROVED:
        case GW3TransactionState.CAPTURED:
        case GW3TransactionState.AUTHORIZED:
        case GW3TransactionState.PENDING:
        case GW3TransactionState.REQUESTED:
        case GW3TransactionState.REFUNDED:
        case GW3TransactionState.VOIDED:
        case GW3TransactionState.CANCELLED:
        case GW3TransactionState.EXPIRED:
          return false;
      }
      // Unrecognized GW3 state → treat as failed
      return true;
    }

    switch (inputTransactionState) {
      case TransactionState.STATE_USER_PAYING:
        return false;
      case TransactionState.STATE_ORDER_CLOSED:
      case TransactionState.STATE_DENIED:
      case TransactionState.STATE_SETTLEMENT_REJECTED:
        return true;
      case TransactionState.STATE_SUCCESS:
      case TransactionState.STATE_AUTHORIZED:
      case TransactionState.STATE_SETTLEMENT_SUBMITTED:
        return false;
      case TransactionState.STATE_REVERSED:
      case TransactionState.STATE_VOIDED:
        return false;
      case TransactionState.STATE_REFUNDED:
        return false;
      default:
        false;
        break;
    }
    return true;
  }

  Widget setTransactionState({required String inputTransactionState}) {
    Color colorTransactionState = Colors.blue;
    Color colorTextTransactionState = Colors.blue;
    String mTransactionState = '';

    switch (inputTransactionState) {
      case TransactionState.STATE_USER_PAYING:
        mTransactionState = CommonConstants.paying.tr;
        colorTransactionState = Colors.grey.withOpacity(.2);
        colorTextTransactionState = Colors.grey;
        break;
      case TransactionState.STATE_ORDER_CLOSED:
      case TransactionState.STATE_DENIED:
      case TransactionState.STATE_SETTLEMENT_REJECTED:
        mTransactionState = CommonConstants.failed.tr;
        colorTransactionState = appController.isDarkModeOn == true
            ? Colors.red
            : Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
      case TransactionState.STATE_SUCCESS:
      case TransactionState.STATE_AUTHORIZED:
      case TransactionState.STATE_SETTLEMENT_SUBMITTED:
        mTransactionState = CommonConstants.success.tr;
        colorTransactionState = appController.isDarkModeOn == true
            ? ColorConstants.greenColorText
            : ColorConstants.greenColorBoder;
        colorTextTransactionState = ColorConstants.greenColorText;
        break;
      case TransactionState.STATE_REVERSED:
      case TransactionState.STATE_VOIDED:
        mTransactionState = CommonConstants.voided.tr;
        colorTransactionState = appController.isDarkModeOn == true
            ? Colors.red
            : Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
      case TransactionState.STATE_REFUNDED:
        mTransactionState = CommonConstants.refund.tr;
        colorTransactionState = appController.isDarkModeOn == true
            ? Colors.red
            : Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
      default:
        mTransactionState = CommonConstants.failed.tr;
        colorTransactionState = appController.isDarkModeOn == true
            ? Colors.red
            : Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorTransactionState,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Text(
          mTransactionState,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? ColorConstants.nearlyWhite
                : colorTextTransactionState,
            fontSize: ResponsiveUtil().getFontSize(
              12,
            ),
          ),
        ),
      ),
    );
  }

  Widget setTextTransactionTime({required String inputTransactionTime}) {
    var transactiontime = StringUtils.formatResponeDateTimeToString(
        inputTransactionTime, StringUtils.dateFormatddMMyyyyHHMMss);

    return Text(
      transactiontime,
      maxLines: 1,
      style: CustomTextStyles.labelGray500Size12Fw400,
    );
  }

  Widget setTextTransactionAmount({
    required String inputTransactionAmount,
    required String inputTransactionType,
    required String currency,
  }) {
    var transactionAmount = inputTransactionAmount;
    Color colorTransactionAmount = Colors.black;

    switch (inputTransactionType) {
      case TransactionType.PREAUTH:
      case TransactionType.SALES:
      case TransactionType.QUICK_PAY:
      case TransactionType.UNIFIED_ORDER:
        transactionAmount =
            '$currency ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(inputTransactionAmount)), "#,##0.00")}';

        colorTransactionAmount = Colors.black;
        break;
      case TransactionType.REFUND:
      case TransactionType.VOID:
      case TransactionType.REVERSE:
      case TransactionType.EWALLET_VOID:
        transactionAmount =
            '$currency -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(inputTransactionAmount)), "#,##0.00")}';
        colorTransactionAmount = appTheme.red300;
        break;
      default:
        break;
    }

    return Text(
      transactionAmount,
      maxLines: 1,
      style: TextStyle(
        color: appController.isDarkModeOn.value
            ? appTheme.whiteA700
            : colorTransactionAmount,
        fontSize: ResponsiveUtil().getFontSize(
          14,
        ),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget setTransactionTypeLabel({required String inputTransactionType}) {
    String labelText = '';
    Color backgroundColor = Colors.blue;
    Color textColor = Colors.white;
    bool isRefundType = false;
    IconData? iconData;

    switch (inputTransactionType) {
      case TransactionType.PREAUTH:
        labelText = 'PREAUTH';
        backgroundColor = Colors.orange[600]!;
        textColor = Colors.white;
        iconData = Icons.pending_actions;
        break;
      case TransactionType.SALES:
        labelText = 'SALES';
        backgroundColor = ColorConstants.greenColorText;
        textColor = Colors.white;
        iconData = Icons.shopping_bag;
        break;
      case TransactionType.QUICK_PAY:
        labelText = 'QUICK PAY';
        backgroundColor = Colors.purple[600]!;
        textColor = Colors.white;
        iconData = Icons.flash_on;
        break;
      case TransactionType.UNIFIED_ORDER:
        labelText = 'UNIFIED';
        backgroundColor = Colors.blue[600]!;
        textColor = Colors.white;
        iconData = Icons.receipt_long;
        break;
      case TransactionType.REFUND:
        labelText = 'REFUND';
        isRefundType = true;
        iconData = Icons.undo;
        break;
      case TransactionType.VOID:
        labelText = 'VOID';
        isRefundType = true;
        iconData = Icons.cancel;
        break;
      case TransactionType.REVERSE:
        labelText = 'REVERSE';
        isRefundType = true;
        iconData = Icons.keyboard_return;
        break;
      case TransactionType.EWALLET_VOID:
        labelText = 'E-VOID';
        isRefundType = true;
        iconData = Icons.money_off;
        break;
      default:
        labelText = 'UNKNOWN';
        backgroundColor = Colors.grey[600]!;
        textColor = Colors.white;
        iconData = Icons.help;
        break;
    }

    // Special styling for refund types
    if (isRefundType) {
      backgroundColor = Colors.red[600]!;
      textColor = Colors.white;
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil().getSize(12),
          vertical: ResponsiveUtil().getSize(6)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        gradient: isRefundType
            ? LinearGradient(
                colors: [Colors.red[600]!, Colors.red[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isRefundType
                ? Colors.red.withOpacity(0.3)
                : backgroundColor.withOpacity(0.3),
            blurRadius: isRefundType ? 8 : 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: ResponsiveUtil().getSize(14),
            color: textColor,
          ),
          SizedBox(width: ResponsiveUtil().getSize(4)),
          Text(
            labelText,
            style: TextStyle(
              fontSize: ResponsiveUtil().getFontSize(11),
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Date Picker Bottom Sheet Widget
class _DatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final bool isDarkMode;
  final Function(DateTime) onDateSelected;

  const _DatePickerBottomSheet({
    Key? key,
    required this.initialDate,
    required this.isDarkMode,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _DatePickerBottomSheetState createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<_DatePickerBottomSheet> {
  late DateTime currentMonth;
  late DateTime selectedDate;
  final DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    currentMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    selectedDate = widget.initialDate;
  }

  void previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
  }

  void selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void confirmDate() {
    widget.onDateSelected(selectedDate);
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;
    final bool isLowSpec =
        detector.isInitialized && detector.shouldUseSimplifiedUI();
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? ColorConstants.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with month navigation
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFF4F4F5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left arrow
                GestureDetector(
                  onTap: previousMonth,
                  child: Container(
                    width: isLowSpec ? 48 : 40,
                    height: isLowSpec ? 48 : 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Color(0xFFE4E5E8).withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: 2),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: isLowSpec ? 20 : 18,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Color(0xFF09090B),
                        ),
                      ),
                    ),
                  ),
                ),

                // Month title
                Text(
                  '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Color(0xFF09090B),
                  ),
                ),

                // Right arrow
                GestureDetector(
                  onTap: nextMonth,
                  child: Container(
                    width: isLowSpec ? 48 : 40,
                    height: isLowSpec ? 48 : 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Color(0xFFE4E5E8).withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: isLowSpec ? 20 : 18,
                        color: widget.isDarkMode
                            ? Colors.white
                            : Color(0xFF09090B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Calendar content
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Weekdays header
                  Container(
                    height: 32,
                    child: Row(
                      children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                          .map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF71717A),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  // Calendar grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final daysInMonth = DateTime(
                                currentMonth.year, currentMonth.month + 1, 0)
                            .day;
                        final firstDayOfMonth =
                            DateTime(currentMonth.year, currentMonth.month, 1);
                        final firstWeekday = (firstDayOfMonth.weekday - 1) % 7;
                        final totalCells = daysInMonth + firstWeekday;

                        return GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            // Skip empty cells before month starts
                            if (index < firstWeekday) {
                              return Container(); // Empty space
                            }

                            final int dayOfMonth = index - firstWeekday + 1;
                            final DateTime displayDate = DateTime(
                              currentMonth.year,
                              currentMonth.month,
                              dayOfMonth,
                            );

                            final bool isSelected =
                                displayDate.day == selectedDate.day &&
                                    displayDate.month == selectedDate.month &&
                                    displayDate.year == selectedDate.year;
                            final bool isToday = displayDate.day == today.day &&
                                displayDate.month == today.month &&
                                displayDate.year == today.year;
                            final bool isFuture = displayDate.isAfter(today);

                            final double cellSize = isLowSpec ? 48 : 40;
                            final double circleSize = isLowSpec ? 40 : 32;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: isFuture
                                  ? null
                                  : () => selectDate(displayDate),
                              child: Center(
                                child: SizedBox(
                                  width: cellSize,
                                  height: cellSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Today circle indicator
                                      if (isToday && !isSelected)
                                        Container(
                                          width: circleSize,
                                          height: circleSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Color(0xFF7357FF),
                                              width: 1,
                                            ),
                                          ),
                                        ),

                                      // Selected circle background
                                      if (isSelected)
                                        Container(
                                          width: circleSize,
                                          height: circleSize,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF7357FF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),

                                      // Date text
                                      Text(
                                        '${displayDate.day}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: isLowSpec ? 15 : 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isFuture
                                              ? (widget.isDarkMode
                                                  ? Colors.white
                                                      .withOpacity(0.3)
                                                  : Color(0xFF9CA3AF))
                                              : (isSelected
                                                  ? Colors.white
                                                  : (widget.isDarkMode
                                                      ? Colors.white
                                                      : Color(0xFF3F3F46))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            height: 80,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF4F4F5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Selected date display
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? ColorConstants.grey800
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Color(0xFF4A5568)
                            : Color(0xFFDFE1E7),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')} / ${selectedDate.month.toString().padLeft(2, '0')} / ${selectedDate.year}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Color(0xFF3F3F46),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 40),

                // Set Date button
                Expanded(
                  child: Container(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: confirmDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7E01D7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        CommonConstants.setDate.tr,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
