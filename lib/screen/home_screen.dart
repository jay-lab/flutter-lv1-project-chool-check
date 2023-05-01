import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool choolCheckDone = false;
  GoogleMapController? mapController;

  // latitude - 위도 , longitude - 경도
  static final LatLng companyLatLng = LatLng( //--1. LatLng : 구글 맵 관련 클래스
    37.5233273,
    126.921252,
  );
  static final CameraPosition initialPosition = CameraPosition( //-- 2. CameraPosition : 우주에서 지구를 바라봤을때에 대한 정보
    target: companyLatLng,
    zoom: 15,
  );
  static final double okDistance = 100;
  static final Circle withinDistanceCircle = Circle( //-- 지도에 원을 그리는법 (4:30), static으로 설정해주면 밑에 파라미터의 값을 변경 후 hotreload 해도 바뀌지 않음. 재시작 필요 (9:10)
    circleId: CircleId('withinDistanceCircle'), //-- 지도에 표시되는 원마다 고유 아이디 부여 기능
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5), //-- 파란색을 주되, 투명도 지정
    radius: okDistance,//-- radius : m단위로 원의 반지름을 지정할때 사용하는 파라미터
    strokeColor: Colors.blue, //-- 원의 둘레
    strokeWidth: 1, //-- 원 둘레의 굵기
  );
  static final Circle notWithinDistanceCircle = Circle(
    circleId: CircleId('notWithinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,
    strokeWidth: 1,
  );
  static final Circle checkDoneCircle = Circle(
    circleId: CircleId('checkDoneCircle'),
    center: companyLatLng,
    fillColor: Colors.green.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.green,
    strokeWidth: 1,
  );
  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(), //-- ?? : 아직 어떨때 class로, widget으로, Appbar로 뚝뚝뚝딱 판단해서 만드는건지 이해하지 못했다.
      body: FutureBuilder<String>( //-- FutureBuilder 위젯 사용하기 (0:50) / 제네릭에 대한 내용은 StreamBuidler 위젯 사용하기(0:45)에 설명. snapshot의 타입을넣어주면 된다고 한다.
        //-- 참고로, snapshot은 Future 함수의 return 타입인것처럼 설명되었다.
        future: checkPermission(), //-- (1:40) future라는 파라미터에는 'Future'를 return 해주는 함수를 파라미터로 넣을 수 있고,
        //-- 해당 함수의 상태가 변경될때마다 아래의 builder를 다시 그려줄 수 있다(ex:로딩중이거나, 로딩이 끝났거나, return이 끝났거나 에러를 던졌거나 )
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { //-- (FutureBuilder 위젯 사용하기 4:00) FutureBuilder에서는 none, waiting, done 세가지만 나올 수 있음
            //-- none : 위의 future 파라미터를 아예 안썼을때. / waiting : Future함수가 로딩중일 / done : 함수가 끝났을 때
            //-- 여기서의 snapshot은 위에서 'Future타입'인 checkPermission함수에 대한 관찰결과를 나타내며,
            //-- 위의 future파라미터에 설정된 (Future타입)함수의 상태(=스냅샷의 상태)가 변할때마다 builder 부분이 다시 실행될 수 있도록 구현되어있다.
            //-- 밑에있는 StreamBuilder에 구현된 snapshot을 보더라도 snapshot이라는건 공통적으로 해당 FutureBuilder든 StreamBuilder는 해당 Builder가 예의주시할 대상 함수에 대한
            //-- 상태 혹은 결과값이 담긴 데이터로 확인된다.
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data == '위치 권한이 허가 되었습니다.') { //-- 권한을 허용하지 않는 테스트를 하고싶을땐, 시뮬레이터에서 앱을 삭제하고 이 코드 다시실행.
            return StreamBuilder<Position>( //-- StreamBuilder 위젯 사용하기(0:30)
              stream: Geolocator.getPositionStream(), //--StreamBuilder 위젯 사용하기(1:20) 우리가 설정한 정확도에 따라서, 현재 위치가 변경될때마다 그 값이 stream에서 return 된다는 설정
              //-- 즉 yield 가 될때마다 getPositionStream()이 yield하는 타입의 값을 불러올 수 있다. getPositionStream 상세 내용 확인해보면 Position을 return해주고 있는것을 볼 수 있다.
              //-- 참고로 이 getPositionStream도 결국 권한을 받았기에 사용할 수 있는것.
              builder: (context, snapshot) {
                //-- 이 위치에 print(snapshot.data) 찍어보면 처음엔 null이 뜨고 그 다음 바로 위도 경도가 출력되는 것을 볼 수 있다. 처음에 null이 뜨는 이유는 wating 상태에 대한 결과
                bool isWithinRange = false;

                if (snapshot.hasData) {
                  final start = snapshot.data!; //--StreamBuilder 위젯 사용하기 (5:43) snapshot.data? 내 위치를 <Position> 타입으로 표현한 데이터
                  final end = companyLatLng; //-- 회사의 위치

                  final distance = Geolocator.distanceBetween( //-- 거리를 구하는 함수
                    start.latitude,
                    start.longitude,
                    end.latitude,
                    end.longitude,
                  );

                  if (distance < okDistance) { //-- 내위치와 회사의 위치가 100미터(위에 선언해놓은 100)보다 작다면 근처에 있다는 내용의 로직
                    isWithinRange = true;
                  }
                }

                return Column(
                  children: [
                    _CustomGoogleMap(
                      initialPosition: initialPosition,
                      circle: choolCheckDone
                          ? checkDoneCircle
                          : isWithinRange
                              ? withinDistanceCircle
                              : notWithinDistanceCircle,
                      marker: marker,
                      onMapCreated: onMapCreated,
                    ),
                    _ChoolCheckButton(
                      isWithinRange: isWithinRange,
                      choolCheckDone: choolCheckDone,
                      onPressed: onChoolCheckPressed,
                    ),
                  ],
                );
              },
            );
          }

          return Center(
            child: Text(snapshot.data),
          );
        },
      ),
    );
  }

  onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  onChoolCheckPressed() async { //-- 출첵 상태관리 (6:12) : 값을 받아오고싶으면 aync로 해야한다
    final result = await showDialog(
      context: context, //-- "statefulWidget에서는 어디서든 context를 가져올수 있다"
      builder: (BuildContext context) { //-- (6:30) BuildContext context를 써서 원하는 위젯을 return해주면된다.
        return AlertDialog( //-- 다이얼로그를 쉽게만들수있도록 최적화가 되어있는위젯
          title: Text('출근하기'),
          content: Text('출근을 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); //--  "alert 다이얼로그 창을 하나의 화면이라 생각하면 쉽습니다" 그래서 뒤로가기 하는것처럼 이 코드를 사용하면된다.
                //-- 뒤로갈때 데이터를 넘겨주는 방법으로써 여기서는 'false'를 넘겨주는 코드. 이 값은 결국 위에 "result"에 담긴다
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('출근하기'),
            ),
          ],
        );
      },
    );

    if (result) {
      setState(() {
        choolCheckDone = true;
      });
    }
  }

  Future<String> checkPermission() async { //-- 4. 사용자에게 권한 사용 여부를 묻고 응답값을 기다리기 위한 로직으로써, 목적에 의해 async 사용
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled(); //-- 디바이스 자체의 위치서비스 on/off 여부

    if (!isLocationEnabled) {
      return '위치 서비스를 활성화 해주세요.';
    }

    LocationPermission checkedPermission = await Geolocator.checkPermission(); //-- 현재 앱이 가지고있는 위치서비스 권한 확인

    if (checkedPermission == LocationPermission.denied) {
      checkedPermission = await Geolocator.requestPermission();

      if (checkedPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요.';
      }
    }

    if (checkedPermission == LocationPermission.deniedForever) { //-- deniedForever : 사용자가 앱에대한 위치사용 권한을 다시는 요청 못하게 막아놨을 때의 케이스
      //-- (이때는 개발자가 어떻게 할수가 없다. 사용자가 직접 설정등어가서 변경 필요)
      return '앱의 위치 권한을 세팅에서 허가해주세요.';
    }

    return '위치 권한이 허가 되었습니다.';
  }

  AppBar renderAppBar() {
    return AppBar(
      title: Text(
        '오늘도 출근',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
      actions: [ //-- 아이콘을 왼쪽에 배치하려면 leading 속성에 넣고, 우측에 배치하려면 actions 속성에 넣으면 된다.
        IconButton( //-- 오른쪽 상단 '내 위치로 바로가기' 버튼에 대한 기능 구현부. (카메라 위치 애니메이션으로 이동하기 1:00)
          //-- 버튼 눌렀을때 보여지는 지도 위치가 현재 내 위치가 되도록 변경하기 위한 기능
          //-- 그러기 위해선, 웹뷰를 다룰때 처럼, 컨트롤러를 받아서 그 컨트롤러로 조작을 해주면 된다. 그럼 문제는 컨트롤러를 어떻게 받는가? 이것도 웹뷰랑 똑같다
          //-- 밑에있는 GoogleMap() 부분의 onMapCreated 부분을 활용한다. (A)
          onPressed: () async {
            if (mapController == null) {
              return;
            }

            final location = await Geolocator.getCurrentPosition(); //-- 카메라위치 애니메이션으로 이동하기(4:53) 디바이스의 현재 위치를 가져오기 위한 코드
            //-- 이렇듯, 디바이스의 위치를 읽어오기 위해선 await가 필요하고, await를 사용하기 위해 위에서 async 키워드를 사용했다
            //-- getPositionStream을 사용하게 되면 지속적으로 가져올 수 있는 로직(위에서 StreamBuilder 안에서 사용하기도 했다)
            //-- 내 위치를 구글맵에 보여주기 위한 로직을 구현하고있기

            mapController!.animateCamera( //-- 바로 여기서 mapController를 사용하기 위해 최상위 (StatefulWidget)에서 mapController를 전역변수화 했다.
              CameraUpdate.newLatLng(
                LatLng(
                  location.latitude,
                  location.longitude,
                ),
              ),
            );
          },
          color: Colors.blue,
          icon: Icon(
            Icons.my_location,
          ),
        ),
      ],
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated; //-- 카메라 위치 애니메이션으로 이동하기 (2:20)

  const _CustomGoogleMap({
    required this.initialPosition,
    required this.circle,
    required this.marker,
    required this.onMapCreated,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap( //-- 3.
        mapType: MapType.normal, //-- 2D 형식 표시. (hybrid : 위성지도)
        initialCameraPosition: initialPosition,
        myLocationEnabled: true, //-- 지도에 원을 그리는법 1:00 /
        //-- 내 위치 임의 설정 방법 :
        //-- iOS : 시뮬레이터 클릭 > 상단 메뉴바에서 Features > Location > Custom Location
        //-- 안드로이드 : 시뮬레이터 옆에 ...(점점점) > Location > Enable GPS signal 'On' > Latitude, Longtitude 설정
        myLocationButtonEnabled: false, //-- 내 위치 바로가기 버튼 유무(안드로이드는 default로 false 상태)
        circles: Set.from([circle]),
        markers: Set.from([marker]),
        onMapCreated: onMapCreated, //-- (A) 부분에 이어서 설명 > onMapCrated 파라미터를 통해 GoogleMap이 생성되었을때 여기서 controller를 받을 수 있다. 이때 컨트롤러를 다른 위젯에서도 사용할 수 있도록 최상위(StatefulWidget 안)에서
        //-- 전역변수화 하는 로직이 되어야 하겠고, 이에 따라 onMapCreated 또한 최상위(StatefulWidget 안)에서 구체화 되었다. (카메라위치애니메이션으로이동하기1:40)
        //-- 구글맵 컨트롤러를 통해서, 변하는 위치를 계속적으로 렌더링해야하는데
        //-- 그 컨트롤러를 사용하기위해 구글맵을 처음에 create될때 컨트롤러를 받아서 전역변수(?)에 담는 로직
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool choolCheckDone;

  const _ChoolCheckButton({
    required this.isWithinRange,
    required this.onPressed,
    required this.choolCheckDone,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 50.0,
            color: choolCheckDone
                ? Colors.green
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
          ),
          const SizedBox(height: 20.0),
          if (!choolCheckDone && isWithinRange)
            TextButton(
              onPressed: onPressed,
              child: Text('출근하기'),
            ),
        ],
      ),
    );
  }
}
