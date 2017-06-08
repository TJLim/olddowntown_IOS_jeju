//
//  ViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 3..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import Tamra
import SystemConfiguration

class ViewController: UIViewController, TamraManagerDelegate {
    
    var tamraManager: TamraManager!
    
    var Button1 = UIButton()
    var Button2 = UIButton()
    var Button3 = UIButton()
    
    var ButtonThemaTour = UIButton()
    var ButtonCourseTour = UIButton()
    var tourButtonBetweenBorder = UIView()
    
    var btn2ClickFlag: Bool = false
    
    var courseGroupList = [CourseGroupVO]()
    var themaGroupList = [CourseGroupVO]()
    var beaconGroupList = [Int]()   // 비콘 그룹 리스트
    var progress : ProgressDialog!
    var timer: Timer!
    var time: Float = 0.0
    var isDataGetFinish: Bool = false
    var btn1StartPosition: CGFloat!
    var btn2StartPosition: CGFloat!
    var btn3StartPosition: CGFloat!
    
    var screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 가로 길이
    var screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 세로 길이
    
    var visited: [Int: Visit] = [:]
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
    
    var isShowProgress: Bool = false    //
    var bluetoothState: Bool = false
    var common: CommonController!
    
    var getDataThreadTimer: Timer!
    var getDataThreadTime: Float = 0.0
    var getDataOfProcessNetwork: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        navigationController?.navigationBarHidden = true
        
        initTamraSet()
        initView()
        
        common = CommonController()
        isShowProgress = isConnectedNetwork()
        
        if isShowProgress {
            print("네트워크 연결 OK")
            getDataOfProcessNetwork = true
            
            getCourseGroupAndPoiInfo()
        } else {
            
            print("네트워크 연결 NO")
            getDataOfProcessNetwork = false
        }
        
        progress = ProgressDialog(delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.insertSubview(self.Button3, aboveSubview: self.ButtonThemaTour)
        self.view.insertSubview(self.Button3, aboveSubview: self.tourButtonBetweenBorder)
        self.view.insertSubview(self.Button3, aboveSubview: self.ButtonCourseTour)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("viewDidAppear")
        getDataProcess()
    }
    
