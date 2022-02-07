import 'dart:async';
import 'dart:typed_data';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/chat.dart';
import 'package:user/models/order.dart';
// import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';

TextEditingController _newMessageController;

class ChatPage extends StatefulWidget {
  static final String route = "chat";

  final Order order;

  ChatPage(this.order) {
    _newMessageController = TextEditingController();
  }

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  DatabaseManager databaseManager;
  bool progressBarVisible;

  bool isFieldEmpty;
  bool isRecording;

  // FlutterAudioRecorder recorder;

  // ignore: cancel_subscriptions
  StreamSubscription chatSubscription;

  Chat chat;

  @override
  void initState() {
    super.initState();

    databaseManager = DatabaseManager.instance;
    progressBarVisible = true;
    isFieldEmpty = true;
    isRecording = false;

    subscribeToChat();

    _newMessageController.addListener(fieldChanged);
  }

  void fieldChanged() {
    if (_newMessageController.text.length > 0 && isFieldEmpty) {
      setState(() {
        isFieldEmpty = false;
      });
    } else if (_newMessageController.text.length == 0 && !isFieldEmpty) {
      setState(() {
        isFieldEmpty = true;
      });
    }
  }

  // void startRecording(_) async {
  //   if (isRecording) stopRecording(null);
  //   if (!isFieldEmpty) return;
  //   printInfo("Recording started");
  //
  //   bool hasPermission = await FlutterAudioRecorder.hasPermissions;
  //   if (hasPermission) {
  //     recorder = FlutterAudioRecorder(
  //       path.join(
  //         (await getApplicationDocumentsDirectory()).path,
  //         "voice_${getEpochOfDevice()}.aac",
  //       ),
  //       audioFormat: AudioFormat.AAC,
  //     );
  //     await recorder.initialized;
  //     await recorder.start();
  //   }
  //
  //   setState(() {
  //     isRecording = true;
  //   });
  // }

  // void stopRecording(_) async {
  //   if (!isRecording || !isFieldEmpty) return;
  //
  //   printInfo("Recording stopped");
  //
  //   if (recorder != null &&
  //       (await recorder.current()).status == RecordingStatus.Recording) {
  //     Recording recording = await recorder.stop();
  //     sendRecording(recording);
  //   }
  //
  //   if (mounted) {
  //     setState(() {
  //       isRecording = false;
  //     });
  //   } else {
  //     isRecording = false;
  //   }
  // }

