import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

const String kDragonballMultiverseHomeUrl =
    'https://www.dragonball-multiverse.com';

void main() {
  runApp(
      const DragonballMultiverseViewer(title: 'Dragonball Multiverse Viewer'));
}

/// A view of a Dragonball Multiverse page that renders in 2 different language at the same time.
class DragonballMultiverseViewer extends StatefulWidget {
  const DragonballMultiverseViewer({super.key, required this.title});

  final String title;

  @override
  State<DragonballMultiverseViewer> createState() =>
      _DragonballMultiverseViewerState();
}

class _DragonballMultiverseViewerState
    extends State<DragonballMultiverseViewer> {
  int _pageIndex = 0;

  void _incrementCounter() {
    setState(() {
      _pageIndex++;
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_pageIndex > 0) {
        _pageIndex--;
      }
    });
  }

  String _dragonballMultiversePageUrl(String lang) {
    return "$kDragonballMultiverseHomeUrl/$lang/page-$_pageIndex.html";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Row(
              children: [
                SinglePageView(url: _dragonballMultiversePageUrl("de")),
                SinglePageView(url: _dragonballMultiversePageUrl("en")),
              ],
            ),
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _decrementCounter,
              child: const Icon(Icons.arrow_left),
            ),
            const SizedBox(
              width: 10.0,
            ),
            Text(
              '$_pageIndex',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              width: 10.0,
            ),
            FloatingActionButton(
              onPressed: _incrementCounter,
              child: const Icon(Icons.arrow_right),
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// A view of a Dragonball Multiverse page.
class SinglePageView extends StatefulWidget {
  const SinglePageView({super.key, required this.url});

  final String url;

  @override
  State<SinglePageView> createState() => _SinglePageViewState();
}

class _SinglePageViewState extends State<SinglePageView> {
  Future<String> _fetchPage(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      return res.body;
    }
    return "";
  }

  Future<String> _dragonballMultiverseImageUrl(String url) async {
    final htmlContent = await _fetchPage(url);
    final document = parser.parse(htmlContent);
    final img = document.getElementById('balloonsimg');
    final src = img?.attributes['src'];
    if (src == null) {
      throw Exception("Couldn't find Dragonball Multiverse Image URL: $url");
    }
    // The image src already has a leading '/'.
    return "$kDragonballMultiverseHomeUrl$src";
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<String>(
            future: _dragonballMultiverseImageUrl(widget.url),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.network(snapshot.data!);
              }
              return UrlLink(
                displayText: "Visit page",
                url: widget.url,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A link widget, similar to <a/>.
class UrlLink extends StatelessWidget {
  const UrlLink({super.key, required this.displayText, required this.url});

  final String displayText;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.blue,
          ),
        ),
      ),
      onTap: () => url_launcher.launchUrl(Uri.parse(url)),
    );
  }
}
