
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';


void main() {
  final mobile = defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS;

  runApp(DevicePreview(
    enabled: !mobile,
    builder: (context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: Chat(),
    ),
  ));
}


class Chat extends StatefulWidget {
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final name = TextEditingController();
  final emoji = TextEditingController();
  final departments = {
  '舞台進行': '🎬',
  '音響': '🎧',
  '照明': '💡',
  '出演者対応': '🎤',
  'その他': '🛠️',
};

String selectedDepartment = '舞台進行';
String selectedPriority = '通常';
  final input = TextEditingController();
  final api = Uri.base.resolve('/api/messages');
  List messages = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final r = Random();
    final names = ['はる', 'さくら', 'あおい', 'ゆず', 'そら', 'りく'];
    final icons = ['🎭','🎥','💡','🎵','🎹','🎬'];
    name.text = '${names[r.nextInt(names.length)]}${r.nextInt(900) + 100}';
    emoji.text = departments[selectedDepartment]!;
    load();
    timer = Timer.periodic(Duration(seconds: 10), (_) => load());
  }

  Future<void> load() async {
    try {
      final r = await http.get(api);
      if (mounted && r.statusCode == 200) {
        setState(() => messages = jsonDecode(r.body));
      }
    } catch (e) {
      debugPrint('$e');
    }
  }


Future<void> send() async {
  if (name.text.isEmpty || emoji.text.isEmpty || input.text.isEmpty) {
    debugPrint('名前・絵文字・メッセージのどれかが空です');
    return;
  }

  try {
    final r = await http.post(
      api,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.text,
        'emoji': emoji.text,
        'text': '[$selectedPriority] ${input.text}',
      }),
    );

    debugPrint('送信結果: ${r.statusCode}');
    debugPrint('サーバーからの返事: ${r.body}');

    if (r.statusCode == 201) {
      input.clear();
      await load();
    }
  } catch (e) {
    debugPrint('通信エラー: $e');
  }
}


  // メッセージを吹き出しで表示する

Widget bubble(Map m) {
  final mine = m['name'] == name.text;
  final message = (m['text'] ?? '').toString();

  final isEmergency = message.startsWith('[緊急]');
  final isRequest = message.startsWith('[確認依頼]');

  Color bubbleColor;

  if (isEmergency) {
    bubbleColor = Color(0xFF991B1B);
  } else if (isRequest) {
    bubbleColor = Color(0xFF854D0E);
  } else {
    bubbleColor = mine
        ? Color(0xFF2563EB)
        : Color(0xFF334155);
  }

  return Padding(
    padding: EdgeInsets.all(6),
    child: Row(
      mainAxisAlignment:
          mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!mine) ...[
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(m['emoji'] ?? '🙂'),
          ),
          SizedBox(width: 6),
        ],
        Flexible(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              mine
                  ? message
                  : "${m['name']}\n$message",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}


  @override
  void dispose() {
    timer?.cancel();
    name.dispose();
    emoji.dispose();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Color(0xFF111827),

    appBar: AppBar(
      backgroundColor: Color(0xFF111827),
      foregroundColor: Colors.white,
      title: Text('🎭 STAGE LINK'),
      actions: [
        IconButton(
          onPressed: load,
          icon: Icon(Icons.refresh),
        ),
      ],
    ),


    body: SafeArea(
      child: Column(
        children: [
          // 絵文字と名前の入力欄
          Row(
            children: [

              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedDepartment,
                  dropdownColor: Color(0xFF334155),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '担当部署',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: departments.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text('${entry.value} ${entry.key}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedDepartment = value;
                      emoji.text = departments[value]!;
                    });
                  },
                ),
              ),

              SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: name,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '名前',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),

          // チャットのメッセージ一覧
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (_, i) => bubble(messages[i]),
            ),
          ),

          Container(
            color: Color(0xFF1E293B),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: Row(
              children: [
                Text(
                  '連絡の種類：',
                  style: TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    dropdownColor: Color(0xFF334155),
                    style: TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: ['通常', '確認依頼', '緊急'].map((priority) {
                      return DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // メッセージの入力欄
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(6),
            child: Row(
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Icon(Icons.camera_alt_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: input,
                    onSubmitted: (_) => send(),
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力',
                      filled: true,
                      fillColor: Color(0xFFF4F4F4),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
