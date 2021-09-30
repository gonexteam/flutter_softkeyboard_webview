import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreenAndroid extends StatefulWidget {
  const LoginScreenAndroid({Key? key}) : super(key: key);

  @override
  _LoginScreenAndroidState createState() => _LoginScreenAndroidState();
}

class _LoginScreenAndroidState extends State<LoginScreenAndroid> {
  final GlobalKey webViewKey = GlobalKey();
  late CookieManager cookieManager;
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "https://tms.fsoft.com.vn/login";
  double progress = 0;
  final urlController = TextEditingController();
  bool checked = false;

  @override
  void initState() {
    super.initState();
    cookieManager = CookieManager.instance();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    // webViewController?.stopLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text("Test webview")),
        body: SafeArea(
            child: Column(children: <Widget>[
          Row(
            children: [
              ElevatedButton(
                child: const Icon(Icons.arrow_back),
                onPressed: () {
                  webViewController?.goBack();
                },
              ),
              ElevatedButton(
                child: const Icon(Icons.arrow_forward),
                onPressed: () {
                  webViewController?.goForward();
                },
              ),
              ElevatedButton(
                child: const Icon(Icons.refresh),
                onPressed: () {
                  webViewController?.reload();
                },
              ),
              ElevatedButton(
                child: const Icon(Icons.logout),
                onPressed: () {
                  cookieManager.deleteAllCookies();
                  webViewController?.reload();
                },
              ),
              Expanded(
                child: TextField(
                  decoration:
                      const InputDecoration(prefixIcon: Icon(Icons.search)),
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  onSubmitted: (value) {
                    var url = Uri.parse(value);

                    webViewController?.loadUrl(
                        urlRequest: URLRequest(url: url));
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(url: Uri.parse(url)),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      print("OnCreate");
                      controller.addJavaScriptHandler(
                          handlerName: 'handlerFooWithArgs',
                          callback: (args) {
                            print(args);
                            // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                          });
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) async {
                      print("Onload $url");
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    androidOnPermissionRequest:
                        (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;

                      print('shouldOverrideUrlLoading url = $url');
                      if (url.toString().contains('gam=')) {
                        // ScaffoldMessenger.of(navigationKey.currentContext!)
                        //     .showSnackBar(SnackBar(
                        //   content:
                        //   Text('gam=' + url.toString().split('gam=')[1]),
                        //   duration: const Duration(seconds: 3),
                        // ));
                      }

                      if (![
                        "http",
                        "https",
                        "file",
                        "chrome",
                        "data",
                        "javascript",
                        "about"
                      ].contains(uri.scheme)) {
                        if (await canLaunch(url)) {
                          // Launch the App
                          await launch(url);
                          // and cancel the request
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      print("LoadStop $url");
                      pullToRefreshController.endRefreshing();
                      if (mounted) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      }
                      await controller.evaluateJavascript(source: """
                            var nodes =document.querySelectorAll("input[type=text]");
                            for (var i=0; i< nodes.length; i++){
                              nodes[i].disabled = true;
                              nodes[i].classList.add("webview_"+i)
                              console.log(nodes[i]);
                            }
                            
                            window.addEventListener("flutterInAppWebViewPlatformReady", function(event) {
                              window.flutter_inappwebview.callHandler('handlerFoo')
                                .then(function(result) {
                                  // print to the console the data coming
                                  // from the Flutter side.
                                  console.log(JSON.stringify(result));
                                  
                                  window.flutter_inappwebview
                                    .callHandler('handlerFooWithArgs', 1, true, ['bar', 5], {foo: 'baz'}, result);
                              });
                            });
                          """);

                      await controller.evaluateJavascript(
                          source: """console.log('Here is the message!');""");
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) async {
                      if (mounted) {
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = this.url;
                        });
                      }
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ),
                ),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
          ),
        ])));
  }
}
