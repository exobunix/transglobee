import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/models/payment_method_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';

import '../../../utils/toast.dart';

class PaymentController extends GetxController {


  // paypal
  Rx<TextEditingController> paypalNameController = TextEditingController().obs;
  Rx<TextEditingController> paypalClientKeyController = TextEditingController().obs;
  Rx<TextEditingController> paypalSecretKeyController = TextEditingController().obs;
  Rx<Status> isPaypalActive = Status.active.obs;
  Rx<Status> isPaypalSandBox = Status.active.obs;

  // payStack
  Rx<TextEditingController> payStackNameController = TextEditingController().obs;
  Rx<TextEditingController> payStackSecretKeyController = TextEditingController().obs;
  Rx<Status> isPayStackActive = Status.active.obs;


  // razorpay
  Rx<TextEditingController> razorpayNameController = TextEditingController(text: 'Razorpay').obs;
  Rx<TextEditingController> razorpayKeyController = TextEditingController().obs;
  Rx<TextEditingController> razorpaySecretController = TextEditingController().obs;
  Rx<Status> isRazorpayActive = Status.active.obs;
  Rx<Status> isRazorPaySandBox = Status.active.obs;

  // stripe
  Rx<TextEditingController> stripeNameController = TextEditingController().obs;
  Rx<TextEditingController> clientPublishableKeyController = TextEditingController().obs;
  Rx<TextEditingController> stripeSecretKeyController = TextEditingController().obs;
  Rx<Status> isStripeActive = Status.active.obs;
  Rx<Status> isStripeSandBox = Status.active.obs;

  // mercadoPogo
  Rx<TextEditingController> mercadoPogoNameController = TextEditingController().obs;
  Rx<TextEditingController> mercadoPogoAccessTokenController = TextEditingController().obs;
  Rx<Status> isMercadoPogoActive = Status.active.obs;

  // payFast
  Rx<TextEditingController> payFastNameController = TextEditingController().obs;
  Rx<TextEditingController> payFastMerchantKeyController = TextEditingController().obs;
  Rx<TextEditingController> payFastMerchantIDController = TextEditingController().obs;
  Rx<TextEditingController> payFastReturnUrlController = TextEditingController().obs;
  Rx<TextEditingController> payFastNotifyUrlController = TextEditingController().obs;
  Rx<TextEditingController> payFastCancelUrlController = TextEditingController().obs;
  Rx<Status> isPayFastSandBox = Status.active.obs;
  Rx<Status> isPayFastActive = Status.active.obs;

  // flutterWave
  Rx<TextEditingController> flutterWaveNameController = TextEditingController().obs;
  Rx<TextEditingController> flutterWavePublicKeyKeyController = TextEditingController().obs;
  Rx<TextEditingController> flutterWaveSecretKeyKeyController = TextEditingController().obs;
  Rx<Status> isFlutterWaveActive = Status.active.obs;
  Rx<Status> isFlutterWaveSandBox = Status.active.obs;

  //cash
  Rx<TextEditingController> cashNameController = TextEditingController(text: 'Cash').obs;
  Rx<Status> isCashActive = Status.active.obs;

  //wallet
  Rx<TextEditingController> walletNameController = TextEditingController(text: 'Wallet').obs;
  Rx<Status> isWalletActive = Status.active.obs;

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxString title = "Payment".tr.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() async {
    isLoading(true);
    await getPaymentData();
    isLoading(false);
    super.onInit();
  }


