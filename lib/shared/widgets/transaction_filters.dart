import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/common.dart';
import '../constants/constants_o7lite.dart';
import '../utils/responsive_util.dart';
import '../../app_controller.dart';
import '../widgets/custom_text_style.dart';
import '../widgets/string_utils.dart';
import '../services/storage_service.dart';
import 'package:app/shared/utils/log_utils.dart';

class TransactionFilters extends StatefulWidget {
  final DateTime selectedFromDate;
  final DateTime selectedToDate;
  final List<String> selectedBrands;
  final List<String> selectedStates;
  // final Function(DateTime, DateTime) onDateRangeChanged;
  final Function(List<String>) onBrandsChanged;
  final Function(List<String>) onStatesChanged;

  TransactionFilters({
    Key? key,
    required this.selectedFromDate,
    required this.selectedToDate,
    required this.selectedBrands,
    required this.selectedStates,
    // required this.onDateRangeChanged,
    required this.onBrandsChanged,
    required this.onStatesChanged,
  }) : super(key: key);

  // Static method to show GW3 bottom sheet
  static void showGw3FilterBottomSheet({
    required BuildContext context,
    required List<String> selectedBrands,
    required List<String> selectedStates,
    required List<String> selectedTypes,
    required Function(List<String>) onBrandsChanged,
    required Function(List<String>) onStatesChanged,
    required Function(List<String>) onTypesChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _Gw3FilterBottomSheet(
        selectedBrands: selectedBrands,
        selectedStates: selectedStates,
        selectedTypes: selectedTypes,
        onBrandsChanged: onBrandsChanged,
        onStatesChanged: onStatesChanged,
        onTypesChanged: onTypesChanged,
      ),
    );
  }

  @override
  State<TransactionFilters> createState() => _TransactionFiltersState();
}

// GW3 Bottom Sheet Widget
class _Gw3FilterBottomSheet extends StatefulWidget {
  final List<String> selectedBrands;
  final List<String> selectedStates;
  final List<String> selectedTypes;
  final Function(List<String>) onBrandsChanged;
  final Function(List<String>) onStatesChanged;
  final Function(List<String>) onTypesChanged;

  const _Gw3FilterBottomSheet({
    Key? key,
    required this.selectedBrands,
    required this.selectedStates,
    required this.selectedTypes,
    required this.onBrandsChanged,
    required this.onStatesChanged,
    required this.onTypesChanged,
  }) : super(key: key);

  @override
  State<_Gw3FilterBottomSheet> createState() => _Gw3FilterBottomSheetState();
}

class _Gw3FilterBottomSheetState extends State<_Gw3FilterBottomSheet> {
  final AppController appController = Get.find();
  late List<String> selectedBrandsRx;
  late List<String> selectedStatesRx;
  late List<String> selectedTypesRx;

  // Convert brandOptions to regular List
  List<String> brandOptions = <String>[
    ConstantsO7Lite.BRAND_ALIPAY,
    ConstantsO7Lite.BRAND_WECHAT,
    ConstantsO7Lite.BRAND_GRABPAY,
    ConstantsO7Lite.BRAND_ATOME,
    ConstantsO7Lite.BRAND_BOOST,
    ConstantsO7Lite.BRAND_TNG,
    ConstantsO7Lite.BRAND_SHOPEE,
    ConstantsO7Lite.BRAND_VISA,
    ConstantsO7Lite.BRAND_MASTERCARD,
    ConstantsO7Lite.BRAND_AMEX,
    ConstantsO7Lite.BRAND_PAYNOW,
  ];

  final List<String> stateOptions = [
    GW3TransactionState.APPROVED,
    GW3TransactionState.REQUESTED,
    GW3TransactionState.AUTHORIZED,
    GW3TransactionState.PENDING,
    GW3TransactionState.REJECTED,
    GW3TransactionState.ERROR,
    GW3TransactionState.EXPIRED,
    GW3TransactionState.VOIDED,
    GW3TransactionState.REFUNDED,
    GW3TransactionState.CAPTURED,
  ];

  final List<String> typeOptions = [
    GW3TransactionType.SALE,
    GW3TransactionType.AUTHORIZATION,
    GW3TransactionType.REFUND,
    GW3TransactionType.QUERY,
    GW3TransactionType.VOID,
    GW3TransactionType.CAPTURE,
  ];

