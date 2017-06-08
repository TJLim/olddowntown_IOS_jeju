//
//  FootPrintCourseViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 14..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import RealmSwift
import Tamra
import Alamofire

class FootPrintCourseViewController: UIViewController, MTMapViewDelegate, TamraManagerDelegate {

    
    @IBOutlet weak var navigationLabel: UINavigationItem!
    var courseList: [PoiListVO] = [PoiListVO]()
    lazy var mapView: MTMapView = MTMapView()
    var poiArray:[poiInfoVO] = [poiInfoVO]()
    var POIitems = [MTMapPOIItem]()
    
    var isCustomLocationMarkerUsing: Bool = false
    var isCUstomPlusBtnUsing: Bool = false
    
    let screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 폭 길이
    let screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 높이 길이
    
    let gpsMarker = UIButton()
    let Plus = UIButton()
    var uiView = UIView()
    var m_Scrollview = UIScrollView()   // 주요 코스 메인 스크롤뷰
    
    var courseGroupList = [CourseGroupVO]()
    
    var beaconGroupList = [Int]()   // 비콘 그룹 리스트
    var tamraManager: TamraManager!
    
    var visited: [Int: Visit] = [:]
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
    
    var common: CommonController = CommonController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("viewDidLoad")
        
        initTamraSet()
        
        if courseList.count > 0 {
            navigationLabel.title = courseList[0].courseMNm
        } else {
            navigationLabel.title = "발자취"
        }

