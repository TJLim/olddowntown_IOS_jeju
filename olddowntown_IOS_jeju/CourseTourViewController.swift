//
//  CourseTourViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 3..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import Tamra
import KakaoNavi

class CourseTourViewController: UIViewController, MTMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, TamraManagerDelegate {

    var pickerDataSourse:[String] = []; // 코스 명 리스트

    lazy var mapView: MTMapView = MTMapView()
    var POIitems = [MTMapPOIItem]()
    
    var poiArray = [poiInfoVO]()

    var courseGroupList = [CourseGroupVO]()
    var themaGroupList = [CourseGroupVO]()
    
    var tamraManager: TamraManager!
    var visited: [Int: Visit] = [:]
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
//    
//    var buttonArr = [UIButton]()
//    var labelArr = [UILabel]()
    
    var courseIndex: Int = 0           // 코스 리스트 배열의 현재 인덱스
    var selectedBeaconId: Int = 0
    
    let screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 폭 길이
    let screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 높이 길이
    
    var mainCourseImgCnt = 0    // 코스별 주요 이미지 개수
    var selectCourseInfo = CourseGroupVO()
    var subScrollCnt = 0        // 서브 스크롤 뷰 페이지 수 ( ex. 이미지가 5개면 페이지 2개 )
    var nowPageImgCnt = 0       // 현재 주요코스 스크롤 박스에 들어갈 이미지 개수

    var removeSubScrollTagList = [Int]()
    var removeDetailSubImgTagList = [Int]()
    
    var dynamicSubScrollArr = [UIScrollView]()
    var dynamicDetailSubImgScrollArr = [UIScrollView]()
    var dynamicDetailText = UILabel()
    var relationCourseList = [RelationCourseVO]()
    
    var uiView = UIView()
    
    var isClickPOIMarker: Bool = false
    var isCourseNmBtnClickFlag: Bool = false
    var isCustomLocationMarkerUsing: Bool = false
    
//    var speechBubbleUpString:String = ""
    
    
    var subImgListCnt = 0   // 선택된 컨텐츠의 서브 이미지 카운트
    var nowPageSubImgCnt = 0       // 현재 주요코스 스크롤 박스에 들어갈 이미지 개수
    
    var beforeDetailTextHeight: CGFloat = 0
    var selectedSubImgPath: String = ""     // 선택된 마커에서 뜨는 여러 서브이미지 중 클릭된 이미지 경로
    var selectedSubImgText: String = ""
    
    let gpsMarker = UIButton()
    let UICourseNmLabel = UILabel()
    let UICourseChangeLabel = UILabel()
    
    let UICreatePickerView = UIPickerView()
    let UICreateCoverPicker = UIView()
    
    var m_mainCourseView = UIView()             // 주요 코스 뷰
    var m_Scrollview = UIScrollView()           // 주요 코스 메인 스크롤뷰
    
    var detailScrollview = UIScrollView()       // 마커 클릭 후 상세화면에서 상세내용 관련 스크롤
    var s_ImgListScrollview = UIScrollView()    // 마커 클릭 후 상세화면에서 시대별 이미지 리스트 스크롤
    
    
    var isCourseChanged: Bool = false
    
    
    var beaconGroupList = [Int]()   // 비콘 그룹 리스트
    var common: CommonController = CommonController()
    
    var progress : ProgressDialog!
    var timer: Timer!
    var time: Float = 0.0
//    var progress : ProgressDialog!
    var isDataGetFinish: Bool = false
//    var timer: NSTimer!
    var current: Int = 0
    
    @IBOutlet weak var progressView: UIProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()

        progress = ProgressDialog(delegate: self)
        
        initTourSet()
        mapViewInit()
        makeUI()
        
        invisiableCourseList()
        