  @override
  void initState() {
    super.initState();
    selectedBrandsRx = List<String>.from(widget.selectedBrands);
    selectedStatesRx = List<String>.from(widget.selectedStates);
    selectedTypesRx = List<String>.from(widget.selectedTypes);
    _loadTerminalDetails();
  }

  // Normalize brand names for comparison
  String _normalizeBrandName(String brandName) {
    // Convert to lowercase and keep only core brand name
    final normalized = brandName
        .toLowerCase()
        .replaceAll('host', '')
        .replaceAll('pay', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z]'), '');
    return normalized;
  }

  // Check if brand is selected using normalized comparison
  bool _isBrandSelected(String option, List<String> selectedBrands) {
    final normalizedOption = _normalizeBrandName(option);
    final isSelected = selectedBrands
        .any((selected) => _normalizeBrandName(selected) == normalizedOption);
    return isSelected;
  }

  Future<void> _loadTerminalDetails() async {
    try {
      final terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();
      if (terminalDetail != null && terminalDetail.routes.isNotEmpty) {
        final newBrands = terminalDetail.routes
            .where((route) =>
                route.brand.isNotEmpty &&
                !route.brand.contains(RegExp(r'[^\w\s]')))
            .map((route) => route.brand)
            .toList();

        setState(() {
          brandOptions = [...newBrands];
        });
      }
    } catch (e) {
      LogUtils.debugLog('Error loading terminal details: $e');
    }
  }

