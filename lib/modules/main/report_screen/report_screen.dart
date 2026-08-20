import 'package:app/shared/utils/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/string_utils.dart';
import '../../../app_controller.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../shared/widgets/custom_text_style.dart';
import '../home_controller.dart';
import 'report_controller.dart';

class ReportScreen extends GetView<ReportController> {
  ReportScreen({Key? key}) : super(key: key);

  final AppController appController = Get.find();
  final HomeController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StorageService.isGw3
          ? (appController.isDarkModeOn.value
              ? ColorConstants.darkScaffoldBackgroundColor
              : Color(0xFFFBFBFB))
          : (appController.isDarkModeOn.value ? null : Colors.white),
      appBar: StorageService.isGw3 ? _buildGw3AppBar() : _buildLegacyAppBar(),
      body: StorageService.isGw3
          ? _buildGw3Layout(context)
          : _buildLegacyLayout(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: appController.isMobileUser.value
              ? const SizedBox.shrink()
              : (StorageService.isGw3
                  ? _buildGw3PrintButton(context)
                  : printButton(context)),
        );
      }),
    );
  }

  // GW3 AppBar following Figma design
  PreferredSizeWidget _buildGw3AppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.reports.tr,
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
        onPressed: () => Get.back(),
      ),
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
        CommonConstants.reports.tr,
        style: CustomTextStyles.labelBlack500Size18Fw700,
      ),
      leading: IconButton(
        onPressed: () {
          Get.back();
        },
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : ColorConstants.black,
          size: ResponsiveUtil().getSize(24),
        ),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // GW3 Layout following Figma design
  Widget _buildGw3Layout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RefreshIndicator(
        onRefresh: () async {
          controller.onRefresh();
        },
        child: SingleChildScrollView(
          child: Obx(() => Column(
                children: [
                  SizedBox(height: 16),

                  // Date Selector
                  _buildGw3DateSelector(context),

                  SizedBox(height: 24),

                  // Summary Container
                  _buildGw3SummaryContainer(),

                  SizedBox(height: 100),
                ],
              )),
        ),
      ),
    );
  }

  // GW3 Date Selector
  Widget _buildGw3DateSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CommonConstants.startDate.tr,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
        ),

        SizedBox(height: 12),

        // Date Selector Field
        Container(
          height: 52,
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showGw3DatePicker(),
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
                  boxShadow: [
                    BoxShadow(
                      color: appController.isDarkModeOn.value
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Color(0xFF827F85),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          StringUtils.dateToString(
                              controller.selectedFromDate.value),
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: appController.isDarkModeOn.value
                                ? Colors.white
                                : Color(0xFF382F41),
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
        ),
      ],
    );
  }

  // GW3 Summary Container
  Widget _buildGw3SummaryContainer() {
    return RepaintBoundary(
      key: controller.cardKey,
      child: Container(
        width: double.infinity,
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
          boxShadow: [
            BoxShadow(
              color: appController.isDarkModeOn.value
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              _buildGw3SummaryHeader(),

              SizedBox(height: 20),

              // Summary Stats
              _buildGw3SummaryStats(),

              SizedBox(height: 20),

              // Transaction List
              _buildGw3TransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  // GW3 Summary Header
  Widget _buildGw3SummaryHeader() {
    return Column(
      children: [
        controller.setTextDailySummaryTitle(),
        SizedBox(height: 8),
        Text(
          StringUtils.dateToString(controller.selectedFromDate.value),
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.8)
                : Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // GW3 Summary Stats
  Widget _buildGw3SummaryStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? Color(0xFF374151)
            : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildGw3StatRow('reportTid'.tr, controller.getTerminalID.value),
          SizedBox(height: 16),
          _buildGw3StatRow(
            CommonConstants.txnAmount.tr,
            StringUtils.formatAmount(
              double.parse(
                  StringUtils.toDollars(controller.transactionAmount.value)),
              "#,##0.00",
            ),
          ),
          SizedBox(height: 16),
          _buildGw3StatRow(
            CommonConstants.txnCount.tr,
            controller.transactionCount.value.isNotEmpty
                ? controller.transactionCount.value
                : '',
          ),
          SizedBox(height: 16),
          _buildGw3StatRow(
            'reportRefundAmount'.tr,
            controller.transactionVoidAmount.value.isNotEmpty
                ? StringUtils.formatAmount(
                    double.parse(StringUtils.toDollars(
                        controller.transactionVoidAmount.value)),
                    "#,##0.00",
                  )
                : '',
          ),
          SizedBox(height: 16),
          _buildGw3StatRow(
            'reportRefundCount'.tr,
            controller.transactionVoidCount.value.isNotEmpty
                ? controller.transactionVoidCount.value
                : '',
          ),
        ],
      ),
    );
  }

  // GW3 Stat Row
  Widget _buildGw3StatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.8)
                : Color(0xFF6B7280),
          ),
        ),
        Text(
          controller.listData.value != null ? value : '',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
        ),
      ],
    );
  }

  // GW3 Transaction List
  Widget _buildGw3TransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: controller.listData.value?.transactionList?.length ?? 0,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _buildGw3TransactionItem(index),
        );
      },
    );
  }

  // GW3 Transaction Item
  Widget _buildGw3TransactionItem(int index) {
    final transaction = controller.listData.value?.transactionList?[index];
    if (transaction == null) return SizedBox();

    return Container(
      decoration: BoxDecoration(
        color:
            appController.isDarkModeOn.value ? Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Brand icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: appController.isDarkModeOn.value
                    ? Color(0xFF4A5568)
                    : Color(0xFFF3F4F6),
              ),
              padding: EdgeInsets.all(8),
              child: controller.setImageBrand(
                  brandName: transaction.brandName ?? ''),
            ),

            SizedBox(width: 12),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type
                  controller.setTextTransactionItemType(
                    inputTransactionType: transaction.type.toString(),
                  ),

                  SizedBox(height: 4),

                  // Transaction time
                  controller.setTextTransactionItemTime(
                    inputTransactionTime:
                        transaction.gatewayResponseDate.toString() != "null"
                            ? transaction.gatewayResponseDate.toString()
                            : transaction.gatewayRequestDate.toString(),
                  ),
                ],
              ),
            ),

            // Amount
            controller.setTextTransactionItemAmount(
              inputTransactionType: transaction.type.toString(),
              inputTransactionAmount: transaction.totalAmount.toString(),
              inputTransactionCurrency: transaction.currency.toString(),
            ),
          ],
        ),
      ),
    );
  }

  // Show GW3 Date Picker Bottom Sheet
  void _showGw3DatePicker() {
    final DateTime initialDate = controller.selectedFromDate.value;

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DatePickerBottomSheet(
        initialDate: initialDate,
        isDarkMode: appController.isDarkModeOn.value,
        onDateSelected: (selectedDate) {
          controller.selectedFromDate.value = selectedDate;
          controller.onRefresh();
          Navigator.pop(context);
        },
      ),
    );
  }

  // GW3 Print Button
  Widget _buildGw3PrintButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => controller.onPrintClicked(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7E01D7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(80),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              ImageConstant.iconPrint,
              height: 24,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              CommonConstants.print.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Legacy Layout
  Widget _buildLegacyLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RefreshIndicator(
        onRefresh: () async {
          controller.onRefresh();
        },
        child: SingleChildScrollView(
          child: Obx(
            () => Column(
              children: [
                SizedBox(height: ResponsiveUtil().getSize(10)),
                dateSelectorRow(
                    title1: CommonConstants.startDate.tr, context: context),
                SizedBox(height: ResponsiveUtil().getSize(40)),
                summaryContainer(),
                SizedBox(height: ResponsiveUtil().getSize(100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dateSelectorRow({
    required BuildContext context,
    required String title1,
  }) {
    return Column(
      children: [
        Text(
          title1,
          style: CustomTextStyles.labelBlack500Size16Fw500,
        ),
        SizedBox(height: ResponsiveUtil().getSize(16)),
        dateSelectorWidget(
          onTap: () => controller.selectDate(
            context,
          ),
        ),
      ],
    );
  }

  Widget dateSelectorWidget({
    required GestureTapCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: ColorConstants.backgroundColorButtonPrint,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: ColorConstants.backgroundColorButtonPrint,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              StringUtils.dateToString(controller.selectedFromDate.value),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: CustomTextStyles.labelWhite700Size16Fw600,
            ),
          ),
        ),
      ),
    );
  }

  Widget summaryContainer() {
    return RepaintBoundary(
      key: controller.cardKey,
      child: Container(
        decoration: BoxDecoration(
          color: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : ColorConstants.colorBackgroundDigital,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: ResponsiveUtil().getPadding(all: 16),
          child: Column(
            children: [
              controller.setTextDailySummaryTitle(),
              SizedBox(height: ResponsiveUtil().getSize(4)),
              Text(
                StringUtils.dateToString(controller.selectedFromDate.value),
                style: CustomTextStyles.labelBlue300Size14Fw500,
              ),
              SizedBox(height: ResponsiveUtil().getSize(10)),
              Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: ResponsiveUtil().getPadding(all: 16),
                  child: Column(
                    children: [
                      rowReportWidget(
                          'reportTid'.tr, controller.getTerminalID.value),
                      SizedBox(height: ResponsiveUtil().getSize(20)),
                      rowReportWidget(
                        CommonConstants.txnAmount.tr,
                        StringUtils.formatAmount(
                            double.parse(StringUtils.toDollars(
                                controller.transactionAmount.value)),
                            "#,##0.00"),
                      ),
                      SizedBox(height: ResponsiveUtil().getSize(20)),
                      rowReportWidget(
                        CommonConstants.txnCount.tr,
                        controller.transactionCount.value.isNotEmpty
                            ? controller.transactionCount.value
                            : '',
                      ),
                      SizedBox(height: ResponsiveUtil().getSize(20)),
                      rowReportWidget(
                        CommonConstants.voidAmt.tr,
                        controller.transactionVoidAmount.value.isNotEmpty
                            ? StringUtils.formatAmount(
                                double.parse(
                                  StringUtils.toDollars(
                                    controller.transactionVoidAmount.value,
                                  ),
                                ),
                                "#,##0.00")
                            : '',
                      ),
                      SizedBox(height: ResponsiveUtil().getSize(20)),
                      rowReportWidget(
                        CommonConstants.voidCount.tr,
                        controller.transactionVoidCount.value.isNotEmpty
                            ? controller.transactionVoidCount.value
                            : '',
                      ),
                      SizedBox(height: ResponsiveUtil().getSize(20)),
                      transactionHistoryWidget(
                        title: CommonConstants.sale.tr,
                        amount: 'SGD-0.01',
                        style: CustomTextStyles.labelRed300Size14Fw600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget rowReportWidget(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: CustomTextStyles.labelGray666400Size14Fw400,
        ),
        Text(
          controller.listData.value != null ? value : '',
          style: CustomTextStyles.labelBlack500Size14Fw600,
        ),
      ],
    );
  }

  Widget transactionHistoryWidget({
    required String title,
    required String amount,
    required TextStyle style,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: controller.listData.value?.transactionList?.length ?? 0,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: ResponsiveUtil().getPadding(bottom: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  width: .6, color: ColorConstants.colorBorderTextField),
            ),
            child: ListTile(
              leading: controller.setImageBrand(
                brandName: controller
                        .listData.value?.transactionList?[index].brandName ??
                    '',
              ),
              title: controller.setTextTransactionItemType(
                inputTransactionType: controller
                        .listData.value?.transactionList?[index].type
                        .toString() ??
                    '',
              ),
              trailing: controller.setTextTransactionItemAmount(
                inputTransactionType: controller
                        .listData.value?.transactionList?[index].type
                        .toString() ??
                    '',
                inputTransactionAmount: controller
                        .listData.value?.transactionList?[index].totalAmount
                        .toString() ??
                    '',
                inputTransactionCurrency: controller
                        .listData.value?.transactionList?[index].currency
                        .toString() ??
                    '',
              ),
              subtitle: controller.setTextTransactionItemTime(
                  inputTransactionTime: controller.listData.value
                              ?.transactionList?[index].gatewayResponseDate
                              .toString() !=
                          "null"
                      ? controller.listData.value?.transactionList![index]
                          .gatewayResponseDate
                          .toString()
                      : controller.listData.value?.transactionList?[index]
                          .gatewayRequestDate
                          .toString()),
            ),
          ),
        );
      },
    );
  }

  Widget printButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        controller.onPrintClicked(context);
      },
      style: ButtonStyle(
        backgroundColor:
            WidgetStatePropertyAll(ColorConstants.backgroundColorButtonPrint),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              ImageConstant.iconPrint,
              height: ResponsiveUtil().getSize(24),
            ),
            SizedBox(width: ResponsiveUtil().getSize(8)),
            Text(
              CommonConstants.print.tr,
              style: CustomTextStyles.labelWhite700Size16Fw600,
            ),
          ],
        ),
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
                    width: 40,
                    height: 40,
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
                          size: 18,
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
                    width: 40,
                    height: 40,
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
                        size: 18,
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

                            return GestureDetector(
                              onTap: isFuture
                                  ? null
                                  : () => selectDate(displayDate),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                child: Center(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Today circle indicator
                                        if (isToday && !isSelected)
                                          Container(
                                            width: 32,
                                            height: 32,
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
                                            width: 32,
                                            height: 32,
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
                                            fontSize: 14,
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
                        'reportSetDate'.tr,
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
