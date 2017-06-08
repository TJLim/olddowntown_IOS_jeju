//
//  ThemaTourViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 3..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import Tamra
import KakaoNavi


class ThemaTourViewController: UIViewController, MTMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, TamraManagerDelegate {
    
    
    lazy var mapView: MTMapView = MTMapView(frame: CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height-95))
    var pickerDataSourse:[String] = []; // 코스 명 리스트
    
    var POIitems = [MTMapPOIItem]()
    var poiArray = [poiInfoVO]()
    
    var tamraManager: TamraManager!
    var visited: [Int: Visit] = [:]
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
    
    
    var courselist = [CourseGroupVO]()
    var poiList = [PoiListVO]()
    
    var courseGroupList = [CourseGroupVO]()
    var themaGroupList = [CourseGroupVO]()
    let screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 폭 길이
    let screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 높이 길이
    
    let gpsMarker = UIButton()
    var isCustomLocationMarkerUsing: Bool = false
    
    var selectedBeaconId: Int!
    
    var uiView = UIView()
    
    var m_mainCourseView = UIView()     // 주요 코스 뷰
    var m_Scrollview = UIScrollView()   // 주요 코스 메인 스크롤뷰
    var detailScrollview = UIScrollView()   // 마커클릭 후 상세화면에서 상세내용 관련 스크롤
    var courseIndex: Int!
    
    var mainCourseImgCnt = 0    // 코스별 주요 이미지 개수
    var subScrollCnt = 0        // 서브 스크롤 뷰 페이지 수 ( ex. 이미지가 5개면 페이지 2개 )
    var nowPageImgCnt = 0       // 현재 주요코스 스크롤 박스에 들어갈 이미지 개수
    
    var removeSubScrollTagList = [Int]()
    var dynamicSubScrollArr = [UIScrollView]()
    var isClickPOIMarker: Bool = false
    var isCourseNmBtnClickFlag: Bool = false
    
    
    let UICreatePickerView = UIPickerView()
    let UICreateCoverPicker = UIView()
    
    let UICourseNmLabel = UILabel()
    let UICourseChangeLabel = UILabel()
    var isCourseChanged: Bool = false
    
    var beaconGroupList = [Int]()   // 비콘 그룹 리스트
    var common: CommonController = CommonController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTourSet()
        mapViewInit()
        makeUI()
        
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
        
        print("ThemaTourViewController : 비콘 검색 시작")
        
        for i in 0 ..< beaconGroupList.count {
            
            tamraManager.startMonitoring(forId: beaconGroupList[i])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("ThemaTourViewController : 비콘 검색 종료")
        tamraManager.stopMonitoring()
        
        if isCustomLocationMarkerUsing {
            
            mapView.showCurrentLocationMarker = false
            mapView.currentLocationTrackingMode = MTMapCurrentLocationTrackingMode.off
            
            isCustomLocationMarkerUsing = false
        }
    }
    
    
    
    func makeUI() {
        
        createMainCourseBox(index: -1)
        createPickerView()
        
        UICourseNmLabel.frame = CGRect(x: 15, y: 44, width: screenWidth * 6 / 10 - 15, height: 44)
        UICourseNmLabel.text = "테마 선택"
        
        let target = UITapGestureRecognizer(target: self, action: #selector(CourseTourViewController.CourseNmLabelClick(_:)))
        target.numberOfTapsRequired = 1
        UICourseNmLabel.isUserInteractionEnabled = true
        UICourseNmLabel.addGestureRecognizer(target)
        
        UICourseChangeLabel.frame = CGRect(x: screenWidth * 6 / 10 - 15, y: 44, width: screenWidth * 4 / 10 + 15, height: 44)
        UICourseChangeLabel.textAlignment = .center
        UICourseChangeLabel.text = "코스 투어 가기"
        UICourseChangeLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        let target2 = UITapGestureRecognizer(target: self, action: #selector(CourseTourViewController.CourseChangeLabelClick(_:)))
        target2.numberOfTapsRequired = 1
        UICourseChangeLabel.isUserInteractionEnabled = true
        UICourseChangeLabel.addGestureRecognizer(target2)
        
        self.view.addSubview(UICourseNmLabel)
        self.view.addSubview(UICourseChangeLabel)
    }
    
    func createPickerView() {
        
        pickerDataSourse.append("테마 선택")
        
        for i in 0 ..< self.themaGroupList.count {
            
            pickerDataSourse.append(self.themaGroupList[i].courseMNm)
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
    
    
    func mapViewInit() {
        
        //mapView.frame.intersectInPlace(CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height - 95))
        mapView.frame.intersects(CGRect(x: 0, y: 95, width: self.view.frame.size.width, height: self.view.frame.size.height - 95))
        mapView.daumMapApiKey = "192483bc98b65172ee46bcc5e222dc9f"
        mapView.delegate = self
        mapView.baseMapType = .standard
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: 33.5025612, longitude: 126.5333188)), zoomLevel: 6, animated: true)
        mapView.useHDMapTile = true
    }
    
    
    /* 비콘 감지 메소드 */
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
    
    /* 주요 코스 화면 만드는 메소드 */
    func createMainCourseBox(index: Int) -> Bool {
        
        if index == -1 {
            
            return false
        }
        
        mainCourseImgCnt = 0
        nowPageImgCnt = 0
        subScrollCnt = 0
        
        removeSubview()
        
        //        beforeSubViewTagCnt = 0
        
        for i in 0 ..< themaGroupList[index].courseList.count {
            
            if themaGroupList[index].courseList[i].courseContentsYn == "Y" {
                
                mainCourseImgCnt += 1
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
            m_mainCourseLabel.font = UIFont(name: "Georgia-Bold", size: 16)
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
                    
                    let url: NSString = "http://221.162.53.24:8080\(themaGroupList[index].courseList[3 * i + j].contentsImg)" as NSString
                    //                    let url: NSString = "http://175.207.241.240:8080\(themaGroupList[index].courseList[3 * i + j].contentsImg)"
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
                    
                    letButton.tag = themaGroupList[index].courseList[3 * i + j].beaconId
                    s_Scrollview.addSubview(letButton)
                    
                    let letLabel = UILabel()
                    
                    letLabel.text = themaGroupList[index].courseList[3 * i + j].contentsTitle
                    letLabel.textAlignment = NSTextAlignment.center
                    letLabel.font = UIFont(name: (letLabel.font?.fontName)!, size: 14)
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
        
        self.view.insertSubview(m_mainCourseView, aboveSubview: self.view)
        
        return true
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
    }
    
    
    func CourseChangeLabelClick(_ recognizer: UITapGestureRecognizer) {
        
        isCourseChanged = true
        self.performSegue(withIdentifier: "CourseChangeSegue", sender: self)
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
    
    
    /* 주요코스 이미지 버튼 클릭시 선택된 비콘 이미지의 좌표를 중심점으로 잡음 */
    @IBAction func buttonPressed(_ sender: UIButton) {
        
        var lat: Double!
        var long: Double!
        var poiItem: MTMapPOIItem!
        
        for i in 0 ..< themaGroupList[courseIndex].courseList.count {
            
            if sender.tag == themaGroupList[courseIndex].courseList[i].beaconId {
                
                lat = Double( themaGroupList[courseIndex].courseList[i].beaconX)
                long = Double( themaGroupList[courseIndex].courseList[i].beaconY)
                poiItem = POIitems[i]
                break
            }
        }
        
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
        mapView.select(poiItem, animated: true)
    }
    
    func removeDetail() {
        uiView.removeFromSuperview()
    }
    
    /* Alamofire 를 이용하여 웹페이지 url을 호출하고 그에 맞는 결과값을 얻어 내오는 함수.
     
     감지한 비콘의 매핑 컨텐츠가 존재하는 경우 alert창을 띄움
     감지한 비콘의 매핑 컨텐츠가 존재하지 않는 경우 반응 없음
     */
    func isExistsMappingContentsId(_ spotId: Int, spotDesc: String) {
        
        LocalDbInsert(spotId)
        
        print("ThemaTourViewController : 매핑 컨텐츠 검색 시작")
        
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
                    self.mappingContentsNo = Int(contentsNo)
                    self.mappingContentsTitle = contentsTitle as? String
                    self.mappingFilePath = filePath as? String
                    
                    self.makeAlertMessage(spotDesc)
                }
                
            case .failure(let error):
                print("Request failed with error: \(error)")
            }
        }
        
        print("ThemaTourViewController : 매핑 컨텐츠 검색 종료")
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
        
        print("ThemaTourViewController : 로컬 디비에 감지한 비콘Id \(beaconId) 저장 시도")
        
        let result = makeQuery("beaconId BEGINSWITH '\(beaconId)'")
        
        
        if result.count == 0 {
            
            for i in 0 ..< themaGroupList.count {
                
                for j in 0 ..< themaGroupList[i].courseList.count {
                    
                    if themaGroupList[i].courseList[j].beaconId == beaconId {
                        
                        makeTask(beaconId, courseMNo: themaGroupList[i].courseList[j].courseMNo, courseMNm: themaGroupList[i].courseList[j].courseMNm)
                    }
                }
            }
            
            //            makeTask(beaconId)
            print("ThemaTourViewController : 비콘Id \(beaconId) 저장 완료")
        } else {
            
            for VisitBeaconArea in result {
                
                print(VisitBeaconArea.beaconId)
                print(VisitBeaconArea.regDt)
                print("ThemaTourViewController : 비콘Id \(beaconId)은 이미 저장되어 있음")
            }
            removeTask(result)
            
            for i in 0 ..< themaGroupList.count {
                
                for j in 0 ..< themaGroupList[i].courseList.count {
                    
                    if themaGroupList[i].courseList[j].beaconId == beaconId {
                        
                        makeTask(beaconId, courseMNo: themaGroupList[i].courseList[j].courseMNo, courseMNm: themaGroupList[i].courseList[j].courseMNm)
                    }
                }
            }
        }
    }
    
    
    /* poi 정보 셋 해주는 함수 */
    /* 나중에 db정보를 불러와 셋 해줘야 함 */
    func setPoiInfo(_ index: Int) {
        
        poiArray.removeAll()
        
        for i in 0 ..< themaGroupList[index-1].courseList.count {
            
            let poiInfo = poiInfoVO()
            
            let result = makeQuery("beaconId BEGINSWITH '\(themaGroupList[index-1].courseList[i].beaconId)'")
            
            if result.count == 0 {
                poiInfo.visitPoi = false
            } else {
                poiInfo.visitPoi = true
            }
            
            poiInfo.poiName = themaGroupList[index-1].courseList[i].contentsTitle
            poiInfo.poiLat = Double(themaGroupList[index-1].courseList[i].beaconX)!
            poiInfo.poiLong = Double(themaGroupList[index-1].courseList[i].beaconY)!
            poiInfo.poiDescription = poiInfo.poiName
            poiInfo.poiBeaconId = themaGroupList[index-1].courseList[i].beaconId
            
            poiArray.append(poiInfo)
        }
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
    
    /* mapView 마커 클릭 이벤트 메소드 */
    func mapView(_ mapView: MTMapView!, selectedPOIItem poiItem: MTMapPOIItem!) -> Bool {
        
        print("select POI : \(poiItem.itemName)")
        
        return true
    }
    
    /* mapView 화면 클릭 시 이벤트 메소드 */
    func mapView(_ mapView: MTMapView!, singleTapOn mapPoint: MTMapPoint!) {
        removeDetail()
        isClickPOIMarker = false
    }
    
    /* pickerView 선택시 동작하는 메소드 */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        isCourseNmBtnClickFlag = false
        UICourseNmLabel.text = pickerDataSourse[row]
        invisiableCourseList()
        
        POIitems.removeAll()
        mapView.removeAllPOIItems()
        courseIndex = row - 1
        
        let isShowingMainCourseBox = createMainCourseBox(index: courseIndex)
        
        if row != 0 {
            
            setPoiInfo(row)
            
            for i in 0 ..< poiArray.count {
                
                POIitems.append(poiItem(poiArray[i].poiName, latitude: poiArray[i].poiLat, longitude: poiArray[i].poiLong, color: "blue", tag: poiArray[i].poiBeaconId))
            }
            
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
    
    
    /* 커스텀 마커 */
    func poiItem(_ name: String, latitude: Double, longitude: Double, custom: Bool) -> MTMapPOIItem {
        let poiItem = MTMapPOIItem()
        poiItem.itemName = name
        poiItem.markerType = .customImage                           //커스텀 타입으로 변경
        poiItem.customImage = UIImage(named: "markerStar")        //커스텀 이미지 지정
        poiItem.markerSelectedType = .customImage                   //선택 되었을 때 마커 타입
        poiItem.customSelectedImage = UIImage(named: "customSelectedMarker")    //선택 되었을 때 마커 이미지 지정
        poiItem.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
        poiItem.showAnimationType = .noAnimation
        poiItem.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)
        
        return poiItem
    }
    
    /* 일반 마커 */
    func poiItem(_ name: String, latitude: Double, longitude: Double, color: String, tag: Int) -> MTMapPOIItem {
        
        let item = MTMapPOIItem()
        
        if color == "red" {
            
            item.markerType = .redPin
            item.markerSelectedType = .redPin
            
        } else if color == "blue" {
            
            item.markerType = .bluePin
            item.markerSelectedType = .bluePin
        }
        
        item.itemName = name
        item.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
        item.showAnimationType = .noAnimation
        item.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)    // 마커 위치 조정
        item.tag = tag
        
        return item
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
    
    
    /* 선택된 비콘의 상세화면 뿌리기 */
    func setDetailOfBeaconID(_ beaconId: Int) {
        
        var lat: Double!
        var long: Double!
        var detailNm: String!
        var detailDescription: String!
        var detailImg: String!
        
        for i in 0 ..< themaGroupList[courseIndex].courseList.count {
            
            if themaGroupList[courseIndex].courseList[i].beaconId == beaconId { // 선택된 비콘의 tag(beaconId) 와 courseList의 beaconId가 같은 경우
                
                lat = Double(themaGroupList[courseIndex].courseList[i].beaconX)
                long = Double(themaGroupList[courseIndex].courseList[i].beaconY)
                detailNm = themaGroupList[courseIndex].courseList[i].contentsTitle
                detailDescription = themaGroupList[courseIndex].courseList[i].contentsText
                detailImg = themaGroupList[courseIndex].courseList[i].contentsImg
                
                break
            }
        }
        
        detailNm = subStringBeaconTitle(detailNm)   // ContentsNm에 특수문자 들어가는경우 빼는 함수
        
        uiView.frame = CGRect(x: 0, y: screenHeight / 2, width: screenWidth, height: screenHeight / 2)
        uiView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        let uiButtonBack = UIButton()
        let uiButtonNm = UIButton()
        let uiButtonNavi = UIButton()
        let uiDetailImgButton = UIButton()
        let uiDetailText = UILabel()
        
        
        uiButtonBack.frame = CGRect(x: 0, y: 0, width: 30, height: 50)
        //        uiButtonBack.setTitle("X", forState: .Normal)
        var leftImg: UIImage = UIImage()
        leftImg = UIImage(named: "left.png")!
        //        leftImg.drawInRect(CGRect(x: 5, y: 10, width: 25, height: 30))
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
        
        var letImage = UIImage()
        
        let url: NSString = "http://www.jeju-showcase.com\(detailImg)" as NSString
        //        let url: NSString = "http://175.207.241.240:8080\(detailImg)"
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
        
        uiDetailImgButton.frame = CGRect(x: 15, y: 10, width: screenWidth / 3, height: 100)
        uiDetailImgButton.setImage(letImage, for: UIControlState())
        
        uiDetailText.text = detailDescription
        let uiDetailTextHeight = calculateContentHeight(uiDetailText)
        
        uiDetailText.frame = CGRect(x: 15, y: 130, width: screenWidth - 30 , height: uiDetailTextHeight)
        detailScrollview.contentSize = CGSize(width: screenWidth, height: uiDetailTextHeight)
        
        
        uiDetailText.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        uiDetailText.numberOfLines = 0
        //        uiDetailText.adjustsFontSizeToFitWidth = true
        
        
        detailScrollview.addSubview(uiDetailImgButton)
        detailScrollview.addSubview(uiDetailText)
        uiView.addSubview(uiButtonBack)
        uiView.addSubview(uiButtonNm)
        uiView.addSubview(uiButtonNavi)
        uiView.addSubview(detailScrollview)
        
        visibleDetail()
        
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: lat, longitude: long)), zoomLevel: 2, animated: true)
    }
    
    
    /* 비콘 컨텐츠 제목 버튼 클릭 이벤트 메소드 */
    func detailNmBtnClick() {
        removeDetail()
        isClickPOIMarker = false
        
    }
    
    /* 길찾기 눌렀을 시 카카오네비 연동*/
    func loadKakaoNavi(_ sender: UIButton) {
        
        let beaconId: Int = sender.tag
        var lat: Double!
        var long: Double!
        var contentsTitle: String!
        
        for i in 0 ..< themaGroupList[courseIndex].courseList.count {
            
            if beaconId == themaGroupList[courseIndex].courseList[i].beaconId {
                
                lat = Double(themaGroupList[courseIndex].courseList[i].beaconY)
                long = Double(themaGroupList[courseIndex].courseList[i].beaconX)
                contentsTitle = themaGroupList[courseIndex].courseList[i].contentsTitle
                
                break
            }
        }
        
        // NAVI INIT START
        let option: KNVOptions = KNVOptions.init()
        let naviLauncher:KNVNaviLauncher = KNVNaviLauncher.init()
        let coordType: KNVCoordType = KNVCoordType.init(rawValue: 2)!
        let navi: KNVLocation = KNVLocation(name: contentsTitle, x:lat! as NSNumber, y: long! as NSNumber)
        option.coordType = coordType
        let params: KNVParams = KNVParams.param(withDestination: navi, options: option)
        
        // NAVI START
        naviLauncher.shareDestination(with: params, error: nil)
    }
    
    
    /* 선택된 비콘에 매핑된 상세 컨텐츠를 띄우는 메소드 */
    func visibleDetail() {
        
        self.view.addSubview(uiView)
    }
    
    /* ContentsNm에 특수문자 들어가는경우 빼는 함수 */
    func subStringBeaconTitle(_ detailNm: String) -> String {

        var search: String
        
        var returnStringArr = [String]();
        
        if detailNm.contains("(") {
            
            search = "("
            
            returnStringArr = detailNm.components(separatedBy: search)
            
            return returnStringArr[0]
            
        } else if detailNm.contains("<") {
            
            search = "<"
            
            returnStringArr = detailNm.components(separatedBy: search)
            
            return returnStringArr[0]
            
        } else if detailNm.contains("/") {
            
            search = "/"
            
            returnStringArr = detailNm.components(separatedBy: search)
            
            return returnStringArr[0]
            
        } else if detailNm.contains("{") {
            
            search = "{"
            
            returnStringArr = detailNm.components(separatedBy: search)
            
            return returnStringArr[0]
            
        }
        
        return detailNm
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Back(_ sender: AnyObject) {
        
        self.dismiss(animated: false, completion: nil)
        
    }
    
    func removeAllTask(){
        
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
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
    //    func makeTask(beaconId: Int){
    //
    //        let task = VisitBeaconArea()
    //        task.beaconId = String(beaconId)
    //
    //        let realm = try! Realm()
    //
    //        try! realm.write {
    //            realm.add(task)
    //        }
    //    }
    func removeTask(_ task: Results<VisitBeaconArea>){
        let realm = try! Realm()
        try! realm.write {
            realm.delete(task)
        }
    }
    func makeQuery(_ query:String) -> Results<VisitBeaconArea>{
        
        print("makeQuery String : \(query)")
        let realm = try! Realm()
        let allTask = realm.objects(VisitBeaconArea.self)
        let queryResult = allTask.filter(query)
        return queryResult
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
    
    
    func visiableCourseList() {
        
        self.view.insertSubview(UICreateCoverPicker, aboveSubview: self.mapView)
    }
    
    func invisiableCourseList() {
        
        self.view.insertSubview(self.mapView, aboveSubview: UICreateCoverPicker)
        
        self.view.insertSubview(gpsMarker, aboveSubview: self.mapView)
    }
    
    func calculateContentHeight(_ setLable: UILabel) -> CGFloat {
        
        let widthSizeminus: CGFloat = 30
        let maxlabelSize: CGSize = CGSize(width: self.view.frame.size.width - widthSizeminus, height: CGFloat(9999))
        
        let options:NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let contentNSString = setLable.text! as NSString
        let expectedLabelSize = contentNSString.boundingRect(with: maxlabelSize, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17.0)], context: nil)
        
        return expectedLabelSize.size.height
    }
    
    
    /* 페이지 이동시 넘겨질 데이터 set 하는 메소드 */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("segue.identifier : \(String(describing: segue.identifier))")
        
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        } else if segue.identifier == "CourseChangeSegue" {
            
            let segue = segue.destination as! CourseTourViewController
            
            segue.themaGroupList = self.themaGroupList
            segue.courseGroupList = self.courseGroupList
        }
    }
    
    func dataInit() {
        
        UICourseNmLabel.text = "테마 선택"
        
        mapView.removeAllPOIItems()
        invisibleMainCourseBox()
        mapView.setMapCenter(MTMapPoint(geoCoord: .init(latitude: 33.5025612, longitude: 126.5333188)), zoomLevel: 6, animated: true)
    }
}
