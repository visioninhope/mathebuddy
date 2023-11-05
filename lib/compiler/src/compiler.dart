/// mathe:buddy - a gamified app for higher math
/// https://mathebuddy.github.io/
/// (c) 2022-2023 by TH Koeln
/// Author: Andreas Schwenk contact@compiler-construction.com
/// Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
/// License: GPL-3.0-or-later

import 'package:slex/slex.dart';

import '../../mbcl/src/chapter.dart';
import '../../mbcl/src/course.dart';
import '../../mbcl/src/level.dart';
import '../../mbcl/src/unit.dart';

import 'block.dart';
import 'course.dart';
import 'help.dart';
import 'level.dart';
import 'references.dart';

/// The compiler that translates a set of MBL files into a single MBCL files.
/// The language specification can be found here:
/// https://mathebuddy.github.io/mathebuddy/doc/mbl.html
class Compiler {
  /// The load function that provides the contents of a text file, given by
  /// a file path.
  final String Function(String) loadFile;

  /// The base directory.
  String baseDirectory = '';

  /// The current equation number (reset per level).
  int equationNumberCounter = 1;

  /// The currently processed course.
  MbclCourse? course;

  /// The currently processed chapter.
  MbclChapter? chapter;

  /// The currently processed unit.
  MbclUnit? unit;

  /// The currently processed level.
  MbclLevel? level;

  /// The source code lines of the current input file.
  List<String> srcLines = [];

  /// The index of the current line (starting from 0).
  int currentLineIdx = -1;

  /// The current line contents.
  String currentLine = '';

  /// Whether block titles are invisible.
  bool disableBlockTitles = false;

  /// Constructor
  Compiler(this.loadFile);

  /// Gets the current course.
  MbclCourse? getCourse() {
    return course;
  }

  /// Gets a (newline-separated) list of all errors.
  String gatherErrors() {
    if (course == null) return "";
    return course!.gatherErrors();
  }

  /// Starts compilation of an MBL file at [path].
  void compile(String path) {
    print("COMPILING FROM PATH '$path'");
    // extract base directory from path
    baseDirectory = extractDirname(path);
    // compile
    if (path.endsWith('course.mbl')) {
      // processing complete course
      compileCourse(path);
    } else if (path.endsWith('index.mbl')) {
      // processing a single course chapter
      course = MbclCourse();
      course?.debug = MbclCourseDebug.chapter;
      compileChapter(path);
    } else {
      // processing a single course level
      course = MbclCourse();
      course!.debug = MbclCourseDebug.level;
      chapter = MbclChapter();
      course!.chapters.add(chapter!);
      unit = MbclUnit();
      chapter!.units.add(unit!);
      compileLevel(path);
      unit!.levels.add(chapter!.levels[0]);
    }
    // post processing
    postProcessCourse(course as MbclCourse);
    // resolve references
    ReferenceSolver rs = ReferenceSolver(course as MbclCourse);
    rs.run();
  }

