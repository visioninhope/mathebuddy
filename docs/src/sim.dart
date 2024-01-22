/// mathe:buddy - a gamified app for higher math
/// https://mathebuddy.github.io/
/// (c) 2022-2024 by TH Koeln
/// Author: Andreas Schwenk contact@compiler-construction.com
/// Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
/// License: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:path/path.dart' as path_lib;

// ignore: avoid_relative_lib_imports
import '../../lib/compiler/src/compiler.dart';

import 'help.dart';

// TODO: comment variables and methods!!

String currentMblPath = "";

List<String> simPath = [];
var simURL = "";
var simBaseDir = "demo/";

var mblData = "";
var mbclData = "";

var dataArea = html.document.getElementById("sim-data-area") as html.DivElement;
var logArea = html.document.getElementById("sim-log-area") as html.DivElement;

void init() {
  html.querySelector('#showSimInfo')?.onClick.listen((event) {
    html.querySelector('#sim-info')?.style.display = 'block';
    html.querySelector('#sim')?.style.display = 'none';
  });
  html.querySelector('#showSimDemo')?.onClick.listen((event) {
    html.querySelector('#sim-info')?.style.display = 'none';
    showSim('demo');
  });
  html.querySelector('#showSimLocalhost')?.onClick.listen((event) {
    html.querySelector('#sim-info')?.style.display = 'none';
    showSim('localhost');
  });
  html.querySelector('#resetSim')?.onClick.listen((event) {
    resetSim();
  });
  html.querySelector('#updateSim')?.onClick.listen((event) {
    updateSim();
  });
  html.querySelector('#simShowMblButton')?.onClick.listen((event) {
    showMbl();
  });
  html.querySelector('#simShowMbclButton')?.onClick.listen((event) {
    showMbcl();
  });
}

// virtual file system
Map<String, String> fs = {};

String loadFunction(String path) {
  path = path.replaceAll('//', '/').replaceAll("http:/", "http://");
  if (fs.containsKey(path)) {
    return fs[path] as String;
  } else {
    return '';
  }
}

String compileMblCode(String path /*, String src*/) {
  print("compiling the following MBL code at path $path");
  logArea.innerHtml =
      '... compiling - this may take a few more milliseconds ...';
  var compiler = Compiler(loadFunction);
  try {
    compiler.compile(path);
    var y = compiler.getCourse()?.toJSON();
    var jsonStr = JsonEncoder.withIndent("  ").convert(y);
    var log = '... compilation was successful!<br/>';
    updateSimShortInfo("");
    var softErrors = compiler.gatherErrors();
    if (softErrors.isNotEmpty) {
      updateSimShortInfo('minor errors occurred (refer to log)', true);
      log += "+++++ MINOR ERRORS +++++<br/>";
      log += softErrors.replaceAll("\n", "<br/>");
      log += "+++++ END OF ERROR LOG +++++<br/>";
    }
    logArea.innerHtml = log;
    return jsonStr;
  } catch (e) {
    updateSimShortInfo(
        '<span color="red">fatal errors occurred (see log below)</span>', true);
    logArea.innerHtml = e.toString();
    return '';
  }
}

void showSim(String location) {
  simPath = [];
  var src = html.window.location.host.contains("localhost")
      ? "sim/index.html"
      : "sim-ghpages/index.html";
  simURL = '$src?ver=${DateTime.now().millisecondsSinceEpoch}';
  //resetSim();
  html.document.getElementById("sim")?.style.display = "block";
  simBaseDir = location == "demo" ? "demo/" : "http://localhost:8271/";
  updateSimPathButtons();
}

void resetSim() {
  if (simURL.isNotEmpty) {
    (html.document.getElementById("sim-iframe") as html.IFrameElement).src =
        simURL;
    Timer(Duration(milliseconds: 250), () => updateSim());
  }
}

void updateSim() {
  if (currentMblPath.isNotEmpty) {
    loadMblFile(currentMblPath);
  }
}

