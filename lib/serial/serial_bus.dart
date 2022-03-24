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

  // static const double inch = 96.0;
  // static const double cm = inch / 2.54;
  // static const double mm = inch / 25.4;

  static const PdfPageFormat inch3 = PdfPageFormat(288, double.infinity, marginAll: 5);

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
                    SerialPortConfig config = SerialPortConfig();
                    config.baudRate = 9600;
                    config.bits = 8;
                    // config.parity = 9600;
                    port.config = config;
                    port.open(mode: SerialPortMode.write);
                    if (port.openWrite()) {
                      port.write(bytes);
                      showSnackbar(
                        context,
                        const Snackbar(
                          content: Text('Serial Port is open !!!'),
                        ),
                      );
                    } else {
                      showSnackbar(
                        context,
                        const Snackbar(
                          content: Text('Serial Port is close !!!'),
                        ),
                      );
                    }
                    port.close();
                    port.dispose();
                    // SerialPort sp = new SerialPort();
                    print(bytes);

                    // sp.PortName = "COM1";
                    // sp.BaudRate = 9600;
                    // sp.Parity = Parity.None;
                    // sp.DataBits = 8;
                    // sp.StopBits = StopBits.One;
                    // sp.Open();
                    // sp.WriteLine("                                        ");
                    // sp.WriteLine("Hi welocme here");

                    // sp.Close();
                    // sp.Dispose();
                    // sp = null;
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

                  _generatePdf(inch3, "POS").then((value) => _printPdf(value));
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
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    List<pw.Widget> rows = [];
    double ptotal = 0;

    var arabicFont = pw.Font.ttf(await rootBundle.load("assets/fonts/HacenQatarRegular.ttf"));

    for (var i = 0; i < 100; i++) {
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
    // pdf.addPage(
    //   pw.MultiPage(
    //     theme: pw.ThemeData.withFont(
    //       base: arabicFont,
    //     ),
    //     // pageFormat: format,
    //     pageFormat: PdfPageFormat.roll80.copyWith(marginBottom: 1.5 * PdfPageFormat.mm),
    //     build: (context) {
    //       return [
    //         pw.SizedBox(
    //           width: double.infinity,
    //           child: pw.FittedBox(
    //             child: pw.Text(title, style: pw.TextStyle(font: font)),
    //           ),
    //         ),
    //         pw.SizedBox(
    //           // width: 40,
    //           child: pw.Image(image),
    //         ),
    //         pw.SizedBox(
    //           // width: double.infinity,
    //           child: pw.Column(children: [
    //             ...rows,
    //             pw.FittedBox(
    //                 child: pw.Text(
    //                     "1---------------------------------------------------------------------------------1")),
    //             pw.Row(
    //                 crossAxisAlignment: pw.CrossAxisAlignment.end,
    //                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    //                 children: [
    //                   pw.Text("Total"),
    //                   pw.Text("$ptotal"),
    //                 ]),
    //             pw.FittedBox(
    //                 child: pw.Text(
    //                     "1---------------------------------------------------------------------------------1")),
    //           ]),
    //         ),
    //         pw.SizedBox(height: 20),
    //       ];
    //     },
    //   ),
    // );
    const double inch = 72.0;
    const double cm = inch / 2.54;
    const double mm = inch / 25.4;
    const PdfPageFormat a4 = PdfPageFormat(21.0 * cm, 29.7 * cm, marginAll: 0);

    pdf.addPage(pw.MultiPage(
        maxPages: 200,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
        margin: const pw.EdgeInsets.fromLTRB(2 * PdfPageFormat.mm, 0, 2 * PdfPageFormat.mm, -4),
        pageFormat: a4.copyWith(
            width: 75 * PdfPageFormat.mm,
            marginTop: 0,
            marginBottom: 0,
            marginLeft: 2 * PdfPageFormat.mm,
            marginRight: 2 * PdfPageFormat.mm),
        build: (context) {
          return [
            pw.SizedBox(height: 20),
            pw.Text('Hello'),
            pw.Text('World'),
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
          ];
        }));

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
  // String items = '''
  //     ''';
  // var html = """
  //   <!DOCTYPE html>
  //   <html>
  //   <head>
  //   <meta name="viewport" content="width=device-width, initial-scale=1">
  //   <link rel="stylesheet" href=
  //   "https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.7/css/bootstrap.min.css" />
  //       <style>

  //         .invoice-box {
  //           max-width:1000px;
  //           margin: auto;
  //           padding: 8px;
  //           border: 1px solid #eee;
  //           box-shadow: 0 0 10px rgba(0, 0, 0, 0.15);
  //           font-size: 8px;
  //           line-height: 24px;
  //           font-family: 'Helvetica Neue', 'Helvetica', Helvetica, Arial, sans-serif;
  //           color: #555;
  //         }
  //           .invoice-box table {
  //           width: 100%;
  //           line-height: inherit;
  //           text-align: center;
  //         }

  //         .invoice-box table td {
  //           padding: 10px;
  //           vertical-align: top;
  //         }

  //         .invoice-box table tr.top table td {
  //           padding-bottom: 5px;
  //         }

  //   * {
  //     box-sizing: border-box;
  //   }

  //   .column {
  //     float: right;
  //     width:23%;

  //     padding: 16px;

  //   }
  //   .header{
  //   text-align:center;
  //   }

  //   .row:after {
  //     content: "";
  //     display: table;
  //     clear: both;
  //   }

  //   </style>
  //   </head>
  //   <body>
  //   <h2 class="header">كشف حساب</h2>
  //   <h3 class="header">بيانات الزبون</h3>
  //   <table>
  //   <tr>
  //   <div class="row">
  //     <div class="column" >
  //       <h4>المبلغ</h4>
  //       <p></p>
  //     </div>

  //     <div class="column" >

  //       <h4>نوع العملية</h4>

  //     </div>

  //     <div class="column" >
  //       <h4>تاريخ</h4>

  //     </div>
  //     <div class="column" >
  //       <h4>وصف</h4>

  //     </div>
  //   </div>
  //   </tr>
  //   $items
  //   </table>
  //   <div>
  //   <p class="header">------------------------</p>
  //   <p>---</p>
  //   <p>--</p>
  //   <p>-</p>
  //   </div>
  //   </body>
  //   </html>""";

  final printers = await Printing.listPrinters();
  print(printers);
  await Printing.directPrintPdf(
      printer: printers.firstWhere((element) => element.isDefault == true), onLayout: (_) => data);
  //     printer: printers.firstWhere((element) => element.isDefault == true), onLayout: (format) async => await Printing.convertHtml(
  //   format: format,
  //   html: html,
  // ));
}
