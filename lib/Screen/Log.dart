import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../main.dart';
import '../parser.dart';
import '../path.dart';

class LogScreen_ extends State<LogScreen> {
  late var InstanceDirName;

  LogScreen_(instance_folder_) {
    InstanceDirName = instance_folder_;
  }

  var log_ = "";
  late Directory ConfigFolder;
  late File ConfigFile;
  late File AccountFile;
  late Map Account;
  late var cfg_file;
  late Directory InstanceDir;
  late ScrollController _scrollController;
  late var config;
  var process;
  String log_text = "";

  List<void Function(String)> onData = [
    (data) {
      stdout.write(data);
    }
  ];

  void initState() {
    ConfigFolder = configHome;
    AccountFile = File(join(ConfigFolder.absolute.path, "accounts.json"));
    Account = json.decode(AccountFile.readAsStringSync());
    Directory DataHome = dataHome;
    InstanceDir =
        Directory(join(DataHome.absolute.path, "instances", InstanceDirName));
    cfg_file = CFG(File(join(InstanceDir.absolute.path, "instance.cfg"))
            .readAsStringSync())
        .GetParsed();
    ConfigFile = File(join(ConfigFolder.absolute.path, "config.json"));
    config = json.decode(ConfigFile.readAsStringSync());
    var VersionID = cfg_file["version"];
    var PlayerName = Account["mojang"][0]["availableProfiles"][0]["name"];
    var ClientJar =
        join(DataHome.absolute.path, "versions", VersionID, "client.jar");
    var Natives =
        join(DataHome.absolute.path, "versions", VersionID, "natives");

    var MinRam = 512;
    var MaxRam = 4096;
    var Width = 854;
    var Height = 480;

    var LauncherVersion = "1.0.0_alpha";
    var LibraryDir = Directory(join(DataHome.absolute.path, "libraries"))
        .listSync(recursive: true, followLinks: true);
    var LibraryFiles = "${ClientJar};";
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += "${i.absolute.path};";
      }
    }

    // var Args = jsonDecode(
    //     File(join(InstanceDir.absolute.path, "args.json")).readAsStringSync());

    _scrollController = new ScrollController(
      keepScrollOffset: true,
    );
    start(
        ClientJar,
        MinRam,
        MaxRam,
        Natives,
        LauncherVersion,
        LibraryFiles,
        PlayerName,
        "RPMLauncher ${VersionID}",
        InstanceDir.absolute.path,
        join(DataHome.absolute.path, "assets"),
        VersionID,
        Account["mojang"][0]["availableProfiles"][0]["uuid"],
        Account["mojang"][0]["accessToken"],
        Account.keys.first,
        Width,
        Height);
    super.initState();
    setState(() {});
  }

  start(
      ClientJar,
      MinRam,
      MaxRam,
      ClassPath,
      LauncherVersion,
      LibraryFiles,
      PlayerName,
      VersionID,
      GameDir,
      AssetsDirRoot,
      AssetIndex,
      UUID,
      Token,
      AuthType,
      Width,
      Height) async {
    Directory.current = join(InstanceDir.absolute.path, InstanceDirName);

    this.process = await Process.start(
        "\"${config["java_path"]}\"", //Java Path
        [
          "-Dminecraft.client.jar=${ClientJar}", //ClientJar位置
          "-Xmn${MinRam}m", //最小記憶體
          "-Xmx${MaxRam}m", //最大記憶體
          "-Djava.library.path=${ClassPath}", //本地依賴項
          "-Dminecraft.launcher.brand=RPMLauncher", //啟動器品牌
          "-Dminecraft.launcher.version=${LauncherVersion}", //啟動器版本
          "-cp",
          "${LibraryFiles}",//函式庫檔案路徑
          "net.minecraft.client.main.Main", //程式進入點
          "--username",
          PlayerName.toString(),
          "--version",
          VersionID.toString(),
          "--gameDir",
          GameDir.toString(),
          "--assetsDir",
          AssetsDirRoot.toString(),
          "--assetIndex",
          AssetIndex.toString(),
          "--uuid",
          UUID.toString(),
          "--accessToken",
          Token.toString(),
          "--userType",
          AuthType.toString(),
          "--versionType",
          "RPMLauncher_${LauncherVersion}",
          "--width",
          Width.toString(),
          "--height",
          Height.toString()
        ],
        workingDirectory: InstanceDir.absolute.path);
    this.process.stdout.transform(utf8.decoder).listen((data) {
      //error
      this.onData.forEach((event) {
        log_ = log_ + data;
      });
    });
    this.process.stderr.transform(utf8.decoder).listen((data) {
      //log
      this.onData.forEach((event) {
        log_ = log_ + data;
      });
    });
    this.process.exitCode.then((code) {
      process = null;
    });
    const oneSec = const Duration(seconds: 1);
    new Timer.periodic(oneSec, (Timer t) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Instance log"),
          leading: IconButton(
            icon: Icon(Icons.close_outlined),
            tooltip: '強制關閉',
            onPressed: () {
              // this.process.kill();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => new MyApp()),
              );
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: SingleChildScrollView(
                    controller: _scrollController, child: Text(log_))),
          ],
        ));
  }
}

class LogScreen extends StatefulWidget {
  late var instance_folder;

  LogScreen(instance_folder_) {
    instance_folder = instance_folder_;
  }

  @override
  LogScreen_ createState() => LogScreen_(instance_folder);
}