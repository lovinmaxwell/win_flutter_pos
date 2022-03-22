import 'dart:math';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/material.dart' as mat;
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:win/serial/print.dart';
// import 'dart:io' show Platform;
// import 'package:image/image.dart';

// import 'settings.dart';

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class SerialBusPage extends StatefulWidget {
  const SerialBusPage({Key? key}) : super(key: key);

  @override
  _SerialBusPageState createState() => _SerialBusPageState();
}

class _SerialBusPageState extends State<SerialBusPage> {
  Color? color;
  double scale = 1.0;
  TextEditingController qrTextController = TextEditingController();
  late FocusNode myFocusNode = FocusNode();
  Widget buildColorBox(Color color) {
    const double boxSize = 25.0;
    return Container(
      height: boxSize,
      width: boxSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initPorts();
    myFocusNode = FocusNode();
    myFocusNode.requestFocus();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    myFocusNode.dispose();

    super.dispose();
  }

  void _onEnter(String val) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counterVal = val;
      qrTextController.clear();
      myFocusNode.requestFocus();
    });
  }

  String _counterVal = "";
  var availablePorts = [];

  List<TreeViewItem> _avalPorts = [];

  void _initPorts() {
    setState(() {
      availablePorts = SerialPort.availablePorts;
      _avalPorts = [];
      for (final address in availablePorts) {
        final port = SerialPort(address);
        _avalPorts.add(TreeViewItem(
          content: Text(address),
          expanded: false,
          lazy: true,
          children: [
            TreeViewItem(content: Text('Description : ${port.description}')),
            TreeViewItem(content: Text('Transport : ${port.transport.toTransport()}')),
            TreeViewItem(content: Text('USB Bus : ${port.busNumber?.toPadded()}')),
            TreeViewItem(content: Text('USB Device : ${port.deviceNumber?.toPadded()}')),
            TreeViewItem(content: Text('Vendor ID : ${port.vendorId?.toHex()}')),
            TreeViewItem(content: Text('Product ID : ${port.productId?.toHex()}')),
            TreeViewItem(content: Text('Manufacturer : ${port.manufacturer}')),
            TreeViewItem(content: Text('Product Name : ${port.productName}')),
            TreeViewItem(content: Text('Serial Number : ${port.serialNumber}')),
            TreeViewItem(content: Text('MAC Address : ${port.macAddress}')),
            TreeViewItem(
              content: Button(
                  style: ButtonStyle(padding: ButtonState.all(const EdgeInsets.all(5))),
                  child: Text("Write Somthing"),
                  onPressed: () {
                    List<int> list = 'Hi Testing asdasd'.codeUnits;
                    Uint8List bytes = Uint8List.fromList(list);
                    port.write(bytes);
                    print(bytes);
                    try {} on SerialPortError catch (e) {
                      print(SerialPort.lastError);
                    }
                  }),
            ),
          ],
        ));
      }
    });
    myFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasFluentTheme(context));
    const Widget spacer = SizedBox(height: 4.0);
    return ScaffoldPage.withPadding(
      header: PageHeader(
        title: Text('Serial bus Test'),
        commandBar: Row(
          children: [
            Tooltip(
              message: 'Refresh Serial Ports',
              child: IconButton(
                icon: Icon(FluentIcons.refresh),
                onPressed: () {
                  _initPorts();
                },
              ),
            ),
            Tooltip(
              message: 'Test Printer',
              child: IconButton(
                icon: Icon(FluentIcons.print),
                onPressed: () {
                  // Print().pticket().then((value) {
                  //   Uint8List bytes = Uint8List.fromList(value);
                  //   _printPdf(bytes);
                  // });

                  _generatePdf(PdfPageFormat.roll80, "POS").then((value) => _printPdf(value));
                },
              ),
            )
          ],
        ),
      ),
      content: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text('Display'),
                    spacer,
                    TextBox(
                      controller: qrTextController,
                      focusNode: myFocusNode,
                      onSubmitted: _onEnter,
                    ),
                    spacer,
                    Text(
                      '$_counterVal',
                    ),
                    spacer,
                    if (_avalPorts.length > 0) TreeView(items: _avalPorts),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();

    List<pw.Widget> rows = [];
    double ptotal = 0;

    var arabicFont = pw.Font.ttf(await rootBundle.load("assets/fonts/HacenQatarRegular.ttf"));

    for (var i = 0; i < 50; i++) {
      int ss = i * Random().nextInt(100);
      ptotal += i * ss;
      rows.add(pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Product محبوب $i"),
            pw.Text("1 x $ss"),
          ]));
    }
    final image = await imageFromAssetBundle('assets/logo.png');
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
        pageFormat: format,
        build: (context) {
          return pw.Column(
            children: [
              pw.SizedBox(
                width: double.infinity,
                child: pw.FittedBox(
                  child: pw.Text(title, style: pw.TextStyle(font: font)),
                ),
              ),
              pw.SizedBox(
                // width: 40,
                child: pw.Image(image),
              ),
              pw.SizedBox(
                // width: double.infinity,
                child: pw.Column(children: [
                  ...rows,
                  pw.FittedBox(
                      child: pw.Text(
                          "1---------------------------------------------------------------------------------1")),
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total"),
                        pw.Text("$ptotal"),
                      ]),
                  pw.FittedBox(
                      child: pw.Text(
                          "1---------------------------------------------------------------------------------1")),
                ]),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

// class CardListTile extends StatelessWidget {
//   final String name;
//   final String? value;

//   CardListTile(this.name, this.value);

//   @override
//   Widget build(BuildContext context) {
//     return mat.Card(
//       child: mat.ListTile(
//         title: mat.Text(value ?? 'N/A'),
//         subtitle: mat.Text(name),
//       ),
//     );
//   }
// }

Future<void> _printPdf(Uint8List data) async {
  final printers = await Printing.listPrinters();
  print(printers);
  await Printing.directPrintPdf(
      printer: printers.firstWhere((element) => element.isDefault == true), onLayout: (_) => data);
}
