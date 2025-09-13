import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart'; 
class FileService {

  Future<File> getLogFileForDate(DateTime date) async {

    final directory = await getApplicationDocumentsDirectory();

    final year = DateFormat('yyyy').format(date);
    final monthNum = DateFormat('MM').format(date);
    final monthName = DateFormat('MMM').format(date);
    final day = DateFormat('dd').format(date);

    final path = '${directory.path}/location/$year/${monthNum}_$monthName';
    final fileName = 'log_$day.json';
    
    final file = File('$path/$fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]'); 
    }

    return file;
  }
}