        mapView.frame = CGRect(x: 0, y: 80, width: self.view.frame.size.width, height: self.view.frame.size.height - 80)
        mapView.daumMapApiKey = "192483bc98b65172ee46bcc5e222dc9f"
        mapView.delegate = self
        mapView.baseMapType = .standard
        mapView.useHDMapTile = true
        
        
        gpsMarker.frame = CGRect(x: screenWidth - 40, y: 100, width: 30, height: 30)
        gpsMarker.setImage(UIImage(named: "markerGPS.png"), for: UIControlState())
        gpsMarker.addTarget(self, action: #selector(FootPrintCourseViewController.GPSMarkerClick), for: .touchUpInside)
        
        self.view.addSubview(mapView)
        self.view.insertSubview(gpsMarker, aboveSubview: self.mapView)
        
        setCourseData()
        
        makeUIView()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("FootPrintCourseViewController : 비콘 검색 시작")
        
        for i in 0 ..< beaconGroupList.count {
            
            tamraManager.startMonitoring(forId: beaconGroupList[i])
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("FootPrintCourseViewController : 비콘 검색 종료")
        
        tamraManager.stopMonitoring()
        
        //mapView.removeAllPOIItems()
        
        //courseList.removeAll()
        //poiArray.removeAll()
        //POIitems.removeAll()
        
        //self.view.willRemoveSubview(mapView)
    }
    
    func initTamraSet() {
        
        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    @IBAction func Back(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    

    /* 현재위치 불러오는 메소드 */
    @IBAction func GPSMarkerClick(_ sender: UIButton) {
        
        if isCustomLocationMarkerUsing {
            
            mapView.showCurrentLocationMarker = false
            mapView.currentLocationTrackingMode = MTMapCurrentLocationTrackingMode.off
            
            isCustomLocationMarkerUsing = !isCustomLocationMarkerUsing
            
        } else {
            
            mapView.setZoomLevel(2, animated: true)
            mapView.currentLocationTrackingMode = MTMapCurrentLocationTrackingMode.onWithHeading
            mapView.showCurrentLocationMarker = true
            
            isCustomLocationMarkerUsing = !isCustomLocationMarkerUsing
        }
    }
    
    func makeUIView() {

        uiView.frame = CGRect(x: 0, y: screenHeight - 30, width: screenWidth, height: 30)
        uiView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        m_Scrollview.frame = CGRect(x: 0, y: 30 , width: screenWidth, height: screenHeight / 3 - 30)
        m_Scrollview.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        let TitleLabel = UILabel()
        
        TitleLabel.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 30)
        TitleLabel.backgroundColor = UIColor(red: 86/255, green: 80/255, blue: 78/255, alpha: 1)
        TitleLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        TitleLabel.text = "발자취 목록"
        
        let TitleTarget = UITapGestureRecognizer(target: self, action: #selector(FootPrintCourseViewController.PlusBtnClick2(_:)))
        TitleTarget.numberOfTapsRequired = 1
        TitleLabel.isUserInteractionEnabled = true
        TitleLabel.addGestureRecognizer(TitleTarget)
        
        Plus.frame = CGRect(x: screenWidth - 40, y: 0, width: 30, height: 30)
        Plus.setImage(UIImage(named: "markerPlus.png"), for: UIControlState())
        Plus.addTarget(self, action: #selector(FootPrintCourseViewController.PlusBtnClick), for: .touchUpInside)
        
        var tempHeight: CGFloat = 10
        
        for i in 0 ..< courseList.count {
            
            let BeaconListNmLabel = UILabel()
            
            BeaconListNmLabel.frame = CGRect(x: 5, y: tempHeight, width: screenWidth / 2, height: 25)
            
            if courseList[i].visited == true {
                BeaconListNmLabel.text = "- \(courseList[i].contentsTitle) (방문)"
                BeaconListNmLabel.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            } else {
                BeaconListNmLabel.text = "- \(courseList[i].contentsTitle)"
                BeaconListNmLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
            
            BeaconListNmLabel.textAlignment = .left
            
            let target = UITapGestureRecognizer(target: self, action: #selector(FootPrintCourseViewController.dynamicLabelClick(_:)))
            target.numberOfTapsRequired = 1
            BeaconListNmLabel.tag = courseList[i].beaconId
            BeaconListNmLabel.isUserInteractionEnabled = true
            BeaconListNmLabel.addGestureRecognizer(target)

            tempHeight += 30
            
            m_Scrollview.addSubview(BeaconListNmLabel)
        }
        
        let scrollHeight: CGFloat = CGFloat(courseList.count * 30)
        m_Scrollview.contentSize = CGSize(width: screenWidth, height: scrollHeight)
        
        uiView.addSubview(TitleLabel)
        uiView.addSubview(m_Scrollview)
        uiView.addSubview(Plus)
        self.view.addSubview(uiView)
 
    }

    
    /* 발자취 리스트에서 UILabel ( 컨텐츠 명 ) 을 클릭 메소드  */
    func dynamicLabelClick(_ recognizer: UITapGestureRecognizer) {
        
        print("aaaaaaaaaa\(recognizer.view!.tag)")
        var lat: Double!
        var long: Double!
        var poiItem: MTMapPOIItem!
        
        for i in 0 ..< courseList.count {
            
            if recognizer.view!.tag == courseList[i].beaconId {
                
                lat = Double(courseList[i].beaconX)
                long = Double(courseList[i].beaconY)
                poiItem = POIitems[i]
                break
            }
        }
        
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
        
        mapView.select(poiItem, animated: true)
        
    }
    
//    @IBAction func courseBtnClick(sender: UIButton) {
//    
//        var lat: Double!
//        var long: Double!
//        var poiItem: MTMapPOIItem!
//        
//        for i in 0 ..< courseList.count {
//            
//            if sender.tag == courseList[i].beaconId {
//                
//                lat = Double(courseList[i].beaconX)
//                long = Double(courseList[i].beaconY)
//                poiItem = POIitems[i]
//                break
//            }
//        }
//        
//        mapView.setMapCenterPoint(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
//        
//        mapView.selectPOIItem(poiItem, animated: true)
//    
//    }
    
    /* 발자취 목록 옆 삼선 버튼 클릭 메소드 */
    @IBAction func PlusBtnClick(_ sender: UIButton) {
        
        if isCUstomPlusBtnUsing {
            
            uiView.frame = CGRect(x: 0, y: screenHeight - 30, width: screenWidth, height: 30)
            self.view.insertSubview(uiView, aboveSubview: mapView)
            
            isCUstomPlusBtnUsing = !isCUstomPlusBtnUsing
            
        } else {
            
            uiView.frame = CGRect(x: 0, y: screenHeight / 3 * 2, width: screenWidth, height: screenHeight / 3)

            isCUstomPlusBtnUsing = !isCUstomPlusBtnUsing
        }
    }
    
    /* 발자취 목록 라벨 클릭 메소드 */
    @IBAction func PlusBtnClick2(_ recognizer: UITapGestureRecognizer) {
        
        if isCUstomPlusBtnUsing {
            
            uiView.frame = CGRect(x: 0, y: screenHeight - 30, width: screenWidth, height: 30)
            self.view.insertSubview(uiView, aboveSubview: mapView)
            
            isCUstomPlusBtnUsing = !isCUstomPlusBtnUsing
            
        } else {
            
            uiView.frame = CGRect(x: 0, y: screenHeight / 3 * 2, width: screenWidth, height: screenHeight / 3)
            
            isCUstomPlusBtnUsing = !isCUstomPlusBtnUsing
        }
    }

    
    func setCourseData() {
        
        setPoiInfo()
        
        for i in 0 ..< poiArray.count {
            
            if poiArray[i].visitPoi == true {
                POIitems.append(poiItem(poiArray[i].poiName, latitude: poiArray[i].poiLat, longitude: poiArray[i].poiLong, custom: true, tag: poiArray[i].poiBeaconId))
            } else {
                POIitems.append(poiItem(poiArray[i].poiName, latitude: poiArray[i].poiLat, longitude: poiArray[i].poiLong, color: "red", tag: poiArray[i].poiBeaconId))
            }
        }
        
        mapView.addPOIItems(POIitems)
        mapView.fitAreaToShowAllPOIItems()   // 모든 마커가 보이게 카메라 위치/줌 조정
    }
    
    /* poi 정보 셋 해주는 함수 */
    /* 나중에 db정보를 불러와 셋 해줘야 함 */
    func setPoiInfo() {
        
        var tempCnt: Int = 0
        var isExistQueryData: Bool = false
        
        poiArray.removeAll()
        var VisitList = [VisitBeaconArea]()
        
        for i in 0 ..< courseList.count {
                
            let poiInfo = poiInfoVO()
                
            let result = makeQuery("beaconId BEGINSWITH '\(courseList[i].beaconId)' AND courseMNo BEGINSWITH '\(courseList[0].courseMNo)'")
                
            if result.count == 0 {
                poiInfo.visitPoi = false
                courseList[i].visited = false
            } else {
                poiInfo.visitPoi = true
                courseList[i].visited = true
            }
            
            for visitData in result {
                
                let VisitVO = VisitBeaconArea()
                
                VisitVO.beaconId = visitData.beaconId
                VisitVO.courseMNm = visitData.courseMNm
                VisitVO.regDt = changeDateFormat(visitData.regDt)
                
                VisitList.append(VisitVO)
                tempCnt += 1
                isExistQueryData = true
            }
                
            //courseList[i].contentsTitle = subStringBeaconTitle(title: courseList[i].contentsTitle)
            
            if isExistQueryData {
                
                if courseList[i].beaconId == Int(VisitList[tempCnt - 1].beaconId) {
                    poiInfo.poiName = "\(courseList[i].contentsTitle)\n방문 : \(VisitList[tempCnt - 1].regDt)"
                }
                
                isExistQueryData = false
            } else {
                poiInfo.poiName = "\(courseList[i].contentsTitle)\n방문 : -"
            }
            
            poiInfo.poiLat = Double(courseList[i].beaconX)!
            poiInfo.poiLong = Double(courseList[i].beaconY)!
            poiInfo.poiDescription = poiInfo.poiName
            poiInfo.poiBeaconId = courseList[i].beaconId
                
            poiArray.append(poiInfo)
        }
    }
    
    
    /* ContentsNm에 특수문자 들어가는경우 빼는 함수 */
    func subStringBeaconTitle(title: String) -> String {

        var returnString: String = ""
        
        if title.contains("(") {
            
            returnString = subStringNm(nm: title, subStringChar: "(")
        } else if title.contains("<") {
            
            returnString = subStringNm(nm: title, subStringChar: "<")
        } else if title.contains("{") {
            
            returnString = subStringNm(nm: title, subStringChar: "{")
        } else if title.contains("[") {
            
            returnString = subStringNm(nm: title, subStringChar: "[")
        }
        
        return returnString
    }
    
    
    /* 문자열 자르기 함수
     
     ex)제주대학병원(abc)입구 => 제주대학병원 입구
     객사대청(abc)영주관(def)터 => 객사대청 영주관 터 로 변환
     */
    func subStringNm(nm: String, subStringChar: String) -> String {
        
        var subStringChar2: String = ""
        var returnString: String = ""
        
        var tokenStringArr = [String]()
        var tempStringArr = [String]()
        
        if subStringChar == "(" {
            subStringChar2 = ")"
        } else if subStringChar == "<" {
            subStringChar2 = ">"
        } else if subStringChar == "{" {
            subStringChar2 = "}"
        } else if subStringChar == "[" {
            subStringChar2 = "]"
        }
        
        if nm.contains(subStringChar) {
            
            tokenStringArr = nm.components(separatedBy: subStringChar)
            
            print("tokenStringArr.count : \(tokenStringArr.count)")
            print("tokenStringArr[0] : \(tokenStringArr[0])")
            print("tokenStringArr[1] : \(tokenStringArr[1])")
            
            if tokenStringArr.count > 1 {
                
                for i in 0 ..< tokenStringArr.count {
                    
                    if i == 0 {
                        
                        if i + 1 == tokenStringArr.count {
                            return nm
                        }
                        
                        returnString = tokenStringArr[i]
                    }
                    
                    if i + 1 < tokenStringArr.count {
                        
                        if tokenStringArr[i + 1].contains(subStringChar2) {
                            tempStringArr = tokenStringArr[i + 1].components(separatedBy: subStringChar2)
                            
                            returnString += tempStringArr[1]
                            
                        }
                    }
                }
                
                return returnString
                
            } else {
                return nm
            }
            
        }
        
        return nm
    }
    
    /* yyyy-MM-DD HH:mm:ss 문자열에서 MM-DD 로 변환하는 함수 */
    func changeDateFormat(_ date:String) -> String {
        
        var dateArr = date.components(separatedBy: "-")
        var resultDate = "\(dateArr[1])-"
        dateArr = dateArr[2].components(separatedBy: " ")
        resultDate += "\(dateArr[0])"

        return resultDate
    }
    

    
    /* 커스텀 마커 */
    func poiItem(_ name: String, latitude: Double, longitude: Double, custom: Bool, tag: Int) -> MTMapPOIItem {
        let poiItem = MTMapPOIItem()
        poiItem.itemName = name
        poiItem.markerType = .customImage                           //커스텀 타입으로 변경
        poiItem.customImage = UIImage(named: "markerStar")        //커스텀 이미지 지정
        poiItem.markerSelectedType = .customImage                   //선택 되었을 때 마커 타입
        poiItem.customSelectedImage = UIImage(named: "markerStar")    //선택 되었을 때 마커 이미지 지정
        poiItem.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
        poiItem.showAnimationType = .noAnimation
        poiItem.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)
        poiItem.tag = tag
        poiItem.showDisclosureButtonOnCalloutBalloon = false
        
        return poiItem
    }
    
    /* 일반 마커 */
    
    func poiItem(_ name: String, latitude: Double, longitude: Double, color: String, tag: Int) -> MTMapPOIItem {
        
        let poiItem = MTMapPOIItem()
        
        if color == "red" {
            
            poiItem.markerType = .redPin
            poiItem.markerSelectedType = .bluePin
            
        } else if color == "blue" {
            
            poiItem.markerType = .bluePin
            poiItem.markerSelectedType = .redPin
        }
        
        poiItem.itemName = name
        poiItem.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
        poiItem.showAnimationType = .noAnimation
        poiItem.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)    // 마커 위치 조정
        poiItem.tag = tag
        poiItem.showDisclosureButtonOnCalloutBalloon = false
        
        return poiItem
    }
    
    
    func tamraManager(didRangeSpots spots: TamraNearbySpots) {
        let filtered = spots.filter {
            spot in
            return spot.proximity == .immediate || spot.proximity == .near
        }
        
        for spot in filtered {
            if let visit = visited[spot.id] {
                visited[spot.id] = visit.update()
            } else {
                visited[spot.id] = Visit(desc: spot.desc, entry: NSDate() as Date)
                let message = "\(spot.desc) 에 접근했습니다."
                
                print(message)
                
                isExistsMappingContentsId(spot.id, spotDesc: spot.desc)
            }
        }
    }
    
    
    /* Alamofire 를 이용하여 웹페이지 url을 호출하고 그에 맞는 결과값을 얻어 내오는 함수.
     
     감지한 비콘의 매핑 컨텐츠가 존재하는 경우 alert창을 띄움
     감지한 비콘의 매핑 컨텐츠가 존재하지 않는 경우 반응 없음
     */
    func isExistsMappingContentsId(_ spotId: Int, spotDesc: String) {
        
        print("CourseTourViewController : 매핑 컨텐츠 검색 시작")

        Alamofire.request(common.mappingURL, method: .get, parameters: ["beaconId": spotId, "userKey": "nndoonw"]).responseJSON{
        //Alamofire.request(.GET, common.mappingURL, parameters: ["beaconId": spotId, "userKey": "nndoonw"]).responseJSON{
            
            response in switch response.result {
                
            case .success(let JSON):
                
                let response = JSON as! NSDictionary
                
                // 응답 Json 의 Key인 "contentsNo" 로 Value를 얻음
                let contentsNo: String = response.object(forKey: "contentsNo")! as! String
                let contentsTitle = response.object(forKey: "contentsTitle")
                let filePath = response.object(forKey: "filePath")
                
                print("Mapping Contents No : \(contentsNo)")
                
                // 리턴 받은 Json 의 Value가 FALSE가 아닌 경우 메시지창 띄움
                if !contentsNo.isEqual("FALSE") {
                    
                    
                    self.LocalDbInsert(spotId)
                    self.mappingContentsNo = Int(contentsNo )
                    self.mappingContentsTitle = contentsTitle as? String
                    self.mappingFilePath = filePath as? String
                    
                    self.makeAlertMessage(spotDesc)
                }
                
            case .failure(let error):
                print("Request failed with error: \(error)")
            }
        }
        
        print("Main_ViewController : 매핑 컨텐츠 검색 종료")
    }
    
    
    /* 매핑된 컨텐츠가 있을 경우 alert창을 띄워 매핑 컨텐츠를 보여줄지 말지 선택하는 함수*/
    func makeAlertMessage(_ name: String) {
        
        let alert = UIAlertController(title: "비콘신호감지", message: "\(name)에서 비콘 신호를 감지하였습니다.\n해당 내용을 확인 하시겠 습니까?", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "확인", style: .default) {
            (parameter) -> Void in
            
            self.performSegue(withIdentifier: "mappingContents", sender: self)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(cancel)
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func LocalDbInsert(_ beaconId: Int) {
        
        print("CourseTourViewController : 로컬 디비에 감지한 비콘Id \(beaconId) 저장 시도")
        
        let result = makeQuery("beaconId BEGINSWITH '\(beaconId)'")
        
        
        if result.count == 0 {
            
            for i in 0 ..< courseGroupList.count {
                
                for j in 0 ..< courseGroupList[i].courseList.count {
                    
                    if courseGroupList[i].courseList[j].beaconId == beaconId {
                        
                        makeTask(beaconId, courseMNo: courseGroupList[i].courseList[j].courseMNo, courseMNm: courseGroupList[i].courseList[j].courseMNm)
                    }
                }
            }
            
            print("CourseTourViewController : 비콘Id \(beaconId) 저장 완료")
            
        } else {
            
            for VisitBeaconArea in result {
                
                print(VisitBeaconArea.beaconId)
                print(VisitBeaconArea.regDt)
                print("CourseTourViewController : 비콘Id \(beaconId)은 이미 저장되어 있음")
                
            }
            
            removeTask(result)
            
            for i in 0 ..< courseGroupList.count {
                
                for j in 0 ..< courseGroupList[i].courseList.count {
                    
                    if courseGroupList[i].courseList[j].beaconId == beaconId {
                        
                        makeTask(beaconId, courseMNo: courseGroupList[i].courseList[j].courseMNo, courseMNm: courseGroupList[i].courseList[j].courseMNm)
                    }
                }
            }
        }
    }
    
    
    func makeTask(_ beaconId: Int, courseMNo: Int, courseMNm: String){
        
        let task = VisitBeaconArea()
        
        task.beaconId = String(beaconId)
        task.courseMNo = String(courseMNo)
        task.courseMNm = courseMNm
        task.regDt = String(describing: Date())
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(task)
        }
    }
    
    func removeTask(_ task: Results<VisitBeaconArea>){
        let realm = try! Realm()
        try! realm.write {
            realm.delete(task)
        }
    }
    
    func makeQuery(_ query:String) -> Results<VisitBeaconArea>{
        
        let realm = try! Realm()
        let allTask = realm.objects(VisitBeaconArea.self)
        let queryResult = allTask.filter(query)
        
        return queryResult
    }
    
    func removeAllTask(){
        
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        }
    }
    
}