  void subscribeToChat() async {
    if (widget.order.chatId != null) {
      chatSubscription = await databaseManager.connectToChat(
        widget.order.chatId,
        init: initChat,
        onNewMessage: onNewMessage,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.order.chatId == null) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          showOkMessage(
            context,
            "Failed",
            "Chat not supported for this order.",
            cancelable: false,
            onDismiss: () {
              if (mounted) Navigator.of(context).pop();
            },
          );
        }
      });
    }
  }

  void sendTextMessage() {
    printInfo("FAB clicked");
    String message = _newMessageController?.text;
    if (!GetUtils.isNullOrBlank(message)) {
      _newMessageController.clear();
      databaseManager.sendMessage(
        widget.order.chatId,
        widget.order.riderId,
        message,
        CHAT_MESSAGE_TYPE.TEXT,
      );
    }
  }

  void sendMediaMessage(
    Uint8List rawFile,
    String extension,
    CHAT_MESSAGE_TYPE type,
  ) async {
    setState(() {
      progressBarVisible = true;
    });

    String fileUrl = await databaseManager.uploadFile(rawFile, extension, type);

    if (mounted) {
      setState(() {
        progressBarVisible = false;
      });
    } else {
      progressBarVisible = false;
    }

    if (fileUrl == null) {
      showOkMessage(context, "Failed", "Failed to send message");
    } else {
      databaseManager.sendMessage(
        widget.order.chatId,
        widget.order.riderId,
        fileUrl,
        type,
      );
    }
  }

  void onNewMessage(ChatMessage newMessage) {
    if (chat != null && mounted) {
      setState(() {
        chat.messages.insert(0, newMessage);
      });
    }
  }

  void initChat(Chat chat) {
    if (mounted) {
      setState(() {
        this.progressBarVisible = false;
        this.chat = chat;
      });
    } else {
      this.progressBarVisible = false;
      this.chat = chat;
    }
  }

  void attachImage() async {
    ImagePicker picker = ImagePicker();

    PermissionStatus statusCamera = await Permission.camera.request();
    PermissionStatus statusStorage = await Permission.storage.request();

    Get.bottomSheet(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TDivider(height: 32),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      if (statusCamera.isGranted) {
                        final pickedFile = await picker.getImage(
                          source: ImageSource.camera,
                        );
                        Get.back();
                        sendImage(pickedFile);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.black54,
                          ),
                          Text("Camera"),
                        ],
                      ),
                    ),
                  ),
                  VTDivider(),
                  InkWell(
                    onTap: () async {
                      if (statusStorage.isGranted) {
                        final pickedFile = await picker.getImage(
                          source: ImageSource.gallery,
                        );
                        Get.back();
                        sendImage(pickedFile);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_rounded,
                            size: 40,
                            color: Colors.black54,
                          ),
                          Text("Gallery"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              TDivider(height: 32),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      elevation: 20,
    );
  }

  void sendImage(PickedFile pickedFile) async {
    if (pickedFile != null) {
      var uint8list = await pickedFile.readAsBytes();
      sendMediaMessage(
        uint8list,
        path.extension(pickedFile.path),
        CHAT_MESSAGE_TYPE.IMAGE,
      );
    }
  }

  // void sendRecording(Recording recording) async {
  //   try {
  //     if (recording != null && recording.duration > Duration(seconds: 1)) {
  //       File file = File(recording.path);
  //       if (file != null) {
  //         var uint8list = await file.readAsBytes();
  //         sendMediaMessage(
  //           uint8list,
  //           recording.extension,
  //           CHAT_MESSAGE_TYPE.VOICE,
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     showOkMessage(context, "Failed", "Failed to send voice message");
  //   }
  // }

  @override
  void dispose() {
    chatSubscription?.cancel?.call();
    databaseManager.chatRealtimeDb.goOffline();
    _newMessageController.removeListener(fieldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: getAppBar(
        context,
        AppBarType.backOnly,
        title: widget.order.riderName ?? "Rider",
        iconsColor: AppTextStyle.color,
        trailing: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.order.riderPhone != null) {
              String url = "tel:${widget.order.riderPhone}";
              canLaunch(url).then((value) => launch(url));
            }
          },
          child: Container(
            width: 28,
            child: Image.asset(
              "assets/icons/ic_phone_number.png",
            ),
          ),
        ),
        onBackPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: chat?.messages?.length ?? 0,
                  reverse: true,
                  itemBuilder: (_, index) {
                    if (chat?.messages == null) return Container();

                    var message = chat.messages[index];
                    return _MessageUI(
                      value: message.value,
                      datetime: message.datetime,
                      isUserMessage: message.sender == widget.order.uid,
                      type: message.type,
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.transparent,
                  ),
                ),
              ),
              TDivider(),
              Opacity(
                opacity: widget.order.resolvedStatus == ORDER_STATUS.DELIVERED
                    ? 0.4
                    : 1,
                child: IgnorePointer(
                  ignoring:
                      widget.order.resolvedStatus == ORDER_STATUS.DELIVERED,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: attachImage,
                          child: Icon(Icons.attach_file),
                        ),
                        VTDivider(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _newMessageController,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "Type a message",
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              labelStyle: TextStyle(color: Colors.black38),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        VTDivider(width: 8),
                        GestureDetector(
                          // onLongPressStart: startRecording,
                          // onLongPressEnd: stopRecording,
                          child: AbsorbPointer(
                            absorbing: isFieldEmpty,
                            child: FloatingActionButton(
                              child: Icon(
                                // isFieldEmpty ?
                                // Icons.mic :
                                Icons.send,
                                size: 30,
                                color: Colors.white,
                              ),
                              onPressed: sendTextMessage,
                              elevation: 0,
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  isRecording ? Colors.red : appPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          AppProgressBar(visible: progressBarVisible),
        ],
      ),
    );
  }
}

class _MessageUI extends StatelessWidget {
  final String value;
  final int datetime;
  final bool isUserMessage;
  final CHAT_MESSAGE_TYPE type;

  final DateFormat timeOnly = DateFormat('hh:mm aa');
  final DateFormat withDateFormatter = DateFormat('MMM dd, hh:mm aa');

  _MessageUI({
    @required this.value,
    @required this.datetime,
    @required this.isUserMessage,
    @required this.type,
  });