  //G course = courseTitle courseAuthor courseChapters;
  //G courseTitle = "TITLE" { ID } "\n";
  //G courseAuthor = "AUTHOR" { ID } "\n";
  //G courseChapters = "CHAPTERS" "\n" { courseChapter };
  //G courseChapter = "(" INT "," INT ")" ID { "!" ID } "\n";
  void compileCourse(String path) {
    // create a new course
    course = MbclCourse();
    // get course description file source
    var src = loadFile(path);
    if (src.isEmpty) {
      course!.error +=
          'Course description file "$path" does not exist or is empty. ';
      return;
    }
    // parse block hierarchy
    Block? rootBlock;
    try {
      rootBlock = _parseBlockHierarchy(src);
    } catch (e) {
      course!.error += ' $e ';
      return;
    }
    for (var block in rootBlock.children) {
      switch (block.id) {
        case "DEFAULT":
          // ignore
          break;
        case "TITLE":
        case "AUTHOR":
        case "CHAPTERS":
          if (block.children.length != 1 || block.children[0].id != "DEFAULT") {
            course!.error += "${block.id} is not well formatted. ";
            return;
          }
          var text = block.children[0].data.trim();
          switch (block.id) {
            case "TITLE":
              course!.title = text;
              break;
            case "AUTHOR":
              course!.author = text;
              break;
            case "CHAPTERS":
              var lines = text.split("\n");
              for (var i = 0; i < lines.length; i++) {
                var line = lines[i];
                if (line.trim().isEmpty) continue;
                var lexer = Lexer();
                lexer.enableEmitBigint(false);
                lexer.enableHyphenInID(true);
                var rowIdx = block.srcLine + i + 1;
                lexer.pushSource(path, line, rowIdx);
                lexer.terminal('(');
                var posX = lexer.integer();
                lexer.terminal(',');
                var posY = lexer.integer();
                lexer.terminal(')');
                var directoryName = lexer.identifier();
                List<String> requirements = [];
                while (lexer.isTerminal('!')) {
                  lexer.next();
                  requirements.add(lexer.identifier());
                }
                lexer.end();
                // compile chapter
                var dirname = extractDirname(path);
                var chapterPath = '$dirname$directoryName/index.mbl';
                try {
                  compileChapter(chapterPath);
                } catch (e) {
                  course!.error += "Chapter '$chapterPath' contains errors. "
                      "Remove these errors first. ";
                  return;
                }
                // set chapter meta data
                chapter?.fileId = directoryName;
                chapter?.posX = posX;
                chapter?.posY = posY;
                chapter?.requiresTmp.addAll(requirements);
              }
              break;
          }
          break;
        default:
        // TODO
      }
    }
    // build dependency graph
    for (var i = 0; i < (course as MbclCourse).chapters.length; i++) {
      var chapter = course?.chapters[i] as MbclChapter;
      for (var j = 0; j < chapter.requiresTmp.length; j++) {
        var r = chapter.requiresTmp[j];
        var requiredChapter = course?.getChapterByFileID(r);
        if (requiredChapter == null) {
          course!.error += 'Unknown chapter "$r". ';
          return;
        } else {
          chapter.requires.add(requiredChapter);
        }
      }
    }
  }