  Future<void> getPaymentData() async {
    try {
      final value = await FireStoreUtils.getPayment();
      if (value != null) {
        paymentModel.value = value;

        //paypal
        if (value.paypal != null) {
          paypalNameController.value.text = paymentModel.value.paypal!.name ?? '';
          paypalClientKeyController.value.text = paymentModel.value.paypal!.paypalClient ?? '';
          paypalSecretKeyController.value.text = paymentModel.value.paypal!.paypalSecret ?? '';
          isPaypalActive.value = paymentModel.value.paypal!.isActive == true ? Status.active : Status.inactive;
          isPaypalSandBox.value = paymentModel.value.paypal!.isSandbox == true ? Status.active : Status.inactive;
        }
        //razorpay
        if (value.razorpay != null) {
          razorpayNameController.value.text = paymentModel.value.razorpay!.name ?? 'Razorpay';
          razorpayKeyController.value.text = paymentModel.value.razorpay!.razorpayKey ?? '';
          razorpaySecretController.value.text = paymentModel.value.razorpay!.razorpaySecret ?? '';
          isRazorpayActive.value = paymentModel.value.razorpay!.isActive == true ? Status.active : Status.inactive;
          isRazorPaySandBox.value = paymentModel.value.razorpay!.isSandbox == true ? Status.active : Status.inactive;
        }
        //stripe
        if (value.strip != null) {
          stripeNameController.value.text = paymentModel.value.strip!.name ?? '';
          clientPublishableKeyController.value.text = paymentModel.value.strip!.clientPublishableKey ?? '';
          stripeSecretKeyController.value.text = paymentModel.value.strip!.stripeSecret ?? '';
          isStripeActive.value = paymentModel.value.strip!.isActive == true ? Status.active : Status.inactive;
          isStripeSandBox.value = paymentModel.value.strip!.isSandbox == true ? Status.active : Status.inactive;
        }
        //cash
        if (value.cash != null) {
          cashNameController.value.text = paymentModel.value.cash!.name ?? 'Cash';
          isCashActive.value = paymentModel.value.cash!.isActive == true ? Status.active : Status.inactive;
        }
        //wallet
        if (value.wallet != null) {
          walletNameController.value.text = paymentModel.value.wallet!.name ?? 'Wallet';
          isWalletActive.value = paymentModel.value.wallet!.isActive == true ? Status.active : Status.inactive;
        }
      }
    } catch (e) {
      log("Firestore payment load note: $e");
    }

    // Always fetch backend gateway config from Node server
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/payments/admin/gateway-config");
      final res = await http.get(uri, headers: ApiConstant.headers(token: token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final d = body['data'];
          razorpayNameController.value.text = 'Razorpay';
          if (d['keyId'] != null && d['keyId'].toString().isNotEmpty) {
            razorpayKeyController.value.text = d['keyId'];
          }
          if (d['keySecret'] != null && d['keySecret'].toString().isNotEmpty) {
            razorpaySecretController.value.text = d['keySecret'];
          }
          if (d['isEnabled'] != null) {
            isRazorpayActive.value = d['isEnabled'] == true ? Status.active : Status.inactive;
          }
          if (d['isSandbox'] != null) {
            isRazorPaySandBox.value = d['isSandbox'] == true ? Status.active : Status.inactive;
          }
        }
      }
    } catch (e) {
      log("Error fetching backend gateway config: $e");
    }
  }
  Future<void> savePayment() async {
    // Validate Razorpay if active
    if (isRazorpayActive.value == Status.active) {
      if (razorpayKeyController.value.text.trim().isEmpty) {
        return ShowToast.errorToast("Please Add Razorpay Key ID".tr);
      }
      if (razorpaySecretController.value.text.trim().isEmpty) {
        return ShowToast.errorToast("Please Add Razorpay Secret Key".tr);
      }
    }

    Constant.waitingLoader();

    // 1. Sync directly with Node.js Backend Gateway Config
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/payments/admin/gateway-config");
      final body = jsonEncode({
        "gateway": "razorpay",
        "keyId": razorpayKeyController.value.text.trim(),
        "keySecret": razorpaySecretController.value.text.trim(),
        "isEnabled": isRazorpayActive.value == Status.active,
        "isSandbox": isRazorPaySandBox.value == Status.active,
      });
      final res = await http.post(uri, headers: ApiConstant.headers(token: token), body: body);
      log("Backend gateway config response: ${res.statusCode} ${res.body}");
    } catch (e) {
      log("Error saving gateway config to backend: $e");
    }

    // 2. Also update Firestore model if available
    try {
      paymentModel.value.razorpay?.name = razorpayNameController.value.text.trim();
      paymentModel.value.razorpay?.razorpayKey = razorpayKeyController.value.text.trim();
      paymentModel.value.razorpay?.razorpaySecret = razorpaySecretController.value.text.trim();
      paymentModel.value.razorpay?.isActive = isRazorpayActive.value == Status.active;
      paymentModel.value.razorpay?.isSandbox = isRazorPaySandBox.value == Status.active;

      paymentModel.value.cash?.name = cashNameController.value.text.trim();
      paymentModel.value.cash?.isActive = isCashActive.value == Status.active;

      paymentModel.value.wallet?.name = walletNameController.value.text.trim();
      paymentModel.value.wallet?.isActive = isWalletActive.value == Status.active;

      await FireStoreUtils.setPayment(paymentModel.value);
    } catch (e) {
      log("Firestore payment update note: $e");
    }

    Get.back();
    ShowToast.successToast("Payment settings updated successfully".tr);
  }
}