  void showFullScreenImage(BuildContext context) {
    Get.dialog(
      GestureDetector(
        onTap: () {
          if (Get.isDialogOpen) Get.back();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: InteractiveViewer(
            panEnabled: false,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: 0.1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: value,
              placeholder: (_, __) => AppProgressBar(),
              errorWidget: (_, __, ___) {
                return Icon(Icons.image_not_supported);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var now = DateTime.now();
    var dt = DateTime.fromMillisecondsSinceEpoch(datetime);
    String dtValue;
    Duration difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      dtValue = timeOnly.format(dt);
    } else if (difference.inDays >= 0 &&
        difference.inDays <= 3 &&
        now.subtract(Duration(days: 1)).day == dt.day) {
      dtValue = "Yesterday ${timeOnly.format(dt)}";
    } else {
      dtValue = withDateFormatter.format(dt);
    }

    return Column(
      crossAxisAlignment:
          isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: isUserMessage ? 36 : 18,
            right: isUserMessage ? 18 : 36,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.only(
                top: 18,
                bottom: 8,
                left: 18,
                right: 18,
              ),
              decoration: BoxDecoration(
                color: isUserMessage ? Colors.black : appPrimaryColor,
              ),
              child: Column(
                crossAxisAlignment: isUserMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: type == CHAT_MESSAGE_TYPE.TEXT,
                    child: Text(
                      value,
                      style: AppTextStyle.copyWith(
                        color: isUserMessage ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: type == CHAT_MESSAGE_TYPE.IMAGE,
                    child: Container(
                      width: 250,
                      height: 250,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => showFullScreenImage(context),
                          child: CachedNetworkImage(
                            imageUrl: value,
                            placeholder: (_, __) => AppProgressBar(),
                            errorWidget: (_, __, ___) {
                              return Icon(Icons.image_not_supported);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: type == CHAT_MESSAGE_TYPE.VOICE,
                    child: _AudioPlayer(
                      value,
                      isUserMessage ? appPrimaryColor : Colors.black,
                      isUserMessage ? Colors.white : Colors.black,
                      isUserMessage ? Colors.black : Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dtValue,
                        style: AppTextStyle.copyWith(
                          color: isUserMessage ? Colors.white : Colors.black,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioPlayer extends StatefulWidget {
  final String url;
  final Color color;
  final Color textColor;
  final Color iconsColor;

  _AudioPlayer(
    this.url,
    this.color,
    this.textColor,
    this.iconsColor,
  );

  @override
  __AudioPlayerState createState() => __AudioPlayerState(url);
}

class __AudioPlayerState extends State<_AudioPlayer> {
  AudioPlayer player;
  bool isPlaying;
  Duration totalDuration;

  __AudioPlayerState(String url) {
    player = AudioPlayer();
    player.setUrl(url);
    player.setReleaseMode(ReleaseMode.STOP);
  }

  @override
  void initState() {
    super.initState();

    isPlaying = false;
    totalDuration = Duration();

    initPlayer();
  }

  void initPlayer() {
    player.onDurationChanged.listen((duration) {
      if (duration != null) {
        if (mounted) {
          setState(() {
            totalDuration = duration;
          });
        } else {
          totalDuration = duration;
        }
      }
    });

    player.onPlayerCompletion.listen((event) {
      pausePlaying(true);
    });
  }

  void startPlaying() async {
    await player.resume();
    setState(() {
      isPlaying = true;
    });
  }

  void pausePlaying([bool toReset = false]) async {
    await player.pause();
    if (mounted) {
      setState(() {
        isPlaying = false;
      });
    } else {
      isPlaying = false;
    }

    if (toReset) {
      player.seek(Duration());
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 40,
      child: Row(
        children: [
          InkWell(
            onTap: isPlaying ? pausePlaying : startPlaying,
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.iconsColor,
                  size: 32,
                ),
              ),
            ),
          ),
          VTDivider(),
          StreamBuilder<Duration>(
            stream: player.onAudioPositionChanged,
            initialData: Duration(),
            builder: (context, snapshot) {
              return Container(
                width: 180,
                child: ProgressBar(
                  progress: snapshot.data,
                  buffered: Duration(),
                  total: totalDuration,
                  onSeek: (duration) {
                    player.seek(duration);
                  },
                  thumbColor: widget.color,
                  timeLabelTextStyle: AppTextStyle.copyWith(
                    color: widget.textColor,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
