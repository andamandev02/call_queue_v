import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> texts = [
    '000',
    '000',
    '000',
    '000',
  ];

  @override
  void dispose() {
    _focusNode.dispose();
  }

  bool _isPlaying = false;
  TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: texts.asMap().entries.map((entry) {
                    int index = entry.key;
                    String text = entry.value.substring(0, 3);
                    bool isFirstText = index == 0;

                    return Text(
                      text,
                      style: TextStyle(
                        color: isFirstText
                            ? _isGreen
                                ? Colors.white // Green color
                                : Color.fromARGB(255, 255, 0, 0) // Red color
                            : isFirstText
                                ? Colors.white // White color
                                : Colors.white, // Red color
                        fontSize: screenSize.height * 0.15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: screenSize.height * 0.07,
                        fontFamily: 'DIGITAL',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Container(
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        checkvalue(value);
                      },
                      onSubmitted: (newText) {
                        updateTexts(newText);
                      },
                      inputFormatters: [
                        // LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+.*/]')),
                      ],
                      autofocus: true,
                      focusNode: _focusNode,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateTexts(String newText) {
    if (_isPlaying) {
      return;
    }
    if (newText == '*') {
      _handleMultiply();
    } else if (int.tryParse(newText) != null) {
      if (newText.length >= 3) {
        newText = newText.substring(0, 3);
      }
      _startFlash();
      handleNumeric(newText);
    } else if (RegExp(r'[^\d+-.*/]').hasMatch(newText)) {
      _handleInvalidCharacter();
    } else if ((newText.startsWith('/'))) {
      _handleSlashValue(newText);
    }
  }

  Future<void> checkvalue(String newText) async {
    if (newText == '.') {
      if (texts[0] == '000' || texts[0] == '00' || texts[0] == '0') {
        _focusNode.requestFocus();
        textController.clear();
      } else {
        int currentValue = int.parse(texts[0]);
        newText = (currentValue).toString().padLeft(3, '0');
        _startFlash();
        _playSound(newText);
        _focusNode.requestFocus();
        textController.clear();
      }
    } else if (newText == '+') {
      handlePlus();
    }
  }

  Future<void> handleNumeric(String newText) async {
    int currentValue = int.parse(newText);
    newText = (currentValue).toString().padLeft(3, '0');
    texts.insert(0, newText);
    if (texts.length > 4) {
      texts.removeLast();
    }
    _playSound(newText);
    _focusNode.requestFocus();
    textController.clear();
  }

  void _handleSlashValue(String newText) {
    if (newText.isNotEmpty && newText.startsWith('/')) {
      newText = newText.substring(1);
      String numberPart = newText.substring(0);
      setState(() {
        int currentValue = int.parse(newText);
        newText = (currentValue).toString().padLeft(3, '0');
        texts.insert(0, newText);
        if (texts.length > 4) {
          texts.removeLast();
        }
        _playSound(newText);
      });
      _focusNode.requestFocus();
      textController.clear();
    } else {
      _focusNode.requestFocus();
      textController.clear();
    }
  }

  void handlePlus() async {
    setState(() {
      int currentValue = int.parse(texts[0]);
      String newText = (currentValue + 1).toString().padLeft(3, '0');
      texts.insert(0, newText);
      if (texts.length > 4) {
        texts.removeLast();
      }
      _playSound(texts[0]);
    });
    _focusNode.requestFocus();
    textController.clear();
  }

  void _handleInvalidCharacter() {
    _focusNode.requestFocus();
    textController.clear();
  }

  void _handleMultiply() {
    setState(() {
      texts = [
        '000',
        '000',
        '000',
        '000',
      ];
    });
    textController.clear();
    _focusNode.requestFocus();
  }

  // เล่นเสียง
  void _playSound(String value) async {
    final trimmedString = value.toString();
    final numberString = trimmedString.replaceAll(RegExp('^0+'), '');
    await _audioPlayer.play(AssetSource('sounds/pnumber.MP3'));
    await Future.delayed(const Duration(milliseconds: 1200));
    for (int i = 0; i < numberString.length; i++) {
      await _audioPlayer.play(AssetSource('sounds/${numberString[i]}.MP3'));
      if (i + 1 < numberString.length &&
          numberString[i] == numberString[i + 1]) {
        await _audioPlayer.onPlayerStateChanged.firstWhere(
          (state) => state == PlayerState.completed,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }
  }

  // จัดการการกระพริบสี
  Timer? _flashTimer;
  int _flashCount = 0;
  bool _isGreen = true;
  void _startFlash() {
    _flashCount = 0;
    _flashTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        _isGreen = !_isGreen;
        _flashCount++;
        if (_flashCount >= 6) {
          _flashTimer?.cancel();
        }
      });
    });
  }

  void _stopFlash() {
    _flashTimer?.cancel();
    setState(() {
      _isGreen = true;
    });
  }
}
