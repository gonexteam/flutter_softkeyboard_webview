import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Demo2 extends StatefulWidget {
  const Demo2({Key? key}) : super(key: key);

  @override
  _Demo2State createState() => new _Demo2State();
}

class _Demo2State extends State<Demo2> {
  late InAppWebViewController _webViewController;
  int _counter = 0;
  dynamic currentVal;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
  );

  changeText(String text) {
    if (currentVal == null) {
      print("Select a inputText");
      return;
    }
    currentVal['value'] = "${currentVal['value']}$text";
    setState(() {
      currentVal = currentVal;
    });
    _webViewController.evaluateJavascript(source: """
      document.getElementsByClassName("${currentVal['className']}")[0].value=${currentVal['value']};
    """);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text("JavaScript Handlers")),
          body: SafeArea(
              child: Column(children: <Widget>[
            Text("Current Input: $currentVal"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () => changeText("1"), child: const Text("1")),
                ElevatedButton(
                    onPressed: () => changeText("2"), child: const Text("2")),
                ElevatedButton(
                    onPressed: () => changeText("3"), child: const Text("3")),
              ],
            ),
            Expanded(
              child: InAppWebView(
                initialData: InAppWebViewInitialData(data: """
                        <!DOCTYPE html>
                        <html lang="en">
                            <head>
                                <meta charset="UTF-8">
                                <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
                            </head>
                            <body>
                                <h1 class="header" data-id="header">JavaScript Handlers</h1>
                                <input type="text" />        
                                <input type="text" />        
                                <input type="text" />        
                            </body>
                        </html>
                      """),
                initialOptions: options,
                onWebViewCreated: (controller) async {
                  _webViewController = controller;
                  _webViewController.addJavaScriptHandler(
                      handlerName: 'myHandlerName',
                      callback: (args) {
                        print("Nhận dữ liệu từ webview:");
                        print(args);
                        setState(() {
                          currentVal = args[0];
                        });
                        // return data to JavaScript side!
                        // return {'bar': 'bar_value', 'baz': 'baz_value'};
                      });
                },
                onLoadStop: (controller, url) async {
                  _webViewController = controller;
                  await _webViewController.evaluateJavascript(source: """
                        var myFunction = function() {
                            var inputAtt = this.getAttribute("data-input");
                            var inputVal = this.value; 
                            window.flutter_inappwebview.callHandler('myHandlerName',{className: inputAtt, value: inputVal});
                        };
                        var nodes =document.querySelectorAll("input[type=text]");
                            for (var i=0; i< nodes.length; i++){
                              nodes[i].readOnly = true;
                              nodes[i].classList.add("input_"+i); 
                              nodes[i].dataset.input= "input_"+i;
                              nodes[i].addEventListener('click', myFunction, false); 
                        }""");
                  // await _webViewController.evaluateJavascript(source: """
                  //     window.addEventListener("myCustomEvent", (event) => {
                  //       console.log(JSON.stringify(event.detail));
                  //     }, false);
                  //   """);
                  // await Future.delayed(const Duration(seconds: 5));
                  // _webViewController.evaluateJavascript(source: """
                  //     const event = new CustomEvent("myCustomEvent", {
                  //       detail: {foo: 1, bar: false}
                  //     });
                  //     window.dispatchEvent(event);
                  //   """);
                  // Gửi lên từ webviews
                  _webViewController.evaluateJavascript(source: """
                    document.getElementsByClassName("header")[0].addEventListener("click",function(e){ 
                      console.log(this.getAttribute("data-id"))
                      window.flutter_inappwebview.callHandler('myHandlerName',{className: "classInput", value: ""});
                    });
                   """);
                },
                onConsoleMessage: (controller, consoleMessage) {
                  print("FLog: $consoleMessage");
                  // it will print: {message: {"bar":"bar_value","baz":"baz_value"}, messageLevel: 1}
                },
              ),
            ),
          ]))),
    );
  }
}
