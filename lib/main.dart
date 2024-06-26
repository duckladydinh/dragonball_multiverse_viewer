import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

const kDragonballMultiverseHomeUrl = 'https://www.dragonball-multiverse.com';

void main() {
  const title = 'Dragonball Multiverse Viewer';
  runApp(MaterialApp(
    title: title,
    theme: ThemeData.dark(useMaterial3: true),
    home: const DragonballMultiverseViewer(title: title),
    debugShowCheckedModeBanner: false,
  ));
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

  void _incrementPage() {
    setState(() {
      _pageIndex++;
    });
  }

  void _decrementPage() {
    setState(() {
      if (_pageIndex > 0) {
        _pageIndex--;
      }
    });
  }

  void _setPage(int page) {
    setState(() {
      if (page != _pageIndex) {
        _pageIndex = page;
      }
    });
  }

  String _dragonballMultiversePageUrl(String lang) {
    return "$kDragonballMultiverseHomeUrl/$lang/page-$_pageIndex.html";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ScrollThroughButton(
            onTap: _decrementPage,
            icon: Icons.arrow_left,
          ),
          const SizedBox(
            width: 10.0,
          ),
          FloatingActionButton.extended(
            onPressed: () async {
              final jumpPage = await showDialog<int>(
                    context: context,
                    builder: (context) =>
                        PageJumperDialog(currentPage: _pageIndex),
                  ) ??
                  _pageIndex;
              _setPage(jumpPage);
            },
            label: Text(
              '$_pageIndex',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(
            width: 10.0,
          ),
          ScrollThroughButton(
            onTap: _incrementPage,
            icon: Icons.arrow_right,
          ),
        ],
      ),
    );
  }
}

/// A button that is transparent to scroll events but still cliclable.
class ScrollThroughButton extends StatelessWidget {
  const ScrollThroughButton(
      {super.key, required this.onTap, required this.icon});

  final Function() onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: IgnorePointer(
        child: FloatingActionButton(
          onPressed: () {},
          child: Icon(icon),
        ),
      ),
    );
  }
}

/// A page jumper dialog that returns the page number to jump.
class PageJumperDialog extends StatelessWidget {
  const PageJumperDialog({super.key, required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final initialText = '$currentPage';
    final controller = TextEditingController()
      ..text = initialText
      ..selection =
          TextSelection(baseOffset: 0, extentOffset: initialText.length);
    return AlertDialog(
      title: const Text("Jump to page"),
      content: TextFormField(
        decoration: InputDecoration(hintText: 'Current page: $initialText'),
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onEditingComplete: () =>
            Navigator.pop(context, int.parse(controller.text)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, currentPage),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, int.parse(controller.text)),
          child: const Text('OK'),
        ),
      ],
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
    return FutureBuilder<String>(
      future: _dragonballMultiverseImageUrl(widget.url),
      builder: (context, snapshot) => Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (snapshot.hasData)
              Image.network(
                snapshot.data!,
                width: MediaQuery.of(context).size.width * 0.5 - 5,
                fit: BoxFit.fitWidth,
              ),
            UrlLink(
              displayText: "Visit page",
              url: widget.url,
            ),
          ],
        ),
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
