import 'package:app/models/response/transaction_list_response/transaction_list_response.dart';
import 'package:app/shared/utils/log_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api/api_repository.dart';
import '../../../app_controller.dart';
import '../../../models/request/querry_transaction_list_request/querry_transaction_list_request.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/custom_dialog/custom_dialog.dart';
import '../../../shared/widgets/string_utils.dart';
import 'dart:async';

class TransactionHistoryController extends GetxController {
  final ApiRepository apiRepository;
  TransactionHistoryController({required this.apiRepository});

  final AppController appController = Get.find();
  final ScrollController scrollController = ScrollController();
  Timer? _debounce;

  RxBool isInitialLoading = true.obs;
  RxBool isLoading = false.obs;

  // Transaction list data
  final Rxn<List<TransactionListResponse>> newsData =
      Rxn<List<TransactionListResponse>>();

  // New filter variables
  final TextEditingController transactionIdController = TextEditingController();
  RxString searchText = ''.obs;
  RxList<String> selectedBrands = <String>[].obs;
  RxList<String> selectedStates = <String>[].obs;
  RxList<String> selectedTypes = <String>[].obs;

  // Date range variables
  Rx<DateTime> selectedFromDate =
      DateTime.now().obs; //DateTime.now().subtract(Duration(days: 7)).obs;
  Rx<DateTime> selectedToDate = DateTime.now().obs;

  late DateTime mCurrentDate;
  String? mTransactionState;
  String? mDateFrom;
  String? mDateTo;
  String? oldestDate;

  RxInt iCurrentPage = 1.obs;
  RxInt iTotalPage = 0.obs;
  RxBool hasMoreData = true.obs;
  static const int pageSize = 20;
  static const double _loadMoreThreshold = 200.0;

  // For collapsible header
  RxBool isHeaderVisible = true.obs;
  double _lastScrollPosition = 0.0;
  static const double _scrollThreshold =
      10.0; // Minimum scroll to trigger hide/show

