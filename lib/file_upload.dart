import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Sentiment Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          centerTitle: true,
          elevation: 5,
        ),
        body: Center(child: FileUploadWidget()),
        backgroundColor: Colors.grey.shade200,
      ),
      theme: ThemeData(
        primaryColor: Colors.deepPurpleAccent,
        hintColor: Colors.amberAccent,
        scaffoldBackgroundColor: Colors.grey.shade200,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurpleAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.deepPurpleAccent,
            onPrimary: Colors.white,
            elevation: 3,
            shadowColor: Colors.deepPurple,
          ),
        ),
      ),
    );
  }
}

class FileUploadWidget extends StatefulWidget {
  @override
  _FileUploadWidgetState createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  late String _filePath = '';
  Map<String, dynamic>? _analysisResult;

  void _openFileExplorer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path!;
      });
    }
  }

  void _uploadFile() async {
    if (_filePath.isNotEmpty) {
      // Show loading page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingPage(),
        ),
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2:8000/upload"),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _filePath,
        ),
      );

      try {
        var response = await request.send();

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse =
          json.decode(await response.stream.bytesToString());

          if (jsonResponse.containsKey('error')) {
            print('Server error: ${jsonResponse['error']}');
          } else {
            var analysisResult = jsonResponse['result'];

            if (analysisResult != null) {
              setState(() {
                _analysisResult = analysisResult;
              });

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultPage(_analysisResult),
                ),
              );
            } else {
              print('Analysis result is null');
            }
          }
        } else {
          print('Failed to upload file. Status code: ${response.statusCode}');
          print('Response body: ${await response.stream.bytesToString()}');
        }
      } catch (e) {
        print('Error uploading file: $e');
      }
    } else {
      print('No file selected for upload');
    }
  }

  @override
  Widget build(BuildContext context) {
    String fileName = _filePath.isNotEmpty ? _filePath.split('/').last : '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _openFileExplorer,
          child: Text(
            'Select Text File',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        SizedBox(height: 20),
        if (_filePath.isNotEmpty)
          Text(
            'File Selected: $fileName',
            style: TextStyle(
              color: Colors.deepPurpleAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _uploadFile,
          child: Text(
            'Upload File',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ],
    );
  }
}

class ResultPage extends StatelessWidget {
  final Map<String, dynamic>? analysisResult;

  ResultPage(this.analysisResult);

  @override
  Widget build(BuildContext context) {
    print(analysisResult);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Analysis Result',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        elevation: 5,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              'Total Authors: ${analysisResult!['total_authors']}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'Total Messages: ${analysisResult!['total_messages']}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          if (analysisResult != null &&
              analysisResult!.containsKey('total_authors') &&
              analysisResult!.containsKey('percentage_by_author'))
            ...analysisResult!['percentage_by_author'].keys.map((author) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Sentiment Analysis for $author',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(author),
                        borderData: FlBorderData(show: false),
                        centerSpaceRadius: 40,
                        sectionsSpace: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Display number of messages by each author
                  Center(
                    child: Text(
                      'Messages by $author: ${analysisResult!['messages_by_author'][author]}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Divider(
                    color: Colors.black,
                    thickness: 2,
                  ),
                ],
              );
            }).toList(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(String author) {
    List<PieChartSectionData> sections = [];

    double positivePercentage =
    analysisResult!['percentage_by_author'][author]['positive'];
    double negativePercentage =
    analysisResult!['percentage_by_author'][author]['negative'];
    double neutralPercentage =
    analysisResult!['percentage_by_author'][author]['neutral'];

    sections.add(
      PieChartSectionData(
        color: Colors.green,
        value: positivePercentage,
        title: 'Positive: ${positivePercentage.toStringAsFixed(2)}%',
        radius: 80,
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    sections.add(
      PieChartSectionData(
        color: Colors.red,
        value: negativePercentage,
        title: 'Negative: ${negativePercentage.toStringAsFixed(2)}%',
        radius: 60,
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
    sections.add(
      PieChartSectionData(
        color: Colors.blue,
        value: neutralPercentage,
        title: 'Neutral: ${neutralPercentage.toStringAsFixed(2)}%',
        radius: 40,
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    return sections;
  }
}

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Simulate loading progress
    _simulateLoading();
  }

  // Simulate loading progress
  Future<void> _simulateLoading() async {
    for (int i = 0; i < 100; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        _progress = (i + 1) / 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
            ),
            SizedBox(height: 20),
            Text(
              'Analyzing...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