    func getDataProcess() {
        
        if time < 3 {
            
            if isShowProgress {
                
                print("progress Show()")
                progress.Show(true, mesaj: "Loading Course Data...")
                
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.setProgressView), userInfo: nil, repeats: true)
                
                print("ViewController : 비콘 검색 시작")
                
                for i in 0 ..< beaconGroupList.count {
                    tamraManager.startMonitoring(forId: beaconGroupList[i])
                }
                
            } else {
                
                makeAlertDialog("NetworkOff")
                getDataThreadTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.getDataThread), userInfo: nil, repeats: true)
                
            }
        }
    }
    
    /* 네트워크가 꺼져있을 때 설정 화면에서 네트워크를 켠 후 복귀 하면 해당 메소드가 탄다. */
    func getDataThread() {
        
        getDataOfProcessNetwork = isConnectedNetwork()
        
        if getDataOfProcessNetwork {
            
            getDataThreadTimer.invalidate()
            getCourseGroupAndPoiInfo()
            
            isShowProgress = true
            getDataProcess()
        }
    }
    
    
    func setProgressView() {
        
        //        if isDataGetFinish == true {
        //            progress.Close()
        //        }
        time += 0.1
        
        if time >= 3 {
            progress.Close()
            //            timer.invalidate()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("ViewController : 비콘 검색 종료")
        tamraManager.stopMonitoring()
        
        btn2ClickFlag = false
        DisappearedUI()
    }
    
    
    //    override func viewDidDisappear(animated: Bool) {
    //        super.viewDidDisappear(animated)
    //        print("ViewController : 비콘 검색 종료")
    //        tamraManager.stopMonitoring()
    //
    //        btn2ClickFlag = false
    //
    //        DisappearedUI()
    //    }
    
    /* 비콘 그룹 세팅 */
    func setBeaconGroupData() {
        
        beaconGroupList.append(72)
        beaconGroupList.append(73)
        beaconGroupList.append(74)
        beaconGroupList.append(75)
        beaconGroupList.append(76)
        beaconGroupList.append(77)
        beaconGroupList.append(78)
    }
    
    func initView() {
        
        Button1.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight / 3)
        Button2.frame = CGRect(x: 0, y: screenHeight / 3, width: screenWidth, height: screenHeight / 3)
        Button3.frame = CGRect(x: 0, y: screenHeight / 3 * 2, width: screenWidth, height: screenHeight / 3)
        
        ButtonThemaTour.frame = CGRect(x: 0, y: screenHeight / 3 * 2, width: screenWidth, height: screenHeight / 10)
        tourButtonBetweenBorder.frame = CGRect(x: 0, y: screenHeight / 3 * 2 + screenHeight / 10, width: screenWidth, height: 1)
        ButtonCourseTour.frame = CGRect(x: 0, y: (screenHeight / 3 * 2 + screenHeight / 10) + 1, width: screenWidth, height: screenHeight / 10)
        
        Button1.setImage(UIImage(named: "btn1_on"), for: UIControlState())
        Button2.setImage(UIImage(named: "btn2_on"), for: UIControlState())
        ButtonThemaTour.setImage(UIImage(named: "app_btn_thema"), for: UIControlState())
        
        ButtonCourseTour.setImage(UIImage(named: "app_btn_course"), for: UIControlState())
        Button3.setImage(UIImage(named: "btn3_on"), for: UIControlState())
        
        Button1.addTarget(self, action: #selector(ViewController.goInfoView), for: .touchUpInside)
        Button2.addTarget(self, action: #selector(ViewController.Button2Click), for: .touchUpInside)
        Button3.addTarget(self, action: #selector(ViewController.goFootPrintView), for: .touchUpInside)
        
        ButtonThemaTour.addTarget(self, action: #selector(ViewController.goThemaTourView), for: .touchUpInside)
        ButtonCourseTour.addTarget(self, action: #selector(ViewController.goCourseTourView), for: .touchUpInside)
        
        btn1StartPosition = 0
        btn2StartPosition = screenHeight / 3
        btn3StartPosition = screenHeight / 3 * 2
        
        self.view.addSubview(Button1)
        self.view.addSubview(Button2)
        self.view.addSubview(Button3)
        self.view.addSubview(ButtonThemaTour)
        self.view.addSubview(ButtonCourseTour)
        self.view.addSubview(tourButtonBetweenBorder)
        
        setBeaconGroupData()
    }
    
    func Button2Click() {
        
        if btn2ClickFlag == false {
            
            btn2ClickFlag = true
            
            UIView.animate(withDuration: 0.5, animations: {
                
                self.Button3.center.y += self.screenHeight / 10 * 2 + 1
                
            })
            
            
        } else {
            
            btn2ClickFlag = false
            
            UIView.animate(withDuration: 0.5, animations: {
                
                self.Button3.center.y -= self.screenHeight / 10 * 2 + 1
                
            }, completion: nil)
            
            // 0.5초 후에 runningAfterFewSecondS() 메소드를 실행하는 함수.
            //            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(ViewController.runningAfterFewSecondS), userInfo: nil, repeats: false)
        }
        
        print("btn2ClickFlag : \(btn2ClickFlag)")
    }
    
    func goInfoView() {
        
        self.performSegue(withIdentifier: "IntroSegue", sender: self)
    }
    
    func goThemaTourView() {
        
        if themaGroupList.count == 0 {
            
            makeAlertDialog("NetworkOff")
            
            //            let alert = UIAlertController(title: "코스정보 미수신", message: "코스 정보를 받아 오지 못하였습니다. 어플을 다시 실행하여 주시기 바랍니다.", preferredStyle: .Alert)
            //
            //            let ok = UIAlertAction(title: "확인", style: .Default) {
            //                (parameter) -> Void in
            //
            //                return
            //            }
            //
            //            alert.addAction(ok)
            //
            //            self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
            self.performSegue(withIdentifier: "ThemaTourSegue", sender: self)
        }
    }
    
    func goCourseTourView() {
        if courseGroupList.count == 0 {
            
            makeAlertDialog("NetworkOff")
            
            //            let alert = UIAlertController(title: "코스정보 미수신", message: "코스 정보를 받아 오지 못하였습니다. 어플을 다시 실행하여 주시기 바랍니다.", preferredStyle: .Alert)
            //
            //            let ok = UIAlertAction(title: "확인", style: .Default) {
            //                (parameter) -> Void in
            //
            //                return
            //            }
            //
            //            alert.addAction(ok)
            //
            //            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "CourseTourSegue", sender: self)
        }
    }
    
    func goFootPrintView() {
        if courseGroupList.count == 0 {
            
            makeAlertDialog("NetworkOff")
            //            let alert = UIAlertController(title: "코스정보 미수신", message: "코스 정보를 받아 오지 못하였습니다. 어플을 다시 실행하여 주시기 바랍니다.", preferredStyle: .Alert)
            //
            //            let ok = UIAlertAction(title: "확인", style: .Default) {
            //                (parameter) -> Void in
            //
            //                return
            //            }
            //
            //            alert.addAction(ok)
            //
            //            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "FootPrintSegue", sender: self)
        }
    }
    
    
    func DisappearedUI() {
        
        self.Button1.frame = CGRect(x: 0, y: 0, width: screenWidth, height: self.Button1.frame.height)
        self.Button2.frame = CGRect(x: 0, y: btn2StartPosition, width: screenWidth, height: self.Button2.frame.height)
        self.Button3.frame = CGRect(x: 0, y: btn3StartPosition, width: screenWidth, height: self.Button3.frame.height)
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        
    }
    
    
    func makeAlertDialog(_ type: String) {
        
        if type == "NetworkOff" {
            
            let alert = UIAlertController(title: "네트워크 오류", message: "Wifi 또는 데이터가 꺼져있어 코스 정보를 불러올 수 없습니다.\n\n코스정보를 받아오려면 '확인' 버튼을 클릭하여 주시기 바랍니다.", preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "확인", style: .default) {
                (parameter) -> Void in
                
                UIApplication.shared.open(URL(string: "App-Prefs:root=Settings")!, options: [:], completionHandler: { (success) in
                    print("Open url : \(success)")
                    //self.getCourseData2()
                })
                
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            
            alert.addAction(cancel)
            alert.addAction(ok)
            
            self.present(alert, animated: true, completion: nil)
            
        } else if type == "ParsingError" {
            
            let alert = UIAlertController(title: "코스정보 미수신", message: "코스 정보를 받아 오지 못하였습니다. 어플을 다시 실행하여 주시기 바랍니다.", preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "확인", style: .default, handler: nil)
            
            alert.addAction(ok)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //    func getCourseData2() {
    //
    //        let workingQueue = dispatch_queue_create("my_queue", nil)
    //
    //        // Dispatch to the newly created queue. GCD take the responsibility for most things.
    //        dispatch_async(workingQueue) {
    //
    //
    //            NSThread.sleepForTimeInterval(10)  // Simulate for 2 secs executing time
    //            self.getCourseGroupAndPoiInfo()
    //            print("Working...")
    //            dispatch_async(dispatch_get_main_queue()) {
    //                // Return to main queue, update UI here
    //                print("Work done. Update UI")
    //            }
    //        }
    //    }
    
    
    func getCourseGroupAndPoiInfo(){
        
        Alamofire.request(common.getCourseDataURL).responseJSON{
            //Alamofire.request(.GET, common.getCourseDataURL, parameters: nil).responseJSON{
            
            response in switch response.result {
                
            case .success(_):
                
                let json = response.result.value
                
                if let objJson = json as! NSArray? {
                    
                    for element in objJson {
                        
                        let courseGroupVO = CourseGroupVO()
                        
                        let courseGroup = element as! NSDictionary
                        
                        courseGroupVO.courseGroupNo = courseGroup.object(forKey: "courseGroupNo") as! Int
                        courseGroupVO.courseMNo = courseGroup.object(forKey: "courseMNo") as! Int
                        courseGroupVO.courseMNm = courseGroup.object(forKey: "courseMNm") as! String
                        courseGroupVO.coursePoiCount = courseGroup.object(forKey: "coursePoiCount") as! Int
                        courseGroupVO.courseMText = courseGroup.object(forKey: "courseMText") as! String
                        courseGroupVO.courseMImg = courseGroup.object(forKey: "courseMImg") as! String
                        
                        let beaconList = courseGroup.object(forKey: "beaconList") as! NSArray?
                        
                        for element in beaconList! {
                            
                            let poiListVO = PoiListVO()
                            
                            let poiList = element as! NSDictionary
                            
                            poiListVO.courseDNo = poiList.object(forKey: "courseDNo") as! Int
                            poiListVO.courseMNo = poiList.object(forKey: "courseMNo") as! Int
                            poiListVO.courseMNm = poiList.object(forKey: "courseMNm") as! String
                            poiListVO.beaconId = poiList.object(forKey: "beaconId") as! Int
                            poiListVO.beaconNm = poiList.object(forKey: "beaconNm") as! String
                            poiListVO.beaconX = poiList.object(forKey: "beaconX") as! String
                            poiListVO.beaconY = poiList.object(forKey: "beaconY") as! String
                            
                            poiListVO.oldtownContentsNo = poiList.object(forKey: "oldtownContentsNo") as! Int
                            poiListVO.contentsTitle = poiList.object(forKey: "contentsTitle") as! String
                            poiListVO.contentsText = poiList.object(forKey: "contentsText") as! String
                            poiListVO.contentsImg = poiList.object(forKey: "contentsImg") as! String
                            poiListVO.courseContentsYn = poiList.object(forKey: "courseContentsYn") as! String
                            poiListVO.visited = false
                            
                            let subImgList = poiList.object(forKey: "subImgList") as! NSArray?
                            
                            for element in subImgList! {
                                
                                let subImgListVO = contentsSubImgVO()
                                
                                let subImgListDetail = element as! NSDictionary
                                
                                
                                subImgListVO.contentsDSeq = subImgListDetail.object(forKey: "contentsDSeq") as! Int
                                subImgListVO.contentsMNo = subImgListDetail.object(forKey: "contentsMNo") as! Int
                                subImgListVO.contentsDImg = subImgListDetail.object(forKey: "contentsDImg") as! String
                                subImgListVO.contentsDText = subImgListDetail.object(forKey: "contentsDText") as! String
                                
                                poiListVO.subImgList.append(subImgListVO)
                            }
                            
                            courseGroupVO.courseList.append(poiListVO)
                        }
                        
                        print("courseGroupNo : \(courseGroupVO.courseGroupNo)")
                        print("courseMNo : \(courseGroupVO.courseMNo)")
                        print("courseGroupNm : \(courseGroupVO.courseMNm)")
                        
                        if courseGroupVO.courseGroupNo == 1 {
                            self.themaGroupList.append(courseGroupVO)
                        } else if courseGroupVO.courseGroupNo == 2 {
                            self.courseGroupList.append(courseGroupVO)
                        }
                    }
                }
                self.isShowProgress = true
                //              self.isDataGetFinish = true
                
            case .failure(let error):
                
                self.makeAlertDialog("ParsingError")
                print("Request failed with error: \(error)")
                
                //              self.isDataGetFinish = true
            }
        }
    }
    
    /**/
    func runningAfterFewSecondS() {
        
        //        self.themaTourBtn.hidden = true
        //        self.courseTourBtn.hidden = true
    }
    
    
    
    func initTamraSet() {
        
        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }
    
    /* 네트워크 연결 상태 체크 메서드 */
    func isConnectedNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
            
        }) else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        } else if segue.identifier == "IntroSegue" {
            
            let segue = segue.destination as! IntroductionMainViewController
            
            segue.courseGroupList = self.courseGroupList
            segue.beaconGroupList = self.beaconGroupList
            
        } else if segue.identifier == "ThemaTourSegue" {
            
            let segue = segue.destination as! ThemaTourViewController
            
            segue.themaGroupList = self.themaGroupList
            segue.courseGroupList = self.courseGroupList
            segue.beaconGroupList = self.beaconGroupList
            
        } else if segue.identifier == "CourseTourSegue" {
            
            let segue = segue.destination as! CourseTourViewController
            
            segue.themaGroupList = self.themaGroupList
            segue.courseGroupList = self.courseGroupList
            segue.beaconGroupList = self.beaconGroupList
            
        } else if segue.identifier == "FootPrintSegue" {
            
            let segue = segue.destination as! FootPrintViewController
            
            segue.courseGroupList = self.courseGroupList
            segue.beaconGroupList = self.beaconGroupList
        }
    }
}

struct Visit {
    let desc: String
    let entry: Date
    let stay: Date = Date()
    
    init(desc: String, entry: Date) {
        self.desc = desc
        self.entry = entry
    }
    
    func update() -> Visit {
        return Visit(desc: self.desc, entry: self.entry)
    }
}
