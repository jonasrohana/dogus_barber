import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../../controller+api/user_controller.dart';
import '../../utils/colors.dart';
import '../../utils/models.dart';
import '../../utils/widgets.dart';

Future<void> navigateToChat(context, String otherUserId, bool isVendor, {bool doublePop = false}) async {

  if(FirebaseAuth.instance.currentUser == null) return;

  String uid = FirebaseAuth.instance.currentUser!.uid;
  Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
  Employee? emp = Provider.of<UserController>(context, listen: false).getEmployeeById(isVendor ? uid : otherUserId);
  if(emp == null) {
    return;
  }

  List<String> userIds = [uid, otherUserId];
  userIds.sort();
  var query = await FirebaseFirestore.instance
    .collection("vendors").doc(vendor.id)
    .collection("rooms")
    .where("userIds", isEqualTo: userIds)
    .limit(1)
    .get();

  if(query.docs.isEmpty) {

    List<ChatUser> userArray = [];
    if(isVendor) {
      var doc = await FirebaseFirestore.instance.collection("user").doc(otherUserId).get();
      if(!doc.exists) return;
      UserProfile cus = UserProfile.fromMap(doc.data() as Map<String,dynamic>);
      userArray = [
        ChatUser(userId: cus.id, name: cus.name, imageUrl: cus.imageUrl),
        ChatUser(userId: uid, name: emp.name, imageUrl: emp.imageUrl)
      ];
    }
    else {
      UserProfile? user = Provider.of<UserController>(context, listen: false).getUserProfile;
      userArray = [
        ChatUser(userId: uid, name: user!.name, imageUrl: user.imageUrl),
        ChatUser(userId: otherUserId, name: emp.name, imageUrl: emp.imageUrl)
      ];
    }

    Room room = Room(id: "", userIds: userIds, lastMessageTime: DateTime.now(),
      lastMessage: "", lastMessageSenderId: "", unread: [otherUserId], chatUser: userArray);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatDetail(vendorId: vendor.id, room: room, createNew: true)),
    );
    if(doublePop) {
      Navigator.pop(context);
    }
  }
  else {
    Room room = Room.fromMap(query.docs.first.data());
    if(room.unread.contains(uid)) {
      FirebaseFirestore.instance
        .collection("vendors").doc(vendor.id)
        .collection("rooms").doc(room.id)
        .update({ "unread": FieldValue.arrayRemove([uid]) });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatDetail(vendorId: vendor.id, room: room)),
    );
    if(doublePop) {
      Navigator.pop(context);
    }
  }
}

class ChatDetail extends StatefulWidget {

  final String vendorId;
  final Room room;
  final bool createNew;

