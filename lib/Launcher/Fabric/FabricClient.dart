// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

import '../MinecraftClient.dart';

class FabricClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  late StateSetter setState;

  FabricClient._init(
      {required this.Meta,
      required this.handler,
      required String VersionID,
      required String LoaderVersion});

  static Future<FabricClient> createClient(
      {required Map Meta,
      required String VersionID,
      required SetState,
      required String LoaderVersion}) async {
    SetState(() {
      NowEvent = "正在解析Fabric數據資料";
    });
    var bodyString = await FabricAPI().getProfileJson(VersionID, LoaderVersion);
    Map<String, dynamic> body = await json.decode(bodyString);
    Map FabricMeta = body;
    return await FabricClient._init(
            handler: MinecraftClientHandler(),
            Meta: Meta,
            VersionID: VersionID,
            LoaderVersion: LoaderVersion)
        ._Ready(Meta, FabricMeta, VersionID, LoaderVersion, SetState);
  }

  Future<FabricClient> getFabricLibrary(Meta, VersionID) async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */

    Meta["libraries"].forEach((lib) async {
      var Result = utility.ParseLibMaven(lib);

      infos.add(DownloadInfo(Result["Url"],
          savePath: join(dataHome.absolute.path, "versions", VersionID,
              "libraries", Result["Filename"]),
          description: i18n.format('version.list.downloading.fabric.library')));
    });
    return this;
  }

  Future getFabricArgs(Map Meta, String VersionID, String LoaderVersion) async {
    File VanillaArgsFile =
        GameRepository.getArgsFile(VersionID, ModLoaders.Vanilla);
    File FabricArgsFile =
        GameRepository.getArgsFile(VersionID, ModLoaders.Fabric, LoaderVersion);
    Map ArgsObject = await json.decode(VanillaArgsFile.readAsStringSync());
    ArgsObject["mainClass"] = Meta["mainClass"];
    FabricArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(ArgsObject));
  }

  Future<FabricClient> _Ready(
      Meta, FabricMeta, VersionID, LoaderVersion, SetState) async {
    setState = SetState;
    await handler.Install(Meta, VersionID, setState);
    setState(() {
      NowEvent = i18n.format('version.list.downloading.fabric.args');
    });
    await this.getFabricArgs(FabricMeta, VersionID, LoaderVersion);
    await this.getFabricLibrary(FabricMeta, VersionID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    return this;
  }
}