        gpsMarker.frame = CGRect(x: screenWidth - 35, y: 100, width: 30, height: 30)
        gpsMarker.setImage(UIImage(named: "markerGPS.png"), for: UIControlState())
        gpsMarker.addTarget(self, action: #selector(CourseTourViewController.GPSMarkerClick), for: .touchUpInside)
        
        invisibleMainCourseBox()
        invisiableCourseList()
        
        self.view.addSubview(mapView)
        self.view.insertSubview(gpsMarker, aboveSubview: self.mapView)
        
    }
    
    
    /* 해당 화면으로 이동 시 비콘 검색 시작*/
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if isCourseChanged == true {
            pickerView(UICreatePickerView, didSelectRow: 0, inComponent: 0)
            UICreatePickerView.selectRow(0, inComponent: 0, animated: true)
            
            isCourseChanged = !isCourseChanged
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {

        print("CourseTourViewController : 비콘 검색 시작")
        
//        tamraManager.stopMonitoring()
        
        for i in 0 ..< beaconGroupList.count {
            
            tamraManager.startMonitoring(forId: beaconGroupList[i])
            
        }
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("CourseTourViewController : 비콘 검색 종료")
        tamraManager.stopMonitoring()
        
        if isCustomLocationMarkerUsing {
            
            mapView.showCurrentLocationMarker = false
            mapView.currentLocationTrackingMode = MTMapCurrentLocationTrackingMode.off
            
            isCustomLocationMarkerUsing = false
        }
    }
    

    
    func makeUI() {
        
//        progress = ProgressDialog(delegate: self)
        
        createMainCourseBox(-1)
        createPickerView()
        
        
        UICourseNmLabel.frame = CGRect(x: 15, y: 44, width: screenWidth * 6 / 10 - 15, height: 44)
        UICourseNmLabel.text = "코스 선택"
        UICourseNmLabel.font = UIFont(name: (UICourseNmLabel.font?.fontName)!, size: 20)

        
        let target = UITapGestureRecognizer(target: self, action: #selector(CourseTourViewController.CourseNmLabelClick(_:)))
        target.numberOfTapsRequired = 1
        UICourseNmLabel.isUserInteractionEnabled = true
        UICourseNmLabel.addGestureRecognizer(target)
        
        UICourseChangeLabel.frame = CGRect(x: screenWidth * 6 / 10 - 15, y: 44, width: screenWidth * 4 / 10 + 15, height: 44)
        UICourseChangeLabel.textAlignment = .center
        UICourseChangeLabel.text = "테마 투어 가기"
        UICourseChangeLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        UICourseChangeLabel.font = UIFont(name: (UICourseChangeLabel.font?.fontName)!, size: 20)
        
        let target2 = UITapGestureRecognizer(target: self, action: #selector(CourseTourViewController.CourseChangeLabelClick(_:)))
        target2.numberOfTapsRequired = 1
        UICourseChangeLabel.isUserInteractionEnabled = true
        UICourseChangeLabel.addGestureRecognizer(target2)
        
        self.view.addSubview(UICourseNmLabel)
        self.view.addSubview(UICourseChangeLabel)
    }
    
    func mapViewInit() {
        
//        mapView.frame.intersectInPlace(CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height - 95))
        mapView.frame.intersects(CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height - 95))
        mapView.daumMapApiKey = "192483bc98b65172ee46bcc5e222dc9f"
        mapView.delegate = self
        mapView.baseMapType = .standard
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: 33.5025612, longitude: 126.5333188)), zoomLevel: 6, animated: true)
        mapView.useHDMapTile = true
    }
    
    func dataInit() {
        
        UICourseNmLabel.text = "코스 선택"
        
        
        mapView.removeAllPOIItems()
        invisibleMainCourseBox()
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: 33.5025612, longitude: 126.5333188)), zoomLevel: 6, animated: true)
    }
    
    func createPickerView() {
        
        pickerDataSourse.append("코스 선택")
        
        for i in 0 ..< self.courseGroupList.count {
            
            pickerDataSourse.append(self.courseGroupList[i].courseMNm)
        }
        
        let pickerHeight: CGFloat = 120
        
        UICreatePickerView.frame = CGRect(x: 0, y: 0, width: screenWidth / 6 * 4, height: pickerHeight)
        UICreatePickerView.showsSelectionIndicator = true
        
        UICreateCoverPicker.frame = CGRect(x: screenWidth / 6, y: (screenHeight - pickerHeight) / 2, width: screenWidth / 6 * 4, height: pickerHeight)
        UICreateCoverPicker.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        UICreateCoverPicker.addSubview(UICreatePickerView)
        
        self.view.addSubview(UICreateCoverPicker)
    }
    
    func removePickerView() {
        
        pickerDataSourse.removeAll()
        
    }
    
    
    
    func CourseNmLabelClick(_ recognizer: UITapGestureRecognizer) {
        
        if isCourseNmBtnClickFlag == false {
            print("isCourseNmBtnClickFlag == false")
            
            isCourseNmBtnClickFlag = true
            
            visiableCourseList()
            
        } else {
            print("isCourseNmBtnClickFlag == true")
            isCourseNmBtnClickFlag = false
            
            invisiableCourseList()
        }
        
        
        if isClickPOIMarker == true {
            print("isClickPOIMarker == true")
            isClickPOIMarker = false
            removeDetail()
        }
    }
    
    func CourseChangeLabelClick(_ recognizer: UITapGestureRecognizer) {
        
//        mapViewInit()
//        invisibleMainCourseBox()
//        invisiableCourseList()
        
        isCourseChanged = true
        self.performSegue(withIdentifier: "CourseChangeSegue", sender: self)
    }
    

    /* 코스 변경시 주요코스 관련 view 지우는 메소드 */
    func removeSubview() {

        for i in 0 ..< removeSubScrollTagList.count {
            
            if let viewWithTag = dynamicSubScrollArr[i].viewWithTag(removeSubScrollTagList[i]) {
                viewWithTag.removeFromSuperview()
            }
        }
        
        m_Scrollview.removeFromSuperview()
        m_mainCourseView.removeFromSuperview()
        removeSubScrollTagList.removeAll()
        dynamicSubScrollArr.removeAll()
        selectCourseInfo.courseList.removeAll()
    }
    
    
    func removeDetail() {
        
        for i in 0 ..< removeDetailSubImgTagList.count {
            
            if let viewWithTag = dynamicDetailSubImgScrollArr[i].viewWithTag(removeDetailSubImgTagList[i]) {
                viewWithTag.removeFromSuperview()
            }
        }

        detailScrollview.removeFromSuperview()
        removeDetailSubImgTagList.removeAll()
        s_ImgListScrollview.removeFromSuperview()
        
        dynamicDetailSubImgScrollArr.removeAll()
        relationCourseList.removeAll()
        dynamicDetailText.removeFromSuperview()
        uiView.removeFromSuperview()
        uiView = UIView()
    }
    