  const ChatDetail({
    super.key,
    required this.vendorId,
    required this.room,
    this.createNew = false
  });

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {

  late Room room = widget.room;
  late bool createNewRoom = widget.createNew;

  StreamSubscription? messageStream;
  List<types.Message> messages = [];

  // listen to document changes and update document
  void onMessageDataChange(QuerySnapshot event) {
    for (var docChange in event.docChanges)  {
      if(docChange.type == DocumentChangeType.added) {
        int index = messages.indexWhere((element) => element.id == docChange.doc.id);
        if(index == -1) {

          // construct message and add to message list
          Map<String, dynamic> data = docChange.doc.data() as Map<String, dynamic>;
          ChatUser user = room.chatUser.firstWhere((element) => element.userId == data['authorId']);
          types.User author = types.User(id: user.userId, firstName: user.name, imageUrl: user.imageUrl);
          data['author'] = author.toJson();
          data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
          data['id'] = docChange.doc.id;
          data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;
          setState(() => messages.insert(0, types.Message.fromJson(data)));
        }
      }
    }
  }

  void initMessageStream() {
    messageStream = FirebaseFirestore.instance
      .collection('vendors/${widget.vendorId}/rooms/${room.id}/messages')
      .orderBy('createdAt', descending: false)
      .snapshots().listen(onMessageDataChange);
  }

  Future<void> sendMessage(dynamic partialMessage) async {
    types.Message? message;

    String uid = FirebaseAuth.instance.currentUser!.uid;
    if (partialMessage is types.PartialCustom) {
      message = types.CustomMessage.fromPartial(
        author: types.User(id: uid),
        id: '',
        partialCustom: partialMessage,
      );
    } else if (partialMessage is types.PartialFile) {
      message = types.FileMessage.fromPartial(
        author: types.User(id: uid),
        id: '',
        partialFile: partialMessage,
      );
    } else if (partialMessage is types.PartialImage) {
      message = types.ImageMessage.fromPartial(
        author: types.User(id: uid),
        id: '',
        partialImage: partialMessage,
      );
    } else if (partialMessage is types.PartialText) {
      message = types.TextMessage.fromPartial(
        author: types.User(id: uid),
        id: '',
        partialText: partialMessage,
      );
    }

    if (message != null) {
      final messageMap = message.toJson();
      messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
      messageMap['authorId'] = uid;
      messageMap['createdAt'] = FieldValue.serverTimestamp();
      messageMap['updatedAt'] = FieldValue.serverTimestamp();

      // there is no active chat -> create new room
      if(createNewRoom) {
        var doc = FirebaseFirestore.instance
          .collection('vendors').doc(widget.vendorId)
          .collection('rooms').doc();
        room.id = doc.id;
        await doc.set(room.toMap());
        createNewRoom = false;
        initMessageStream();
      }

      // push message to firestore
      await FirebaseFirestore.instance
        .collection('vendors/${widget.vendorId}/rooms/${room.id}/messages')
        .add(messageMap);
    }
  }

  @override
  void initState() {
    if(!widget.createNew) {
      initMessageStream();
    }
    super.initState();
  }

  @override
  void dispose() {
    messageStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: appBar,
      body: body,
    );
  }

  PreferredSizeWidget get appBar {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    ChatUser otherUser = room.chatUser.firstWhere((element) => element.userId != uid);

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: SafeArea(
        child: Container(
          color: colors.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              BackButton(color: colors.textColor),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ImageViewer(hero: otherUser.userId, url: otherUser.imageUrl))
                      ),
                      child: ProfileImageCircle(otherUser.imageUrl, 45, hero: otherUser.userId)
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        otherUser.name,
                        style: TextStyle(fontSize: 15 ,fontWeight: FontWeight.w500, color: colors.textColor)
                      )
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

  Widget get body {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    UserProfile? up = Provider.of<UserController>(context).getUserProfile;
    final user = types.User(
      id: up!.id,
      imageUrl: up.imageUrl,
      firstName: up.name.split(" ").first
    );

    return FadeInUp(
      child: Chat(
        theme: DefaultChatTheme(
          backgroundColor: colors.buttonColor,
          inputBackgroundColor: colors.backgroundColor,
          inputTextColor: colors.textColor,
          inputTextCursorColor: colors.textColor,
          inputTextDecoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            hintText: "Nachricht senden",
            hintStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.6)),
            filled: true,
            fillColor: colors.buttonColor,
          ),
          primaryColor: colors.primary,
          secondaryColor: colors.isDarkTheme ? Colors.white : Colors.grey.withValues(alpha: 0.25),
          sentMessageBodyTextStyle: TextStyle(color: colors.primaryText, fontSize: 16),
          receivedMessageBodyTextStyle: TextStyle(color: colors.isDarkTheme ? Colors.black : Colors.black, fontSize: 16),
          sendButtonIcon: Icon(Ionicons.paper_plane, color: colors.primary),
          dateDividerTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.6)),
        ),
        messages: messages,
        onSendPressed: sendMessage,
        showUserAvatars: true,
        showUserNames: false,
        user: user,
        emptyState: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const ThemedSvgImage(assetName: "chat", height: 150),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'general.noChatsUser'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textColor.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}