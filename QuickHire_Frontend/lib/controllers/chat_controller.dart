import 'package:get/get.dart';
import '../services/service_chat.dart';

class ChatController extends GetxController {
  final ChatService chatService = Get.find();

  @override
  void onInit() {
    super.onInit();
    chatService.init();
  }

  @override
  void onClose() {
    chatService.onClose();
    super.onClose();
  }
}