//    func setProgressView() {
//        
//        if isDataGetFinish == true {
//            
//            print("progress Close()")
//            progress.Close()
//            timer.invalidate()
//        }
//    }
    
    /* 주요 코스 화면 만드는 메소드 */
    func createMainCourseBox(_ index: Int) -> Bool {
        
        if index == -1 {
            
            return false
        }

//        print("progress Show()")
//        progress.Show(true, mesaj: "Loading Course Data...")
//        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(CourseTourViewController.setProgressView), userInfo: nil, repeats: true)
        
//        print("progress Show()")
//        progress.Show(true, mesaj: "Loading Course Data...")
//        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CourseTourViewController.setProgressView), userInfo: nil, repeats: true)
        mainCourseImgCnt = 0
        nowPageImgCnt = 0
        subScrollCnt = 0
     
        removeSubview()
        
//        beforeSubViewTagCnt = 0

        
        
        for i in 0 ..< courseGroupList[index].courseList.count {
            
            if courseGroupList[index].courseList[i].courseContentsYn == "Y" {
                
                mainCourseImgCnt += 1
                selectCourseInfo.courseList.append(courseGroupList[index].courseList[i])
            }
        }
        
        if mainCourseImgCnt == 0 {
            return false
            
            
        } else {
            
            m_mainCourseView.frame = CGRect(x:0, y: self.view.frame.size.height - 150, width: screenWidth, height: 150)
            m_mainCourseView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            

            let m_mainCourseLabel = InsetLabel()
            
            m_mainCourseLabel.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 35 )
            m_mainCourseLabel.text = "볼거리"
            m_mainCourseLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            m_mainCourseLabel.backgroundColor = UIColor(red: 86/255, green: 80/255, blue: 78/255, alpha: 1)
            
            m_Scrollview.frame = CGRect(x: 0, y: 35, width: screenWidth, height: 115 )
            
            let buttonWidth: CGFloat = (self.view.frame.width - 80 )/3
            let labelWidth = buttonWidth
            
            ///////////////////////////////////////////////////////////////////
            // 주요코스 이미지 개수에 따라서 주요코스 보여지는 subScrollView 개수 구하는 로직 //
            ///////////////////////////////////////////////////////////////////
            if mainCourseImgCnt % 3 == 0 {
                subScrollCnt = mainCourseImgCnt / 3
            } else {
                subScrollCnt = ( mainCourseImgCnt / 3 ) + 1
            }
            ///////////////////////////////////////////////////////////////////

            for i in 0 ..< subScrollCnt {
                
                let s_Scrollview = UIScrollView()
                
                s_Scrollview.frame = CGRect(x: CGFloat(i) * screenWidth, y: 0, width: screenWidth, height: 115)
                s_Scrollview.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
               
                s_Scrollview.tag = i
                removeSubScrollTagList.append(i)
                dynamicSubScrollArr.append(s_Scrollview)
                
                if mainCourseImgCnt >= 3 {
                    nowPageImgCnt = 3
                    
                    mainCourseImgCnt -= 3
                    
                } else {
                    
                    nowPageImgCnt = mainCourseImgCnt
                    mainCourseImgCnt = 0
                }
 
                for j in 0 ..< nowPageImgCnt {
                    
                    var CGRectParam = 0
                    
                    if j % 3 == 0 {
                        CGRectParam = 0
                    } else {
                        CGRectParam = j % 3
                    }
                    
                    let x = 20 * (CGFloat(CGRectParam) + 1 ) + buttonWidth * CGFloat(CGRectParam)
                    
                    let letButton = UIButton();
                    var letImage = UIImage()

                    let url: NSString = "http://221.162.53.24:8080\(selectCourseInfo.courseList[3 * i + j].contentsImg)" as NSString
//                    let url: NSString = "http://www.jeju-showcase.com\(selectCourseInfo.courseList[3 * i + j].contentsImg)" as NSString

                    let urlStr : NSString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
                    let searchURL: URL = URL(string: urlStr as String)!
                        
                    let data = try? Data(contentsOf: searchURL)
                        
                    // It is the best way to manage nil issue.
                    if data!.count > 0 {
                        letImage = UIImage(data:data!)!
                    } else {
                        // In this when data is nil or empty then we can assign a placeholder image
                        letImage = UIImage(named: "placeholder.png")!
                    }
                        
                    letButton.setImage(letImage, for: UIControlState())
                    
                    letButton.frame = CGRect(x: x, y: 5, width: buttonWidth, height: 70) // X, Y, width, height
                    
                    letButton.addTarget(self, action: #selector(CourseTourViewController.buttonPressed), for: .touchUpInside)
                        
                    letButton.tag = selectCourseInfo.courseList[3 * i + j].beaconId
                    s_Scrollview.addSubview(letButton)
                   
                    let letLabel = UILabel()
                    
                    letLabel.text = selectCourseInfo.courseList[3 * i + j].contentsTitle
                    letLabel.textAlignment = NSTextAlignment.center
                    letLabel.numberOfLines = 0
                    letLabel.lineBreakMode = .byWordWrapping
                    letLabel.font = UIFont(name: (UICourseNmLabel.font?.fontName)!, size: 14)
                    
                    letLabel.frame = CGRect(x: x, y: 80, width: labelWidth, height: 35)
                    s_Scrollview.addSubview(letLabel)
                    
                }
                
                m_Scrollview.addSubview(s_Scrollview)
                s_Scrollview.contentSize = CGSize(width: screenWidth, height: 115)
                
            }
            m_Scrollview.isPagingEnabled = true
            m_Scrollview.contentSize = CGSize(width: screenWidth * CGFloat(subScrollCnt), height: 115)
            
            m_mainCourseView.addSubview(m_mainCourseLabel)
            m_mainCourseView.addSubview(m_Scrollview)

        }

        
        isDataGetFinish = true
        self.view.insertSubview(m_mainCourseView, aboveSubview: self.view)
        
        return true
    }
    
    
    /* 주요코스 이미지 버튼 클릭시 선택된 비콘 이미지의 좌표를 중심점으로 잡음 */
    @IBAction func buttonPressed(_ sender: UIButton) {
        
//        print(sender)
        
        var lat: Double!
        var long: Double!
        var poiItem: MTMapPOIItem!
        
        for i in 0 ..< courseGroupList[courseIndex].courseList.count {
            
            if sender.tag == courseGroupList[courseIndex].courseList[i].beaconId {
                
                lat = Double( courseGroupList[courseIndex].courseList[i].beaconX)
                long = Double( courseGroupList[courseIndex].courseList[i].beaconY)
                poiItem = POIitems[i]
                break
            }
        }
        
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
        mapView.select(poiItem, animated: true)
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
    
    
    func removeAllTask(){
        
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
    func mapView(_ mapView: MTMapView!, updateCurrentLocation location: MTMapPoint!, withAccuracy accuracy: MTMapLocationAccuracy) {
        
        print("2")
        
    }
    
//    func makeTask(beaconId: Int){
//        
//        let task = VisitBeaconArea()
//        
//        task.beaconId = String(beaconId)
// 
//        
//        let realm = try! Realm()
//        
//        try! realm.write {
//            realm.add(task)
//        }
//    }
    
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
    
    
    /* 비콘 ID를 통하여 로컬DB에 조회하여 해당 비콘 ID가 있지만 특정 시간이 지나지 않았으면 return false, 비콘 ID가 없거나 있지만 특정 시간이 지나면 returh true */
    func findBeaconMappingCheckScheduler(_ BeaconId: Int) -> Bool{
        
        let result = makeQuery("beaconId BEGINSWITH '\(BeaconId)'")
        
        if result.count == 0 {
            
            return true
            
        } else {

            return true
        }
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
            
//            makeTask(beaconId)
            print("CourseTourViewController : 비콘Id \(beaconId) 저장 완료")
        } else {
            
            for VisitBeaconArea in result {
                
                print(VisitBeaconArea.beaconId)
                print(VisitBeaconArea.regDt)
                print("CourseTourViewController : 비콘Id \(beaconId)은 이미 저장되어 있음")
                
                
//                updateTask(Int(VisitBeaconArea.beaconId)!)
//                VisitBeaconArea.regDt = NSDate()
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
    

    func initTourSet() {
        
        self.UICreatePickerView.dataSource = self
        self.UICreatePickerView.delegate = self

        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSourse.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSourse[row]
    }
    
    /* 하단 주요장소 박스 띄우는 함수 */
    func visableMainCourseBox() {
        
        mapView.frame = CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height - 223)

//        self.view.insertSubview(m_mainCourseView, aboveSubview: self.mapView)
    }
    
    /* 하단 주요장소 박스 안보이게 하는 함수 */
    func invisibleMainCourseBox() {

        mapView.frame = CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height - 95)
        
        self.view.insertSubview(self.mapView, aboveSubview: m_mainCourseView)
    }
    
    func visiableCourseList() {
        
        self.view.insertSubview(UICreateCoverPicker, aboveSubview: self.mapView)
    }
    
    func invisiableCourseList() {
        
        self.view.insertSubview(self.mapView, aboveSubview: UICreateCoverPicker)
        self.view.insertSubview(gpsMarker, aboveSubview: self.mapView)
    }
    
    
    func ProgressStart() {
        
        // Get current values.
        let i = current
        let max = 10
        
        // If we still have progress to make.
        if i <= max {
            // Compute ratio of 0 to 1 for progress.
            let ratio = Float(i) / Float(max)
            // Set progress.
            progressView.progress = Float(ratio)
            // Write message.
//            simpleLabel.text = "Processing \(i) of \(max)..."
            current += 1
        }
        
    }
    
    
    /* pickerView 선택시 동작하는 메소드 */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        isDataGetFinish = false
        isCourseNmBtnClickFlag = false

        UICourseNmLabel.text = pickerDataSourse[row]

        invisiableCourseList()
        POIitems.removeAll()
        mapView.removeAllPOIItems()
        courseIndex = row - 1
        
        let isShowingMainCourseBox = createMainCourseBox(courseIndex)
        
        if row != 0 {

            setPoiInfo(row)
            
            for i in 0 ..< poiArray.count {
                
                POIitems.append(poiItem(poiArray[i].poiName, latitude: poiArray[i].poiLat, longitude: poiArray[i].poiLong, color: "red", tag: poiArray[i].poiBeaconId))
            }
            
            //POIitems.append(poiItem("ccccc", latitude: 33.510165, longitude: 126.5401964, color: "red", tag: 230))

            
            mapView.addPOIItems(POIitems)
            
            if isShowingMainCourseBox == true {
                visableMainCourseBox()
            } else {
                invisibleMainCourseBox()
            }
            mapView.fitAreaToShowAllPOIItems()   // 모든 마커가 보이게 카메라 위치/줌 조정
            
        } else {
            
            dataInit()
        }
    }
    
    /* poi 정보 셋 해주는 함수 */
    /* 나중에 db정보를 불러와 셋 해줘야 함 */
    func setPoiInfo(_ index: Int) {
    
        poiArray.removeAll()

        for i in 0 ..< courseGroupList[index-1].courseList.count {
                
            let poiInfo = poiInfoVO()
               
            let result = makeQuery("beaconId BEGINSWITH '\(courseGroupList[index-1].courseList[i].beaconId)'")

            if result.count == 0 {
                poiInfo.visitPoi = false
            } else {
                poiInfo.visitPoi = true
            }

            poiInfo.poiName = courseGroupList[index-1].courseList[i].contentsTitle
            
            if poiInfo.poiName.length > 12 {
                
                let firstName: String = (poiInfo.poiName as NSString).substring(to: 12)
                let lastName: String = (poiInfo.poiName as NSString).substring(from: 12)

                poiInfo.poiName = "\(firstName)\n\(lastName)"
            }
            
            poiInfo.poiLat = Double(courseGroupList[index-1].courseList[i].beaconX)!
            print("poiLat : \(poiInfo.poiLat)")
            poiInfo.poiLong = Double(courseGroupList[index-1].courseList[i].beaconY)!
            poiInfo.poiDescription = poiInfo.poiName
            poiInfo.poiBeaconId = courseGroupList[index-1].courseList[i].beaconId
                
            poiArray.append(poiInfo)
        }
    }

    
    /* mapView 마커 클릭 이벤트 메소드 */
    func mapView(_ mapView: MTMapView!, selectedPOIItem poiItem: MTMapPOIItem!) -> Bool {
        
        print("select POI : \(poiItem.itemName!)")
//
//        var lat: Double!
//        var long: Double!
//
//        
//        for i in 0 ..< courseGroupList[courseIndex].courseList.count {
//            
//            if poiItem.tag == courseGroupList[courseIndex].courseList[i].beaconId {
//                
//                lat = Double( courseGroupList[courseIndex].courseList[i].beaconX)
//                long = Double( courseGroupList[courseIndex].courseList[i].beaconY)
//
//                break
//            }
//        }
//        
//        mapView.setMapCenterPoint(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
        
        if isClickPOIMarker == false {
            print("isClickPOIMarker == false")
            isClickPOIMarker = true
            
            getRelationCourse(poiItem.tag)
            selectedBeaconId = poiItem.tag
            
        } else {
            print("isClickPOIMarker == true")
            isClickPOIMarker = false
            
            removeDetail()
            
            if poiItem.tag != selectedBeaconId {
                
                isClickPOIMarker = true
                
                getRelationCourse(poiItem.tag)
                selectedBeaconId = poiItem.tag
            }
        }
        
        return true
    }
    
    
    /* mapView 화면 클릭 시 이벤트 메소드 */
    func mapView(_ mapView: MTMapView!, singleTapOn mapPoint: MTMapPoint!) {
        removeDetail()
        isClickPOIMarker = false
    }

    
    /* 선택된 마커의 tag(beaconId) 값으로 연관 코스 불러오는 함수. */
    func getRelationCourse(_ beaconId: Int) {

        Alamofire.request(common.getRelationCourse, method: .get, parameters: ["beaconId": beaconId]).responseJSON{
        //Alamofire.request(.GET, common.getRelationCourse, parameters: ["beaconId": beaconId]).responseJSON{

            response in switch response.result {
                
            case .success( _):
                
//                print("JSON2 : \(JSON)")
                
                let json = response.result.value
                
                if let objJson = json as! NSArray? {
                    
                    for element in objJson {
                        
                        let relationCourse = RelationCourseVO()
                        
                        let relation = element as! NSDictionary
                        
                        relationCourse.courseMNo = relation.object(forKey: "courseMNo") as! Int
                        relationCourse.courseMNm = relation.object(forKey: "courseMNm") as! String
                        
                        
                        self.relationCourseList.append(relationCourse)
                    }
                }
                
                self.setDetailOfBeaconID(beaconId)
                
            case .failure(let error):
                print("Request failed with error: \(error)")
            }
        }
    }

    
    /* 선택된 비콘의 상세화면 뿌리기 */
    func setDetailOfBeaconID(_ beaconId: Int) {

        var lat: Double = 0.0
        var long: Double = 0.0
        var detailNm: String = ""
        var detailDescription: String = ""
        
        subImgListCnt = 0
        nowPageSubImgCnt = 0
        
        for i in 0 ..< courseGroupList[courseIndex].courseList.count {
            
            if courseGroupList[courseIndex].courseList[i].beaconId == beaconId { // 선택된 비콘의 tag(beaconId) 와 courseList의 beaconId가 같은 경우
                
                lat = Double(courseGroupList[courseIndex].courseList[i].beaconX)!
                long = Double(courseGroupList[courseIndex].courseList[i].beaconY)!
                detailNm = courseGroupList[courseIndex].courseList[i].contentsTitle
                detailDescription = courseGroupList[courseIndex].courseList[i].contentsText

                break
            }
        }
        
        if detailNm.length > 16 {
            
            detailNm = subStringBeaconTitle(detailNm: detailNm)   // ContentsNm에 특수문자 들어가는경우 빼는 함수
        }
        
        
        uiView.frame = CGRect(x: 0, y: screenHeight / 2, width: screenWidth, height: screenHeight / 2)
        uiView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        let uiButtonBack = UIButton()
        let uiButtonNm = UIButton()
        let uiButtonNavi = UIButton()
        let uiDetailText = UILabel()
        let uiRelationCourseText = UILabel()
        
        uiButtonBack.frame = CGRect(x: 0, y: 0, width: 30, height: 50)

        var leftImg: UIImage = UIImage()
        
        leftImg = UIImage(named: "left.png")!
        uiButtonBack.setImage(leftImg, for: UIControlState())
        
        uiButtonBack.setTitleColor(UIColor(red: 0, green: 0, blue: 0, alpha: 1), for: .highlighted)
        uiButtonBack.backgroundColor = UIColor(red: 134/255, green: 208/255, blue: 235/255, alpha: 1)
        uiButtonBack.addTarget(self, action: #selector(CourseTourViewController.detailNmBtnClick), for: .touchUpInside)
        
        uiButtonNm.frame = CGRect(x: 30, y: 0, width: screenWidth / 3 * 2 - 30, height: 50)
        uiButtonNm.setTitle(detailNm, for: UIControlState())
        uiButtonNm.setTitleColor(UIColor(red: 1, green: 1, blue: 1, alpha: 1), for: .highlighted)
        uiButtonNm.backgroundColor = UIColor(red: 134/255, green: 208/255, blue: 235/255, alpha: 1)
        uiButtonNm.addTarget(self, action: #selector(CourseTourViewController.detailNmBtnClick), for: .touchUpInside)
        
        uiButtonNavi.frame = CGRect(x: screenWidth / 3 * 2, y: 0 , width: screenWidth / 3, height: 50)
        uiButtonNavi.setTitle("길찾기", for: UIControlState())
        uiButtonNavi.setTitleColor(UIColor(red: 81/255, green: 57/255, blue: 47/255, alpha: 1), for: .highlighted)
        uiButtonNavi.backgroundColor = UIColor(red: 38/255, green: 141/255, blue: 198/255, alpha: 1)
        uiButtonNavi.tag = beaconId
        uiButtonNavi.addTarget(self, action: #selector(CourseTourViewController.loadKakaoNavi), for: .touchUpInside)
        
        detailScrollview.frame = CGRect(x: 0, y: 50, width: screenWidth, height: screenHeight / 2 - 50)
        detailScrollview.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        var ImgPathArr:[String] = [String]()
        var ImgPathIndexArr:[Int] = [Int]()
        
        for k in 0 ..< courseGroupList[courseIndex].courseList.count {
            
            if courseGroupList[courseIndex].courseList[k].beaconId == beaconId {
                
                subImgListCnt = courseGroupList[courseIndex].courseList[k].subImgList.count
                
                for z in 0 ..< courseGroupList[courseIndex].courseList[k].subImgList.count {
                    
                    ImgPathArr.append("http://221.162.53.24:8080\(courseGroupList[courseIndex].courseList[k].subImgList[z].contentsDImg)")
//                    ImgPathArr.append("http://www.jeju-showcase.com\(courseGroupList[courseIndex].courseList[k].subImgList[z].contentsDImg)")
                    
                    
                    ImgPathIndexArr.append(courseGroupList[courseIndex].courseList[k].subImgList[z].contentsDSeq)
                }
            }
        }
        
        if subImgListCnt == 0 { // 서브 이미지가 없을 때
            
            uiDetailText.numberOfLines = 0
            
            dynamicDetailText = uiDetailText
            
            var relationStr: String = ""
            
            for i in 0 ..< relationCourseList.count {
                
                if relationCourseList.count == 1 {
                    relationStr = relationCourseList[i].courseMNm
                } else {
                    
                    if i != relationCourseList.count - 1 {
                        
                        relationStr = relationStr + relationCourseList[i].courseMNm + ", "
                        
                    } else {
                        relationStr = relationStr + relationCourseList[i].courseMNm
                    }
                }
            }
            
            detailDescription =  detailDescription + "\n\n연관코스 : \(relationStr)"
            
            uiDetailText.text = detailDescription
            var uiDetailTextHeight = calculateContentHeight(uiDetailText)
            uiDetailText.frame = CGRect(x: 15, y: 5, width: screenWidth - 30 , height: uiDetailTextHeight)
            
            uiDetailTextHeight += 15
            detailScrollview.contentSize = CGSize(width: screenWidth, height: uiDetailTextHeight)

            detailScrollview.addSubview(s_ImgListScrollview)

        } else {    // 서브 이미지가 있을 때
            
            let buttonWidth: CGFloat = (self.view.frame.width - 80 )/3
            
            if (subImgListCnt <= 3) {
                subScrollCnt = 1
            } else if (subImgListCnt > 3 && subImgListCnt <= 6 ) {
                subScrollCnt = 2
            } else if (subImgListCnt > 6 && subImgListCnt <= 9 ) {
                subScrollCnt = 3
            } else if (subImgListCnt > 9 && subImgListCnt <= 12 ) {
                subScrollCnt = 4
            }
            
            s_ImgListScrollview.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 95)
            s_ImgListScrollview.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            
            for i in 0 ..< subScrollCnt {
                
                let s_SubImgListView = UIScrollView()
                
                s_SubImgListView.frame = CGRect(x: CGFloat(i) * screenWidth, y: 0, width: screenWidth, height: 95)
                s_SubImgListView.tag = i
                
                dynamicDetailSubImgScrollArr.append(s_SubImgListView)
                removeDetailSubImgTagList.append(i)
                if subImgListCnt > 3 {
                    
                    nowPageSubImgCnt = 3
                    subImgListCnt -= 3
                    
                } else {
                    nowPageSubImgCnt = subImgListCnt
                    subImgListCnt = 0
                }
                
                for j in 0 ..< nowPageSubImgCnt {
                    
                    var CGRectParam = 0
                    
                    if j % 3 == 0 {
                        CGRectParam = 0
                    } else {
                        CGRectParam = j % 3
                    }
                    
                    let x = 20 * (CGFloat(CGRectParam) + 1 ) + buttonWidth * CGFloat(CGRectParam)
                    
                    let letButton = UIButton();
                    var letImage = UIImage()
                    
                    let url: NSString = ImgPathArr[3 * i + j] as NSString
                    let urlStr : NSString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
                    let searchURL: URL = URL(string: urlStr as String)!
                    
                    let data = try? Data(contentsOf: searchURL)
                    
                    // It is the best way to manage nil issue.
                    if data!.count > 0 {
                        letImage = UIImage(data:data!)!
                    } else {
                        // In this when data is nil or empty then we can assign a placeholder image
                        letImage = UIImage(named: "placeholder.png")!
                    }
                    
                    letButton.setImage(letImage, for: UIControlState())
                    letButton.tag = 3 * i + j
                    letButton.addTarget(self, action: #selector(CourseTourViewController.SubImgClick), for: .touchUpInside)
                    letButton.frame = CGRect(x: x, y: 5, width: buttonWidth, height: 70) // X, Y, width, height
                    
                    s_SubImgListView.addSubview(letButton)
                }
                
                s_ImgListScrollview.addSubview(s_SubImgListView)
            }
            
            s_ImgListScrollview.contentSize = CGSize(width: screenWidth * CGFloat(subScrollCnt), height: 95)
            s_ImgListScrollview.isPagingEnabled = true
            
            detailScrollview.addSubview(s_ImgListScrollview)

            uiDetailText.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            uiDetailText.numberOfLines = 0
            
            
            
//            uiDetailText.text = detailDescription
//            var uiDetailTextHeight = calculateContentHeight(uiDetailText)
//            uiDetailText.frame = CGRectMake(15, 95, screenWidth - 30 , uiDetailTextHeight)
            
            
            var relationStr: String = ""
            
            for i in 0 ..< relationCourseList.count {
                
                if relationCourseList.count == 1 {
                    relationStr = relationCourseList[i].courseMNm
                } else {
                    
                    if i != relationCourseList.count - 1 {
                        
                        relationStr = relationStr + relationCourseList[i].courseMNm + ", "
                        
                    } else {
                        relationStr = relationStr + relationCourseList[i].courseMNm
                    }
                }
            }
            
            uiRelationCourseText.text = "\n\n연관코스 : "
            detailDescription =  detailDescription + "\n\n연관코스 : \(relationStr)"

            uiDetailText.text = detailDescription
            dynamicDetailText = uiDetailText
            
            var uiDetailTextHeight = calculateContentHeight(uiDetailText)
            uiDetailText.frame = CGRect(x: 15, y: 95, width: screenWidth - 30 , height: uiDetailTextHeight)
            
            uiDetailTextHeight += 110
            detailScrollview.contentSize = CGSize(width: screenWidth, height: uiDetailTextHeight)
//            detailScrollview.contentSize = CGSize(width: screenWidth, height: 440.0)
        }
       
        detailScrollview.addSubview(uiDetailText)
        uiView.addSubview(uiButtonBack)
        uiView.addSubview(uiButtonNm)
        uiView.addSubview(uiButtonNavi)
        uiView.addSubview(detailScrollview)
        
        visibleDetail()

        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
    }
    
    
    /* 서브 이미지 클릭 이벤트 메소드 */
    func SubImgClick(_ sender: UIButton) {
        
        print("태그 값 : \(sender.tag)")
        
        
        for i in 0 ..< courseGroupList[courseIndex].courseList.count {
            
            if courseGroupList[courseIndex].courseList[i].beaconId == selectedBeaconId {
                
                for j in 0 ..< courseGroupList[courseIndex].courseList[i].subImgList.count {

                    if j == sender.tag {
                        
                        selectedSubImgPath = courseGroupList[courseIndex].courseList[i].subImgList[j].contentsDImg
                        selectedSubImgText = courseGroupList[courseIndex].courseList[i].subImgList[j].contentsDText
                        self.performSegue(withIdentifier: "SubImgDetail", sender: self)
                        
                        break
                    }
                }
            }
        }
    }
    
   
    /* ContentsNm에 특수문자 들어가는경우 빼는 함수 */
    func subStringBeaconTitle(detailNm: String) -> String {
        
        var returnString: String = ""
        
        if detailNm.contains("(") {
        
            returnString = subStringNm(nm: detailNm, subStringChar: "(")
        } else if detailNm.contains("<") {
            
            returnString = subStringNm(nm: detailNm, subStringChar: "<")
        } else if detailNm.contains("{") {
            
            returnString = subStringNm(nm: detailNm, subStringChar: "{")
        } else if detailNm.contains("[") {
            
            returnString = subStringNm(nm: detailNm, subStringChar: "[")
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
            
            if tokenStringArr.count > 1 {
                
                for i in 0 ..< tokenStringArr.count {
                    
                    if i == 0 {
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
    
    /* 비콘 컨텐츠 제목 버튼 클릭 이벤트 메소드 */
    func detailNmBtnClick() {
        
        removeDetail()
        isClickPOIMarker = false
    }
    
    /* 길찾기 눌렀을 시 카카오네비 연동*/
    func loadKakaoNavi(_ sender: UIButton) {
        
        let beaconId: Int = sender.tag
        var lat: Double = 0.0
        var long: Double = 0.0
        var contentsTitle: String = ""
        
        for i in 0 ..< courseGroupList[courseIndex].courseList.count {
         
            if beaconId == courseGroupList[courseIndex].courseList[i].beaconId {
                
                lat = Double(courseGroupList[courseIndex].courseList[i].beaconY)!
                long = Double(courseGroupList[courseIndex].courseList[i].beaconX)!
                contentsTitle = courseGroupList[courseIndex].courseList[i].contentsTitle
                
                break
            }
        }
        
        // NAVI INIT START
        let option: KNVOptions = KNVOptions.init()
        let naviLauncher:KNVNaviLauncher = KNVNaviLauncher.init()
        let coordType: KNVCoordType = KNVCoordType.init(rawValue: 2)!
        let navi: KNVLocation = KNVLocation(name: contentsTitle, x:lat as NSNumber, y: long as NSNumber)
        option.coordType = coordType
        let params: KNVParams = KNVParams.param(withDestination: navi, options: option)
        
        // NAVI START
        naviLauncher.shareDestination(with: params, error: nil)
    }
    
    func visibleDetail() {
        
        self.view.addSubview(uiView)
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
            poiItem.markerSelectedType = .redPin
            
        } else if color == "blue" {
            
            poiItem.markerType = .bluePin
            poiItem.markerSelectedType = .bluePin
        }
        
        poiItem.itemName = name
        poiItem.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
        poiItem.showAnimationType = .noAnimation
        poiItem.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)    // 마커 위치 조정
        poiItem.tag = tag
        poiItem.showDisclosureButtonOnCalloutBalloon = false
        
        return poiItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    @IBAction func Back(_ sender: AnyObject) {

        self.dismiss(animated: false, completion: nil)
    }

    
    func calculateContentHeight(_ setLable: UILabel) -> CGFloat {
        
        let widthSizeminus: CGFloat = 30
        let maxlabelSize: CGSize = CGSize(width: self.view.frame.size.width - widthSizeminus, height: CGFloat(9999))
        
        let options:NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let contentNSString = setLable.text! as NSString
        let expectedLabelSize = contentNSString.boundingRect(with: maxlabelSize, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17.0)], context: nil)
        
        return expectedLabelSize.size.height
    }
    
//    Alamofire 함수가 비동기 함수라서 대부분의 alamofire는 메인에서 처리하고 데이터 받기
    /* 페이지 이동시 넘겨질 데이터 set 하는 메소드 */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        } else if segue.identifier == "CourseChangeSegue" {
            
            let segue = segue.destination as! ThemaTourViewController
            segue.themaGroupList = self.themaGroupList
            segue.courseGroupList = self.courseGroupList

        } else if segue.identifier == "SubImgDetail" {
            
            let segue = segue.destination as! SubImgDetailViewController
            
            segue.subImage = selectedSubImgPath
            segue.subImageText = selectedSubImgText
        }
    }
}



extension String {
    var length: Int {
        return self.characters.count
    }
}

class InsetLabel: UILabel {
    let topInset = CGFloat(12.0), bottomInset = CGFloat(12.0), leftInset = CGFloat(12.0), rightInset = CGFloat(12.0)
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override var intrinsicContentSize : CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}
