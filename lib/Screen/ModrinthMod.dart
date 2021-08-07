import 'dart:io';

import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Mod/ModrinthHandler.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

class ModrinthMod_ extends State<ModrinthMod> {
  late String InstanceDirName;
  TextEditingController SearchController = TextEditingController();
  late Directory ModDir =
      InstanceRepository.getInstanceModRootDir(InstanceDirName);
  late Map InstanceConfig =
      InstanceRepository.getInstanceConfig(InstanceDirName);

  late List BeforeModList = [];
  late int Index = 0;

  List<String> SortItemsCode = ["relevance", "downloads", "updated", "newest"];
  List<String> SortItems = [
    i18n.Format("edit.instance.mods.sort.modrinth.relevance"),
    i18n.Format("edit.instance.mods.sort.modrinth.downloads"),
    i18n.Format("edit.instance.mods.sort.modrinth.updated"),
    i18n.Format("edit.instance.mods.sort.modrinth.newest")
  ];
  String SortItem = i18n.Format("edit.instance.mods.sort.modrinth.relevance");

  ScrollController ModScrollController = ScrollController();

  ModrinthMod_(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  void initState() {
    ModScrollController.addListener(() {
      if (ModScrollController.position.maxScrollExtent ==
          ModScrollController.position.pixels) {
        //如果滑動到底部
        setState(() {});
      }
    });
    super.initState();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(i18n.Format("edit.instance.mods.download.modrinth"),
              textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(i18n.Format("edit.instance.mods.download.search")),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: SearchController,
                decoration: InputDecoration(
                  hintText:
                      i18n.Format("edit.instance.mods.download.search.hint"),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue, width: 5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue, width: 3.0),
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              )),
              SizedBox(
                width: 12,
              ),
              ElevatedButton(
                style: new ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurpleAccent)),
                onPressed: () {
                  setState(() {
                    Index = 0;
                    BeforeModList = [];
                  });
                },
                child: Text(i18n.Format("gui.search")),
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(i18n.Format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: SortItem,
                    style: TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      setState(() {
                        SortItem = newValue!;
                        Index = 0;
                        BeforeModList = [];
                      });
                    },
                    items:
                        SortItems.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      content: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: ModrinthHandler.getModList(
                InstanceConfig["version"],
                InstanceConfig["loader"],
                SearchController,
                BeforeModList,
                Index,
                SortItemsCode[SortItems.indexOf(SortItem)]),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                Index++;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  controller: ModScrollController,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String ModName = data["title"];
                    String ModDescription = data["description"];
                    String ModrinthID = data["mod_id"].split("local-").join("");
                    String PageUrl = data["page_url"];

                    late Widget ModIcon;
                    if (data["icon_url"].isEmpty) {
                      ModIcon = Icon(Icons.image, size: 50);
                    } else {
                      ModIcon = Image.network(
                        data["icon_url"],
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded
                                        .toInt() /
                                    loadingProgress.expectedTotalBytes!.toInt()
                                : null,
                          );
                        },
                      );
                    }

                    return ListTile(
                      leading: ModIcon,
                      title: Text(ModName),
                      subtitle: Text(ModDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (await canLaunch(PageUrl)) {
                                launch(PageUrl);
                              } else {
                                print("Can't open the url $PageUrl");
                              }
                            },
                            icon: Icon(Icons.open_in_browser),
                            tooltip:
                                i18n.Format("edit.instance.mods.page.open"),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(i18n.Format(
                                        "edit.instance.mods.download.select.version")),
                                    content: Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        child: FutureBuilder(
                                            future:
                                                ModrinthHandler.getModFilesInfo(
                                                    ModrinthID,
                                                    InstanceConfig["version"],
                                                    InstanceConfig["loader"]),
                                            builder: (context,
                                                AsyncSnapshot snapshot) {
                                              if (snapshot.hasData) {
                                                return ListView.builder(
                                                    itemCount:
                                                        snapshot.data!.length,
                                                    itemBuilder: (BuildContext
                                                            FileBuildContext,
                                                        int VersionIndex) {
                                                      Map VersionInfo = snapshot
                                                          .data[VersionIndex];
                                                      return ListTile(
                                                        title: Text(VersionInfo[
                                                            "name"]),
                                                        subtitle: ModrinthHandler
                                                            .ParseReleaseType(
                                                                VersionInfo[
                                                                    "version_type"]),
                                                        onTap: () {
                                                          File ModFile = File(join(
                                                              ModDir.absolute
                                                                  .path,
                                                              VersionInfo[
                                                                      "files"][0]
                                                                  [
                                                                  "filename"]));

                                                          final url =
                                                              VersionInfo[
                                                                      "files"]
                                                                  [0]["url"];
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) =>
                                                                Task(
                                                                    url,
                                                                    ModFile,
                                                                    ModName),
                                                          );
                                                        },
                                                      );
                                                    });
                                              } else {
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator()
                                                  ],
                                                );
                                              }
                                            })),
                                    actions: <Widget>[
                                      IconButton(
                                        icon: Icon(Icons.close_sharp),
                                        tooltip: i18n.Format("gui.close"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text(i18n.Format("gui.install")),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  i18n.Format("edit.instance.mods.list.name") +
                                      ModName),
                              content: Text(i18n.Format(
                                      "edit.instance.mods.list.description") +
                                  ModDescription),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: i18n.Format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class ModrinthMod extends StatefulWidget {
  late String InstanceDirName;

  ModrinthMod(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  ModrinthMod_ createState() => ModrinthMod_(InstanceDirName);
}

class Task extends StatefulWidget {
  late var url;
  late var ModFile;
  late var ModName;

  Task(url_, ModFile_, ModName_) {
    url = url_;
    ModFile = ModFile_;
    ModName = ModName_;
  }

  @override
  Task_ createState() => Task_(url, ModFile, ModName);
}

class Task_ extends State<Task> {
  late var url;
  late var ModFile;
  late var ModName;

  Task_(url_, ModFile_, ModName_) {
    url = url_;
    ModFile = ModFile_;
    ModName = ModName_;
  }

  @override
  void initState() {
    super.initState();
    Downloading(url, ModFile);
  }

  double _progress = 0;

  Downloading(url, ModFile) async {
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);
    final contentLength = response.contentLength;
    List<int> bytes = [];
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        setState(() {
          _progress = downloadedLength / contentLength!;
        });
      },
      onDone: () async {
        _progress = 1;
        await ModFile.writeAsBytes(bytes);
      },
      onError: (e) {
        print(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1) {
      return AlertDialog(
        title: Text(i18n.Format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(i18n.Format("gui.close")))
        ],
      );
    } else {
      return AlertDialog(
        title: Text("${i18n.Format("gui.download.ing")} ${ModName}"),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${(_progress * 100).toStringAsFixed(3)}%"),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
  }
}