  void _applyFilters() {
    widget.onBrandsChanged(selectedBrandsRx);
    widget.onStatesChanged(selectedStatesRx);
    widget.onTypesChanged(selectedTypesRx);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      selectedBrandsRx.clear();
      selectedStatesRx.clear();
      selectedTypesRx.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 613,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Color(0xFFFBFBFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                SizedBox(width: 24), // Space for symmetry
                Expanded(
                  child: Text(
                    'filterTitle'.tr,
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
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: appController.isDarkModeOn.value
                        ? Colors.white
                        : Color(0xFF382F41),
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),

                  // Payment Methods Section
                  _buildGw3SectionHeader('filterPaymentMethods'.tr),
                  SizedBox(height: 16),
                  _buildGw3FilterChipSection(
                    brandOptions,
                    selectedBrandsRx,
                    (brand, selected) {
                      setState(() {
                        if (selected) {
                          selectedBrandsRx.add(brand);
                        } else {
                          selectedBrandsRx.remove(brand);
                        }
                      });
                    },
                    useNormalizedComparison: true,
                  ),

                  SizedBox(height: 32),

                  // Transaction Types Section
                  _buildGw3SectionHeader('filterTransactionType'.tr),
                  SizedBox(height: 16),
                  _buildGw3FilterChipSection(
                    typeOptions,
                    selectedTypesRx,
                    (type, selected) {
                      setState(() {
                        if (selected) {
                          selectedTypesRx.add(type);
                        } else {
                          selectedTypesRx.remove(type);
                        }
                      });
                    },
                  ),

                  SizedBox(height: 32),

                  // Transaction States Section
                  _buildGw3SectionHeader('filterTransactionStates'.tr),
                  SizedBox(height: 16),
                  _buildGw3FilterChipSection(
                    stateOptions,
                    selectedStatesRx,
                    (state, selected) {
                      setState(() {
                        if (selected) {
                          selectedStatesRx.add(state);
                        } else {
                          selectedStatesRx.remove(state);
                        }
                      });
                    },
                    labelBuilder: _getTransactionStateLabel,
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            height: 104,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7E01D7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'filterApply'.tr,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGw3SectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color:
            appController.isDarkModeOn.value ? Colors.white : Color(0xFF382F41),
      ),
    );
  }

  Widget _buildGw3FilterChipSection(
    List<String> options,
    List<String> selectedValues,
    Function(String, bool) onSelected, {
    String Function(String)? labelBuilder,
    bool useNormalizedComparison = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = useNormalizedComparison
            ? _isBrandSelected(option, selectedValues)
            : selectedValues.contains(option);
        return GestureDetector(
          onTap: () => onSelected(option, !isSelected),
          child: Container(
            height: 34,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(0xFF7E01D7)
                  : (appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : Color(0xFFF7F7F7)),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected
                    ? Color(0xFF7E01D7)
                    : (appController.isDarkModeOn.value
                        ? Color(0xFF4A5568)
                        : Color(0xFFCFD3D0)),
                width: 1,
              ),
            ),
            child: Text(
              labelBuilder?.call(option.toUpperCase()) ?? option.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (appController.isDarkModeOn.value
                        ? Colors.white
                        : Color(0xFF382F41)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getTransactionStateLabel(String state) {
    switch (state) {
      case TransactionState.STATE_SUCCESS:
        return CommonConstants.success.tr;
      case TransactionState.STATE_USER_PAYING:
        return CommonConstants.paying.tr;
      case TransactionState.STATE_VOIDED:
        return CommonConstants.voided.tr;
      case TransactionState.STATE_REFUNDED:
        return CommonConstants.refund.tr;
      case TransactionState.STATE_DENIED:
        return CommonConstants.failed.tr;
      case TransactionState.STATE_ORDER_CLOSED:
        return 'filterOrderClosed'.tr;
      default:
        return state;
    }
  }
}

class _TransactionFiltersState extends State<TransactionFilters> {
  final AppController appController = Get.find();
  late RxList<String> selectedBrandsRx;
  late RxList<String> selectedStatesRx;
  late Rx<DateTime> selectedFromDateRx;
  late Rx<DateTime> selectedToDateRx;
  late RxList<String> selectedTypesRx;

  // Convert brandOptions to RxList
  final RxList<String> brandOptions = <String>[
    ConstantsO7Lite.BRAND_ALIPAY,
    ConstantsO7Lite.BRAND_WECHAT,
    ConstantsO7Lite.BRAND_GRABPAY,
    ConstantsO7Lite.BRAND_ATOME,
    ConstantsO7Lite.BRAND_BOOST,
    ConstantsO7Lite.BRAND_TNG,
    ConstantsO7Lite.BRAND_SHOPEE,
    ConstantsO7Lite.BRAND_VISA,
    ConstantsO7Lite.BRAND_MASTERCARD,
    ConstantsO7Lite.BRAND_AMEX,
    ConstantsO7Lite.BRAND_PAYNOW,
  ].obs;

  final List<String> stateOptions = [
    GW3TransactionState.APPROVED,
    GW3TransactionState.REQUESTED,
    GW3TransactionState.AUTHORIZED,
    GW3TransactionState.PENDING,
    GW3TransactionState.REJECTED,
    GW3TransactionState.ERROR,
    GW3TransactionState.EXPIRED,
    GW3TransactionState.VOIDED,
    GW3TransactionState.REFUNDED,
    GW3TransactionState.CAPTURED,
  ];

  final List<String> typeOptions = [
    GW3TransactionType.SALE,
    GW3TransactionType.AUTHORIZATION,
    GW3TransactionType.REFUND,
    GW3TransactionType.QUERY,
    GW3TransactionType.VOID,
    GW3TransactionType.CAPTURE,
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with copies of the original lists
    selectedBrandsRx = RxList<String>.from(widget.selectedBrands);
    selectedStatesRx = RxList<String>.from(widget.selectedStates);
    selectedFromDateRx = widget.selectedFromDate.obs;
    selectedToDateRx = widget.selectedToDate.obs;
    selectedTypesRx = RxList<String>();

    // Load terminal details immediately
    _loadTerminalDetails();
  }

  Future<void> _loadTerminalDetails() async {
    try {
      EasyLoading.show(status: '${CommonConstants.loading.tr}...');

      final terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();
      if (terminalDetail != null && terminalDetail.routes.isNotEmpty) {
        final newBrands = terminalDetail.routes
            .where((route) =>
                route.brand.isNotEmpty &&
                !route.brand.contains(RegExp(r'[^\w\s]')))
            .map((route) => route.brand)
            .toList();

        // Update the RxList using update method
        brandOptions.call([...newBrands]);
      }
    } catch (e) {
      LogUtils.debugLog('Error loading terminal details: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _applyFilters() {
    widget.onBrandsChanged(selectedBrandsRx);
    widget.onStatesChanged(selectedStatesRx);
    // widget.onDateRangeChanged(selectedFromDateRx.value, selectedToDateRx.value);
    Navigator.pop(context);
  }

  void _resetFilters() {
    selectedBrandsRx.clear();
    selectedStatesRx.clear();
    selectedTypesRx.clear();
    selectedFromDateRx.value = DateTime.now().subtract(Duration(days: 7));
    selectedToDateRx.value = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: appController.isDarkModeOn.value
                ? ColorConstants.nearlyWhite
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'filterFilters'.tr,
          style: CustomTextStyles.labelBlack500Size18Fw700,
        ),
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              _resetFilters();
            },
            child: Text(
              'filterReset'.tr,
              style: TextStyle(
                color: ColorConstants.backgroundColorButtonPrint,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('filterPaymentMethods'.tr),
                      SizedBox(height: ResponsiveUtil().getSize(16)),
                      Obx(() => _buildFilterChipSection(
                            brandOptions,
                            selectedBrandsRx,
                            (brand, selected) {
                              if (selected) {
                                selectedBrandsRx.add(brand);
                              } else {
                                selectedBrandsRx.remove(brand);
                              }
                            },
                          )),
                      SizedBox(height: ResponsiveUtil().getSize(32)),
                      _buildSectionHeader('filterTransactionTypes'.tr),
                      SizedBox(height: ResponsiveUtil().getSize(16)),
                      _buildFilterChipSection(
                        typeOptions,
                        selectedTypesRx,
                        (type, selected) {
                          if (selected) {
                            selectedTypesRx.add(type);
                          } else {
                            selectedTypesRx.remove(type);
                          }
                        },
                      ),
                      SizedBox(height: ResponsiveUtil().getSize(32)),
                      _buildSectionHeader('filterTransactionStates'.tr),
                      SizedBox(height: ResponsiveUtil().getSize(16)),
                      _buildFilterChipSection(
                        stateOptions,
                        selectedStatesRx,
                        (state, selected) {
                          if (selected) {
                            selectedStatesRx.add(state);
                          } else {
                            selectedStatesRx.remove(state);
                          }
                        },
                        labelBuilder: _getTransactionStateLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: ColorConstants.colorBorderTextField,
                    width: 0.6,
                  ),
                ),
              ),
              child: Center(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.backgroundColorButtonPrint,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'filterApply'.tr,
                    style: CustomTextStyles.labelWhite700Size16Fw600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime selectedDate,
    Function(DateTime?) onDateSelected,
  ) {
    return Material(
      color: ColorConstants.backgroundColorButtonPrint,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          onDateSelected(picked);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            StringUtils.dateToString(selectedDate),
            textAlign: TextAlign.center,
            style: CustomTextStyles.labelWhite700Size16Fw600,
          ),
        ),
      ),
    );
  }

  String _getTransactionStateLabel(String state) {
    switch (state) {
      case TransactionState.STATE_SUCCESS:
        return CommonConstants.success.tr;
      case TransactionState.STATE_USER_PAYING:
        return CommonConstants.paying.tr;
      case TransactionState.STATE_VOIDED:
        return CommonConstants.voided.tr;
      case TransactionState.STATE_REFUNDED:
        return CommonConstants.refund.tr;
      case TransactionState.STATE_DENIED:
        return CommonConstants.failed.tr;
      case TransactionState.STATE_ORDER_CLOSED:
        return 'filterOrderClosed'.tr;
      default:
        return state;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: CustomTextStyles.labelBlack500Size16Fw500.copyWith(
          color: appController.isDarkModeOn.value
              ? ColorConstants.nearlyWhite
              : Colors.black,
        ),
      ),
    );
  }

  Widget _buildFilterChipSection(
    List<String> options,
    RxList<String> selectedValues,
    Function(String, bool) onSelected, {
    String Function(String)? labelBuilder,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? (ColorConstants.grey800 ?? Colors.grey[800])!.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.colorBorderTextField,
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Wrap(
            spacing: 8,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);
              return FilterChip(
                label: Text(labelBuilder?.call(option.toUpperCase()) ??
                    option.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) => onSelected(option, selected),
                backgroundColor: appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.white,
                selectedColor:
                    ColorConstants.backgroundColorButtonPrint.withOpacity(0.2),
                checkmarkColor: ColorConstants.backgroundColorButtonPrint,
                labelStyle: TextStyle(
                  color: isSelected
                      ? ColorConstants.backgroundColorButtonPrint
                      : appController.isDarkModeOn.value
                          ? ColorConstants.nearlyWhite
                          : Colors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? ColorConstants.backgroundColorButtonPrint
                        : ColorConstants.colorBorderTextField,
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }
}
