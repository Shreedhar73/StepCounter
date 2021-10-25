import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTH_NOT_GRANTED
}

class _MyAppState extends State<MyApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;

  @override
  void initState() {
    super.initState();
  }

  //fetch total number  of steps

  Future<int> fetchTotalSteps() async {
    // get everything from midnight until now
    DateTime startDate = DateTime(2021, 4, 09, 0, 0, 0);
    DateTime endDate = DateTime(2025, 11, 07, 23, 59, 59);

    HealthFactory health = HealthFactory();

    // define the types to get
    List<HealthDataType> types = [
      HealthDataType.STEPS,
    ];

    // you MUST request access to the data types before reading them
    bool accessWasGranted = await health.requestAuthorization(types);

    int steps = 0;

    if (accessWasGranted) {
      try {
        // fetch new data
        List<HealthDataPoint> healthData =
            await health.getHealthDataFromTypes(startDate, endDate, types);

        // save all the new data points
        _healthDataList.addAll(healthData);
      } catch (e) {
        print("Caught exception in getHealthDataFromTypes: $e");
      }

      // filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      // print the results
      _healthDataList.forEach((x) {
        print("Data point: $x");
        steps += x.value.round();
      });

      print("Steps: $steps");

      return steps;
    } else {
      print("Authorization not granted");
      return 0;
    }
  }

  // Fetch data from the health plugin and print it
  Future fetchData() async {
    // get everything from midnight until now
    DateTime startDate = DateTime(2021, 4, 09, 0, 0, 0);
    DateTime endDate = DateTime(2025, 11, 07, 23, 59, 59);

    HealthFactory health = HealthFactory();

    // define the types to get
    List<HealthDataType> types = [
      HealthDataType.STEPS,
    ];

    setState(() => _state = AppState.FETCHING_DATA);

    // you MUST request access to the data types before reading them
    bool accessWasGranted = await health.requestAuthorization(types);

    int steps = 0;

    if (accessWasGranted) {
      try {
        // fetch new data
        List<HealthDataPoint> healthData =
            await health.getHealthDataFromTypes(startDate, endDate, types);

        // save all the new data points
        _healthDataList.addAll(healthData);
      } catch (e) {
        print("Caught exception in getHealthDataFromTypes: $e");
      }

      // filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      // print the results
      _healthDataList.forEach((x) {
        print("Data point: $x");
        steps += x.value.round();
      });

      print("Steps: $steps");

      // update the UI to display the results
      setState(() {
        _state =
            _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
      });
    } else {
      print("Authorization not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              strokeWidth: 10,
            )),
        Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    //var steps = fetchSteps();
    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 110,
            child: Image(image: AssetImage('Images/fitimage.png')),
          ),
          Container(
            margin: EdgeInsets.all(30),
            height: 50,
            width: 250,
            child: FutureBuilder(
                future: fetchTotalSteps(),
                builder: (context, snapshot) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 15,
                    color: Colors.pinkAccent.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.directions_run),
                        Center(
                            child: Text(
                                "Total Steps: " + snapshot.data.toString())),
                      ],
                    ),
                  );
                }),
          ),
          Text("Steps Data on Certain Time Interval"),
          Container(
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent.shade100)),
            child: SizedBox(
              height: 450,
              child: ListView.builder(
                  itemCount: _healthDataList.length,
                  itemBuilder: (_, index) {
                    HealthDataPoint p = _healthDataList[index];
                    return Card(
                      color: Colors.white10,
                      elevation: 50,
                      child: ListTile(
                        title: Text("${p.typeString}: ${p.value}"),
                        // trailing: Text('${p.type}'),
                        subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentNoData() {
    return Text('No Data to show');
  }

  Widget _contentNotFetched() {
    return Text('Press the download button to fetch data');
  }

  Widget _authorizationNotGranted() {
    return Text('''Authorization not given.
        For Android please check your OAUTH2 client ID is correct in Google Developer Console.
         For iOS check your permissions in Apple Health.''');
  }

  Widget _content() {
    var step;
    if (_state == AppState.DATA_READY)
      return _contentDataReady();
    else if (_state == AppState.NO_DATA)
      return _contentNoData();
    else if (_state == AppState.FETCHING_DATA)
      return _contentFetchingData();
    else if (_state == AppState.AUTH_NOT_GRANTED)
      return _authorizationNotGranted();

    return _contentNotFetched();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('Steps Counter'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () {
                  fetchData();
                },
              )
            ],
          ),
          body: _content()),
    );
  }
}
