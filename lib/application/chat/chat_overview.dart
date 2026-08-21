import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller+api/user_controller.dart';
import '../../controller+api/vendor_controller.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/functions.dart';
import '../../utils/models.dart';
import '../../utils/widgets.dart';
import 'chat_detail.dart';

class ChatOverview extends StatefulWidget {
  const ChatOverview({super.key});

  @override
  State<ChatOverview> createState() => _ChatOverviewState();
}

class _ChatOverviewState extends State<ChatOverview> {

  String vendorId = fixedVendorId;

  StreamSubscription? authStream;
  StreamSubscription? chatStream;
  List<Room> chats = [];
  bool loading = true;

  void onMessageDataChange(QuerySnapshot event) {
    for (var docChange in event.docChanges)  {
      if(docChange.type == DocumentChangeType.modified) {
        int index = chats.indexWhere((element) => element.id == docChange.doc.id);
        if(index != -1) {
          chats[index] = Room.fromMap(docChange.doc.data() as Map<String, dynamic>);
        }
      }
      else if(docChange.type == DocumentChangeType.added) {
        int index = chats.indexWhere((element) => element.id == docChange.doc.id);
        if(index != -1) {
          chats[index] = Room.fromMap(docChange.doc.data() as Map<String, dynamic>);
        }
        else {
          chats.add(Room.fromMap(docChange.doc.data() as Map<String, dynamic>));
        }
      }
    }
    setState(() => chats.sort((b,a) => a.lastMessageTime.compareTo(b.lastMessageTime)));
  }

  Future<void> fetchUserMessages() async {
    Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;
    var uid = FirebaseAuth.instance.currentUser?.uid;
    chatStream = FirebaseFirestore.instance
      .collection("vendors").doc(vendor.id)
      .collection("rooms")
      .where("userIds", arrayContains: uid)
      .orderBy("lastMessageTime", descending: true)
      .snapshots().listen(onMessageDataChange);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
  }

  @override
  void initState() {
    fetchUserMessages();
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {
      chatStream?.cancel();
      chats.clear();
      if(user != null) {
        loading = true;
        fetchUserMessages();
      }
    });
    super.initState();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   print("DEPENDENCIES");
  //   Provider.of<UserController>(context).addListener(() {
  //     Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
  //     if(vendorId != vendor.id) {
  //       print("NEW VENDOR CO");
  //       vendorId = vendor.id;
  //       chatStream?.cancel();
  //       chats.clear();
  //       loading = true;
  //       fetchUserMessages();
  //     }
  //   });
  // }

  @override
  void dispose() {
    chatStream?.cancel();
    authStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    if(loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (chats.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const ThemedSvgImage(assetName: "chat", height: 150),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'general.noChats'.tr(),
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
      );
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 150),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        Room room = chats[index];
        bool read = !room.unread.contains(uid);
        ChatUser otherUser = room.chatUser.firstWhere((element) => element.userId != uid);
        return InkWell(
          onTap: () {
            Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;
            if(room.unread.contains(uid)) {
              FirebaseFirestore.instance
                .collection("vendors").doc(vendor.id)
                .collection("rooms").doc(room.id)
                .update({ "unread": FieldValue.arrayRemove([uid]) });
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatDetail(vendorId: vendor.id, room: room)),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ProfileImageCircle(otherUser.imageUrl, 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherUser.name, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(room.lastMessage, style: TextStyle(color: colors.textColor.withValues(alpha: 0.6), fontWeight: FontWeight.w500, fontSize: 15), maxLines: 2,),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 6),
                    Text(
                      getTimeString(room.lastMessageTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !read ? FontWeight.bold : FontWeight.normal,
                        color: colors.textColor,
                        letterSpacing: 0
                      )
                    ),
                    const SizedBox(height: 6),
                    if(!read)
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: colors.primary,
                      )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}