import 'package:flutter/material.dart';
import 'package:local_data_source/local_data_source.dart';

/// A simple example demonstrating how to use [local_data_source] with the
/// Hive CE engine.
///
/// To run this example, add the following to your `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   local_data_source: ^1.0.0
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the data source with the Hive engine.
  final LocalDataSource dataSource = await LocalDataSourceFactory.create(
    HiveConfig(),
  );

  // Put a simple string value.
  await dataSource.put<String>('settings', 'theme', 'dark');

  // Read it back.
  final String? theme = await dataSource.get<String>('settings', 'theme');
  debugPrint('Stored theme: $theme'); // Stored theme: dark

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'local_data_source Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'local_data_source Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocalDataSource? _dataSource;
  String _message = 'Press the button to store and read a value.';

  @override
  void initState() {
    super.initState();
    _initDataSource();
  }

  Future<void> _initDataSource() async {
    _dataSource = await LocalDataSourceFactory.create(HiveConfig());
  }

  Future<void> _runExample() async {
    final LocalDataSource? dataSource = _dataSource;
    if (dataSource == null) return;

    const String collection = 'counter';
    const String key = 'value';

    // Read the current count (or default to 0).
    final String? stored = await dataSource.get<String>(collection, key);
    final int count = int.tryParse(stored ?? '') ?? 0;

    // Increment and persist.
    final int newCount = count + 1;
    await dataSource.put<String>(collection, key, newCount.toString());

    setState(() {
      _message = 'Button pressed $newCount time(s). Value persisted locally.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runExample,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