  final RxBool isLoadingGetAdsTaskPoint = false.obs;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    transactionIdController.addListener(() {
      searchText.value = transactionIdController.text;
    });
    getData();
  }

  @override
  void onClose() {
    _isDisposed = true;
    _debounce?.cancel();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    // transactionIdController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (_isDisposed || !scrollController.hasClients) return;
    final position = scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Handle header visibility based on scroll direction
    _handleHeaderVisibility(currentScroll);

    // Don't trigger load more if already loading or no more data
    if (isLoading.value || !hasMoreData.value) return;

    // Only trigger load more if:
    // 1. List is scrollable (maxScroll > 0)
    // 2. User is near the bottom (within threshold)
    // 3. User is scrolling down (not bouncing back)
    if (maxScroll > 0 &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _loadMoreThreshold) {
      iCurrentPage.value++;
      LogUtils.debugLog('iCurrentPage: ${iCurrentPage.value}');
      LogUtils.debugLog('isLoadMore: true');
      getData(isLoadMore: true);
    }
  }

  void _handleHeaderVisibility(double currentScroll) {
    // Calculate scroll delta
    final scrollDelta = currentScroll - _lastScrollPosition;

    // Only react if scroll delta exceeds threshold
    if (scrollDelta.abs() > _scrollThreshold) {
      if (scrollDelta > 0 && currentScroll > 50) {
        // Scrolling down and past initial area - hide header
        if (isHeaderVisible.value) {
          isHeaderVisible.value = false;
        }
      } else if (scrollDelta < 0) {
        // Scrolling up - show header
        if (!isHeaderVisible.value) {
          isHeaderVisible.value = true;
        }
      }
      _lastScrollPosition = currentScroll;
    }

    // Always show header when at top
    if (currentScroll <= 0) {
      isHeaderVisible.value = true;
      _lastScrollPosition = 0;
    }
  }

  Future<void> getData({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      isInitialLoading.value = true;
      newsData.value = [];
      iCurrentPage.value = 1;
      hasMoreData.value = true;
    } else {
      if (!hasMoreData.value) return;
      isLoading.value = true;
    }

    try {
      final convertStartDate = convertToGW2StartDate(selectedFromDate.value);
      final convertEndDate = convertToGW2SameOrEndDate(
          selectedFromDate.value, selectedToDate.value);

      final request = QuerryTransactionListRequest(
        startDate: convertStartDate,
        endDate: convertEndDate,
        page: iCurrentPage.toString(),
        pageSize: pageSize,
      );

      if (StorageService.isGw3) {
        request.startDate = StringUtils.dateToStringWithFormat(
            selectedFromDate.value, 'yyyy-MM-dd');
        request.endDate = StringUtils.dateToStringWithFormat(
            selectedToDate.value, 'yyyy-MM-dd');
        request.transactionId = searchText.value.trim();
        request.brands = selectedBrands;
        request.states = selectedStates;
        request.page = iCurrentPage.toString();
        request.pageSize = pageSize;
      }

      final response = await apiRepository.querryTransactionList(request);

      if (response != null) {
        var newTransactions = response.transactionList ?? [];

        // Check if we have more data to load
        if (newTransactions.length < pageSize) {
          hasMoreData.value = false;
        }

        if (isLoadMore && newsData.value != null) {
          // Append new data to existing list (API returns sorted by date desc)
          newsData.value = [...newsData.value!, ...newTransactions];
        } else {
          newsData.value = newTransactions;
        }
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      LogUtils.debugLog(e);
      hasMoreData.value = false;
    } finally {
      isInitialLoading.value = false;
      isLoading.value = false;
    }
  }

  String convertToGW2EndDate(DateTime date) {
    return StringUtils.convertToGW2EndDate(date);
  }

  String convertToGW2StartDate(DateTime date) {
    return StringUtils.convertToGW2StartDate(date);
  }

  String convertToGW2SameOrEndDate(DateTime fromDate, DateTime toDate) {
    return (fromDate.year == toDate.year &&
            fromDate.month == toDate.month &&
            fromDate.day == toDate.day)
        ? StringUtils.convertToGW2SameDate(toDate)
        : StringUtils.convertToGW2EndDate(toDate);
  }

  Future<void> selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? selectedFromDate.value : selectedToDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      if (isFromDate) {
        selectedFromDate.value = picked;
      } else {
        selectedToDate.value = picked;
      }
      getData();
    }
  }

  void onTransactionIdChanged(String value) {
    searchText.value = value;
    // debounce 500ms
    onSearchSubmitted();
  }

  void onSearchSubmitted() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    // debounce 500ms
    _debounce = Timer(Duration(milliseconds: 500), () {
      getData();
    });
  }

  void onBrandsChanged(List<String> brands) {
    selectedBrands.clear();
    selectedBrands.addAll(brands);
    getData();
  }

  void onStatesChanged(List<String> states) {
    selectedStates.clear();
    selectedStates.addAll(states);
    getData();
  }

  void onTypesChanged(List<String> types) {
    selectedTypes.clear();
    selectedTypes.addAll(types);
    getData();
  }

  void showFailedTransactionDialog() {
    CustomDialog.showMaterial(
      Get.context!,
      CommonConstants.transactionFailed.tr,
      textTitle: Text(CommonConstants.dialogPaymentStatusTitle.tr),
      btnText: CommonConstants.ok.tr,
      onPressed: () {
        Get.back();
      },
    );
  }

  void resetFilters() {
    // Clear all filters
    selectedBrands.clear();
    selectedStates.clear();
    selectedTypes.clear();
    transactionIdController.clear();
    searchText.value = '';

    // Reset date range to default if needed
    // selectedFromDate.value = DateTime.now().subtract(Duration(days: 7));
    // selectedToDate.value = DateTime.now();

    // Reload data
    getData();
  }
}
