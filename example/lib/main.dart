import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:m3u8_downloader/m3u8_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

@pragma('vm:entry-point')
class _MyAppState extends State<MyApp> {
  ReceivePort _port = ReceivePort();
  String? _downloadingUrl;
  String? _printData;

  // 未加密的 m3u8 测试地址（替换为有效的 m3u8 索引）
  String url1 = "https://play.maoyanplay.top/20251025/0xh6Na8c/index.m3u8";
  // 加密的url地址（火影忍者疾风传）
  String url2 = "https://v3.dious.cc/20201116/SVGYv7Lo/index.m3u8";

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  void initAsync() async {
    String saveDir = await _findSavePath();
    M3u8Downloader.initialize(onSelect: () async {
      print('下载成功点击');
      return null;
    });
    M3u8Downloader.config(saveDir: saveDir, threadCount: 2, convertMp4: true, debugMode: true);
    // 注册监听器
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      // 监听数据请求
      setState(() {
        _printData = '$data';
        print("========>>>>>>>>>>=$data");
      });
    });
  }

  bool _isM3u8Url(String url) {
    return url.toLowerCase().endsWith(".m3u8");
  }

  void _showNotM3u8Tip(String url) {
    setState(() {
      _printData = "当前URL不是m3u8索引，已取消下载: $url";
    });
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<String> _findSavePath() async {
    final directory =
        Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    String saveDir = directory!.path + '/vPlayDownload';
    Directory root = Directory(saveDir);
    if (!root.existsSync()) {
      await root.create();
    }
    print(saveDir);
    return saveDir;
  }

  @pragma('vm:entry-point')
  static progressCallback(dynamic args) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      args["status"] = 1;
      send.send(args);
    }
  }

  @pragma('vm:entry-point')
  static successCallback(dynamic args) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      send.send({"status": 2, "url": args["url"], "filePath": args["filePath"], "dir": args["dir"]});
    }
  }

  @pragma('vm:entry-point')
  static errorCallback(dynamic args) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      send.send({"status": 3, "url": args["url"]});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SizedBox(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              ElevatedButton(
                  child: Text("${_downloadingUrl == url1 ? '暂停' : '下载'}未加密m3u8"),
                  onPressed: () {
                    if (_downloadingUrl == url1) {
                      // 暂停
                      setState(() {
                        _downloadingUrl = null;
                      });
                      M3u8Downloader.pause(url1);
                      return;
                    }
                    // 下载
                    _checkPermission().then((hasGranted) async {
                      if (hasGranted) {
                        if (!_isM3u8Url(url1)) {
                          _showNotM3u8Tip(url1);
                          return;
                        }
                        await M3u8Downloader.config(
                          convertMp4: false,
                        );
                        setState(() {
                          _downloadingUrl = url1;
                        });
                        M3u8Downloader.download(
                            url: url1,
                            name: "下载未加密m3u8",
                            progressCallback: progressCallback,
                            successCallback: successCallback,
                            errorCallback: errorCallback);
                      }
                    });
                  }),
              ElevatedButton(
                child: Text("${_downloadingUrl == url2 ? '暂停' : '下载'}已加密m3u8"),
                onPressed: () {
                  if (_downloadingUrl == url2) {
                    // 暂停
                    setState(() {
                      _downloadingUrl = null;
                    });
                    M3u8Downloader.pause(url2);
                    return;
                  }
                  // 下载
                  _checkPermission().then((hasGranted) async {
                    if (hasGranted) {
                      if (!_isM3u8Url(url2)) {
                        _showNotM3u8Tip(url2);
                        return;
                      }
                      await M3u8Downloader.config(
                        convertMp4: false,
                      );
                      setState(() {
                        _downloadingUrl = url2;
                      });
                      M3u8Downloader.download(
                          url: url2,
                          name: "下载已加密m3u8",
                          progressCallback: progressCallback,
                          successCallback: successCallback,
                          errorCallback: errorCallback);
                    }
                  });
                },
              ),
              ElevatedButton(
                child: Text("打开已下载的未加密的文件"),
                onPressed: () async {
                  var res = await M3u8Downloader.getSavePath(url1);
                  print(res);
                  File mp4 = File(res['mp4']);
                  if (mp4.existsSync()) {
                    OpenFile.open(res['mp4']);
                  }
                },
              ),
              ElevatedButton(
                child: Text("打开已下载的已加密的文件"),
                onPressed: () async {
                  var res = await M3u8Downloader.getSavePath(url2);
                  print(res);
                  File mp4 = File(res['mp4']);
                  print(mp4);
                  if (mp4.existsSync()) {
                    OpenFile.open(res['mp4']);
                  }
                },
              ),
              ElevatedButton(
                child: Text("清空下载"),
                onPressed: () async {
                  await M3u8Downloader.delete(url1);
                  await M3u8Downloader.delete(url2);
                  print("清理完成");
                },
              ),
              Text(_printData ?? '')
            ],
          ),
        ),
      ),
    );
  }
}