void updateSimPathButtons() {
  var path = simBaseDir + simPath.join("/");
  if (simPath.isEmpty || simPath[simPath.length - 1].endsWith("/")) {
    getFilesFromDir(path).then((files) {
      // only keep directories and .mbl files
      List<String> filesList = [];
      for (var file in files) {
        if (file.endsWith(".mbl") || file.endsWith("/")) filesList.add(file);
      }
      files = filesList;
      // add dir-up button
      if (simPath.isNotEmpty && files.contains("..") == false) {
        files.insert(0, "..");
      }
      // create buttons
      updateSimPathButtonsCore(files);
    });
  } else if (simPath.isNotEmpty &&
      simPath[simPath.length - 1].endsWith(".mbl")) {
    loadMblFile(path);
  }
  // TODO: reactivate message in div "localhost-error-info"!
}

void loadMblFile(String path) {
  currentMblPath = path;
  //path = path.replaceAll('//', '/');
  readTextFile(path).then((text) async {
    mblData = text;
    updateSimPathButtonsCore(simPath.isNotEmpty ? [".."] : []);
    showMbl();
    // compile
    path = path.replaceAll("//", "/").replaceAll("http:/", "http://");
    fs[path] = mblData;

    readDirRecursively(fs, path_lib.dirname(path)).then((value) {
      // print("FILE_SYSTEM:");
      // for (var key in fs.keys) {
      //   print(key);
      // }
      // print("... END OF FILE_SYSTEM");

      mbclData = compileMblCode(path);
      // send course to sim
      var e = html.document.getElementById("sim-iframe") as html.IFrameElement;
      e.contentWindow?.postMessage(htmlSafe(mbclData), '*');
    });
  });
}

void showMbl() {
  // insert line numbers
  var res = "";
  var lines = mblData.split("\n");
  var i = 1;
  for (var line in lines) {
    res += "$i".padLeft(4, '0');
    res += "  ";
    res += "$line\n";
    i++;
  }
  // set
  var tmp = htmlSafe(res);
  dataArea.innerHtml = "<pre><code>$tmp</code></pre>";
}

void showMbcl() {
  var tmp = htmlSafe(mbclData);
  dataArea.innerHtml = "<pre><code>$tmp</code></pre>";
}

String htmlSafe(String s) {
  s = s.replaceAll("&", "&amp;");
  s = s.replaceAll("<", '&lt;');
  s = s.replaceAll(">", '&gt;');
  s = s.replaceAll("\"", '&quot;');
  s = s.replaceAll("'", '&#039;');
  return s;
}

void updateSimPathButtonsCore(List<String> files) {
  var simPathButtons =
      html.document.getElementById("sim-path-buttons") as html.SpanElement;
  simPathButtons.innerHtml = "";
  // sort files
  List<String> dirs = [];
  List<String> nonDirs = [];
  for (var file in files) {
    if (file.endsWith("/")) {
      dirs.add(file);
    } else if (file == "..") {
      dirs.insert(0, file);
    } else {
      nonDirs.add(file);
    }
  }
  dirs.sort();
  nonDirs.sort();
  files = dirs;
  files.addAll(nonDirs);
  // add files
  for (var file in files) {
    var button = html.document.createElement("button");
    button.classes.add("button");
    button.style.paddingLeft = "8px";
    button.style.paddingRight = "8px";
    button.style.textTransform = "none";
    button.style.height = "32px";
    button.style.lineHeight = "32px";
    button.style.letterSpacing = "normal";
    if (file.endsWith("/") || file == "..") {
      button.style.backgroundColor = "black";
      button.style.color = "white";
    }
    if (file == "..") {
      button.innerHtml = "&nbsp;&nbsp;$file&nbsp;&nbsp;";
    } else {
      button.innerHtml = file;
    }
    simPathButtons.append(button);
    var span = html.document.createElement("span");
    span.innerHtml = "&nbsp;";
    simPathButtons.append(span);
    button.onClick.listen((event) {
      if (file == "..") {
        simPath.removeLast();
      } else {
        simPath.add(file);
      }
      updateSimPath();
      updateSimPathButtons();
    });
  }
}

void updateSimPath() {
  var e = html.document.getElementById("sim-current-path")!;
  var p = "";
  for (var i = 0; i < simPath.length; i++) {
    p += "&raquo; ${simPath[i].replaceAll("/", "")} ";
  }
  p += "<br/>";
  e.innerHtml = p;
}

void updateSimShortInfo(String msg, [bool redColor = false]) {
  var e = html.document.getElementById("sim-short-info")!;
  var span = html.document.createElement("span");
  if (redColor) {
    span.style.color = "red";
  }
  span.innerHtml = msg;
  e.innerHtml = "";
  e.append(span);
}