  //G chapter = chapterTitle chapterAuthor { chapterUnit };
  //G chapterTitle = "TITLE" { ID } "\n";
  //G chapterAuthor = "AUTHOR" { ID } "\n";
  //G chapterUnit = "UNIT" { ID } "\n" { chapterLevel };
  //G chapterLevel = "(" INT "," INT ")" ID { "!" ID } "\n";
  void compileChapter(String path) {
    // create a new chapter
    chapter = MbclChapter();
    course?.chapters.add(chapter as MbclChapter);
    // get chapter index file source
    var src = loadFile(path);
    if (src.isEmpty) {
      chapter!.error +=
          'Chapter index file "$path" does not exist or is empty. ';
      return;
    }
    // parse block hierarchy
    Block rootBlock;
    try {
      rootBlock = _parseBlockHierarchy(src);
    } catch (e) {
      chapter!.error += " $e ";
      return;
    }
    for (var block in rootBlock.children) {
      switch (block.id) {
        case "DEFAULT":
          // ignore
          break;
        case "TITLE":
        case "AUTHOR":
        case "OPTIONS":
        case "UNIT":
          if (block.children.length != 1 || block.children[0].id != "DEFAULT") {
            chapter!.error += "${block.id} is not well formatted. ";
            return;
          }
          var text = block.children[0].data.trim();
          switch (block.id) {
            case "TITLE":
              chapter!.title = text;
              break;
            case "AUTHOR":
              chapter!.author = text;
              break;
            case "OPTIONS":
              for (var key in block.attributes.keys) {
                var value = block.attributes[key];
                switch (key) {
                  case "NO_BLOCK_TITLES":
                    if (value == "true") {
                      disableBlockTitles = true;
                    } else if (value == "false") {
                      disableBlockTitles = false;
                    } else {
                      chapter!.error +=
                          "Invalid value '$value' for key='$key'. ";
                      return;
                    }
                    break;
                  default:
                    chapter!.error += "Unknown attribute '$key'. ";
                    return;
                }
              }
              break;
            case "UNIT":
              unit = MbclUnit();
              unit?.title = block.title;
              chapter?.units.add(unit as MbclUnit);
              var lines = text.split("\n");
              for (var i = 0; i < lines.length; i++) {
                var line = lines[i];
                if (line.trim().isEmpty) continue;
                var lexer = Lexer();
                lexer.enableEmitBigint(false);
                lexer.enableHyphenInID(true);
                var rowIdx = block.srcLine + i + 1;
                lexer.pushSource(path, line, rowIdx);
                lexer.terminal('(');
                double posX = 0.0;
                if (lexer.isRealNumber()) {
                  posX = lexer.realNumber().toDouble();
                } else {
                  posX = lexer.integer().toDouble();
                }
                lexer.terminal(',');
                double posY = 0.0;
                if (lexer.isRealNumber()) {
                  posY = lexer.realNumber().toDouble();
                } else {
                  posY = lexer.integer().toDouble();
                }
                lexer.terminal(')');
                var fileName = lexer.identifier();
                List<String> requirements = [];
                while (lexer.isTerminal('!')) {
                  lexer.next();
                  requirements.add(lexer.identifier());
                }
                var iconData = '';
                if (lexer.isTerminal("ICON")) {
                  lexer.next();
                  var path = baseDirectory;
                  while (lexer.getToken().type != LexerTokenType.end) {
                    path += lexer.getToken().token.trim();
                    lexer.next();
                  }
                  iconData = loadFile(path);
                }
                lexer.end();
                // compile level
                var dirname = extractDirname(path);
                var levelPath = '$dirname$fileName.mbl';
                try {
                  compileLevel(levelPath);
                } catch (e) {
                  chapter!.error += "Level '$levelPath' contains errors. "
                      "Remove these errors first. ";
                  return;
                }
                unit?.levels.add(level as MbclLevel);
                // set chapter meta data
                level?.fileId = fileName;
                level?.posX = posX.toDouble();
                level?.posY = posY.toDouble();
                level?.requiresTmp.addAll(requirements);
                level?.iconData = iconData;
              }
          }
          break;
      }
    }
    // build dependency graph
    for (var i = 0; i < (chapter as MbclChapter).levels.length; i++) {
      var level = chapter?.levels[i] as MbclLevel;
      for (var j = 0; j < level.requiresTmp.length; j++) {
        var r = level.requiresTmp[j];
        var requiredLevel = chapter?.getLevelByFileID(r);
        if (requiredLevel == null) {
          chapter!.error += 'Unknown dependency-level "$r". ';
          return;
        } else {
          level.requires.add(requiredLevel);
        }
      }
    }
  }

  //G level = TODO
  void compileLevel(String path) {
    equationNumberCounter = 1;
    // create a new level
    level = MbclLevel();
    if (disableBlockTitles) {
      level!.disableBlockTitles = true;
    }
    chapter!.levels.add(level as MbclLevel);
    // get level source
    var src = loadFile(path);
    if (src.isEmpty) {
      level!.error += 'Level file $path does not exist or is empty.';
      return;
    }
    // parse block hierarchy
    try {
      var rootBlock = _parseBlockHierarchy(src);
      // process and deep-parse block hierarchy
      parseLevelBlock(rootBlock, this, level!, null, 0, null);
    } catch (e) {
      level!.error += ' $e';
      return;
    }
  }

  void _next() {
    currentLineIdx++;
    if (currentLineIdx < srcLines.length) {
      currentLine = srcLines[currentLineIdx];
    } else {
      currentLine = '§END';
    }
  }

  void _error(String message) {
    // TODO: include file path!
    throw Exception('ERROR:${currentLineIdx + 1}: $message');
  }

