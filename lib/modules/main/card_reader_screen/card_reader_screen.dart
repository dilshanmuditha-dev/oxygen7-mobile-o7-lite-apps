import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'card_reader_controller.dart';

class CardReaderScreen extends GetView<CardReaderController> {
  const CardReaderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('cardReaderPaymentTitle'.tr),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.cardReaderFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Reader Status
              Obx(() => Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: controller.isCardReaderReady.value
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: controller.isCardReaderReady.value
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.isCardReaderReady.value
                              ? Icons.check_circle
                              : Icons.access_time,
                          color: controller.isCardReaderReady.value
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.cardReaderStatus.value,
                            style: TextStyle(
                              color: controller.isCardReaderReady.value
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: controller.amountController,
                focusNode: controller.amountFocus,
                decoration: InputDecoration(
                  labelText: 'amount'.tr,
                  hintText: 'cardReaderEnterAmount'.tr,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'cardReaderPleaseEnterAmount'.tr;
                  }
                  if (double.tryParse(value) == null) {
                    return 'cardReaderPleaseEnterValidAmount'.tr;
                  }
                  return null;
                },
                onChanged: controller.updateAmount,
              ),

              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: controller.descriptionController,
                focusNode: controller.descriptionFocus,
                decoration: InputDecoration(
                  labelText: 'cardReaderDescriptionOptional'.tr,
                  hintText: 'cardReaderEnterPaymentDescription'.tr,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 32),

              // Process Payment Button
              Obx(() => ElevatedButton(
                    onPressed: controller.isProcessingPayment.value
                        ? null
                        : () => controller.processCardPayment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isCardReaderReady.value &&
                              !controller.isProcessingPayment.value
                          ? Colors.blue
                          : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      controller.isProcessingPayment.value
                          ? 'processingStatus'.tr
                          : 'cardReaderProcessCardPayment'.tr,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )),

              const SizedBox(height: 16),

              // Retry Button
              Obx(() => !controller.isCardReaderReady.value
                  ? ElevatedButton(
                      onPressed: controller.retryInitialization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'cardReaderRetryInitialization'.tr,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    )
                  : Container()),

              const SizedBox(height: 16),

              // Status Check Button
              ElevatedButton(
                onPressed: controller.checkReaderStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'cardReaderCheckReaderStatus'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

              const Spacer(),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cardReaderMineSecTitle'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'cardReaderMineSecDescription'.tr,
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