  Block _parseBlockHierarchy(String src) {
    // set source, split it into lines, trim these lines and
    // filter out comments of each line
    srcLines = src.split('\n');
    for (var k = 0; k < srcLines.length; k++) {
      var line = srcLines[k];
      var tokens = line.split('%');
      srcLines[k] = tokens[0];
    }
    // init lexer
    currentLineIdx = -1;
    _next();
    // parse
    var depthList =
        List<Block?>.filled(0, null, growable: true); // TODO: write comment!!
    var rootBlock = Block("ROOT", 0, -1);
    depthList.length = 1;
    depthList[0] = rootBlock;
    var currentBlock = rootBlock;
    while (currentLine != '§END') {
      var trimmed = currentLine.trim();
      if (trimmed == "!STOP") break;
      var spaces = 0;
      for (var k = 0; k < currentLine.length; k++) {
        if (currentLine[k] == ' ') {
          spaces++;
        } else if (currentLine[k] == '\t') {
          spaces += 4;
        } else {
          break;
        }
      }
      int indentation = spaces ~/ 4;
      indentation += 1; // add one for root element
      // A keyword is fully uppercase; also "_", "-" and "*" are allowed
      // characters.
      // If "=" is followed (directly or after some spaces), we are actually
      // parsing an attribute and NOT a keyword.
      var keyword = "";
      for (int i = 0; i < trimmed.length; i++) {
        var ch = trimmed[i];
        var isValid = ch.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
                ch.codeUnitAt(0) <= 'Z'.codeUnitAt(0) ||
            (i > 0 && ch == '_') ||
            (i > 0 && ch == '-') ||
            (i > 0 && ch == '*');
        if (isValid) {
          keyword += ch;
        } else {
          for (int j = i; j < trimmed.length; j++) {
            if (ch == " " || ch == "\t") continue;
            if (ch == "=") {
              // attribute!
              keyword = "";
            }
          }
          // require at least length 3
          if (keyword.length < 3) {
            keyword = "";
          }
          break;
        }
      }
      if (keyword.isNotEmpty) {
        if ((spaces % 4) != 0) {
          _error('bad spacing before "$keyword".');
        }
        var srcLine = currentLineIdx + 1;
        currentBlock = Block(keyword, indentation, srcLine);
        depthList.length = indentation + 1;
        var parent = depthList[indentation - 1];
        if (parent == null) {
          _error('bad indentation before "$keyword".');
        } else {
          parent.children.add(currentBlock);
        }
        depthList[indentation] = currentBlock;
        // parse TITLE [ "@" ID ]
        var tokens = trimmed.substring(keyword.length).split("@");
        if (tokens.isNotEmpty) {
          currentBlock.title = tokens[0].trim();
          if (tokens.length >= 2) {
            currentBlock.label = tokens[1].trim();
            if (currentBlock.label.contains(' ')) {
              _error('bad label (must be one word)');
            }
          }
        }
      } else {
        // not a keyword
        if (trimmed.isNotEmpty && indentation <= currentBlock.indent) {
          currentBlock = depthList[indentation - 1]!;
        }
        var line = currentLine.replaceAll('\t', '    ');
        var isAttribute = false;
        if (line.contains("=")) {
          isAttribute = true;
          var l = Lexer();
          l.enableEmitBigint(false);
          l.pushSource("", line);
          try {
            var key = l.uppercaseIdentifier();
            if (key.length < 3) throw Exception("not a key");
            var value = "";
            l.terminal("=");
            while (l.isNotEnd()) {
              value += l.getToken().token;
              l.next();
            }
            l.end();
            // parsing of attribute succeeded
            currentBlock.attributes[key] = value;
          } catch (e) {
            isAttribute = false;
          }
          if (isAttribute && currentBlock.children.isNotEmpty) {
            _error('Attributes must be first. '
                'Hint: Move line ${currentLineIdx + 1} to line ${currentBlock.srcLine + 1}');
          }
        }
        if (isAttribute == false) {
          var b = Block("DEFAULT", indentation, currentLineIdx + 1);
          b.data = '$line\n';
          currentBlock.children.add(b);
        }
      }
      _next();
    }
    rootBlock.postProcess();
    //print(rootBlock);
    return rootBlock;
  }
}
